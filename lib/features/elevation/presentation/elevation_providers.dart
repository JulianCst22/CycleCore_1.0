import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/database/app_database.dart';
import 'package:cyclecore_core/database/database_providers.dart';
import 'package:cyclecore_core/elevation/srtm_tile_naming.dart';
import 'package:cyclecore_core/providers/location_providers.dart';
import '../data/elevation_repository.dart';
import '../data/elevation_resolver.dart';
import '../data/gpx_track_repository.dart';

final elevationRepositoryProvider = Provider<ElevationRepository>((ref) {
  return ElevationRepository(ref.watch(appDatabaseProvider));
});

/// Fuente de elevación de prioridad 1 (perfiles de GPX importados / del
/// catálogo). Ver `GpxTrackRepository`.
final gpxTrackRepositoryProvider = Provider<GpxTrackRepository>((ref) {
  return GpxTrackRepository(ref.watch(appDatabaseProvider));
});

/// Cadena de prioridades de elevación: GPX > HGT > fusión en vivo.
/// Lo usan el aplanado post-actividad y la fusión en vivo.
final elevationResolverProvider = Provider<ElevationResolver>((ref) {
  return ElevationResolver(
    ref.watch(gpxTrackRepositoryProvider),
    ref.watch(elevationRepositoryProvider),
  );
});

final downloadedElevationTilesProvider =
    StreamProvider<List<DownloadedElevationTile>>((ref) {
  return ref.watch(elevationRepositoryProvider).watchDownloadedTiles();
});

/// Radio (km) que se descarga alrededor de la posición del usuario. 30 km
/// cubre de sobra cualquier ruta de un solo día saliendo de un mismo
/// punto (ej. Bogotá y cerros aledaños) sin pedir teselas de más que
/// tengas que salir a conseguir para poder probar. Si más adelante haces
/// pilotos en zonas más extensas, puedes subirlo -- pero mientras tanto
/// esto reduce cuántas teselas necesitas tener en el bucket para probar.
const double elevationDownloadRadiusKm = 50;

/// Teselas que faltan por descargar para la posición GPS actual.
final missingElevationTilesProvider = FutureProvider<List<SrtmTileId>>((
  ref,
) async {
  final position = await ref.watch(currentPositionProvider.future);
  return ref
      .watch(elevationRepositoryProvider)
      .missingTilesForRadius(
        centerLat: position.latitude,
        centerLng: position.longitude,
        radiusKm: elevationDownloadRadiusKm,
      );
});
