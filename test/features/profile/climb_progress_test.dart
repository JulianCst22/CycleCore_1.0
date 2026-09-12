import 'package:cyclecore_app/features/profile/domain/climb_progress.dart';
import 'package:cyclecore_app/features/profile/domain/climb_route.dart';
import 'package:cyclecore_core/gamification/level_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extremos: nivel 1 en Belisario, nivel 30 en la cima', () {
    final base = climbProgressForLevelValue(1.0);
    expect(base.fractionOfClimb, 0.0);
    expect(base.altitudeM, closeTo(ElevationProfile.startAltitude, 0.5));
    expect(base.distanceKm, closeTo(0, 0.01));
    expect(base.currentLevel, 1);
    expect(base.nextLevel, 2);

    final summit = climbProgressForLevelValue(ClimbRoute.maxLevel.toDouble());
    expect(summit.fractionOfClimb, 1.0);
    expect(summit.altitudeM, closeTo(ElevationProfile.summitAltitude, 0.5));
    expect(summit.isAtSummit, isTrue);
    expect(summit.nextLevel, isNull);
    expect(summit.nextPoi, isNull);
  });

  test('valor fraccionario: el ciclista descansa entre arcos', () {
    final p = climbProgressForLevelValue(12.5);
    expect(p.currentLevel, 12);
    expect(p.nextLevel, 13);
    expect(p.fractionToNextLevel, closeTo(0.5, 0.001));
    expect(p.nextPoi, ClimbRoute.forLevel(13));
    expect(p.currentPoi, ClimbRoute.forLevel(12));
    // altitud entre la del nivel 12 y la del 13
    expect(p.altitudeM, greaterThan(ClimbRoute.forLevel(12).altitudeM - 1));
    expect(p.altitudeM, lessThan(ClimbRoute.forLevel(13).altitudeM + 1));
  });

  test('nextRank sólo cuando el próximo arco es de otro rango', () {
    // Nivel 12 -> 13: ambos Escalador, no hay cambio de rango a la vista.
    expect(climbProgressForLevelValue(12.3).nextRank, isNull);
    // Nivel 4 -> 5: Novato -> Rodador, cambio de rango inminente.
    final p = climbProgressForLevelValue(4.8);
    expect(p.rank.rank, CyclistRank.novato);
    expect(p.nextRank, isNotNull);
    expect(p.nextRank!.rank, CyclistRank.rodador);
  });

  test('climbProgressFor usa nivel + progreso dentro del nivel', () {
    // XP = 0 -> nivel 1, progreso 0.
    final start = climbProgressFor(LevelCalculator.fromTotalXp(0));
    expect(start.levelValue, closeTo(1.0, 0.001));

    // A mitad del nivel 12.
    final l12 = LevelCalculator.cumulativeXpToReach(12);
    final l13 = LevelCalculator.cumulativeXpToReach(13);
    final mid = climbProgressFor(LevelCalculator.fromTotalXp((l12 + l13) ~/ 2));
    expect(mid.currentLevel, 12);
    expect(mid.fractionToNextLevel, closeTo(0.5, 0.02));
  });
}
