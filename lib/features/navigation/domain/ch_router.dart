import 'package:collection/collection.dart';

import 'a_star_router.dart' show RoutePath;
import 'road_graph.dart';

/// Calcula el camino de menor costo entre dos nodos usando búsqueda
/// bidireccional sobre la jerarquía de Contraction Hierarchies (CH)
/// precalculada en los niveles de los nodos y los atajos del grafo.
///
/// Corre DOS Dijkstra a la vez -- uno desde el origen, otro desde el
/// destino -- que solo suben en la jerarquía (hacia nodos de nivel
/// mayor, es decir, hacia vías más importantes). Eso concentra la
/// exploración en la parte alta del grafo y por eso es rápido.
///
/// Dos detalles que antes estaban mal y hacían rutas raras:
///  - Cuándo parar. En un Dijkstra bidireccional común basta con que la
///    suma de los dos frentes supere al mejor encuentro, pero en CH las
///    dos búsquedas recorren grafos distintos (cada una solo sube), así
///    que esa regla cortaba antes de tiempo y podía devolver una ruta
///    peor. Acá cada frente sigue mientras su mínimo sea menor que el
///    mejor encuentro.
///  - Desenrollar los atajos respetando el sentido. Una vía de doble
///    sentido recorrida al revés devolvía el nodo de partida en vez del
///    de llegada, y la línea dibujada salía con picos.
///
/// El costo que se minimiza es el ponderado por tipo de vía (ver
/// `tools/preprocess_osm_to_roadgraph.py`), no los metros: por eso la
/// ruta prefiere las vías principales. La distancia que se muestra se
/// sigue sumando con los metros reales de cada tramo.
class ChRouter {
  final RoadGraph graph;
  const ChRouter(this.graph);

  RoutePath? findPath({
    required int startNodeIndex,
    required int endNodeIndex,
  }) {
    if (startNodeIndex == endNodeIndex) {
      return RoutePath(
        nodeIndices: [startNodeIndex],
        edgesUsed: const [],
        totalDistanceMeters: 0,
      );
    }

    final fwd = _Search(startNodeIndex);
    final bwd = _Search(endNodeIndex);
    var best = double.infinity;
    var meet = -1;

    void settle(_Search mine, _Search theirs, {required bool forward}) {
      final entry = mine.queue.removeFirst();
      final u = entry.node;
      if (entry.dist > (mine.dist[u] ?? double.infinity)) return;
      final through = entry.dist + (theirs.dist[u] ?? double.infinity);
      if (through < best) {
        best = through;
        meet = u;
      }
      final level = graph.levelOf(u);
      final edges = forward ? graph.outEdgesOf(u) : graph.inEdgesOf(u);
      for (final e in edges) {
        final w = graph.otherEnd(e, u);
        if (w == u || graph.levelOf(w) < level) continue;
        final nd = entry.dist + graph.edgeCost(e);
        if (nd < (mine.dist[w] ?? double.infinity)) {
          mine.dist[w] = nd;
          mine.prevEdge[w] = e;
          mine.prevNode[w] = u;
          mine.queue.add(_QueueEntry(w, nd));
        }
      }
    }

    while (fwd.canBeat(best) || bwd.canBeat(best)) {
      if (fwd.canBeat(best)) settle(fwd, bwd, forward: true);
      if (bwd.canBeat(best)) settle(bwd, fwd, forward: false);
    }

    if (meet < 0) {
      // Sin ruta: origen y destino en partes desconectadas del grafo.
      return null;
    }

    // Aristas de la búsqueda (pueden ser atajos), en orden de marcha.
    final searchEdges = <int>[];
    for (var x = meet; x != startNodeIndex; x = fwd.prevNode[x]!) {
      searchEdges.add(fwd.prevEdge[x]!);
    }
    final ordered = searchEdges.reversed.toList();
    for (var x = meet; x != endNodeIndex; x = bwd.prevNode[x]!) {
      ordered.add(bwd.prevEdge[x]!);
    }

    final nodePath = <int>[startNodeIndex];
    final realEdges = <int>[];
    var current = startNodeIndex;
    for (final e in ordered) {
      current = _unpack(e, current, nodePath, realEdges);
    }

    var total = 0.0;
    final edgesUsed = <RoadEdge>[];
    for (final e in realEdges) {
      edgesUsed.add(graph.edgeAt(e));
      total += graph.edgeDistance(e);
    }
    return RoutePath(
      nodeIndices: nodePath,
      edgesUsed: edgesUsed,
      totalDistanceMeters: total,
    );
  }

  /// Recorre [edge] desde [from], cambiando cada atajo por las dos
  /// aristas que reemplaza, y anota los nodos y las aristas reales.
  /// Devuelve el nodo al que se llega.
  ///
  /// Iterativo a propósito: los atajos se anidan cientos de niveles.
  int _unpack(int edge, int from, List<int> nodes, List<int> edges) {
    final pending = <int>[edge];
    var current = from;
    while (pending.isNotEmpty) {
      final e = pending.removeLast();
      if (graph.isShortcut(e)) {
        // Primero la mitad que sale de `current`, después la otra.
        pending
          ..add(graph.viaB(e))
          ..add(graph.viaA(e));
        continue;
      }
      current = graph.otherEnd(e, current);
      nodes.add(current);
      edges.add(e);
    }
    return current;
  }
}

class _Search {
  final Map<int, double> dist;
  final Map<int, int> prevNode = {};
  final Map<int, int> prevEdge = {};
  final HeapPriorityQueue<_QueueEntry> queue = HeapPriorityQueue(
    (a, b) => a.dist.compareTo(b.dist),
  );

  _Search(int origin) : dist = {origin: 0} {
    queue.add(_QueueEntry(origin, 0));
  }

  /// Este frente todavía puede encontrar un encuentro mejor que [best].
  bool canBeat(double best) => queue.isNotEmpty && queue.first.dist < best;
}

class _QueueEntry {
  final int node;
  final double dist;
  const _QueueEntry(this.node, this.dist);
}
