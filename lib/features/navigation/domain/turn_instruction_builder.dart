import 'dart:math' as math;

import 'a_star_router.dart';
import 'navigation_route.dart';
import 'road_graph.dart';

/// Convierte un `RoutePath` crudo (lista de nodos/aristas que devuelve
/// `AStarRouter`) en un `NavigationRoute` con instrucciones de giro en
/// español.
///
/// El principio es el mismo que usan Waze/Google Maps, simplificado:
/// en cada nodo intermedio de la ruta se compara el rumbo de la arista
/// de entrada contra el de la arista de salida. Si el ángulo entre
/// ambos es chico, vas derecho y no hace falta avisar nada; si es
/// grande, se clasifica como izquierda/derecha/giro brusco/cambio de
/// sentido según qué tan grande es.
class TurnInstructionBuilder {
  final RoadGraph graph;
  const TurnInstructionBuilder(this.graph);

  /// Ángulo mínimo (grados) para considerar que hay un giro real y no
  /// solo el ruido normal de una calle que curva suavemente.
  static const double _straightThresholdDegrees = 15;

  NavigationRoute build(RoutePath path) {
    final polyline = path.nodeIndices.map((i) => graph.nodes[i]).toList();
    final instructions = <RouteInstruction>[];

    if (polyline.isEmpty) {
      return const NavigationRoute(
        polyline: [],
        instructions: [],
        totalDistanceMeters: 0,
      );
    }

    instructions.add(RouteInstruction(
      direction: TurnDirection.straight,
      text: 'Comienza tu recorrido',
      distanceFromStartMeters: 0,
      lat: polyline.first.lat,
      lng: polyline.first.lng,
    ));

    double cumulativeDistance = 0;

    for (int i = 0; i < path.edgesUsed.length; i++) {
      cumulativeDistance += path.edgesUsed[i].distanceMeters;
      final isLastEdge = i == path.edgesUsed.length - 1;

      if (isLastEdge) {
        instructions.add(RouteInstruction(
          direction: TurnDirection.arrive,
          text: 'Llegaste a tu destino',
          distanceFromStartMeters: cumulativeDistance,
          lat: polyline.last.lat,
          lng: polyline.last.lng,
        ));
        break;
      }

      final prevNode = polyline[i];
      final atNode = polyline[i + 1];
      final nextNode = polyline[i + 2];

      final bearingIn = _bearing(prevNode, atNode);
      final bearingOut = _bearing(atNode, nextNode);
      final turnAngle = _normalizeAngle(bearingOut - bearingIn);
      final direction = _classifyTurn(turnAngle);

      if (direction != TurnDirection.straight) {
        instructions.add(RouteInstruction(
          direction: direction,
          text: _textFor(direction),
          distanceFromStartMeters: cumulativeDistance,
          lat: atNode.lat,
          lng: atNode.lng,
        ));
      }
    }

    return NavigationRoute(
      polyline: polyline,
      instructions: instructions,
      totalDistanceMeters: path.totalDistanceMeters,
    );
  }

  double _bearing(RoadNode from, RoadNode to) {
    final lat1 = _degToRad(from.lat);
    final lat2 = _degToRad(to.lat);
    final dLng = _degToRad(to.lng - from.lng);
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (_radToDeg(math.atan2(y, x)) + 360) % 360;
  }

  /// Deja el ángulo en el rango (-180, 180] -- así "gira" siempre por
  /// el camino más corto (izquierda si es negativo, derecha si es
  /// positivo).
  double _normalizeAngle(double angle) {
    double a = angle % 360;
    if (a > 180) a -= 360;
    if (a < -180) a += 360;
    return a;
  }

  TurnDirection _classifyTurn(double angle) {
    final abs = angle.abs();
    if (abs < _straightThresholdDegrees) return TurnDirection.straight;
    if (abs < 45) {
      return angle > 0 ? TurnDirection.slightRight : TurnDirection.slightLeft;
    }
    if (abs < 120) {
      return angle > 0 ? TurnDirection.right : TurnDirection.left;
    }
    if (abs < 165) {
      return angle > 0 ? TurnDirection.sharpRight : TurnDirection.sharpLeft;
    }
    return TurnDirection.uTurn;
  }

  String _textFor(TurnDirection direction) {
    switch (direction) {
      case TurnDirection.left:
        return 'Gira a la izquierda';
      case TurnDirection.right:
        return 'Gira a la derecha';
      case TurnDirection.slightLeft:
        return 'Mantente a la izquierda';
      case TurnDirection.slightRight:
        return 'Mantente a la derecha';
      case TurnDirection.sharpLeft:
        return 'Gira fuerte a la izquierda';
      case TurnDirection.sharpRight:
        return 'Gira fuerte a la derecha';
      case TurnDirection.uTurn:
        return 'Haz un cambio de sentido';
      case TurnDirection.arrive:
        return 'Llegaste a tu destino';
      case TurnDirection.straight:
        return 'Continúa recto';
    }
  }

  double _degToRad(double d) => d * math.pi / 180;
  double _radToDeg(double r) => r * 180 / math.pi;
}
