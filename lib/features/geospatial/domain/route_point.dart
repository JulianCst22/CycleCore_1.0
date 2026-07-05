/// Representa un único punto capturado mientras se graba una ruta.
///
/// Este es el bloque base con el que luego se construyen las rutas
/// completas y, a partir de ellas, los segmentos (punto A -> punto B)
/// que el usuario define sobre el mapa.
class RoutePoint {
  final double latitude;
  final double longitude;

  /// Altitud FUSIONADA (GPS + barómetro vía AltitudeFusionService), en
  /// metros. Esta es la que se usa para todos los cálculos de pendiente
  /// y desnivel -- no es la altitud cruda del GPS.
  final double altitude;

  /// Velocidad instantánea en metros/segundo, reportada directamente por
  /// el GPS del dispositivo (Position.speed de geolocator).
  final double speedMetersPerSecond;

  /// Rumbo de desplazamiento en grados (0-360, 0 = norte), reportado por
  /// el GPS del dispositivo (Position.heading de geolocator). Se usa
  /// para orientar el ícono del ciclista en el mapa según hacia dónde
  /// se está moviendo, y más adelante para el reconocimiento de
  /// segmentos sobre la ruta.
  final double bearingDegrees;

  final DateTime timestamp;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speedMetersPerSecond,
    required this.bearingDegrees,
    required this.timestamp,
  });

  @override
  String toString() =>
      'RoutePoint(lat: $latitude, lng: $longitude, alt: $altitude, '
      'speed: $speedMetersPerSecond, bearing: $bearingDegrees, t: $timestamp)';
}
