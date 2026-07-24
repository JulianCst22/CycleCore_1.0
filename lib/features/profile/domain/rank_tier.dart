import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'level_info.dart';

/// Metadata visual + rango de niveles de un [CyclistRank].
///
/// Esta clase es la fuente única de verdad para todo lo que antes vivía
/// repartido: el switch de color en `level_badge.dart` y el switch de
/// "qué nivel pertenece a qué rango" en `level_info.dart`. Cualquier
/// widget nuevo (roadmap, climb screen, overlays) debe leer de aquí en
/// vez de declarar su propio mapeo de color por rango.
class RankTierInfo {
  final CyclistRank rank;
  final String label;
  final Color color;
  final IconData icon;
  final int minLevel;
  final int maxLevel;

  const RankTierInfo({
    required this.rank,
    required this.label,
    required this.color,
    required this.icon,
    required this.minLevel,
    required this.maxLevel,
  });

  bool containsLevel(int level) => level >= minLevel && level <= maxLevel;
}

/// Catálogo ordenado de los 6 rangos temáticos, de menor a mayor.
///
/// Los colores reutilizan la paleta de acentos que ya usas para
/// métricas (`AppColors.accentTime`, `accentSlope`, etc.) en vez de
/// definir hex nuevos, para que el roadmap se sienta parte de la
/// misma identidad visual del resto de la app.
class RankTier {
  RankTier._();

  static const List<RankTierInfo> all = [
    RankTierInfo(
      rank: CyclistRank.novato,
      label: 'Novato',
      color: AppColors.textSecondaryOnPanel,
      icon: Icons.directions_bike,
      minLevel: 1,
      maxLevel: 4,
    ),
    RankTierInfo(
      rank: CyclistRank.rodador,
      label: 'Rodador',
      color: AppColors.accentTime,
      icon: Icons.pedal_bike,
      minLevel: 5,
      maxLevel: 9,
    ),
    RankTierInfo(
      rank: CyclistRank.escalador,
      label: 'Escalador',
      color: AppColors.accentSlope,
      icon: Icons.terrain,
      minLevel: 10,
      maxLevel: 14,
    ),
    RankTierInfo(
      rank: CyclistRank.fondista,
      label: 'Fondista',
      color: AppColors.accentElevation,
      icon: Icons.landscape,
      minLevel: 15,
      maxLevel: 19,
    ),
    RankTierInfo(
      rank: CyclistRank.elite,
      label: 'Élite',
      color: AppColors.accentPower,
      icon: Icons.bolt,
      minLevel: 20,
      maxLevel: 24,
    ),
    RankTierInfo(
      rank: CyclistRank.leyenda,
      label: 'Leyenda',
      color: AppColors.primary,
      icon: Icons.emoji_events,
      minLevel: 25,
      // Sin techo real: 999 es solo un valor alto para "resto de niveles".
      maxLevel: 999,
    ),
  ];

  static RankTierInfo forRank(CyclistRank rank) =>
      all.firstWhere((tier) => tier.rank == rank);

  /// Deriva el rango correspondiente a un nivel. `level_info.dart` usa
  /// esto en vez de tener su propio switch.
  static RankTierInfo forLevel(int level) => all.firstWhere(
        (tier) => tier.containsLevel(level),
        orElse: () => all.last,
      );

  static CyclistRank rankForLevel(int level) => forLevel(level).rank;

  static int indexOfRank(CyclistRank rank) =>
      all.indexWhere((tier) => tier.rank == rank);
}
