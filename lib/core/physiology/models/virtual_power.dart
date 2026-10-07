import 'dart:math' as math;

import '../uncertainty/covariance.dart';
import '../uncertainty/propagation.dart';
import '../units.dart';

/// Lo que hay que saber de la bicicleta y del aire para estimar la
/// potencia a partir de la velocidad, cada cosa con lo incierta que es.
///
/// Los valores por defecto son los de una bicicleta de ruta con el
/// ciclista sentado, a la altura de Bogotá. Se pueden afinar por
/// usuario, pero lo importante no es acertarles: es que la banda diga
/// honestamente cuánto se está adivinando.
final class RidingResistance {
  /// Masa total (ciclista + bicicleta + lo que lleve), en kilogramos.
  final double massKg;
  final double massUncertaintyKg;

  /// Resistencia a la rodadura.
  final double rollingResistance;
  final double rollingResistanceUncertainty;

  /// Área frontal por coeficiente de arrastre (m²).
  final double dragArea;
  final double dragAreaUncertainty;

  /// Densidad del aire (kg/m³). A 2.600 m es ~0,93.
  final double airDensity;
  final double airDensityUncertainty;

  /// Viento de frente que no se conoce (m/s): su valor medio se supone
  /// cero y su incertidumbre es lo que ensancha la banda en llano.
  final double windUncertainty;

  /// Rendimiento de la transmisión.
  final double drivetrainEfficiency;

  /// Metros que avanza la bicicleta por pedalada en el desarrollo más
  /// suave. Es lo que decide si al ciclista le queda piñón: `null`
  /// cuando no se sabe qué bicicleta lleva.
  final double? lowestGearMeters;

  /// Metros por pedalada en el desarrollo más **duro**. Es lo que
  /// decide si se puede bajar la cadencia: a 110 rpm el consejo es
  /// «baja un piñón», y para eso tiene que quedar piñón que bajar.
  final double? highestGearMeters;

  const RidingResistance({
    this.massKg = 75,
    this.massUncertaintyKg = 2.5,
    this.rollingResistance = 0.005,
    this.rollingResistanceUncertainty = 0.0015,
    this.dragArea = 0.32,
    this.dragAreaUncertainty = 0.05,
    this.airDensity = 0.93,
    this.airDensityUncertainty = 0.06,
    this.windUncertainty = 1.5,
    this.drivetrainEfficiency = 0.975,
    this.lowestGearMeters,
    this.highestGearMeters,
  });

  /// Si en el desarrollo más suave se puede pedalear a [cadence] rpm
  /// yendo a [speedMetersPerSecond].
  ///
  /// Sirve para no decir tonterías: «sube un piñón» en una rampa del
  /// 20 % a 6 km/h no es un consejo, es una burla, porque ya no queda
  /// piñón que suba. Se exige un margen de [margin] rpm para no mandar
  /// a alguien al último piñón justo antes de que se le acabe.
  ///
  /// Sin datos de la bicicleta devuelve `false`: mejor no sugerir un
  /// cambio que sugerir uno imposible.
  bool canReachCadence(
    double cadence,
    double speedMetersPerSecond, {
    double margin = 3,
  }) {
    final development = lowestGearMeters;
    if (development == null || development <= 0) return false;
    return cadenceInGear(speedMetersPerSecond, development) >= cadence + margin;
  }

  /// Si en el desarrollo más duro se puede pedalear **por debajo** de
  /// [cadence] yendo a [speedMetersPerSecond].
  ///
  /// El reverso del anterior: pedirle a alguien que baje la cadencia
  /// cuando ya va en el plato grande y el piñón chico es tan inútil
  /// como mandarlo a un piñón más suave que no existe.
  bool canLowerCadence(
    double cadence,
    double speedMetersPerSecond, {
    double margin = 3,
  }) {
    final development = highestGearMeters;
    if (development == null || development <= 0) return false;
    return cadenceInGear(speedMetersPerSecond, development) <= cadence - margin;
  }

  /// La misma resistencia con el aire de una altitud dada: subir a
  /// 2.600 m quita casi un cuarto del arrastre, y en Colombia eso no es
  /// un detalle.
  RidingResistance atAltitude(double meters, {double temperatureCelsius = 15}) {
    final density = airDensityAtAltitude(
      meters,
      temperatureCelsius: temperatureCelsius,
    );
    return RidingResistance(
      massKg: massKg,
      massUncertaintyKg: massUncertaintyKg,
      rollingResistance: rollingResistance,
      rollingResistanceUncertainty: rollingResistanceUncertainty,
      dragArea: dragArea,
      dragAreaUncertainty: dragAreaUncertainty,
      airDensity: density,
      // Lo que sobra por no saber temperatura ni humedad exactas.
      airDensityUncertainty: density * 0.05,
      windUncertainty: windUncertainty,
      drivetrainEfficiency: drivetrainEfficiency,
      lowestGearMeters: lowestGearMeters,
      highestGearMeters: highestGearMeters,
    );
  }

  RidingResistance withMass(double kilograms) => RidingResistance(
    massKg: kilograms,
    massUncertaintyKg: massUncertaintyKg,
    rollingResistance: rollingResistance,
    rollingResistanceUncertainty: rollingResistanceUncertainty,
    dragArea: dragArea,
    dragAreaUncertainty: dragAreaUncertainty,
    airDensity: airDensity,
    airDensityUncertainty: airDensityUncertainty,
    windUncertainty: windUncertainty,
    drivetrainEfficiency: drivetrainEfficiency,
    lowestGearMeters: lowestGearMeters,
    highestGearMeters: highestGearMeters,
  );
}

/// Cadencia (rpm) que da un desarrollo de [gearMeters] metros por
/// pedalada a [speedMetersPerSecond].
double cadenceInGear(double speedMetersPerSecond, double gearMeters) =>
    gearMeters <= 0 ? 0 : math.max(0, speedMetersPerSecond) * 60 / gearMeters;

const _gravity = 9.80665;

/// Densidad del aire (kg/m³) a una altitud, con la atmósfera estándar.
///
///     p = p0·(1 − 0,0065·h / 288,15)^5,2559        ρ = p / (R·T)
///
/// A nivel del mar da 1,22; en Bogotá (2.600 m) 0,93; en el alto de
/// Patios (3.000 m) 0,90. Es la diferencia entre creerle o no a la
/// potencia estimada en llano.
double airDensityAtAltitude(double meters, {double temperatureCelsius = 15}) {
  const seaLevelPressure = 101325.0;
  const gasConstant = 287.058;
  final altitude = math.max(0.0, meters);
  final pressure =
      seaLevelPressure *
      math.pow(1 - 0.0065 * altitude / 288.15, 5.2559).toDouble();
  return pressure / (gasConstant * (temperatureCelsius + 273.15));
}

/// Potencia estimada a partir de la velocidad y la pendiente, con su
/// banda de incertidumbre.
///
///     P = v · (m·g·(sen θ + Crr·cos θ) + ½·ρ·CdA·(v + w)² + m·a) / η
///
/// Sirve para que el coach no se quede mudo cuando no hay
/// potenciómetro: en una subida la gravedad se lleva casi toda la
/// potencia, así que la velocidad y la pendiente ya dicen bastante. En
/// llano, en cambio, manda el aire —y el viento no se mide—, así que la
/// banda se abre tanto que las reglas que dependen de la potencia dejan
/// de pesar. Eso es exactamente lo que debe pasar: el tipo-2 no
/// esconde lo que no sabe.
///
/// La banda sale de propagar (GUM, primer orden) la incertidumbre de la
/// masa, la rodadura, el área frontal, la densidad del aire y el viento.
UncertainValue virtualPower({
  required double speedMetersPerSecond,
  required double slopePercent,
  RidingResistance resistance = const RidingResistance(),
  double accelerationMetersPerSecond2 = 0,
}) {
  final v = math.max(0.0, speedMetersPerSecond);
  final theta = math.atan(slopePercent / 100);
  final sin = math.sin(theta), cos = math.cos(theta);
  final r = resistance;

  // x = [masa, Crr, CdA, densidad, viento]
  double watts(List<double> x) {
    final gravityTerm = x[0] * _gravity * (sin + x[1] * cos);
    final air = v + x[4];
    final dragTerm = 0.5 * x[2] * x[3] * air * air * (air < 0 ? -1 : 1);
    final inertia = x[0] * accelerationMetersPerSecond2;
    final power = v * (gravityTerm + dragTerm + inertia);
    return math.max(0.0, power) / r.drivetrainEfficiency;
  }

  return propagateLinear(
    watts,
    [r.massKg, r.rollingResistance, r.dragArea, r.airDensity, 0],
    Covariance.diagonal([
      r.massUncertaintyKg,
      r.rollingResistanceUncertainty,
      r.dragAreaUncertainty,
      r.airDensityUncertainty,
      r.windUncertainty,
    ]),
  );
}

/// Cuánto se le puede creer a la potencia estimada, según la pendiente.
///
/// En llano casi todo es aire y viento: la estimación no sirve para
/// decidir nada. Desde el 3 % la gravedad manda y a partir del 6 % la
/// estimación es buena, aunque nunca tanto como un potenciómetro: por
/// eso el tope es 0,8 y no 1.
double virtualPowerCredibility(double slopePercent, {double ceiling = 0.8}) {
  if (slopePercent <= 3) return 0;
  if (slopePercent >= 6) return ceiling;
  return ceiling * (slopePercent - 3) / 3;
}

/// Velocidad de equilibrio para una potencia dada: la operación
/// inversa, por bisección. Sirve para simular y para comprobar que la
/// estimación y su inversa cuadran.
double speedForPower(
  Watts power, {
  required double slopePercent,
  RidingResistance resistance = const RidingResistance(),
}) {
  var lo = 0.0, hi = 30.0;
  for (var i = 0; i < 60; i++) {
    final mid = (lo + hi) / 2;
    final needed = virtualPower(
      speedMetersPerSecond: mid,
      slopePercent: slopePercent,
      resistance: resistance,
    ).value;
    if (needed < power) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}
