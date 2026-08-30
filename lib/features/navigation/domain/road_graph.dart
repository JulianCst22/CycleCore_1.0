import 'dart:io';
import 'dart:typed_data';

/// Tipo de vía -- se usa para generar mejores instrucciones ("gira en
/// la calle principal") y para penalizar/preferir ciertos tipos de
/// vía al calcular la ruta (ej. preferir cycleway sobre residencial).
enum RoadType {
  unknown,
  primary,
  secondary,
  residential,
  cycleway,
  path,
}

class RoadNode {
  final double lat;
  final double lng;

  /// Nivel de contracción (Contraction Hierarchies) -- orden en que
  /// este nodo fue "contraído" durante el preprocesamiento. Mayor
  /// nivel = nodo más importante (vías principales quedan con nivel
  /// alto, calles residenciales sin salida quedan con nivel bajo).
  /// `ChRouter` lo usa para restringir la búsqueda a moverse siempre
  /// "hacia arriba" en la jerarquía. Si cargás un `.roadgraph` viejo
  /// sin esta info, queda en 0 para todos los nodos (ver `parse`).
  final int chLevel;

  const RoadNode({required this.lat, required this.lng, this.chLevel = 0});
}

class RoadEdge {
  final int fromIndex;
  final int toIndex;
  final double distanceMeters;
  final RoadType roadType;
  final bool oneWay;

  /// Costo ponderado por tipo de vía, usado SOLO por `ChRouter` para
  /// decidir qué camino tomar (prioriza principales/ciclovías sin
  /// dejar de ser un algoritmo de costo mínimo correcto). No afecta
  /// `distanceMeters`, que sigue siendo la distancia real -- todo lo
  /// que ya usa `distanceMeters` (instrucciones, distancia total)
  /// sigue funcionando exactamente igual que antes.
  final double chCost;

  /// true si esta arista es un "atajo" (shortcut) generado en el
  /// preprocesamiento CH y no una vía real de OSM. `ChRouter` la usa
  /// internamente y la desenrolla antes de devolver el `RoutePath`
  /// final, así que en la práctica nunca vas a ver `isShortcut: true`
  /// en una arista dentro de un `RoutePath` ya construido.
  final bool isShortcut;

  /// Si `isShortcut` es true, índices (en `RoadGraph.edges`) de las 2
  /// aristas que este atajo reemplaza. -1 si no es shortcut.
  final int viaEdgeA;
  final int viaEdgeB;

  const RoadEdge({
    required this.fromIndex,
    required this.toIndex,
    required this.distanceMeters,
    required this.roadType,
    required this.oneWay,
    double? chCost,
    this.isShortcut = false,
    this.viaEdgeA = -1,
    this.viaEdgeB = -1,
  }) : chCost = chCost ?? distanceMeters;
}

/// Grafo vial de una región, cargado desde un archivo `.roadgraph`
/// binario propio -- ver `tools/preprocess_osm_to_roadgraph.py` para
/// cómo se genera a partir de un extracto OSM (`.osm.pbf`).
///
/// Soporta 2 versiones de archivo:
///   RGF1 -- formato original (solo distancia real, sin CH). Sigue
///           funcionando: `chLevel`/`chCost` quedan en 0/distancia,
///           y `ChRouter` sobre un grafo RGF1 se comporta como
///           Dijkstra plano (sin restricción de jerarquía real).
///   RGF2 -- formato con Contraction Hierarchies precalculadas, lo
///           que hace que `ChRouter` corra en su modo rápido real.
///
/// Formato binario RGF2 (little-endian):
/// ```
///   4 bytes  magic "RGF2"
///   int32    cantidad de nodos (N)
///   N * (float64 lat, float64 lng, int32 chLevel)
///   int32    cantidad de aristas (E)
///   E * (int32 from, int32 to, float32 chCost,
///        uint8 roadType, uint8 oneWay, uint8 isShortcut,
///        int32 viaEdgeA, int32 viaEdgeB, float32 distanceMeters)
/// ```
/// El índice de cada nodo en la lista ES su id -- no hace falta
/// guardar un id explícito por nodo.
class RoadGraph {
  final List<RoadNode> nodes;
  final List<RoadEdge> edges;

  /// adjacency[i] = índices (en `edges`) de las aristas que salen del
  /// nodo i -- se construye una sola vez al parsear, así `neighborsOf`
  /// es O(grado del nodo) en vez de recorrer todas las aristas. Se
  /// mantiene sin cambios respecto a la versión v1 -- lo sigue usando
  /// `AStarRouter` si todavía convive con `ChRouter` en el proyecto.
  final List<List<int>> adjacency;

  /// outAdjacency[i] = aristas que SALEN de i, respetando oneWay.
  /// inAdjacency[i]  = aristas que LLEGAN a i, respetando oneWay.
  /// `ChRouter` necesita esta separación direccional para la búsqueda
  /// bidireccional (la búsqueda hacia atrás desde el destino tiene
  /// que caminar las aristas "al revés"). `adjacency` (arriba) no
  /// distingue dirección de recorrido, por eso se agregan estas dos
  /// listas nuevas en vez de reutilizarla.
  final List<List<int>> outAdjacency;
  final List<List<int>> inAdjacency;

  RoadGraph._({
    required this.nodes,
    required this.edges,
    required this.adjacency,
    required this.outAdjacency,
    required this.inAdjacency,
  });

  static Future<RoadGraph> loadFromFile(String path) async {
    final bytes = await File(path).readAsBytes();
    return parse(bytes);
  }

  static RoadGraph parse(Uint8List bytes) {
    final magic = String.fromCharCodes(bytes.sublist(0, 4));
    if (magic == 'RGF1') {
      return _parseV1(bytes);
    }
    if (magic == 'RGF2') {
      return _parseV2(bytes);
    }
    throw FormatException(
      'Archivo .roadgraph inválido: magic esperado "RGF1" o "RGF2", '
      'encontrado "$magic".',
    );
  }

  static RoadGraph _parseV1(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    int offset = 4; // magic ya verificado

    final nodeCount = data.getInt32(offset, Endian.little);
    offset += 4;

    final nodes = List<RoadNode>.filled(
      nodeCount,
      const RoadNode(lat: 0, lng: 0),
      growable: false,
    );
    for (int i = 0; i < nodeCount; i++) {
      final lat = data.getFloat64(offset, Endian.little);
      offset += 8;
      final lng = data.getFloat64(offset, Endian.little);
      offset += 8;
      nodes[i] = RoadNode(lat: lat, lng: lng); // chLevel queda en 0
    }

    final edgeCount = data.getInt32(offset, Endian.little);
    offset += 4;

    final edges = <RoadEdge>[];
    for (int i = 0; i < edgeCount; i++) {
      final from = data.getInt32(offset, Endian.little);
      offset += 4;
      final to = data.getInt32(offset, Endian.little);
      offset += 4;
      final distance = data.getFloat32(offset, Endian.little);
      offset += 4;
      final roadTypeRaw = data.getUint8(offset);
      offset += 1;
      final oneWay = data.getUint8(offset) == 1;
      offset += 1;

      edges.add(RoadEdge(
        fromIndex: from,
        toIndex: to,
        distanceMeters: distance,
        roadType: _safeRoadType(roadTypeRaw),
        oneWay: oneWay,
        // sin CH: chCost = distanceMeters (comportamiento Dijkstra puro)
      ));
    }

    return _buildAdjacency(nodes, edges);
  }

  static RoadGraph _parseV2(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    int offset = 4; // magic ya verificado

    final nodeCount = data.getInt32(offset, Endian.little);
    offset += 4;

    final nodes = List<RoadNode>.filled(
      nodeCount,
      const RoadNode(lat: 0, lng: 0),
      growable: false,
    );
    for (int i = 0; i < nodeCount; i++) {
      final lat = data.getFloat64(offset, Endian.little);
      offset += 8;
      final lng = data.getFloat64(offset, Endian.little);
      offset += 8;
      final level = data.getInt32(offset, Endian.little);
      offset += 4;
      nodes[i] = RoadNode(lat: lat, lng: lng, chLevel: level);
    }

    final edgeCount = data.getInt32(offset, Endian.little);
    offset += 4;

    final edges = <RoadEdge>[];
    for (int i = 0; i < edgeCount; i++) {
      final from = data.getInt32(offset, Endian.little);
      offset += 4;
      final to = data.getInt32(offset, Endian.little);
      offset += 4;
      final chCost = data.getFloat32(offset, Endian.little);
      offset += 4;
      final roadTypeRaw = data.getUint8(offset);
      offset += 1;
      final oneWay = data.getUint8(offset) == 1;
      offset += 1;
      final isShortcut = data.getUint8(offset) == 1;
      offset += 1;
      final viaA = data.getInt32(offset, Endian.little);
      offset += 4;
      final viaB = data.getInt32(offset, Endian.little);
      offset += 4;
      final realDistance = data.getFloat32(offset, Endian.little);
      offset += 4;

      edges.add(RoadEdge(
        fromIndex: from,
        toIndex: to,
        distanceMeters: realDistance,
        roadType: _safeRoadType(roadTypeRaw),
        oneWay: oneWay,
        chCost: chCost,
        isShortcut: isShortcut,
        viaEdgeA: viaA,
        viaEdgeB: viaB,
      ));
    }

    return _buildAdjacency(nodes, edges);
  }

  static RoadType _safeRoadType(int raw) {
    return raw < RoadType.values.length ? RoadType.values[raw] : RoadType.unknown;
  }

  static RoadGraph _buildAdjacency(List<RoadNode> nodes, List<RoadEdge> edges) {
    final nodeCount = nodes.length;
    final adjacency = List.generate(nodeCount, (_) => <int>[]);
    final outAdjacency = List.generate(nodeCount, (_) => <int>[]);
    final inAdjacency = List.generate(nodeCount, (_) => <int>[]);

    for (int edgeIndex = 0; edgeIndex < edges.length; edgeIndex++) {
      final edge = edges[edgeIndex];

      adjacency[edge.fromIndex].add(edgeIndex);
      outAdjacency[edge.fromIndex].add(edgeIndex);
      inAdjacency[edge.toIndex].add(edgeIndex);

      if (!edge.oneWay) {
        adjacency[edge.toIndex].add(edgeIndex);
        outAdjacency[edge.toIndex].add(edgeIndex);
        inAdjacency[edge.fromIndex].add(edgeIndex);
      }
    }

    return RoadGraph._(
      nodes: nodes,
      edges: edges,
      adjacency: adjacency,
      outAdjacency: outAdjacency,
      inAdjacency: inAdjacency,
    );
  }

  /// Vecinos accesibles desde `nodeIndex` (comportamiento original,
  /// sin cambios) -- para cada arista adyacente, el índice del nodo
  /// del otro extremo y la arista usada. Se mantiene tal cual la
  /// necesita `AStarRouter` si sigue existiendo en el proyecto.
  Iterable<(int neighborIndex, RoadEdge edge)> neighborsOf(
    int nodeIndex,
  ) sync* {
    for (final edgeIndex in adjacency[nodeIndex]) {
      final edge = edges[edgeIndex];
      final neighbor =
          edge.fromIndex == nodeIndex ? edge.toIndex : edge.fromIndex;
      yield (neighbor, edge);
    }
  }
}
