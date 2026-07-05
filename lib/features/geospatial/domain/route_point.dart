/// Representa un único punto capturado del GPS mientras se graba una ruta.
///
/// Este es el bloque base con el que luego se construyen las rutas
/// completas y, a partir de ellas, los segmentos (punto A -> punto B)
/// que el usuario define sobre el mapa.
class RoutePoint {
  final double latitude;
  final double longitude;

  /// Altitud en metros, reportada por el GPS del dispositivo.
  /// Se usará más adelante en la fusión GPS + barómetro para pendiente.
  final double altitude;

  final DateTime timestamp;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
  });

  @override
  String toString() =>
      'RoutePoint(lat: $latitude, lng: $longitude, alt: $altitude, t: $timestamp)';
}
