import 'dart:math' as math;

import '../../../../core/fuzzy_type2/fuzzy_type2.dart';
import '../../../../core/physiology/physiology.dart' show UncertainValue;
import '../coaching_parameters.dart';

/// Un objetivo numérico con su incertidumbre y el valor que se dice en
/// voz alta.
final class Target {
  /// Valor recomendado (punto medio del centroide de intervalo).
  final double value;

  /// Centroide de intervalo: la incertidumbre del propio objetivo.
  final Interval band;

  /// Valores aceptables (corte 0,5 de la figura superior).
  final Interval? range;

  /// Región segura (corte 0,7 de la figura inferior).
  final Interval? core;

  /// Múltiplo de 5 que se dice en voz alta: el más cercano, empujado hacia
  /// el lado seguro y sin salirse de la banda cuando es posible.
  final double spoken;

  /// El objetivo lo levantó la potencia sostenible: aflojar más no
  /// guardaría reserva, solo perdería tiempo.
  final bool limitedBySustainable;

  /// El objetivo lo **bajó** la potencia sostenible: las reglas pedían
  /// más de lo que la reserva aguanta hasta la cima.
  final bool cappedBySustainable;

  /// Los vatios que pidieron las reglas antes de recortarlos con la
  /// física. Es lo que hace falta para contrastar los dos caminos: si
  /// se compara el valor ya recortado, la comparación se contesta sola.
  final double requested;

  const Target({
    required this.value,
    required this.band,
    required this.range,
    required this.core,
    required this.spoken,
    required this.requested,
    this.limitedBySustainable = false,
    this.cappedBySustainable = false,
  });

  /// Piso que no conviene cruzar: el borde inferior de la región segura.
  double? get floor => core?.lo;
}

/// Objetivo de potencia a partir del ajuste:
///
///     P(y) = P_base · (1 + y/100 · Δmáx)
///
/// Se aplica al centroide, a los extremos del centroide de intervalo y a
/// los cortes α.
///
/// [sustainableFloor] es la potencia que el modelo de W′ dice que se
/// puede sostener hasta el final en su caso desfavorable (extremo
/// inferior de la banda). Cuando el consejo sale justamente de la reserva
/// (ver `reserveDrivenAdjustmentRules`), el objetivo no baja de ahí: por
/// debajo se pierde tiempo sin guardar nada. Nunca sube por encima de la
/// potencia que ya lleva.
Target? powerTarget(
  OutputInference adjustment, {
  required double basePower,
  UncertainValue? sustainable,
  double? sufficiency,
  bool reserveDriven = false,
  CoachingParameters parameters = const CoachingParameters(),
}) {
  final centroid = adjustment.centroid;
  if (centroid == null) return null;

  // Piso: solo cuando el consejo sale de la reserva. Es el extremo
  // prudente de lo sostenible, y nunca por encima de lo que ya lleva.
  final floor = !reserveDriven || sustainable == null
      ? null
      : math.min(sustainable.lo, basePower);

  // Techo: cuando la reserva no alcanza para lo que falta (S < 1), el
  // objetivo no puede pasarse de lo que de verdad se puede sostener,
  // venga de donde venga el consejo. Las reglas razonan con etiquetas
  // («soltar» es −7 %), y un porcentaje fijo sobre una potencia ya
  // pasada sigue siendo una potencia pasada.
  final ceiling =
      sustainable == null ||
          sufficiency == null ||
          sufficiency >= parameters.sufficiencyCeiling
      ? null
      : sustainable.value;

  double watts(double y) {
    var w = basePower * (1 + y / 100 * parameters.maxAdjustment);
    if (ceiling != null) w = math.min(w, ceiling);
    if (floor != null) w = math.max(w, floor);
    return w;
  }

  Interval? map(({double lo, double hi})? cut) =>
      cut == null ? null : Interval(watts(cut.lo), watts(cut.hi));
  final raw = basePower * (1 + centroid.mid / 100 * parameters.maxAdjustment);
  return _target(
    value: watts(centroid.mid),
    band: Interval(watts(centroid.lo), watts(centroid.hi)),
    range: map(adjustment.upperShape.alphaCut(0.5)),
    core: map(adjustment.lowerShape.alphaCut(0.7)),
    requested: raw,
    limitedBySustainable: floor != null && raw < floor,
    cappedBySustainable: ceiling != null && raw > ceiling,
  );
}

/// Objetivo de pulso cuando el corazón es lo que está topando.
///
/// No es una zona de entrenamiento: es «bájalo hasta acá y podrás
/// seguir». Se calcula sobre la reserva cardíaca (Karvonen), que es la
/// misma normalización que usa el motor, y se redondea a múltiplos de
/// cinco porque nadie persigue un pulso exacto pedaleando.
///
/// Devuelve `null` si el pulso ya está por debajo: no tiene sentido
/// pedirle a alguien que baje a donde ya está.
double? heartRateTarget({
  required double current,
  required double maxHeartRate,
  required double restingHeartRate,
  double fraction = 0.87,
  double minimumDrop = 4,
}) {
  final reserve = maxHeartRate - restingHeartRate;
  if (reserve <= 0) return null;
  final target = ((restingHeartRate + fraction * reserve) / 5).round() * 5.0;
  return current - target >= minimumDrop ? target : null;
}

/// Objetivo de cadencia: la salida ya está en rpm.
///
/// [reachable] es la cadencia máxima que la bicicleta da a la velocidad
/// actual, en el piñón más suave, y [atLeast] la mínima, en el más
/// duro. Pedir fuera de esos dos topes es pedir lo imposible: en una
/// rampa a 6 km/h un 34×32 no pasa de 44 rpm, y un consejo imposible no
/// es un consejo. Cuando se saben, el objetivo se recorta ahí.
Target? cadenceTarget(
  OutputInference cadence, {
  double? reachable,
  double? atLeast,
}) {
  final centroid = cadence.centroid;
  if (centroid == null) return null;
  double rpm(double value) {
    var out = value;
    if (reachable != null) out = math.min(out, reachable);
    if (atLeast != null) out = math.max(out, atLeast);
    return out;
  }
  Interval? map(({double lo, double hi})? cut) =>
      cut == null ? null : Interval(rpm(cut.lo), rpm(cut.hi));
  return _target(
    value: rpm(centroid.mid),
    band: Interval(rpm(centroid.lo), rpm(centroid.hi)),
    range: map(cadence.upperShape.alphaCut(0.5)),
    core: map(cadence.lowerShape.alphaCut(0.7)),
  );
}

Target _target({
  required double value,
  required Interval band,
  required Interval? range,
  required Interval? core,
  double? requested,
  bool limitedBySustainable = false,
  bool cappedBySustainable = false,
}) => Target(
  value: value,
  band: band,
  range: range,
  core: core,
  spoken: roundTowardSafety(value, band: band, safe: core ?? band),
  requested: requested ?? value,
  limitedBySustainable: limitedBySustainable,
  cappedBySustainable: cappedBySustainable,
);

/// Redondea [value] a un múltiplo de [step]: entre los dos vecinos elige
/// el más cercano al centro de la región [safe], salvo que solo el otro
/// quede dentro de [band].
double roundTowardSafety(
  double value, {
  required Interval band,
  required Interval safe,
  double step = 5,
}) {
  final down = (value / step).floorToDouble() * step;
  final up = (value / step).ceilToDouble() * step;
  if (down == up) return down;
  final center = safe.mid;
  final preferred = (down - center).abs() <= (up - center).abs() ? down : up;
  final other = preferred == down ? up : down;
  bool inBand(double x) => band.contains(x, tolerance: 1e-9);
  if (inBand(preferred)) return preferred;
  if (inBand(other)) return other;
  return preferred;
}
