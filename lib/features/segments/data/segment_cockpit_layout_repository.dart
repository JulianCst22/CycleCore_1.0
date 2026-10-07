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
  /// v2: el mapa, el perfil y la barra de progreso dejaron de ser
  /// recuadros de la cuadrícula (ahora son la cabecera fija de la
  /// pantalla). Clave nueva para que nadie arrastre la distribución
  /// vieja, que ya no tiene sentido sin esos tres bloques.
  static const String _prefsKey = 'segment_cockpit_tiles_v2';

  /// Lo que se mira subiendo, en orden: el esfuerzo (potencia, pulso,
  /// cadencia), el terreno de ahora y el reloj. Lo que falta para la
  /// cima y la comparación con la mejor marca ya están en la cabecera.
  static const List<SegmentCockpitTileConfig> defaultTiles = [
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.potencia,
      size: CockpitTileSize.small,
    ),
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.frecuenciaCardiaca,
      size: CockpitTileSize.small,
    ),
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.cadencia,
      size: CockpitTileSize.small,
    ),
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.velocidad,
      size: CockpitTileSize.small,
    ),
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.pendienteActual,
      size: CockpitTileSize.small,
    ),
    SegmentCockpitTileConfig(
      field: SegmentCockpitField.proyeccionMeta,
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
          .where((t) => !t.field.isVisualBlock)
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
