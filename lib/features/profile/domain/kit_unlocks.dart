import 'package:cyclecore_core/gamification/kit_unlock_context.dart';
import 'package:cyclecore_core/gamification/level_info.dart';

import 'cyclist_kit.dart';
import 'kit_catalog.dart';
import 'profile_stats.dart';

export 'package:cyclecore_core/gamification/kit_unlock_context.dart';

/// Arma el contexto de desbloqueos desde el estado REAL del usuario --
/// nivel + estadísticas totales + cuántas postales lleva descubiertas.
/// (El tipo `KitUnlockContext` en sí vive en cyclecore_core sin este
/// constructor de conveniencia, porque `ProfileStats` es de este
/// feature y core no puede depender de features.)
KitUnlockContext kitUnlockContextFrom({
  required LevelInfo levelInfo,
  required ProfileStats allTimeStats,
  required int postalesCount,
}) {
  return KitUnlockContext(
    level: levelInfo.level,
    rank: levelInfo.rank,
    totalKm: allTimeStats.totalDistanceMeters / 1000,
    totalElevationM: allTimeStats.totalElevationGainMeters,
    postalesCount: postalesCount,
    bestRideSpeedKmh: allTimeStats.fastestRideKmh,
    longestRideKm: allTimeStats.longestRideMeters / 1000,
  );
}

/// Ids de todas las piezas desbloqueadas para este contexto.
Set<String> unlockedKitItemIds(KitUnlockContext ctx) => {
  for (final item in KitCatalog.items)
    if (isKitConditionMet(item.unlock, ctx)) item.id,
};

/// Cuántas piezas de un set ya tienes de las que lo componen.
({int have, int total}) kitSetProgress(KitSet set, Set<String> unlockedIds) {
  final have = set.itemIds.where(unlockedIds.contains).length;
  return (have: have, total: set.itemIds.length);
}

/// La primera pieza de un set que todavía falta -- para el texto
/// "Falta: voz La Escaladora".
KitItem? nextMissingSetPiece(KitSet set, Set<String> unlockedIds) {
  for (final id in set.itemIds) {
    if (!unlockedIds.contains(id)) return KitCatalog.byId[id];
  }
  return null;
}
