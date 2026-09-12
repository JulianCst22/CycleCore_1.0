import 'package:cyclecore_app/features/profile/domain/cyclist_kit.dart';
import 'package:cyclecore_app/features/profile/domain/kit_catalog.dart';
import 'package:cyclecore_app/features/profile/domain/kit_unlocks.dart';
import 'package:cyclecore_core/gamification/level_info.dart';
import 'package:flutter_test/flutter_test.dart';

KitUnlockContext _ctx({
  int level = 12,
  CyclistRank rank = CyclistRank.escalador,
  double totalKm = 800,
  double totalElevationM = 3000,
  int postalesCount = 8,
  double bestRideSpeedKmh = 22,
  double longestRideKm = 45,
}) {
  return KitUnlockContext(
    level: level,
    rank: rank,
    totalKm: totalKm,
    totalElevationM: totalElevationM,
    postalesCount: postalesCount,
    bestRideSpeedKmh: bestRideSpeedKmh,
    longestRideKm: longestRideKm,
  );
}

void main() {
  test('condiciones básicas', () {
    final ctx = _ctx();
    expect(isKitConditionMet(KitUnlockCondition.always, ctx), isTrue);
    expect(
      isKitConditionMet(
        const KitUnlockCondition(KitUnlockKind.rankReached, value: 10),
        ctx,
      ),
      isTrue,
    );
    expect(
      isKitConditionMet(
        const KitUnlockCondition(KitUnlockKind.rankReached, value: 15),
        ctx,
      ),
      isFalse,
    );
    expect(
      isKitConditionMet(
        const KitUnlockCondition(KitUnlockKind.totalKm, value: 3000),
        ctx,
      ),
      isFalse,
    );
    expect(
      isKitConditionMet(
        const KitUnlockCondition(KitUnlockKind.postales, value: 15),
        ctx,
      ),
      isFalse,
    );
  });

  test('rankCompleted = tu rango actual está por encima del pedido', () {
    final ctx = _ctx(rank: CyclistRank.escalador);
    expect(
      isKitConditionMet(
        const KitUnlockCondition(
          KitUnlockKind.rankCompleted,
          rank: CyclistRank.rodador,
        ),
        ctx,
      ),
      isTrue,
    );
    // Todavía no coronó Escalador (está en él).
    expect(
      isKitConditionMet(
        const KitUnlockCondition(
          KitUnlockKind.rankCompleted,
          rank: CyclistRank.escalador,
        ),
        ctx,
      ),
      isFalse,
    );
  });

  test('unlockedKitItemIds: novato principiante -> sólo lo de fábrica', () {
    final ids = unlockedKitItemIds(
      _ctx(
        level: 2,
        rank: CyclistRank.novato,
        totalKm: 30,
        totalElevationM: 200,
        postalesCount: 1,
        bestRideSpeedKmh: 16,
        longestRideKm: 12,
      ),
    );
    expect(ids, contains('maillot_r0'));
    expect(ids, contains('bici_r0'));
    expect(ids, contains('gesto_beber'));
    expect(ids, contains('gesto_danzar'));
    expect(ids, isNot(contains('maillot_r2'))); // aún no es Escalador
    expect(ids, isNot(contains('maillot_lunares')));
    expect(ids, isNot(contains('gesto_wheelie')));
  });

  test('unlockedKitItemIds: escalador con logros', () {
    final ids = unlockedKitItemIds(
      _ctx(
        level: 12,
        rank: CyclistRank.escalador,
        totalKm: 3200,
        totalElevationM: 6000,
        postalesCount: 16,
        bestRideSpeedKmh: 35,
        longestRideKm: 62,
      ),
    );
    expect(ids, contains('maillot_r2')); // Escalador alcanzado
    expect(ids, contains('bici_perfil')); // 3000 km
    expect(ids, contains('gesto_wheelie')); // 15 postales
    expect(ids, contains('gesto_bandera')); // coronó Rodador
    expect(ids, contains('maillot_aero')); // salida a 34 km/h
    expect(ids, isNot(contains('maillot_r3'))); // aún no es Fondista
    expect(ids, isNot(contains('maillot_lunares'))); // no coronó Escalador
    expect(ids, isNot(contains('maillot_lana'))); // ninguna salida de 100 km
  });

  test('progreso de set y siguiente pieza que falta', () {
    final ids = <String>{'gesto_danzar', 'bici_ligera'};
    final escarabajo = KitCatalog.setById('set_escarabajo')!;
    final progress = kitSetProgress(escarabajo, ids);
    expect(progress.have, 2);
    expect(progress.total, 3);
    expect(nextMissingSetPiece(escarabajo, ids)!.id, 'maillot_lunares');
  });

  test('el kit por defecto sólo usa piezas de fábrica', () {
    final base = unlockedKitItemIds(
      _ctx(
        level: 1,
        rank: CyclistRank.novato,
        totalKm: 0,
        totalElevationM: 0,
        postalesCount: 0,
        bestRideSpeedKmh: 0,
        longestRideKm: 0,
      ),
    );
    expect(base, contains(KitCatalog.defaultKit.maillotId));
    expect(base, contains(KitCatalog.defaultKit.biciId));
    for (final g in KitCatalog.defaultKit.gestoIds) {
      expect(base, contains(g));
    }
  });
}
