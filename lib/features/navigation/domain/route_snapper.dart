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
    final count = graph.nodeCount;
    if (count == 0) {
      throw StateError('El grafo no tiene nodos cargados.');
    }

    // Un grado de longitud mide menos que uno de latitud lejos del
    // ecuador; sin corregirlo, el "más cercano" se sesga hacia el
    // norte o el sur.
    final lngScale = math.cos(lat * math.pi / 180);
    int bestIndex = 0;
    double bestDistSqDegrees = double.infinity;

    for (int i = 0; i < count; i++) {
      final dLat = graph.latOf(i) - lat;
      final dLng = (graph.lngOf(i) - lng) * lngScale;
      final distSq = dLat * dLat + dLng * dLng;
      if (distSq < bestDistSqDegrees) {
        bestDistSqDegrees = distSq;
        bestIndex = i;
      }
    }

    // Conversión aproximada grados -> metros, solo para reportar qué
    // tan lejos quedó el enganche. No afecta qué nodo se eligió arriba.
    const metersPerDegree = 111320;
    final approxMeters = math.sqrt(bestDistSqDegrees) * metersPerDegree;

    return SnapResult(nodeIndex: bestIndex, approxDistanceMeters: approxMeters);
  }
}
