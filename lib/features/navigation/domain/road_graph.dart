import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

/// Tipo de vía -- se usa para generar mejores instrucciones ("gira en
/// la calle principal") y para penalizar/preferir ciertos tipos de
/// vía al calcular la ruta (ej. preferir cycleway sobre residencial).
enum RoadType { unknown, primary, secondary, residential, cycleway, path }

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
  /// decidir qué camino tomar (prioriza principales sin dejar de ser un
  /// algoritmo de costo mínimo correcto). No afecta `distanceMeters`,
  /// que sigue siendo la distancia real.
  final double chCost;

  /// true si esta arista es un "atajo" (shortcut) generado en el
  /// preprocesamiento CH y no una vía real de OSM. `ChRouter` la
  /// desenrolla antes de devolver el `RoutePath` final.
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
/// binario propio -- ver `tools/preprocess_osm_to_roadgraph.py` (vías y
/// pesos) y `tool/road_graph_ch.dart` (jerarquía).
///
/// Soporta 2 versiones de archivo:
///   RGF1 -- formato original (solo distancia real, sin CH). Sigue
///           funcionando como Dijkstra plano por distancia.
///   RGF2 -- costo ponderado por tipo de vía + jerarquía de contracción
///           (niveles y atajos).
///
/// Se guarda en arreglos compactos (`Float64List`, `Int32List`...) y no
/// como millones de objetos: el grafo de Cundinamarca tiene ~1 millón de
/// nodos, y como objetos sueltos pesaba cientos de MB y tardaba varios
/// segundos en armarse. Las listas [nodes], [edges] y de adyacencia son
/// vistas que crean el objeto al pedirlo, así que el resto del código
/// las usa igual que antes.
class RoadGraph {
  final Float64List _lat;
  final Float64List _lng;
  final Int32List _level;
  final Int32List _from;
  final Int32List _to;
  final Float32List _cost;
  final Float32List _dist;
  final Uint8List _type;

  /// bit 0: sentido único; bit 1: atajo.
  final Uint8List _flags;
  final Int32List _viaA;
  final Int32List _viaB;

  /// Adyacencia en formato CSR: las aristas que salen del nodo `i` son
  /// `_outEdges[_outStart[i] .. _outStart[i + 1]]`. Las de doble
  /// sentido aparecen en los dos extremos.
  final Int32List _outStart;
  final Int32List _outEdges;
  final Int32List _inStart;
  final Int32List _inEdges;

  /// Cuántas vías reales (no atajos) tocan cada nodo, con tope en 255.
  /// Con 3 o más es una intersección; con 2, la vía solo sigue.
  final Uint8List _degree;

  RoadGraph._(
    this._lat,
    this._lng,
    this._level,
    this._from,
    this._to,
    this._cost,
    this._dist,
    this._type,
    this._flags,
    this._viaA,
    this._viaB,
    this._outStart,
    this._outEdges,
    this._inStart,
    this._inEdges,
    this._degree,
  );

  int get nodeCount => _lat.length;
  int get edgeCount => _from.length;

  double latOf(int node) => _lat[node];
  double lngOf(int node) => _lng[node];
  int levelOf(int node) => _level[node];

  /// Vías reales que se cruzan en [node].
  int degreeOf(int node) => _degree[node];

  int edgeFrom(int edge) => _from[edge];
  int edgeTo(int edge) => _to[edge];
  double edgeCost(int edge) => _cost[edge];
  double edgeDistance(int edge) => _dist[edge];
  bool isOneWay(int edge) => _flags[edge] & 1 != 0;
  bool isShortcut(int edge) => _flags[edge] & 2 != 0;
  int viaA(int edge) => _viaA[edge];
  int viaB(int edge) => _viaB[edge];

  /// El otro extremo de [edge] visto desde [node].
  int otherEnd(int edge, int node) =>
      _from[edge] == node ? _to[edge] : _from[edge];

  /// Aristas por las que se sale de [node] (sin copiar).
  Int32List outEdgesOf(int node) =>
      Int32List.sublistView(_outEdges, _outStart[node], _outStart[node + 1]);

  /// Aristas por las que se llega a [node] (sin copiar).
  Int32List inEdgesOf(int node) =>
      Int32List.sublistView(_inEdges, _inStart[node], _inStart[node + 1]);

  // --- Vistas compatibles con el código que usaba objetos ------------

  late final List<RoadNode> nodes = _NodeView(this);
  late final List<RoadEdge> edges = _EdgeView(this);
  late final List<List<int>> outAdjacency = _AdjacencyView(
    _outStart,
    _outEdges,
  );
  late final List<List<int>> inAdjacency = _AdjacencyView(_inStart, _inEdges);

  /// Igual que [outAdjacency]: las de doble sentido ya están en los dos
  /// extremos.
  List<List<int>> get adjacency => outAdjacency;

  RoadNode nodeAt(int i) =>
      RoadNode(lat: _lat[i], lng: _lng[i], chLevel: _level[i]);

  RoadEdge edgeAt(int e) => RoadEdge(
    fromIndex: _from[e],
    toIndex: _to[e],
    distanceMeters: _dist[e],
    roadType: _safeRoadType(_type[e]),
    oneWay: isOneWay(e),
    chCost: _cost[e],
    isShortcut: isShortcut(e),
    viaEdgeA: _viaA[e],
    viaEdgeB: _viaB[e],
  );

  /// Vecinos accesibles desde `nodeIndex` -- para cada arista que sale,
  /// el nodo del otro extremo y la arista usada.
  Iterable<(int neighborIndex, RoadEdge edge)> neighborsOf(
    int nodeIndex,
  ) sync* {
    for (final edgeIndex in outEdgesOf(nodeIndex)) {
      yield (otherEnd(edgeIndex, nodeIndex), edgeAt(edgeIndex));
    }
  }

  // --- Carga ---------------------------------------------------------

  /// Lee y arma el grafo en un isolate aparte: son decenas de MB y la
  /// pantalla no se puede quedar congelada mientras tanto. Los arreglos
  /// vuelven al isolate principal sin copiarse.
  static Future<RoadGraph> loadFromFile(String path) =>
      Isolate.run(() => parse(File(path).readAsBytesSync()));

  /// Lee y arma el grafo en el isolate actual: lo usa el isolate de
  /// ruteo (`RouteWorker`), que ya corre aparte de la interfaz.
  static Future<RoadGraph> loadFromFileHere(String path) async =>
      parse(await File(path).readAsBytes());

  static RoadGraph parse(Uint8List bytes) {
    final magic = String.fromCharCodes(bytes.sublist(0, 4));
    if (magic == 'RGF1') return _parse(bytes, version: 1);
    if (magic == 'RGF2') return _parse(bytes, version: 2);
    throw FormatException(
      'Archivo .roadgraph inválido: magic esperado "RGF1" o "RGF2", '
      'encontrado "$magic".',
    );
  }

  static RoadGraph _parse(Uint8List bytes, {required int version}) {
    final data = ByteData.sublistView(bytes);
    var offset = 4;
    final nodeCount = data.getInt32(offset, Endian.little);
    offset += 4;

    final lat = Float64List(nodeCount);
    final lng = Float64List(nodeCount);
    final level = Int32List(nodeCount);
    for (var i = 0; i < nodeCount; i++) {
      lat[i] = data.getFloat64(offset, Endian.little);
      lng[i] = data.getFloat64(offset + 8, Endian.little);
      if (version == 2) {
        level[i] = data.getInt32(offset + 16, Endian.little);
        offset += 20;
      } else {
        offset += 16;
      }
    }

    final edgeCount = data.getInt32(offset, Endian.little);
    offset += 4;
    final from = Int32List(edgeCount);
    final to = Int32List(edgeCount);
    final cost = Float32List(edgeCount);
    final dist = Float32List(edgeCount);
    final type = Uint8List(edgeCount);
    final flags = Uint8List(edgeCount);
    final viaA = Int32List(edgeCount);
    final viaB = Int32List(edgeCount);
    for (var e = 0; e < edgeCount; e++) {
      from[e] = data.getInt32(offset, Endian.little);
      to[e] = data.getInt32(offset + 4, Endian.little);
      if (version == 2) {
        cost[e] = data.getFloat32(offset + 8, Endian.little);
        type[e] = data.getUint8(offset + 12);
        final oneWay = data.getUint8(offset + 13) == 1;
        final shortcut = data.getUint8(offset + 14) == 1;
        flags[e] = (oneWay ? 1 : 0) | (shortcut ? 2 : 0);
        viaA[e] = data.getInt32(offset + 15, Endian.little);
        viaB[e] = data.getInt32(offset + 19, Endian.little);
        dist[e] = data.getFloat32(offset + 23, Endian.little);
        offset += 27;
      } else {
        // RGF1: sin jerarquía; el costo es la distancia.
        final d = data.getFloat32(offset + 8, Endian.little);
        dist[e] = d;
        cost[e] = d;
        type[e] = data.getUint8(offset + 12);
        flags[e] = data.getUint8(offset + 13) == 1 ? 1 : 0;
        viaA[e] = -1;
        viaB[e] = -1;
        offset += 14;
      }
    }

    // Adyacencia CSR: primero se cuenta, después se llena.
    final outStart = Int32List(nodeCount + 1);
    final inStart = Int32List(nodeCount + 1);
    final degree = Uint8List(nodeCount);
    for (var e = 0; e < edgeCount; e++) {
      final a = from[e], b = to[e];
      outStart[a + 1]++;
      inStart[b + 1]++;
      if (flags[e] & 1 == 0) {
        outStart[b + 1]++;
        inStart[a + 1]++;
      }
      if (flags[e] & 2 == 0) {
        if (degree[a] < 255) degree[a]++;
        if (degree[b] < 255) degree[b]++;
      }
    }
    for (var i = 0; i < nodeCount; i++) {
      outStart[i + 1] += outStart[i];
      inStart[i + 1] += inStart[i];
    }
    final outEdges = Int32List(outStart[nodeCount]);
    final inEdges = Int32List(inStart[nodeCount]);
    final outFill = Int32List.fromList(outStart);
    final inFill = Int32List.fromList(inStart);
    for (var e = 0; e < edgeCount; e++) {
      final a = from[e], b = to[e];
      outEdges[outFill[a]++] = e;
      inEdges[inFill[b]++] = e;
      if (flags[e] & 1 == 0) {
        outEdges[outFill[b]++] = e;
        inEdges[inFill[a]++] = e;
      }
    }

    return RoadGraph._(
      lat,
      lng,
      level,
      from,
      to,
      cost,
      dist,
      type,
      flags,
      viaA,
      viaB,
      outStart,
      outEdges,
      inStart,
      inEdges,
      degree,
    );
  }

  static RoadType _safeRoadType(int raw) {
    return raw < RoadType.values.length
        ? RoadType.values[raw]
        : RoadType.unknown;
  }
}

class _NodeView extends ListBase<RoadNode> {
  final RoadGraph _graph;
  _NodeView(this._graph);

  @override
  int get length => _graph.nodeCount;

  @override
  set length(int value) => throw UnsupportedError('Grafo de solo lectura');

  @override
  RoadNode operator [](int index) => _graph.nodeAt(index);

  @override
  void operator []=(int index, RoadNode value) =>
      throw UnsupportedError('Grafo de solo lectura');
}

class _EdgeView extends ListBase<RoadEdge> {
  final RoadGraph _graph;
  _EdgeView(this._graph);

  @override
  int get length => _graph.edgeCount;

  @override
  set length(int value) => throw UnsupportedError('Grafo de solo lectura');

  @override
  RoadEdge operator [](int index) => _graph.edgeAt(index);

  @override
  void operator []=(int index, RoadEdge value) =>
      throw UnsupportedError('Grafo de solo lectura');
}

class _AdjacencyView extends ListBase<List<int>> {
  final Int32List _start;
  final Int32List _edges;
  _AdjacencyView(this._start, this._edges);

  @override
  int get length => _start.length - 1;

  @override
  set length(int value) => throw UnsupportedError('Grafo de solo lectura');

  @override
  List<int> operator [](int index) =>
      Int32List.sublistView(_edges, _start[index], _start[index + 1]);

  @override
  void operator []=(int index, List<int> value) =>
      throw UnsupportedError('Grafo de solo lectura');
}
