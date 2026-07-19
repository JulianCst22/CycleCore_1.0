import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cockpit_layout_repository.dart';
import '../domain/cockpit_tile_config.dart';

final cockpitLayoutRepositoryProvider = Provider<CockpitLayoutRepository>((
  ref,
) {
  return CockpitLayoutRepository();
});

/// Layout completo del cockpit de pantalla completa: qué campos, en qué
/// orden, y con qué tamaño cada uno. AsyncNotifier porque la carga
/// inicial es asíncrona (SharedPreferences) -- mismo patrón que
/// `ZonesNotifier`.
///
/// REEMPLAZA la versión anterior (`List<CockpitField>` sin tamaño). El
/// orden de la lista es lo que decide el acomodo en la grilla (ver
/// `packCockpitTiles`); reordenar equivale a arrastrar un campo en modo
/// edición.
class CockpitLayoutNotifier extends AsyncNotifier<List<CockpitTileConfig>> {
  @override
  Future<List<CockpitTileConfig>> build() async {
    return ref.read(cockpitLayoutRepositoryProvider).loadTiles();
  }

  Future<void> setTiles(List<CockpitTileConfig> tiles) async {
    await ref.read(cockpitLayoutRepositoryProvider).saveTiles(tiles);
    state = AsyncValue.data(tiles);
  }

  /// Cambia cuántos campos hay en total, preservando los existentes
  /// (ver `CockpitLayoutRepository.adjustCount`). No persiste todavía
  /// -- eso pasa al llamar [setTiles] (p.ej. al tocar "Guardar").
  List<CockpitTileConfig> previewCountChange(int newCount) {
    final current = state.valueOrNull ?? CockpitLayoutRepository.defaultTiles;
    return CockpitLayoutRepository.adjustCount(current, newCount);
  }
}

final cockpitLayoutProvider =
    AsyncNotifierProvider<CockpitLayoutNotifier, List<CockpitTileConfig>>(
      CockpitLayoutNotifier.new,
    );
