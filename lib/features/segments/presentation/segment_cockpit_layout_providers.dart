import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/segment_cockpit_layout_repository.dart';
import '../domain/segment_cockpit_tile_config.dart';

final segmentCockpitLayoutRepositoryProvider =
    Provider<SegmentCockpitLayoutRepository>((ref) {
  return SegmentCockpitLayoutRepository();
});

/// Layout de la pantalla de segmento en vivo: qué campos, en qué orden,
/// con qué tamaño. `AsyncNotifier` porque la carga es asíncrona
/// (SharedPreferences) -- mismo patrón que `CockpitLayoutNotifier`.
class SegmentCockpitLayoutNotifier
    extends AsyncNotifier<List<SegmentCockpitTileConfig>> {
  @override
  Future<List<SegmentCockpitTileConfig>> build() {
    return ref.read(segmentCockpitLayoutRepositoryProvider).loadTiles();
  }

  Future<void> setTiles(List<SegmentCockpitTileConfig> tiles) async {
    await ref.read(segmentCockpitLayoutRepositoryProvider).saveTiles(tiles);
    state = AsyncValue.data(tiles);
  }

  Future<void> resetToDefault() =>
      setTiles(SegmentCockpitLayoutRepository.defaultTiles);
}

final segmentCockpitLayoutProvider = AsyncNotifierProvider<
    SegmentCockpitLayoutNotifier, List<SegmentCockpitTileConfig>>(
  SegmentCockpitLayoutNotifier.new,
);
