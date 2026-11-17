/// De dónde salió una altitud resuelta.
enum ElevationSource {
  /// Perfil de un GPX de ciclocomputador -- prioridad 1.
  gpx,

  /// Grilla del modelo de elevación (Copernicus, `.hgt`) descargada --
  /// prioridad 2.
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

/// Las fuentes de altitud de una coordenada, cada una por su lado.
class ElevationSamples {
  /// Perfil de un GPX importado cercano, ya anclado al modelo.
  final double? gpx;

  /// Modelo de elevación (Copernicus) descargado.
  final double? model;

  const ElevationSamples({this.gpx, this.model});
}

/// Consulta de altitud por coordenada según la cadena de prioridades
/// de elevación. La implementa `ElevationResolver` (capa de datos); el
/// dominio -- p. ej. `ActivityAltitudeFlattener` -- solo conoce esta
/// interfaz.
abstract interface class ElevationLookup {
  ResolvedElevation resolve(double lat, double lng);

  /// GPX y modelo por separado: la capa 3 difusa decide cuánto pesa cada
  /// uno, en vez de aplicar la prioridad fija de [resolve].
  ElevationSamples samples(double lat, double lng);
}
