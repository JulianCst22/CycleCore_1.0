import 'package:cyclecore_app/features/profile/domain/activity_climb_result.dart';
import 'package:cyclecore_app/features/profile/domain/level_info.dart';
import 'package:flutter_test/flutter_test.dart';

int _xpForLevel(int level) => LevelCalculator.cumulativeXpToReach(level);

void main() {
  test('sin subir de nivel: avanza un poco, no cruza arcos', () {
    final l12 = _xpForLevel(12);
    final l13 = _xpForLevel(13);
    final r = computeActivityClimbResult(
      totalXpBefore: l12 + (l13 - l12) ~/ 4,
      totalXpAfter: l12 + (l13 - l12) ~/ 2,
    );
    expect(r.leveledUp, isFalse);
    expect(r.levelsCrossed, isEmpty);
    expect(r.crossedPois, isEmpty);
    expect(r.rankChanged, isFalse);
    expect(r.kmAdvanced, greaterThan(0));
  });

  test('sube un nivel dentro del mismo rango: cruza un arco', () {
    final r = computeActivityClimbResult(
      totalXpBefore: _xpForLevel(12) + 100,
      totalXpAfter: _xpForLevel(13) + 100,
    );
    expect(r.leveledUp, isTrue);
    expect(r.levelsCrossed, [13]);
    expect(r.crossedPois.length, 1);
    expect(r.crossedPois.single.level, 13);
    expect(r.rankChanged, isFalse);
  });

  test('salto grande de XP: cruza varios arcos y cambia de rango', () {
    // Nivel 9 (Rodador) -> nivel 11 (Escalador).
    final r = computeActivityClimbResult(
      totalXpBefore: _xpForLevel(9) + 50,
      totalXpAfter: _xpForLevel(11) + 50,
    );
    expect(r.levelsCrossed, [10, 11]);
    expect(r.crossedPois.map((p) => p.level), [10, 11]);
    expect(r.rankChanged, isTrue);
    expect(r.newRank!.rank, CyclistRank.escalador);
    expect(r.after.altitudeM, greaterThan(r.before.altitudeM));
  });

  test('xpGained y metersClimbed son coherentes', () {
    final r = computeActivityClimbResult(
      totalXpBefore: 5000,
      totalXpAfter: 5248,
    );
    expect(r.xpGained, 248);
    expect(r.metersClimbed, greaterThanOrEqualTo(0));
  });
}
