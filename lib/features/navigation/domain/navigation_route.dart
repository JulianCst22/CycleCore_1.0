import 'road_graph.dart';

enum TurnDirection {
  straight,
  slightLeft,
  slightRight,
  left,
  right,
  sharpLeft,
  sharpRight,
  uTurn,
  arrive,
}

/// Una instrucción de navegación, anclada a un punto de la ruta.
class RouteInstruction {
  final TurnDirection direction;

  /// Texto listo para mostrar en el banner y para pasarle a la voz,
  /// ej. "Gira a la derecha", "Llegaste a tu destino".
  final String text;

  /// Distancia acumulada desde el inicio de la ruta hasta este punto
  /// -- se usa para calcular "faltan 150m para el próximo giro".
  final double distanceFromStartMeters;

  final double lat;
  final double lng;

  const RouteInstruction({
    required this.direction,
    required this.text,
    required this.distanceFromStartMeters,
    required this.lat,
    required this.lng,
  });
}

/// Resultado final de calcular una ruta: lo que se dibuja en el mapa
/// (polyline) más la lista de instrucciones de giro en orden.
class NavigationRoute {
  final List<RoadNode> polyline;
  final List<RouteInstruction> instructions;
  final double totalDistanceMeters;

  const NavigationRoute({
    required this.polyline,
    required this.instructions,
    required this.totalDistanceMeters,
  });
}
