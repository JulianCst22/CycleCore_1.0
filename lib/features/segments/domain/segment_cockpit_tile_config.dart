import '../../cockpit/cockpit.dart' show CockpitTileSize;
import 'segment_cockpit_field.dart';

/// Un campo elegido para la pantalla de segmento + su tamaño. Reusa
/// `CockpitTileSize` (Chico/Ancho/Grande) del cockpit del mapa -- la
/// mecánica de tamaños es la misma, solo cambia el catálogo de campos.
///
/// El ORDEN dentro de la lista persistida decide el acomodo (ver
/// `packCockpitTiles`), igual que en el cockpit del mapa.
class SegmentCockpitTileConfig {
  final SegmentCockpitField field;
  final CockpitTileSize size;

  const SegmentCockpitTileConfig({required this.field, required this.size});

  SegmentCockpitTileConfig copyWith({
    SegmentCockpitField? field,
    CockpitTileSize? size,
  }) {
    return SegmentCockpitTileConfig(
      field: field ?? this.field,
      size: size ?? this.size,
    );
  }

  String serialize() => '${field.name}|${size.name}';

  static SegmentCockpitTileConfig? tryDeserialize(String raw) {
    final parts = raw.split('|');
    if (parts.length != 2) return null;
    try {
      return SegmentCockpitTileConfig(
        field: SegmentCockpitField.values.byName(parts[0]),
        size: CockpitTileSize.values.byName(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }
}
