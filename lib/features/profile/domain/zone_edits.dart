import 'dart:math' as math;

import 'training_zones.dart';

/// Ajustes de límites que mantienen las zonas encadenadas: mover el
/// inicio de una zona mueve el tope de la anterior, y mover su tope
/// mueve el inicio de la siguiente. Así nunca se pisan ni dejan huecos,
/// y ninguna queda vacía.
///
/// Lo que no se puede tocar desde aquí: el inicio de la primera zona de
/// potencia (es 0) y el tope de la última (la de potencia no tiene; la
/// de pulso es la FC máxima, que se cambia en el perfil).
class ZoneEdits {
  ZoneEdits._();

  /// Tope de cualquier límite, para que un dedo pegado al «+» no se
  /// vaya al infinito.
  static const _ceiling = 3000;

  static bool canMoveMin(List<TrainingZone> zones, int i) =>
      i > 0 || zones[i].min > 0;

  static bool canMoveMax(List<TrainingZone> zones, int i) =>
      i < zones.length - 1 && zones[i].max != null;

  /// Valores que puede tomar el inicio de la zona [i]. La primera de
  /// pulso no baja de 30 ppm (si no venía ya más abajo).
  static (int, int) minRange(List<TrainingZone> zones, int i) => (
    i == 0 ? math.min(30, zones[0].min) : zones[i - 1].min + 1,
    zones[i].max ?? _ceiling,
  );

  /// Valores que puede tomar el tope de la zona [i].
  static (int, int) maxRange(List<TrainingZone> zones, int i) => (
    zones[i].min,
    i + 1 < zones.length ? (zones[i + 1].max ?? _ceiling + 1) - 1 : _ceiling,
  );

  static List<TrainingZone> moveMin(List<TrainingZone> zones, int i, int to) {
    if (!canMoveMin(zones, i)) return zones;
    final (low, high) = minRange(zones, i);
    final value = to.clamp(low, high);
    return [
      for (var k = 0; k < zones.length; k++)
        if (k == i)
          zones[k].copyWith(min: value)
        else if (k == i - 1)
          zones[k].copyWith(max: value - 1)
        else
          zones[k],
    ];
  }

  static List<TrainingZone> moveMax(List<TrainingZone> zones, int i, int to) {
    if (!canMoveMax(zones, i)) return zones;
    final (low, high) = maxRange(zones, i);
    final value = to.clamp(low, high);
    return [
      for (var k = 0; k < zones.length; k++)
        if (k == i)
          zones[k].copyWith(max: value)
        else if (k == i + 1)
          zones[k].copyWith(min: value + 1)
        else
          zones[k],
    ];
  }

  static bool sameZones(List<TrainingZone> a, List<TrainingZone> b) {
    if (a.length != b.length) return false;
    for (var k = 0; k < a.length; k++) {
      if (a[k].min != b[k].min || a[k].max != b[k].max) return false;
    }
    return true;
  }
}
