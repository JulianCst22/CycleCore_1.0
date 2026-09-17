/// De dónde salió una altitud resuelta.
enum ElevationSource {
  /// Perfil de un GPX de ciclocomputador -- prioridad 1.
  gpx,

  /// Grilla SRTM/HGT descargada -- prioridad 2.
  hgt,

  /// Ninguna fuente confiable en esa coordenada -- el llamador cae al
  /// GPS/barómetro fusionado y marca el punto como aproximado.
  none,
}

class ResolvedElevation {
  final double? altitudeMeters;
  final ElevationSource source;

  const ResolvedElevation(this.altitudeMeters, this.source);

  static const none = ResolvedElevation(null, ElevationSource.none);
}

/// Consulta de altitud por coordenada según la cadena de prioridades
/// de elevación. La implementa `ElevationResolver` (capa de datos); el
/// dominio -- p. ej. `ActivityAltitudeFlattener` -- solo conoce esta
/// interfaz.
abstract interface class ElevationLookup {
  ResolvedElevation resolve(double lat, double lng);
}
