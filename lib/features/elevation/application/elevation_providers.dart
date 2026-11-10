import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../domain/elevation_dataset.dart';
import '../domain/srtm_tile_naming.dart';
import '../../../core/platform/platform.dart';
import '../data/elevation_dataset_preference.dart';
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

/// Cadena de prioridades de elevación: GPX > HGT > fusión en vivo, con el
/// modelo que eligió el ciclista. Lo usan el aplanado post-actividad y la
/// fusión en vivo.
final elevationResolverProvider = Provider<ElevationResolver>((ref) {
  return ElevationResolver(
    ref.watch(gpxTrackRepositoryProvider),
    ref.watch(elevationRepositoryProvider),
  );
});

/// Un resolvedor aparte con un modelo fijo, para "Ajustar altimetría" con
/// el modelo que se elija ahí: no toca el de la grabación en curso.
final elevationResolverForProvider =
    Provider.family<ElevationResolver, ElevationDataset>((ref, dataset) {
      final database = ref.watch(appDatabaseProvider);
      return ElevationResolver(
        GpxTrackRepository(database),
        ElevationRepository(database),
        fixedDataset: dataset,
      );
    });

/// El modelo de elevación elegido en Ajustes › Elevación. Cambiarlo solo
/// afecta a las salidas nuevas: las guardadas se cambian una por una en
/// "Ajustar altimetría".
class ElevationDatasetController extends StateNotifier<ElevationDataset> {
  ElevationDatasetController() : super(ElevationDataset.standard) {
    _load();
  }

  Future<void> _load() async {
    final saved = await ElevationDatasetPreference.load();
    if (mounted) state = saved;
  }

  Future<void> select(ElevationDataset dataset) async {
    state = dataset;
    await ElevationDatasetPreference.save(dataset);
  }
}

final elevationDatasetProvider =
    StateNotifierProvider<ElevationDatasetController, ElevationDataset>(
      (ref) => ElevationDatasetController(),
    );

final downloadedElevationTilesProvider =
    StreamProvider<List<DownloadedElevationTile>>((ref) {
  return ref.watch(elevationRepositoryProvider).watchDownloadedTiles();
});

/// Radio (km) que se cubre alrededor de la posición del usuario. 30 km
/// cubre una salida de un día desde Bogotá (Patios, La Calera, Choachí,
/// la Sabana) con las dos teselas de la ciudad.
///
/// Es UNO solo para Ajustes › Elevación y para la revisión al grabar:
/// antes Ajustes bajaba un radio de 15 km y al grabar se pedían 50, así
/// que lo que se descargaba en Ajustes nunca alcanzaba y la app volvía a
/// pedir teselas en cada salida.
const double elevationDownloadRadiusKm = 30;

/// Teselas del modelo elegido que faltan para la posición GPS actual, sin
/// las que el ciclista pidió no volver a ofrecer. Se recalcula sola
/// cuando cambia lo descargado o el modelo; antes de grabar conviene
/// pedirla de nuevo (`ref.refresh`), porque la posición pudo cambiar.
final missingElevationTilesProvider = FutureProvider<List<SrtmTileId>>((
  ref,
) async {
  ref.watch(downloadedElevationTilesProvider);
  final dataset = ref.watch(elevationDatasetProvider);
  final repository = ref.watch(elevationRepositoryProvider);
  final position = await ref.watch(currentPositionProvider.future);
  final missing = await repository.missingTilesForRadius(
    centerLat: position.latitude,
    centerLng: position.longitude,
    radiusKm: elevationDownloadRadiusKm,
    dataset: dataset,
  );
  final declined = await repository.declinedTiles(dataset: dataset);
  return [
    for (final tile in missing)
      if (!declined.contains(tile.fileName)) tile,
  ];
});
