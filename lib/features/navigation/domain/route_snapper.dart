import 'dart:math' as math;

import 'road_graph.dart';

class SnapResult {
  final int nodeIndex;
  final double approxDistanceMeters;
  const SnapResult({
    required this.nodeIndex,
    required this.approxDistanceMeters,
  });
}

/// Encuentra el nodo del grafo más cercano a una coordenada GPS libre
/// -- tu posición real casi nunca cae justo sobre un nodo, así que
/// tanto el origen como el destino de una ruta necesitan "engancharse"
/// (snap) al punto más cercano de la red vial antes de correr A*.
///
/// Implementación por fuerza bruta (recorre todos los nodos): es
/// suficiente porque el grafo ya está acotado a una región de a lo
/// sumo unas pocas decenas de miles de nodos, no al país entero. Si en
/// el futuro se vuelve un cuello de botella, se puede indexar con un
/// grid espacial simple o un R-Tree.
class RouteSnapper {
  final RoadGraph graph;
  const RouteSnapper(this.graph);

  SnapResult nearestNode(double lat, double lng) {
    if (graph.nodes.isEmpty) {
      throw StateError('El grafo no tiene nodos cargados.');
    }

    int bestIndex = 0;
    double bestDistSqDegrees = double.infinity;

    for (int i = 0; i < graph.nodes.length; i++) {
      final node = graph.nodes[i];
      final dLat = node.lat - lat;
      final dLng = node.lng - lng;
      final distSq = dLat * dLat + dLng * dLng;
      if (distSq < bestDistSqDegrees) {
        bestDistSqDegrees = distSq;
        bestIndex = i;
      }
    }

    // Conversión aproximada grados -> metros, solo para reportar qué
    // tan lejos quedó el enganche (ej. para avisar "estás a 40m de la
    // calle más cercana"). No afecta qué nodo se eligió arriba.
    const metersPerDegree = 111320;
    final approxMeters = math.sqrt(bestDistSqDegrees) * metersPerDegree;

    return SnapResult(nodeIndex: bestIndex, approxDistanceMeters: approxMeters);
  }
}
