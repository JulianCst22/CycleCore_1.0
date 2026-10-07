import 'dart:math' as math;

import '../units.dart';

/// `60 / 2π`: pasa de rpm a rad/s en `P = τ·ω`.
const _rpmToRadPerSecond = 60 / (2 * math.pi);

/// Factor de intensidad: cuántas veces su umbral está empujando.
double intensityFactor(Watts power, Watts criticalPower) {
  assert(criticalPower > 0);
  return power / criticalPower;
}

/// Índice de variabilidad `NP / media`: qué tan parejo pedalea (1 es
/// perfectamente constante).
double variabilityIndex(Watts normalizedPower, Watts meanPower) {
  assert(meanPower > 0);
  return normalizedPower / meanPower;
}

/// Reserva de frecuencia cardíaca consumida (Karvonen):
/// `(FC − FCrep) / (FCmáx − FCrep)`.
double heartRateReserveFraction(
  Bpm heartRate, {
  required Bpm resting,
  required Bpm maximum,
}) {
  assert(maximum > resting);
  return (heartRate - resting) / (maximum - resting);
}

/// Torque en el pedal, `τ = 60·P / (2π·cadencia)`; `null` sin pedaleo.
NewtonMeters? pedalTorque(Watts power, Rpm cadence) {
  if (cadence <= 0) return null;
  return NewtonMeters(_rpmToRadPerSecond * power / cadence);
}

/// Torque relativo al que el ciclista aplica en su umbral y a su cadencia
/// preferida; `null` sin pedaleo.
double? relativeTorque(
  Watts power,
  Rpm cadence, {
  required Watts criticalPower,
  required Rpm preferredCadence,
}) {
  final now = pedalTorque(power, cadence);
  final reference = pedalTorque(criticalPower, preferredCadence);
  if (now == null || reference == null || reference <= 0) return null;
  return now / reference;
}

/// Desacople pulso–potencia entre dos tramos del esfuerzo:
/// `(EF₂ − EF₁) / EF₁`, con `EF = potencia / pulso`.
///
/// Negativo cuando cada latido rinde menos potencia en el segundo tramo:
/// fatiga acumulada. Por encima de un 5 % en valor absoluto es una señal
/// clara.
double decoupling({
  required Watts firstPower,
  required Bpm firstHeartRate,
  required Watts secondPower,
  required Bpm secondHeartRate,
}) {
  assert(firstHeartRate > 0 && secondHeartRate > 0 && firstPower > 0);
  final ef1 = firstPower / firstHeartRate;
  final ef2 = secondPower / secondHeartRate;
  return (ef2 - ef1) / ef1;
}

/// Desacople de dos series simultáneas de 1 Hz, partidas por la mitad.
/// Solo cuentan los segundos con las dos lecturas; `null` si alguna mitad
/// queda sin datos.
double? decouplingOfSeries(List<double?> watts, List<double?> heartRate) {
  final n = math.min(watts.length, heartRate.length);
  if (n < 2) return null;
  ({double p, double hr})? halfMeans(int from, int to) {
    var p = 0.0, hr = 0.0, count = 0;
    for (var i = from; i < to; i++) {
      final w = watts[i], h = heartRate[i];
      if (w == null || h == null) continue;
      p += w;
      hr += h;
      count++;
    }
    return count == 0 || hr == 0 ? null : (p: p / count, hr: hr / count);
  }

  final first = halfMeans(0, n ~/ 2);
  final second = halfMeans(n ~/ 2, n);
  if (first == null || second == null || first.p <= 0) return null;
  return decoupling(
    firstPower: Watts(first.p),
    firstHeartRate: Bpm(first.hr),
    secondPower: Watts(second.p),
    secondHeartRate: Bpm(second.hr),
  );
}
