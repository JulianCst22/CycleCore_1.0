import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/elevation/srtm_tile_naming.dart';
import '../../geospatial/presentation/map_providers.dart';
import '../data/elevation_repository.dart';

final elevationRepositoryProvider = Provider<ElevationRepository>((ref) {
  return ElevationRepository(ref.watch(appDatabaseProvider));
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
