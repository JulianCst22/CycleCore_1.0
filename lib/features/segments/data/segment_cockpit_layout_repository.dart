import 'package:shared_preferences/shared_preferences.dart';

import '../domain/segment_cockpit_field.dart';
import '../domain/segment_cockpit_tile_config.dart';
import '../../cockpit/cockpit.dart' show CockpitTileSize;

/// Persiste qué campos muestra la pantalla de segmento en vivo, en qué
/// orden y con qué tamaño. Mismo patrón (y misma clase de tamaño) que
/// `CockpitLayoutRepository` del mapa, en su propia clave de
/// SharedPreferences para que las dos configuraciones sean
/// independientes.
class SegmentCockpitLayoutRepository {
  static const String _prefsKey = 'segment_cockpit_tiles_v1';

  static const List<SegmentCockpitTileConfig> defaultTiles = [
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.mapaSegmento,
      size: CockpitTileSize.large,
    ),
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.deltaPr,
      size: CockpitTileSize.large,
    ),
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.perfilAltimetria,
      size: CockpitTileSize.wide,
    ),
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.barraProgreso,
      size: CockpitTileSize.wide,
    ),
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.tiempoEnSegmento,
      size: CockpitTileSize.small,
    ),
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.proyeccionMeta,
      size: CockpitTileSize.small,
    ),
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.pendienteActual,
      size: CockpitTileSize.small,
    ),
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.desnivelRestante,
      size: CockpitTileSize.small,
    ),
  ];

  Future<List<SegmentCockpitTileConfig>> loadTiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      final parsed = raw
          .map(SegmentCockpitTileConfig.tryDeserialize)
          .whereType<SegmentCockpitTileConfig>()
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return defaultTiles;
  }

  Future<void> saveTiles(List<SegmentCockpitTileConfig> tiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      tiles.map((t) => t.serialize()).toList(),
    );
  }
}
