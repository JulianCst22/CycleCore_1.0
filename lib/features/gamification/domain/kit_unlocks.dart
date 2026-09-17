import 'kit_unlock_context.dart';
import 'level_info.dart';

import 'cyclist_kit.dart';
import 'kit_catalog.dart';
import '../../stats/stats.dart';

export 'kit_unlock_context.dart';

/// Arma el contexto de desbloqueos desde el estado REAL del usuario --
/// nivel + estadísticas totales + cuántas postales lleva descubiertas.
/// (El tipo `KitUnlockContext` en sí vive en kit_unlock_context.dart sin
/// este constructor de conveniencia: así no depende de `ProfileStats`,
/// que es de la feature stats.)
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
