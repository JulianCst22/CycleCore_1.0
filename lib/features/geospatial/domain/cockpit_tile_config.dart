import '../domain/cockpit_field.dart';

/// Tamaño visual de un campo dentro del cockpit configurable.
///
/// Se eligieron 3 tamaños fijos (Chico/Ancho/Grande) en vez de
/// redimensionado libre por píxeles: con tamaños libres habría que
/// resolver colisiones entre campos vecinos cada vez que uno crece
/// (empujar, encoger o superponer a los demás) -- una cantidad de
/// casos borde considerable para el beneficio real. Con 3 tamaños fijos
/// más la posibilidad de reordenar arrastrando, el usuario sigue
/// teniendo control real sobre la jerarquía visual (qué campo se ve
/// más grande) sin ese riesgo.
enum CockpitTileSize {
  /// 1 columna x 1 fila (en la grilla interna de 2 columnas).
  small,

  /// 2 columnas x 1 fila -- ocupa todo el ancho, alto normal.
  wide,

  /// 2 columnas x 2 filas -- el tile protagonista.
  large,
}

extension CockpitTileSizeX on CockpitTileSize {
  int get colSpan => this == CockpitTileSize.small ? 1 : 2;
  int get rowSpan => this == CockpitTileSize.large ? 2 : 1;

  String get shortLabel {
    switch (this) {
      case CockpitTileSize.small:
        return 'S';
      case CockpitTileSize.wide:
        return 'M';
      case CockpitTileSize.large:
        return 'L';
    }
  }
}

/// Un campo elegido por el usuario + el tamaño con el que se muestra.
/// El ORDEN dentro de la lista en `CockpitLayoutNotifier` determina
/// dónde cae cada uno al momento de acomodar la grilla (ver
/// `packCockpitTiles` en cockpit_grid_layout.dart) -- reordenar la
/// lista (arrastrar en modo edición) cambia el acomodo.
class CockpitTileConfig {
  final CockpitField field;
  final CockpitTileSize size;

  const CockpitTileConfig({required this.field, required this.size});

  CockpitTileConfig copyWith({CockpitField? field, CockpitTileSize? size}) {
    return CockpitTileConfig(
      field: field ?? this.field,
      size: size ?? this.size,
    );
  }

  /// Serialización simple como "campo|tamaño" -- suficiente para
  /// guardar en SharedPreferences como lista de strings, sin traer una
  /// dependencia de JSON solo para esto.
  String serialize() => '${field.name}|${size.name}';

  static CockpitTileConfig? tryDeserialize(String raw) {
    final parts = raw.split('|');
    if (parts.length != 2) return null;
    try {
      final field = CockpitField.values.byName(parts[0]);
      final size = CockpitTileSize.values.byName(parts[1]);
      return CockpitTileConfig(field: field, size: size);
    } catch (_) {
      return null;
    }
  }
}
