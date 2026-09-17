import '../domain/elevation_lookup.dart';
import 'elevation_repository.dart';
import 'gpx_track_repository.dart';

/// Punto único de la cadena de prioridades de elevación:
///
///   1. GPX  (`GpxTrackRepository`)  -- barométrico, lo más fiable.
///   2. HGT  (`ElevationRepository`) -- grilla SRTM ~30 m.
///   3. nada -- el llamador usa el GPS/barómetro fusionado en vivo.
///
/// Lo consultan tanto el aplanado post-actividad
/// (`ActivityAltitudeFlattener`) como la fusión en vivo
/// (`RouteRecordingController._onNewPosition`), así que la lógica de
/// "qué fuente gana" vive en un solo lugar.
class ElevationResolver implements ElevationLookup {
  final GpxTrackRepository gpxTracks;
  final ElevationRepository dem;

  ElevationResolver(this.gpxTracks, this.dem);

  /// Carga a memoria los catálogos de ambas fuentes. Llamar antes de
  /// grabar o de re-aplanar una actividad.
  Future<void> preload() async {
    await gpxTracks.preload();
    await dem.preloadCatalog();
  }

  @override
  ResolvedElevation resolve(double lat, double lng) {
    final gpx = gpxTracks.elevationAtSync(lat, lng);
    if (gpx != null) return ResolvedElevation(gpx, ElevationSource.gpx);

    final hgt = dem.elevationAtSync(lat, lng);
    if (hgt != null) return ResolvedElevation(hgt, ElevationSource.hgt);

    return ResolvedElevation.none;
  }
}
