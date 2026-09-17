import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cockpit_field.dart';
import '../domain/cockpit_tile_config.dart';

/// Persiste el layout del cockpit (qué campos, en qué orden, con qué
/// tamaño) en SharedPreferences.
///
/// REEMPLAZA la versión anterior de este archivo, que solo guardaba
/// `List<CockpitField>` (sin tamaño). Si el dispositivo ya tenía un
/// layout guardado con el formato viejo, `_tryMigrateLegacyFormat` lo
/// reinterpreta como una lista de campos en tamaño Chico -- así nadie
/// pierde su selección de campos al actualizar, aunque sí tenga que
/// volver a decidir tamaños/orden una vez.
class CockpitLayoutRepository {
  static const String _prefsKey = 'cockpit_tiles_v2';
  static const String _legacyPrefsKey = 'cockpit_fields_v1';

  static const List<CockpitTileConfig> defaultTiles = [
    CockpitTileConfig(field: CockpitField.velocidad, size: CockpitTileSize.large),
    CockpitTileConfig(field: CockpitField.tiempo, size: CockpitTileSize.small),
    CockpitTileConfig(field: CockpitField.distancia, size: CockpitTileSize.small),
  ];

  /// Se mantiene por compatibilidad con quien todavía llame
  /// `CockpitLayoutRepository.defaultFields` -- equivale a los campos
  /// de [defaultTiles], sin la info de tamaño.
  static List<CockpitField> get defaultFields =>
      defaultTiles.map((t) => t.field).toList();

  Future<List<CockpitTileConfig>> loadTiles() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getStringList(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      final parsed = raw
          .map(CockpitTileConfig.tryDeserialize)
          .whereType<CockpitTileConfig>()
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }

    final migrated = await _tryMigrateLegacyFormat(prefs);
    if (migrated != null) return migrated;

    return defaultTiles;
  }

  Future<void> saveTiles(List<CockpitTileConfig> tiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      tiles.map((t) => t.serialize()).toList(),
    );
  }

  Future<List<CockpitTileConfig>?> _tryMigrateLegacyFormat(
    SharedPreferences prefs,
  ) async {
    final legacyRaw = prefs.getStringList(_legacyPrefsKey);
    if (legacyRaw == null || legacyRaw.isEmpty) return null;

    final migrated = <CockpitTileConfig>[];
    for (final name in legacyRaw) {
      try {
        migrated.add(
          CockpitTileConfig(
            field: CockpitField.values.byName(name),
            size: CockpitTileSize.small,
          ),
        );
      } catch (_) {
        // Campo desconocido (versión vieja de la app) -- se ignora en
        // vez de fallar la migración completa.
      }
    }
    if (migrated.isEmpty) return null;

    await saveTiles(migrated);
    return migrated;
  }

  /// Ajusta una lista existente de tiles a un nuevo número total de
  /// campos, preservando los que ya había: si crece, agrega campos no
  /// usados en tamaño Chico; si se usaron los 12 disponibles, repite
  /// desde el principio antes de dejar un slot vacío (mismo criterio
  /// que ya tenía la hoja de configuración original). Si se reduce,
  /// recorta desde el final.
  static List<CockpitTileConfig> adjustCount(
    List<CockpitTileConfig> current,
    int newCount,
  ) {
    if (newCount <= current.length) {
      return current.sublist(0, newCount);
    }

    final result = List<CockpitTileConfig>.from(current);
    final usedFields = result.map((t) => t.field).toSet();
    final unused =
        CockpitField.values.where((f) => !usedFields.contains(f)).toList();

    var i = 0;
    while (result.length < newCount && i < unused.length) {
      result.add(CockpitTileConfig(field: unused[i], size: CockpitTileSize.small));
      i++;
    }
    while (result.length < newCount) {
      final field = CockpitField.values[result.length % CockpitField.values.length];
      result.add(CockpitTileConfig(field: field, size: CockpitTileSize.small));
    }
    return result;
  }
}
