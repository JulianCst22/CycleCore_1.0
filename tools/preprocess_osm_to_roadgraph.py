#!/usr/bin/env python3
"""
Convierte un extracto OpenStreetMap (.osm.pbf) en un archivo binario
.roadgraph (formato v2, con Contraction Hierarchies precalculadas)
listo para que RoadGraph.parse() (Dart) haga ruteo bidireccional
ultra rápido directo en el dispositivo, sin Dijkstra plano.

Uso:
    pip install osmium
    python3 preprocess_osm_to_roadgraph.py entrada.osm.pbf salida.roadgraph

------------------------------------------------------------------
QUÉ CAMBIÓ RESPECTO A LA VERSIÓN v1 (solo filtrado de vías)
------------------------------------------------------------------
1. Cada RoadType ahora tiene un "costo de prioridad" (no solo la
   distancia en metros importa): vías principales cuestan menos por
   metro real que vías residenciales, así que el algoritmo de ruteo
   las prefiere de forma natural sin dejar de ser Dijkstra/CH
   correcto (sigue siendo el camino de MENOR COSTO, solo que costo
   ya no es igual a distancia pura).
2. Fase de contracción: se ordenan los nodos por "importancia" y se
   contraen uno por uno, generando shortcuts (atajos) que preservan
   los caminos de menor costo. El resultado es una jerarquía que
   permite búsqueda bidireccional en runtime, sin explorar todo el
   grafo.
3. El .roadgraph v2 incluye: nodos, aristas originales + shortcuts,
   nivel de contracción de cada nodo, y el costo de prioridad ya
   horneado en cada arista.

Formato de salida v2 (little-endian, ver road_graph.dart):
    4 bytes  magic "RGF2"
    int32    cantidad de nodos (N)
    N * (float64 lat, float64 lng, int32 chLevel)
    int32    cantidad de aristas totales, originales + shortcuts (E)
    E * (int32 from, int32 to, float32 chCost,
         uint8 roadType, uint8 oneWay, uint8 isShortcut,
         int32 viaEdgeA, int32 viaEdgeB, float32 distanceMeters)
         -- viaEdgeA/viaEdgeB solo tienen sentido si isShortcut=1
            (índices de las 2 aristas que este atajo reemplaza,
            para poder "desenrollar" la ruta real al final).
         -- distanceMeters es la distancia REAL (no ponderada) --
            necesaria aparte de chCost porque el router usa chCost
            para decidir el camino pero la UI/instrucciones de giro
            necesitan metros reales. Para shortcuts, distanceMeters
            es la suma de las distancias reales de las 2 aristas que
            reemplaza (se sigue pudiendo mostrar "X km" correctos
            aunque la ruta final use shortcuts antes de expandirse).
"""

import sys
import struct
import math
import heapq

try:
    import osmium
except ImportError:
    print("Falta la librería 'osmium'. Instalala con: pip install osmium")
    sys.exit(1)


# Mismo orden que el enum RoadType en road_graph.dart -- si cambiás
# uno, cambiá el otro.
ROAD_TYPES = ["unknown", "primary", "secondary", "residential", "cycleway", "path"]

# Tags de OSM `highway=*` que se consideran "vía transitable" para
# este grafo, mapeados al RoadType correspondiente.
# Se removieron 'track', 'path' y 'footway' para evitar destapados y trochas.
HIGHWAY_TO_ROAD_TYPE = {
    "motorway": "primary",
    "trunk": "primary",
    "primary": "primary",
    "secondary": "secondary",
    "tertiary": "secondary",
    "residential": "residential",
    "living_street": "residential",
    "unclassified": "residential",
    "cycleway": "cycleway",
}

# Superficies prohibidas explícitamente para asegurar que sean vías pavimentadas
BAD_SURFACES = {
    "unpaved", "dirt", "gravel", "sand", "mud", "earth", "ground", "grass", "compacted"
}

# ------------------------------------------------------------------
# PESO DE PRIORIDAD POR TIPO DE VÍA -- "balance moderado"
# ------------------------------------------------------------------
# Multiplica la distancia real (metros) para obtener el "costo" que
# usa el algoritmo. Un multiplicador MENOR a 1.0 hace que esa vía se
# vea "más corta" de lo que es en la práctica, así que el algoritmo
# la prefiere. Un multiplicador MAYOR a 1.0 la penaliza.
#
# Balance moderado = las principales se prefieren claramente, pero
# las secundarias/residenciales no quedan descartadas salvo que el
# desvío por la principal sea mucho más largo en la realidad. Es
# decir: para un tramo corto, gana la vía real más corta casi
# siempre; para tramos largos, el algoritmo tiende a "saltar" a la
# principal en cuanto compensa el rodeo.
ROAD_TYPE_COST_MULTIPLIER = {
    "primary": 0.75,       # autopistas / troncales / avenidas principales
    "secondary": 0.90,     # vías secundarias / colectoras
    "residential": 1.15,   # calles de barrio
    "cycleway": 0.70,      # ciclovía dedicada -- la mejor opción posible
    "unknown": 1.30,
}

# Penalización adicional fija (en metros "virtuales") por cada tramo
# de tipo residencial que motiva evitar zigzaguear por calles internas
# aunque cada tramo individual sea corto -- sin esto, muchos tramos
# residenciales cortos podrían ganarle a una sola vía principal larga
# por acumulación de descuentos que no aplican.
RESIDENTIAL_FIXED_PENALTY_METERS = 15.0


def haversine_meters(lat1, lng1, lat2, lng2):
    r = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def edge_cost(distance_m, road_type):
    """Costo ponderado (no la distancia cruda) que usa el ruteo.
    Esto es lo que hace que el algoritmo 'prefiera' vías principales
    sin dejar de ser un algoritmo de camino más corto correcto -- el
    camino de menor COSTO puede no ser el de menor DISTANCIA."""
    mult = ROAD_TYPE_COST_MULTIPLIER.get(road_type, 1.30)
    cost = distance_m * mult
    if road_type == "residential":
        cost += RESIDENTIAL_FIXED_PENALTY_METERS
    return cost


class RoadWayHandler(osmium.SimpleHandler):
    """Primera pasada: recolecta, por cada `way` de tipo vía, la lista
    de node-ids que la componen, su tipo y si es de sentido único."""

    def __init__(self):
        super().__init__()
        self.ways = []  # lista de (node_ids: list[int], road_type: str, oneway: bool)
        self.used_node_ids = set()

    def way(self, w):
        highway = w.tags.get("highway")
        if highway is None or highway not in HIGHWAY_TO_ROAD_TYPE:
            return

        # Filtro estricto de superficies destapadas
        surface = w.tags.get("surface")
        if surface in BAD_SURFACES:
            return

        node_ids = [n.ref for n in w.nodes]
        if len(node_ids) < 2:
            return

        oneway_tag = w.tags.get("oneway", "no")
        oneway = oneway_tag in ("yes", "true", "1")

        road_type = HIGHWAY_TO_ROAD_TYPE[highway]
        self.ways.append((node_ids, road_type, oneway))
        self.used_node_ids.update(node_ids)


class NodeCoordHandler(osmium.SimpleHandler):
    """Segunda pasada: solo para los node-ids que sí forman parte de
    alguna vía (evita cargar en memoria TODOS los nodos del extracto,
    la mayoría de los cuales son solo geometría de edificios/etc)."""

    def __init__(self, wanted_ids):
        super().__init__()
        self.wanted_ids = wanted_ids
        self.coords = {}  # node_id -> (lat, lng)

    def node(self, n):
        if n.id in self.wanted_ids:
            self.coords[n.id] = (n.location.lat, n.location.lon)


def build_graph(pbf_path):
    print("Pasada 1/2: leyendo vías...")
    way_handler = RoadWayHandler()
    way_handler.apply_file(pbf_path, locations=False)
    print(f"  {len(way_handler.ways)} vías, {len(way_handler.used_node_ids)} nodos usados")

    print("Pasada 2/2: leyendo coordenadas de esos nodos...")
    node_handler = NodeCoordHandler(way_handler.used_node_ids)
    node_handler.apply_file(pbf_path, locations=True)
    print(f"  {len(node_handler.coords)} coordenadas resueltas")

    # Reindexa los node-ids de OSM (int64 dispersos) a índices densos
    # 0..N-1 -- así el formato binario puede usar int32 en vez de
    # int64 para cada referencia de nodo.
    osm_id_to_index = {}
    nodes = []  # lista de (lat, lng) en orden de índice
    for osm_id, (lat, lng) in node_handler.coords.items():
        osm_id_to_index[osm_id] = len(nodes)
        nodes.append((lat, lng))

    # Convierte cada way (secuencia de N nodos) en N-1 aristas
    # consecutivas -- un way de 5 nodos es un "camino poligonal" de 4
    # tramos rectos. Cada arista guarda distancia real Y costo
    # ponderado por tipo de vía.
    edges = []  # dict: from, to, dist_m, cost, road_type_idx, oneway
    for node_ids, road_type, oneway in way_handler.ways:
        indices = [osm_id_to_index.get(nid) for nid in node_ids]
        road_type_idx = ROAD_TYPES.index(road_type)
        for i in range(len(indices) - 1):
            a, b = indices[i], indices[i + 1]
            if a is None or b is None:
                continue  # nodo sin coordenada resuelta (raro, pero posible en el borde del extracto)
            lat1, lng1 = nodes[a]
            lat2, lng2 = nodes[b]
            dist = haversine_meters(lat1, lng1, lat2, lng2)
            cost = edge_cost(dist, road_type)
            edges.append({
                "from": a, "to": b, "dist_m": dist, "cost": cost,
                "road_type_idx": road_type_idx, "oneway": oneway,
                "is_shortcut": False, "via_a": -1, "via_b": -1,
                "real_dist_m": dist,
            })

    print(f"Grafo base: {len(nodes)} nodos, {len(edges)} aristas")
    return nodes, edges


# ------------------------------------------------------------------
# CONTRACTION HIERARCHIES -- fase de preprocesamiento
# ------------------------------------------------------------------
# Idea central: contraemos los nodos uno por uno, en orden de
# "importancia creciente" (los menos importantes primero). Al
# contraer un nodo v, para cada par de vecinos (u, w) de v,
# verificamos si el camino u -> v -> w sigue siendo el camino más
# corto entre u y w una vez que v ya no está disponible como nodo
# intermedio. Si lo es, agregamos un "shortcut" u -> w que representa
# ese camino de 2 saltos, para no perder esa ruta al sacar v del
# grafo. El orden de contracción determina la calidad de la
# jerarquía: contraemos primero los nodos "menos conectados"
# (menor edge difference), dejando las autopistas/troncales para el
# final -- eso es justamente lo que hace que la búsqueda en runtime
# se concentre en las vías principales cuando el origen y destino
# están lejos.

class ContractionGraph:
    def __init__(self, num_nodes, edges):
        self.n = num_nodes
        # adyacencia dinámica: node -> list of (neighbor, cost, edge_idx, oneway_forward)
        self.out = [[] for _ in range(num_nodes)]
        self.inn = [[] for _ in range(num_nodes)]
        self.edges = edges  # se va extendiendo con shortcuts
        self.contracted = [False] * num_nodes
        self.level = [0] * num_nodes

        for idx, e in enumerate(edges):
            self._add_adj(e["from"], e["to"], idx)
            if not e["oneway"]:
                self._add_adj(e["to"], e["from"], idx, reversed_=True)

    def _add_adj(self, a, b, edge_idx, reversed_=False):
        self.out[a].append((b, edge_idx, reversed_))
        self.inn[b].append((a, edge_idx, reversed_))

    def edge_cost(self, edge_idx, reversed_):
        e = self.edges[edge_idx]
        return e["cost"]

    def neighbors_out(self, v):
        for (b, idx, rev) in self.out[v]:
            if self.contracted[b]:
                continue
            yield b, self.edge_cost(idx, rev)

    def neighbors_in(self, v):
        for (a, idx, rev) in self.inn[v]:
            if self.contracted[a]:
                continue
            yield a, self.edge_cost(idx, rev)

    def add_shortcut(self, a, b, cost, via_edge_a, via_edge_b):
        # distancia real del atajo = suma de las distancias reales de
        # las 2 aristas que reemplaza, para que el RoutePath final
        # (ya desenrollado en Dart) siga reportando metros correctos
        # incluso en los tramos que pasaron por un shortcut.
        real_dist = (
            self.edges[via_edge_a]["real_dist_m"]
            + self.edges[via_edge_b]["real_dist_m"]
        )
        idx = len(self.edges)
        self.edges.append({
            "from": a, "to": b, "dist_m": 0.0, "cost": cost,
            "road_type_idx": 0, "oneway": True,
            "is_shortcut": True, "via_a": via_edge_a, "via_b": via_edge_b,
            "real_dist_m": real_dist,
        })
        self._add_adj(a, b, idx)
        return idx

    def witness_search(self, source, target, max_cost, avoid):
        """Dijkstra local acotado: ¿existe un camino de source a
        target que NO pase por 'avoid' (el nodo que estamos
        contrayendo) y que cueste <= max_cost? Si sí, el shortcut
        source->target NO hace falta (ya existe una alternativa
        igual o mejor sin pasar por v)."""
        if source == target:
            return True
        dist = {source: 0.0}
        pq = [(0.0, source)]
        visited = set()
        # límite de nodos explorados para que esto sea rápido -- es
        # una búsqueda LOCAL, no queremos recorrer medio Bogotá por
        # cada verificación de shortcut.
        max_settled = 60
        while pq and len(visited) < max_settled:
            d, u = heapq.heappop(pq)
            if u in visited:
                continue
            visited.add(u)
            if u == target:
                return d <= max_cost
            if d > max_cost:
                continue
            for (b, idx, rev) in self.out[u]:
                if b == avoid or self.contracted[b]:
                    continue
                nd = d + self.edge_cost(idx, rev)
                if nd > max_cost:
                    continue
                if b not in dist or nd < dist[b]:
                    dist[b] = nd
                    heapq.heappush(pq, (nd, b))
        return False

    def contraction_priority(self, v):
        """Edge difference: cuántos shortcuts necesitaría agregar al
        contraer v, menos cuántas aristas desaparecen. Nodos con
        prioridad baja (pocas conexiones, ej. una calle residencial
        sin salida) se contraen primero; nodos muy conectados (una
        troncal con muchos cruces) se contraen al final y por eso
        quedan 'arriba' en la jerarquía -- son los que se usan para
        los saltos largos en runtime."""
        neighbors_in = list(self.neighbors_in(v))
        neighbors_out = list(self.neighbors_out(v))
        shortcuts_needed = 0
        for (u, cost_uv) in neighbors_in:
            for (w, cost_vw) in neighbors_out:
                if u == w:
                    continue
                shortcuts_needed += 1  # estimación optimista (upper bound), suficiente para ordenar
        removed = len(neighbors_in) + len(neighbors_out)
        return shortcuts_needed - removed

    def contract_node(self, v):
        neighbors_in = list(self.neighbors_in(v))
        neighbors_out = list(self.neighbors_out(v))
        for (u, cost_uv) in neighbors_in:
            if u == v:
                continue
            for (w, cost_vw) in neighbors_out:
                if w == v or w == u:
                    continue
                total = cost_uv + cost_vw
                if not self.witness_search(u, w, total, v):
                    # no hay atajo mejor sin pasar por v -> hace falta el shortcut
                    edge_idx_uv = self._find_edge_idx(u, v)
                    edge_idx_vw = self._find_edge_idx(v, w)
                    self.add_shortcut(u, w, total, edge_idx_uv, edge_idx_vw)
        self.contracted[v] = True

    def _find_edge_idx(self, a, b):
        for (nb, idx, rev) in self.out[a]:
            if nb == b and not self.contracted[b]:
                return idx
        # fallback: puede ser un shortcut recién creado
        for (nb, idx, rev) in self.out[a]:
            if nb == b:
                return idx
        return -1


def build_contraction_hierarchy(num_nodes, edges):
    print("Preprocesamiento CH: ordenando nodos por importancia...")
    cg = ContractionGraph(num_nodes, edges)

    # Cola de prioridad lazy: (edge_difference, node). Recalculamos
    # la prioridad del nodo en el momento de sacarlo de la cola por
    # si cambió desde que se insertó (los vecinos ya contraídos
    # bajan su prioridad).
    pq = []
    for v in range(num_nodes):
        heapq.heappush(pq, (cg.contraction_priority(v), v))

    order = 0
    total = num_nodes
    report_every = max(1, total // 20)

    while pq:
        _, v = heapq.heappop(pq)
        if cg.contracted[v]:
            continue
        fresh_priority = cg.contraction_priority(v)
        if pq and fresh_priority > pq[0][0]:
            # otro nodo ahora es más barato de contraer -- reinsertar
            # y probar con ese primero (lazy update, estándar en CH)
            heapq.heappush(pq, (fresh_priority, v))
            continue
        cg.contract_node(v)
        cg.level[v] = order
        order += 1
        if order % report_every == 0:
            pct = 100 * order // total
            print(f"  {pct}% contraído ({order}/{total} nodos, {len(cg.edges)} aristas totales)")

    print(f"CH lista: {len(cg.edges)} aristas totales ({len(cg.edges) - len(edges)} shortcuts agregados)")
    return cg.level, cg.edges


def write_roadgraph(path, nodes, levels, edges):
    with open(path, "wb") as f:
        f.write(b"RGF2")
        f.write(struct.pack("<i", len(nodes)))
        for (lat, lng), level in zip(nodes, levels):
            f.write(struct.pack("<ddi", lat, lng, level))

        f.write(struct.pack("<i", len(edges)))
        for e in edges:
            f.write(struct.pack(
                "<iifBBBiif",
                e["from"],
                e["to"],
                e["cost"],
                e["road_type_idx"],
                1 if e["oneway"] else 0,
                1 if e["is_shortcut"] else 0,
                e["via_a"],
                e["via_b"],
                e["real_dist_m"],
            ))
            # "<iifBBBiif": 2 int32 (from,to) + 1 float32 (chCost) +
            # 3 uint8 (roadType, oneWay, isShortcut) + 2 int32
            # (viaEdgeA, viaEdgeB) + 1 float32 (distanceMeters real)
            # -- coincide con RoadGraph._parseV2 en road_graph.dart


def main():
    if len(sys.argv) != 3:
        print(f"Uso: {sys.argv[0]} entrada.osm.pbf salida.roadgraph")
        sys.exit(1)

    pbf_path, out_path = sys.argv[1], sys.argv[2]
    nodes, edges = build_graph(pbf_path)
    levels, all_edges = build_contraction_hierarchy(len(nodes), edges)
    write_roadgraph(out_path, nodes, levels, all_edges)
    print(f"Listo: {out_path}")


if __name__ == "__main__":
    main()
