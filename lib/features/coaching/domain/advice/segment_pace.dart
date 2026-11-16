import 'dart:math' as math;

import '../../../../core/geo/geo.dart';
import '../../../../core/physiology/physiology.dart';
import '../athlete.dart';
import '../coaching_parameters.dart';
import '../variables/labels.dart';

/// Potencia pareja con la que se gastan [budget] julios de la reserva
/// entre [fromMeters] y la cima, y lo que se tardaría.
///
/// El tiempo sale de la física sobre el perfil que queda, no de la
/// referencia: la referencia dice lo que tardó el récord, y a un
/// ciclista que va más lento que su récord le prometía un final más
/// corto del que de verdad le queda (y le pedía gastar de más).
///
/// Con [kick], desde [kickFromMeters] se va ese tanto por uno más
/// fuerte, y la reserva para el remate se aparta desde antes: si se
/// sube parejo y se aprieta solo al final, el apretón sale de una
/// reserva que ya se había gastado.
///
/// La potencia y el tiempo se necesitan el uno al otro, así que se
/// resuelven juntos en unas pocas vueltas. Devuelve la potencia antes
/// del remate.
({double power, double seconds}) pacedPowerOf(
  SegmentProfile profile,
  CoachAthlete athlete, {
  required double budget,
  double fromMeters = 0,
  double? kickFromMeters,
  double kick = 0,
  double stepMeters = 100,
}) {
  final cp = athlete.power.cp.toDouble();
  final total = profile.totalDistanceMeters;
  final split = math.max(fromMeters, math.min(kickFromMeters ?? total, total));

  double secondsBetween(double from, double to, double power) {
    var seconds = 0.0;
    for (var d = from; d < to; d += stepMeters) {
      final length = math.min(stepMeters, to - d);
      final speed = speedForPower(
        Watts(power),
        slopePercent: profile.slopePercentAtDistance(d + length / 2) ?? 0,
        resistance: athlete.resistance,
      );
      seconds += length / math.max(speed, 0.5);
    }
    return seconds;
  }

  var power = cp;
  var seconds = 0.0;
  for (var i = 0; i < 6; i++) {
    final before = secondsBetween(fromMeters, split, power);
    final after = secondsBetween(split, total, power * (1 + kick));
    seconds = before + after;
    if (seconds <= 0) break;
    power = math.max(
      0.5 * cp,
      (budget + cp * seconds) / (before + (1 + kick) * after),
    );
  }
  return (power: power, seconds: seconds);
}

/// Ritmo a tope del segmento entero: la potencia pareja con la que el
/// ciclista lo subiría gastando el tanque del modo «a tope».
///
/// Es la vara con la que se miden los otros modos (duro es el 93 % de
/// esta potencia y fondo el 83 %), así que no puede depender de cómo
/// venga pedaleando hoy: sale de su potencia crítica, su reserva y el
/// perfil.
({double power, double seconds}) allOutPaceOf(
  SegmentProfile profile,
  CoachAthlete athlete,
) => pacedPowerOf(
  profile,
  athlete,
  budget: (1 - Goal.pr.reserveFloor) * athlete.power.wPrime.toDouble(),
);

/// Metro del segmento en el que empieza el tramo final: el último
/// kilómetro, el último 10 % en una subida de más de veinte kilómetros
/// o el último tercio en una de menos de dos.
double finalStretchStart(
  double totalMeters, [
  CoachingParameters parameters = const CoachingParameters(),
]) {
  if (totalMeters > parameters.longClimbMeters) {
    return totalMeters * (1 - parameters.longClimbShare);
  }
  if (totalMeters < parameters.shortClimbMeters) {
    return totalMeters * (1 - parameters.shortClimbShare);
  }
  return totalMeters - parameters.finalMeters;
}
