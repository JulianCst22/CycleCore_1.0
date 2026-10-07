import 'dart:math' as math;

import 'package:cyclecore_app/core/geo/geo.dart';
import 'package:cyclecore_app/core/physiology/physiology.dart';
import 'package:cyclecore_app/features/coaching/domain/athlete.dart';
import 'package:cyclecore_app/features/coaching/domain/extraction/effort_tracker.dart';
import 'package:cyclecore_app/features/coaching/domain/extraction/sensor_credibility.dart';
import 'package:cyclecore_app/features/coaching/domain/extraction/terrain_reader.dart';
import 'package:cyclecore_app/features/coaching/domain/replay/ride_recording.dart';

/// Subida de Belisario a Patios **simulada**: no es una salida real.
///
/// Sirve para que las herramientas de la tesis corran de punta a punta
/// sin depender de un archivo del teléfono, y para que las figuras se
/// puedan regenerar siempre iguales (la semilla es fija). Los datos de
/// campo llegan en la fase 9; todo lo que salga de acá va rotulado como
/// simulado.
///
/// La velocidad no se inventa: sale de un modelo físico de ciclismo
///
///     P·η = v·(m·g·(sen θ + Crr·cos θ) + ½·ρ·CdA·v²)
///
/// resuelto por bisección en cada segundo. El pulso sigue a la potencia
/// con un retardo de primer orden y una deriva lenta, y la cadencia baja
/// con la pendiente, que es lo que se ve en una subida larga.
RideRecording simulatedPatiosRide({int seed = 7}) {
  final profile = patiosProfile();
  final random = math.Random(seed);
  final ticks = <RideTick>[];

  const mass = 72.0; // ciclista + bicicleta, kg
  const gravity = 9.81;
  const crr = 0.005;
  const cda = 0.32;
  const rho = 0.93; // aire a 2.600 m
  const drivetrain = 0.975;

  var along = 0.0;
  var heartRate = 128.0;
  var smoothedPower = 330.0;
  final total = profile.totalDistanceMeters;

  for (var second = 0; along < total && second < 2400; second++) {
    final target = _plannedPower(second);
    // La potencia real no es una línea recta: oscila alrededor del plan.
    smoothedPower +=
        (target - smoothedPower) / 6 + (random.nextDouble() - 0.5) * 14;
    final power = smoothedPower.clamp(120.0, 520.0);

    final slope = profile.slopePercentAtDistance(along) ?? 0;
    final speed = _speedAt(
      power * drivetrain,
      slope,
      mass,
      gravity,
      crr,
      cda,
      rho,
    );

    // El pulso persigue a la potencia y se va yendo arriba con el rato.
    final hrTarget = 118 + 0.18 * power + second * 0.006;
    heartRate +=
        (hrTarget - heartRate) / 25 + (random.nextDouble() - 0.5) * 0.8;

    final cadence =
        (78 -
                (slope - 8) * 1.6 +
                (power - 300) / 18 +
                (random.nextDouble() - 0.5) * 3)
            .clamp(58.0, 95.0);

    ticks.add(
      RideTick(
        second: second,
        alongMeters: along,
        power: power.roundToDouble(),
        heartRate: heartRate.roundToDouble(),
        cadence: cadence.roundToDouble(),
        speed: speed,
      ),
    );
    along += speed;
  }

  return RideRecording(
    name: 'Belisario → Patios (simulado)',
    athlete: _athlete(),
    profile: profile,
    ticks: ticks,
    reference: ReferenceEffort([
      (meters: 0, seconds: 0),
      (meters: 1000, seconds: 214),
      (meters: 5920, seconds: 1200),
    ]),
    terrainSource: TerrainSource.ownActivity,
  );
}

/// La misma subida como se vería sin potenciómetro: se le quita la
/// potencia y queda la velocidad, que es de lo que el motor la estima.
///
/// Sirve para mostrar en la tesis que el coach no depende de un solo
/// sensor: mismo camino, mismos datos de GPS y pulso, sin el aparato
/// más caro.
RideRecording withoutPowerMeter(RideRecording ride) => RideRecording(
  name: '${ride.name} · sin potenciómetro',
  athlete: ride.athlete,
  profile: ride.profile,
  reference: ride.reference,
  terrainSource: ride.terrainSource,
  goal: ride.goal,
  ticks: [
    for (final tick in ride.ticks)
      RideTick(
        second: tick.second,
        alongMeters: tick.alongMeters,
        heartRate: tick.heartRate,
        cadence: tick.cadence,
        speed: tick.speed,
        slopePercent: tick.slopePercent,
      ),
  ],
);

/// Plan de potencia de la subida: sale fuerte, se asienta y se apaga
/// antes del remate. Es el caso donde el coach tiene algo que decir.
double _plannedPower(int second) {
  if (second < 120) return 334;
  if (second < 420) return 318;
  if (second < 700) return 302;
  if (second < 1000) return 288;
  if (second < 1200) return 279;
  return 292;
}

/// Velocidad de equilibrio para una potencia en la rueda, por bisección.
double _speedAt(
  double wheelPower,
  double slopePercent,
  double mass,
  double gravity,
  double crr,
  double cda,
  double rho,
) {
  final theta = math.atan(slopePercent / 100);
  final resistance = mass * gravity * (math.sin(theta) + crr * math.cos(theta));
  double demand(double v) => v * (resistance + 0.5 * rho * cda * v * v);

  var lo = 0.1, hi = 25.0;
  for (var i = 0; i < 60; i++) {
    final mid = (lo + hi) / 2;
    if (demand(mid) < wheelPower) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// El ciclista de los documentos: CP 285 W y W′ 20 kJ, con la
/// incertidumbre del ajuste de cuatro puntos, sobre una bicicleta de
/// ruta con 34×32 (el desarrollo más suave avanza 2,27 m por pedalada).
/// El desarrollo importa: es lo que impide que el coach pida en una
/// rampa una cadencia que la bicicleta no da.
CoachAthlete _athlete() {
  final fitted = CriticalPowerModel.fitPoints(const {
    180: 390,
    300: 349,
    720: 318,
    1200: 300,
  })!;
  return CoachAthlete(
    power: CriticalPowerModel.manual(
      cp: const Watts(285),
      wPrime: const Joules(20000),
      seCp: fitted.seCp,
      seWPrime: fitted.seWPrime,
      covariance: fitted.covariance,
    ),
    restingHeartRate: const Bpm(55),
    maxHeartRate: const Bpm(190),
    preferredCadence: const Rpm(90),
    resistance: RidingResistance(
      massKg: 72,
      rollingResistance: 0.004,
      airDensity: airDensityAtAltitude(2700),
      lowestGearMeters: 34 / 32 * 2.136,
      highestGearMeters: 50 / 11 * 2.136,
    ),
  );
}

/// Perfil sintético de Belisario → Patios (5.920 m, 499 m de desnivel)
/// con una rampa al 9,4 % a 1.400 m: el mismo de los documentos de la
/// tesis y de las pruebas doradas.
SegmentProfile patiosProfile() {
  const gradients = [7.0, 8.6, 8.0, 8.2, 8.0, 8.4, 8.6, 8.8, 8.2, 8.0, 8.8];
  const total = 5920.0;
  double gradientAt(double d) =>
      d >= 5500 ? 100 * 46 / 420 : gradients[(d ~/ 500).clamp(0, 10)];
  double altitudeAt(double d) {
    var h = 0.0;
    for (var start = 0.0; start < d; start += 500) {
      final end = start + 500 < d ? start + 500 : d;
      h += (end - start) * gradientAt(start) / 100;
    }
    return h;
  }

  return SegmentProfile([
    for (var d = 0.0; d <= total; d += 100)
      SegmentProfilePoint(
        distanceFromStartMeters: d,
        latitude: 4.7 + d / 100000,
        longitude: -74.0,
        altitude: altitudeAt(d),
        slopePercent: d == 1400 ? 9.4 : gradientAt(d),
      ),
  ]);
}
