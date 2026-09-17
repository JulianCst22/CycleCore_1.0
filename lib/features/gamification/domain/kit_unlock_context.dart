import 'kit_unlock_condition.dart';
import 'level_info.dart';
import 'rank_tier.dart';

/// Todo lo que hace falta saber del usuario para decidir qué tiene
/// desbloqueado (piezas del vestidor, voces de guía...). Se arma desde
/// el nivel + las estadísticas totales + cuántas postales lleva
/// descubiertas -- ver `kitUnlockContextFrom` en el feature `profile`,
/// que es quien de verdad conoce esas estadísticas.
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
