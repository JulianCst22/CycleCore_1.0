import 'cyclist_kit.dart';
import 'kit_catalog.dart';
import 'level_info.dart';
import 'profile_stats.dart';
import 'rank_tier.dart';

/// Todo lo que hace falta saber del usuario para decidir qué piezas del
/// vestidor tiene desbloqueadas. Se arma desde el nivel + las
/// estadísticas totales + cuántas postales lleva descubiertas.
class KitUnlockContext {
  final int level;
  final CyclistRank rank;
  final double totalKm;
  final double totalElevationM;
  final int postalesCount;
  final double bestRideSpeedKmh;
  final double longestRideKm;

  const KitUnlockContext({
    required this.level,
    required this.rank,
    required this.totalKm,
    required this.totalElevationM,
    required this.postalesCount,
    required this.bestRideSpeedKmh,
    required this.longestRideKm,
  });

  factory KitUnlockContext.from({
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
}

bool isKitConditionMet(KitUnlockCondition c, KitUnlockContext ctx) {
  switch (c.kind) {
    case KitUnlockKind.always:
      return true;
    case KitUnlockKind.rankReached:
      return ctx.level >= c.value;
    case KitUnlockKind.rankCompleted:
      // "Coronado" = tu rango actual está por encima del pedido.
      return RankTier.indexOfRank(ctx.rank) > RankTier.indexOfRank(c.rank!);
    case KitUnlockKind.totalKm:
      return ctx.totalKm >= c.value;
    case KitUnlockKind.totalElevation:
      return ctx.totalElevationM >= c.value;
    case KitUnlockKind.postales:
      return ctx.postalesCount >= c.value;
    case KitUnlockKind.rideSpeedKmh:
      return ctx.bestRideSpeedKmh >= c.value;
    case KitUnlockKind.longestRideKm:
      return ctx.longestRideKm >= c.value;
  }
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
