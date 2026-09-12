import 'climb_progress.dart';
import 'climb_route.dart';
import 'package:cyclecore_core/gamification/level_info.dart';
import 'package:cyclecore_core/gamification/rank_tier.dart';

/// Qué le pasó al ciclista de la subida cuando el usuario guardó una
/// actividad: cuánta XP ganó, cuánto avanzó sobre el Alto de Patios, qué
/// arcos (niveles / postales) cruzó y si cambió de rango.
///
/// Es lo que alimenta la pantalla de la subida en modo "post-actividad"
/// (aparece SIEMPRE al guardar): anima al ciclista de [before] a
/// [after], festeja cada arco de [crossedPois], y si [newRank] no es
/// nulo encadena el festejo de cambio de rango + el desbloqueo.
class ActivityClimbResult {
  final int xpGained;
  final ClimbProgress before;
  final ClimbProgress after;

  /// Niveles enteros cruzados (arcos por los que pasó el ciclista).
  final List<int> levelsCrossed;

  /// Los puntos de interés de esos niveles -- las postales que se
  /// revelan en el trayecto.
  final List<ClimbPointOfInterest> crossedPois;

  /// El nuevo rango, si el ciclista cambió de rango en esta actividad.
  final RankTierInfo? newRank;

  const ActivityClimbResult({
    required this.xpGained,
    required this.before,
    required this.after,
    required this.levelsCrossed,
    required this.crossedPois,
    required this.newRank,
  });

  bool get leveledUp => levelsCrossed.isNotEmpty;
  bool get rankChanged => newRank != null;

  /// Kilómetros avanzados sobre la subida real.
  double get kmAdvanced =>
      (after.distanceKm - before.distanceKm).clamp(0, double.infinity);

  /// Metros de desnivel ganados sobre la subida real.
  double get metersClimbed =>
      (after.altitudeM - before.altitudeM).clamp(0, double.infinity);
}

/// Calcula el resultado comparando el XP total antes y después de
/// guardar la actividad. Puro: la XP nunca se persiste, siempre se
/// recalcula desde las actividades (ver [LevelCalculator]).
ActivityClimbResult computeActivityClimbResult({
  required int totalXpBefore,
  required int totalXpAfter,
}) {
  final infoBefore = LevelCalculator.fromTotalXp(totalXpBefore);
  final infoAfter = LevelCalculator.fromTotalXp(totalXpAfter);

  final levelsCrossed = <int>[
    for (var level = infoBefore.level + 1; level <= infoAfter.level; level++)
      if (level <= ClimbRoute.maxLevel) level,
  ];

  return ActivityClimbResult(
    xpGained: totalXpAfter - totalXpBefore,
    before: climbProgressFor(infoBefore),
    after: climbProgressFor(infoAfter),
    levelsCrossed: levelsCrossed,
    crossedPois: [
      for (final level in levelsCrossed) ClimbRoute.forLevel(level),
    ],
    newRank: infoAfter.rank != infoBefore.rank
        ? RankTier.forRank(infoAfter.rank)
        : null,
  );
}
