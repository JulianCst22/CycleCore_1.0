import 'dart:collection';
import 'dart:math' as math;

import 'package:collection/collection.dart';

import 'a_star_router.dart' show RoutePath;
import 'road_graph.dart';

/// Calcula el camino de menor costo entre dos nodos usando búsqueda
/// bidireccional sobre la jerarquía de Contraction Hierarchies (CH)
/// precalculada en `RoadNode.chLevel` / `RoadEdge.chCost`.
///
/// Reemplazo directo de `AStarRouter`: misma firma de uso
/// (`findPath(startNodeIndex:, endNodeIndex:)`), mismo tipo de
/// retorno (`RoutePath`), así que `TurnInstructionBuilder` y
/// `NavigationController` no necesitan ningún cambio más allá de
/// instanciar `ChRouter` en vez de `AStarRouter`.
///
/// Cómo es más rápido que A*: en vez de expandir un solo frente de
/// búsqueda guiado por una heurística, corre DOS Dijkstra
/// simultáneos -- uno desde el origen, otro desde el destino -- que
/// solo avanzan hacia nodos de `chLevel` MAYOR (hacia "arriba" en la
/// jerarquía, es decir, hacia vías más importantes). Se detienen
/// cuando ambos frentes se tocan. Esto concentra casi toda la
/// exploración en la parte alta de la jerarquía (autopistas,
/// avenidas principales), que es un porcentaje mínimo del grafo
/// total -- de ahí la ganancia de velocidad frente a A*/Dijkstra.
///
/// El costo que se minimiza es `RoadEdge.chCost` (ponderado por tipo
/// de vía), no `distanceMeters` -- por eso la ruta resultante ya
/// prefiere vías principales/ciclovías de forma natural. La distancia
/// real (`totalDistanceMeters` del `RoutePath`) se sigue calculando
/// sumando `distanceMeters`, así que la UI sigue mostrando metros
/// reales, no costo ponderado.
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

    final fwd = _SearchState()..dist[startNodeIndex] = 0;
    final bwd = _SearchState()..dist[endNodeIndex] = 0;

    final fwdQueue = HeapPriorityQueue<_QueueEntry>(
      (a, b) => a.dist.compareTo(b.dist),
    )..add(_QueueEntry(startNodeIndex, 0));
    final bwdQueue = HeapPriorityQueue<_QueueEntry>(
      (a, b) => a.dist.compareTo(b.dist),
    )..add(_QueueEntry(endNodeIndex, 0));

    double bestMeetCost = double.infinity;
    int? meetNode;

    while (fwdQueue.isNotEmpty || bwdQueue.isNotEmpty) {
      if (fwdQueue.isNotEmpty) {
        final settled = _stepSearch(
          fwdQueue,
          fwd,
          graph.outAdjacency,
          forward: true,
        );
        if (settled != null) {
          final combined =
              fwd.dist[settled]! + (bwd.dist[settled] ?? double.infinity);
          if (combined < bestMeetCost) {
            bestMeetCost = combined;
            meetNode = settled;
          }
        }
      }
      if (bwdQueue.isNotEmpty) {
        final settled = _stepSearch(
          bwdQueue,
          bwd,
          graph.inAdjacency,
          forward: false,
        );
        if (settled != null) {
          final combined =
              bwd.dist[settled]! + (fwd.dist[settled] ?? double.infinity);
          if (combined < bestMeetCost) {
            bestMeetCost = combined;
            meetNode = settled;
          }
        }
      }

      final fwdMin =
          fwdQueue.isNotEmpty ? fwdQueue.first.dist : double.infinity;
      final bwdMin =
          bwdQueue.isNotEmpty ? bwdQueue.first.dist : double.infinity;
      if (fwdMin + bwdMin >= bestMeetCost) break;
    }

    if (meetNode == null) {
      // Sin ruta -- start y end en componentes desconectadas, igual
      // que en AStarRouter.
      return null;
    }

    final rawNodePath = _reconstructPath(
      fwd,
      bwd,
      meetNode,
      startNodeIndex,
      endNodeIndex,
    );
    final expandedNodePath = _expandShortcuts(rawNodePath);
    return _buildRoutePath(expandedNodePath);
  }

  /// Avanza un paso de Dijkstra en una dirección, respetando la
  /// restricción CH de "solo subir en la jerarquía" (`chLevel`
  /// creciente). Devuelve el nodo recién asentado, o null si la cola
  /// se vació.
  int? _stepSearch(
    HeapPriorityQueue<_QueueEntry> queue,
    _SearchState state,
    List<List<int>> adjacency, {
    required bool forward,
  }) {
    while (queue.isNotEmpty) {
      final entry = queue.removeFirst();
      if (state.settled.contains(entry.node)) continue;
      if (entry.dist > (state.dist[entry.node] ?? double.infinity)) continue;

      state.settled.add(entry.node);
      final myLevel = graph.nodes[entry.node].chLevel;

      for (final edgeIndex in adjacency[entry.node]) {
        final edge = graph.edges[edgeIndex];
        final neighbor = forward
            ? (edge.fromIndex == entry.node ? edge.toIndex : edge.fromIndex)
            : (edge.toIndex == entry.node ? edge.fromIndex : edge.toIndex);
        if (neighbor == entry.node) continue;

        // Restricción de jerarquía: solo avanzar hacia nodos "más
        // arriba" -- confina la búsqueda a la parte alta (vías
        // principales) en vez de bajar de nuevo a calles laterales.
        // En un grafo RGF1 sin CH real, chLevel es 0 para todos los
        // nodos y esta condición nunca filtra nada -- se comporta
        // como Dijkstra plano (correcto, solo sin la ganancia de
        // velocidad de la jerarquía).
        if (graph.nodes[neighbor].chLevel < myLevel) continue;

        final newDist = entry.dist + edge.chCost;
        final known = state.dist[neighbor] ?? double.infinity;
        if (newDist < known) {
          state.dist[neighbor] = newDist;
          state.prevNode[neighbor] = entry.node;
          state.prevEdge[neighbor] = edgeIndex;
          queue.add(_QueueEntry(neighbor, newDist));
        }
      }
      return entry.node;
    }
    return null;
  }

  List<int> _reconstructPath(
    _SearchState fwd,
    _SearchState bwd,
    int meetNode,
    int startNode,
    int endNode,
  ) {
    final left = <int>[];
    var cur = meetNode;
    while (cur != startNode) {
      left.add(cur);
      cur = fwd.prevNode[cur]!;
    }
    left.add(startNode);
    final leftPath = left.reversed.toList();

    final right = <int>[];
    cur = meetNode;
    while (cur != endNode) {
      final next = bwd.prevNode[cur]!;
      right.add(next);
      cur = next;
    }

    return [...leftPath, ...right];
  }

  /// Los shortcuts generados en el preprocesamiento CH no son vías
  /// reales -- cada uno representa 2 aristas originales (o 2
  /// shortcuts anteriores, recursivamente). Se desenrollan acá antes
  /// de construir el `RoutePath` final, así que `TurnInstructionBuilder`
  /// nunca ve una arista con `isShortcut: true` ni necesita saber que
  /// CH existe.
  List<int> _expandShortcuts(List<int> nodePath) {
    final result = <int>[nodePath.first];
    for (var i = 0; i < nodePath.length - 1; i++) {
      final a = nodePath[i];
      final b = nodePath[i + 1];
      final edgeIndex = _findDirectedEdge(a, b);
      if (edgeIndex == null) {
        // No debería pasar si la reconstrucción fue correcta, pero
        // evita perder el nodo en vez de tirar una excepción en
        // medio de una navegación activa.
        result.add(b);
        continue;
      }
      final expanded = <int>[];
      _expandEdge(edgeIndex, expanded);
      result.addAll(expanded);
    }
    return result;
  }

  void _expandEdge(int edgeIndex, List<int> out) {
    final edge = graph.edges[edgeIndex];
    if (!edge.isShortcut) {
      out.add(edge.toIndex);
      return;
    }
    _expandEdge(edge.viaEdgeA, out);
    _expandEdge(edge.viaEdgeB, out);
  }

  int? _findDirectedEdge(int a, int b) {
    for (final edgeIndex in graph.outAdjacency[a]) {
      final e = graph.edges[edgeIndex];
      final matchesForward = e.fromIndex == a && e.toIndex == b;
      final matchesBackward = !e.oneWay && e.fromIndex == b && e.toIndex == a;
      if (matchesForward || matchesBackward) return edgeIndex;
    }
    return null;
  }

  /// Reconstruye un `RoutePath` completo (con las aristas reales, no
  /// los shortcuts) a partir de la secuencia final de nodos ya
  /// expandida -- mismo formato que produce `AStarRouter`.
  RoutePath _buildRoutePath(List<int> nodePath) {
    final edgesUsed = <RoadEdge>[];
    double totalDistance = 0;

    for (var i = 0; i < nodePath.length - 1; i++) {
      final a = nodePath[i];
      final b = nodePath[i + 1];
      final edgeIndex = _findDirectedEdge(a, b);
      if (edgeIndex != null) {
        final edge = graph.edges[edgeIndex];
        edgesUsed.add(edge);
        totalDistance += edge.distanceMeters;
      } else {
        // Fallback defensivo: no se encontró la arista real (no
        // debería ocurrir tras expandShortcuts) -- se aproxima la
        // distancia con haversine para no romper totalDistanceMeters.
        totalDistance += _haversine(graph.nodes[a], graph.nodes[b]);
      }
    }

    return RoutePath(
      nodeIndices: nodePath,
      edgesUsed: edgesUsed,
      totalDistanceMeters: totalDistance,
    );
  }

  double _haversine(RoadNode a, RoadNode b) {
    const earthRadiusMeters = 6371000.0;
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
    return earthRadiusMeters * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180;
}

class _SearchState {
  final Map<int, double> dist = {};
  final Map<int, int> prevNode = {};
  final Map<int, int> prevEdge = {};
  final Set<int> settled = {};
}

class _QueueEntry {
  final int node;
  final double dist;
  const _QueueEntry(this.node, this.dist);
}
