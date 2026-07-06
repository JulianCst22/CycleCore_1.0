/// Snapshot de una actividad recién grabada en el mapa, antes de que el
/// usuario le ponga título, tipo y bicicleta y decida guardarla.
///
/// Esto NO es el modelo persistido (ese es `Activity`, generado por Drift
/// a partir de la tabla `Activities`). Este objeto es solo el puente
/// entre "lo que grabó el GPS/sensores" y la pantalla de guardado.
class ActivitySummary {
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final double distanceMeters;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final double elevationGainMeters;

  /// Null si no hubo sensor de FC conectado durante la grabación.
  final int? avgHeartRate;
  final int? maxHeartRate;

  final List<RoutePointSnapshot> routePoints;

  const ActivitySummary({
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.distanceMeters,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.elevationGainMeters,
    required this.routePoints,
    this.avgHeartRate,
    this.maxHeartRate,
  });
}

/// Punto de ruta simplificado a solo lat/lng, para no acoplar esta capa
/// al paquete `latlong2` que usa la capa de mapas.
class RoutePointSnapshot {
  final double latitude;
  final double longitude;

  const RoutePointSnapshot({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};

  factory RoutePointSnapshot.fromJson(Map<String, dynamic> json) {
    return RoutePointSnapshot(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
    );
  }
}
