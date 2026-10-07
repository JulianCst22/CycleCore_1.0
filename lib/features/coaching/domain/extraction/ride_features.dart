import 'dart:math' as math;

import '../../../../core/physiology/physiology.dart';
import '../../../../core/physiology/physiology.dart'
    as energy
    show sufficiency, sustainablePower, timeToExhaustion;
import '../athlete.dart';
import '../coaching_parameters.dart';
import '../variables/labels.dart';
import 'effort_tracker.dart';
import 'terrain_reader.dart';

/// Las variables que entran a los motores, cada una con su valor y su
/// banda de incertidumbre (±1σ). Las que dependen de un sensor que no hay
/// quedan en `null`: el motor las trata con credibilidad cero.
final class RideFeatures {
  // Motor A
  final UncertainValue? intensity;
  final UncertainValue? heartRateReserve;
  final UncertainValue? torque;
  final UncertainValue? reserve;
  final UncertainValue? sufficiency;
  final UncertainValue? decoupling;
  final UncertainValue? variability;

  // Motor B
  final UncertainValue gradientAhead;
  final UncertainValue maxRamp;
  final UncertainValue roughness;
  final UncertainValue climbLeft;
  final UncertainValue progress;

  // Motor C
  final UncertainValue? recordPace;

  // Contexto numérico para los objetivos y los mensajes (no se fuzzifica)
  /// Potencia media de los últimos 30 s: base del objetivo en vatios.
  final double? basePower;
  final double? cadence;

  /// Velocidad media reciente (m/s). No entra al motor: sirve para
  /// saber qué cadencia da el desarrollo que lleva puesto.
  final double? speed;

  /// Pulso actual (media de la ventana corta), para los mensajes.
  final double? heartRate;
  final double remainingSeconds;
  final double? sustainablePower;

  /// La misma potencia sostenible pero con el tanque entero, sin la
  /// fracción que reserva el modo de entrenamiento. Es la ecuación 2.10
  /// tal cual: la que sirve para contrastar las reglas contra la física
  /// (F12) sin que el modo del día ensucie la comparación.
  final double? physicalSustainablePower;

  /// Banda de la potencia sostenible (±1σ del conjunto de atletas
  /// posibles). Su extremo inferior es el objetivo prudente: por debajo
  /// de ahí se pierde tiempo sin ganar reserva.
  final UncertainValue? sustainablePowerBand;
  final double? timeToExhaustion;
  final TerrainWindow? terrain;

  /// La potencia no viene de un potenciómetro sino de la velocidad y la
  /// pendiente. El motor la usa igual, pero con la banda ancha que le
  /// corresponde, y el mensaje no dice vatios: serían un número
  /// inventado.
  final bool powerIsEstimated;

  const RideFeatures({
    required this.intensity,
    required this.heartRateReserve,
    required this.torque,
    required this.reserve,
    required this.sufficiency,
    required this.decoupling,
    required this.variability,
    required this.gradientAhead,
    required this.maxRamp,
    required this.roughness,
    required this.climbLeft,
    required this.progress,
    required this.recordPace,
    required this.basePower,
    required this.remainingSeconds,
    this.cadence,
    this.speed,
    this.heartRate,
    this.sustainablePower,
    this.physicalSustainablePower,
    this.sustainablePowerBand,
    this.timeToExhaustion,
    this.terrain,
    this.powerIsEstimated = false,
  });

  /// Calcula las variables a partir de la historia del esfuerzo y del
  /// tramo que viene.
  ///
  /// Bandas por propagación de primer orden (intensidad, reserva
  /// cardíaca, torque, deriva) y por el conjunto de atletas posibles
  /// (reserva y suficiencia de W′). La banda siempre contiene el valor
  /// nominal, para que el resultado tipo-1 quede dentro del tipo-2.
  factory RideFeatures.extract({
    required EffortTracker effort,
    required TerrainWindow terrain,
    required ReferenceEffort? reference,
    required double alongMeters,
    required CoachAthlete athlete,
    Goal goal = Goal.pr,
    CoachingParameters parameters = const CoachingParameters(),
  }) {
    final p = parameters;
    final model = athlete.power;
    final cp = model.cp.toDouble();
    final t = effort.seconds.toDouble();

    // Tiempo restante y ventaja sobre la referencia.
    double? pace;
    double remaining;
    if (reference != null) {
      pace = reference.secondsAt(alongMeters) - t;
      remaining = reference.totalSeconds - pace - t;
    } else if (terrain.climbDone > 5 && t > 0) {
      remaining = terrain.climbLeft / (terrain.climbDone / t);
    } else if (alongMeters > 0 && t > 0) {
      remaining = terrain.distanceLeft / (alongMeters / t);
    } else {
      remaining = 3600;
    }
    remaining = math.max(1.0, remaining);

    final power = effort.power;
    final base = effort.basePower;
    final hr = effort.heartRate;
    final cad = effort.cadence;
    // Con potenciómetro es el 1,5 % del aparato; sin él, lo que de
    // verdad se está adivinando al estimar con la velocidad.
    final powerSigma = effort.powerRelativeUncertainty;

    UncertainValue gum(
      double Function(List<double> x) f,
      List<double> mean,
      List<double> sigmas,
    ) => propagateLinear(f, mean, Covariance.diagonal(sigmas));

    UncertainValue? intensity;
    UncertainValue? torque;
    if (power != null) {
      intensity = gum(
        (x) => x[0] * power / x[1],
        [1, cp],
        [powerSigma, model.seCp],
      );
      if (cad != null && cad > 0) {
        final pref = athlete.preferredCadence.toDouble();
        torque = gum(
          (x) => (x[0] * power / x[1]) / (x[2] / pref),
          [1, cad, cp],
          [powerSigma, p.cadenceAccuracy, model.seCp],
        );
      }
    }

    UncertainValue? hrReserve;
    if (hr != null) {
      final rest = athlete.restingHeartRate.toDouble();
      hrReserve = gum(
        (x) => (x[0] - rest) / (x[1] - rest),
        [hr, athlete.maxHeartRate.toDouble()],
        [p.heartRateAccuracy, p.maxHeartRateAccuracy],
      );
    }

    UncertainValue? decoupling;
    final halves = effort.halves;
    if (halves != null) {
      final p1 = halves.firstPower, p2 = halves.secondPower;
      decoupling = gum(
        (x) => 100 * ((p2 / x[1]) - (p1 / x[0])).abs() / (p1 / x[0]),
        [halves.firstHr, halves.secondHr],
        [p.heartRateAccuracy, p.heartRateAccuracy],
      );
    }

    final vi = effort.variability;
    UncertainValue? reserve;
    UncertainValue? sufficiencyValue;
    double? sustainable;
    double? physicalSustainable;
    UncertainValue? sustainableBand;
    double? exhaustion;
    // Las tres magnitudes del conjunto de atletas posibles salen de una
    // sola pasada: en carretera esto se recalcula en cada inferencia.
    final bands = base == null || effort.seconds == 0
        ? null
        : effort.ensembleBands(
            power: base,
            remainingSeconds: remaining,
            spendable: goal.spendable,
          );
    if (power != null && bands != null) {
      reserve = _bandOf(effort.reservePercent, bands.reservePercent);
    }
    if (base != null && bands != null) {
      final nominal = energy.sufficiency(
        balance: effort.balance,
        power: Watts(base),
        cp: model.cp,
        remainingSeconds: remaining,
        spendable: goal.spendable,
      );
      sufficiencyValue = _bandOf(nominal, bands.sufficiency);
      sustainable = energy.sustainablePower(
        balance: effort.balance,
        cp: model.cp,
        remainingSeconds: remaining,
        spendable: goal.spendable,
      );
      sustainableBand = _bandOf(sustainable, bands.sustainablePower);
      physicalSustainable = goal.spendable == 1
          ? sustainable
          : energy.sustainablePower(
              balance: effort.balance,
              cp: model.cp,
              remainingSeconds: remaining,
            );
      exhaustion = energy.timeToExhaustion(
        balance: effort.balance,
        power: Watts(base),
        cp: model.cp,
      );
    }

    final total = alongMeters + terrain.distanceLeft;
    return RideFeatures(
      intensity: intensity,
      heartRateReserve: hrReserve,
      torque: torque,
      reserve: reserve,
      sufficiency: sufficiencyValue,
      decoupling: decoupling,
      variability: vi == null ? null : UncertainValue.symmetric(vi, 0),
      gradientAhead: UncertainValue.symmetric(
        terrain.gradientAhead,
        p.gradientAccuracy,
      ),
      maxRamp: UncertainValue.symmetric(terrain.maxRamp, p.rampAccuracy),
      roughness: _nonNegative(terrain.roughness, p.roughnessAccuracy),
      climbLeft: _nonNegative(terrain.climbLeft, p.climbAccuracy),
      progress: UncertainValue.symmetric(
        terrain.progress,
        total > 0 ? 100 * p.positionAccuracy / total : 0,
      ),
      recordPace: pace == null
          ? null
          : UncertainValue.symmetric(pace, p.referenceAccuracy),
      basePower: base,
      cadence: cad,
      speed: effort.speed,
      heartRate: hr,
      remainingSeconds: remaining,
      sustainablePower: sustainable,
      physicalSustainablePower: physicalSustainable,
      sustainablePowerBand: sustainableBand,
      timeToExhaustion: exhaustion,
      terrain: terrain,
      powerIsEstimated: effort.powerIsEstimated,
    );
  }

  /// Banda de ±1σ del conjunto de atletas posibles, ampliada si hace
  /// falta para contener el valor nominal (así el resultado tipo-1 queda
  /// dentro del tipo-2).
  static UncertainValue _bandOf(double nominal, ({double lo, double hi}) band) {
    final lo = math.min(nominal, band.lo);
    final hi = math.max(nominal, band.hi);
    return UncertainValue(
      value: nominal,
      standardUncertainty: (hi - lo) / 2,
      lo: lo,
      hi: hi,
    );
  }

  static UncertainValue _nonNegative(double value, double u) => UncertainValue(
    value: value,
    standardUncertainty: u,
    lo: math.max(0.0, value - u),
    hi: value + u,
  );
}
