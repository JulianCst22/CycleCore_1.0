import 'dart:math' as math;

import 'package:collection/collection.dart';

import 'road_graph.dart';

/// Camino más corto encontrado entre dos nodos.
class RoutePath {
  final List<int> nodeIndices;
  final List<RoadEdge> edgesUsed;
  final double totalDistanceMeters;

  const RoutePath({
    required this.nodeIndices,
    required this.edgesUsed,
    required this.totalDistanceMeters,
  });
}

/// Calcula el camino más corto entre dos nodos del grafo con A*
/// (Dijkstra + heurística de distancia en línea recta al destino).
///
/// Es, en esencia, el mismo Dijkstra: mismo costo garantizado óptimo
/// (porque la heurística -- distancia recta -- nunca sobreestima la
/// distancia real por carretera), pero explora muchísimos menos nodos
/// porque prioriza avanzar hacia el destino en vez de expandir en
/// todas direcciones por igual. Con un grafo restringido a una región
/// (no el país entero cargado en memoria), esto corre en milisegundos.
class AStarRouter {
  final RoadGraph graph;
  const AStarRouter(this.graph);

  static const double _earthRadiusMeters = 6371000;

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

    final target = graph.nodes[endNodeIndex];

    final gScore = <int, double>{startNodeIndex: 0};
    final cameFromNode = <int, int>{};
    final cameFromEdge = <int, RoadEdge>{};
    final visited = <int>{};

    final open = HeapPriorityQueue<_QueueEntry>(
      (a, b) => a.fScore.compareTo(b.fScore),
    );
    open.add(_QueueEntry(
      startNodeIndex,
      _haversine(graph.nodes[startNodeIndex], target),
    ));

    while (open.isNotEmpty) {
      final current = open.removeFirst().nodeIndex;
      if (visited.contains(current)) continue;
      visited.add(current);

      if (current == endNodeIndex) {
        return _reconstructPath(
          cameFromNode,
          cameFromEdge,
          endNodeIndex,
          gScore[endNodeIndex]!,
        );
      }

      for (final (neighbor, edge) in graph.neighborsOf(current)) {
        if (visited.contains(neighbor)) continue;

        final tentativeG = gScore[current]! + edge.distanceMeters;
        if (tentativeG < (gScore[neighbor] ?? double.infinity)) {
          gScore[neighbor] = tentativeG;
          cameFromNode[neighbor] = current;
          cameFromEdge[neighbor] = edge;
          final f = tentativeG + _haversine(graph.nodes[neighbor], target);
          open.add(_QueueEntry(neighbor, f));
        }
      }
    }

    // Sin camino -- start y end quedan en componentes desconectadas
    // del grafo (poco común si el extracto OSM está bien preprocesado,
    // pero puede pasar cerca de los bordes de una región).
    return null;
  }

  RoutePath _reconstructPath(
    Map<int, int> cameFromNode,
    Map<int, RoadEdge> cameFromEdge,
    int end,
    double totalDistance,
  ) {
    final nodes = <int>[end];
    final edgesUsed = <RoadEdge>[];
    int current = end;
    while (cameFromNode.containsKey(current)) {
      edgesUsed.add(cameFromEdge[current]!);
      current = cameFromNode[current]!;
      nodes.add(current);
    }
    return RoutePath(
      nodeIndices: nodes.reversed.toList(),
      edgesUsed: edgesUsed.reversed.toList(),
      totalDistanceMeters: totalDistance,
    );
  }

  double _haversine(RoadNode a, RoadNode b) {
    final dLat = _degToRad(b.lat - a.lat);
    final dLng = _degToRad(b.lng - a.lng);
    final lat1 = _degToRad(a.lat);
    final lat2 = _degToRad(b.lat);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) *
            math.sin(dLng / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return _earthRadiusMeters * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180;
}

class _QueueEntry {
  final int nodeIndex;
  final double fScore;
  const _QueueEntry(this.nodeIndex, this.fScore);
}
