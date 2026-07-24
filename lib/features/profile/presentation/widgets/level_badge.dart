import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/level_info.dart';
import '../profile_providers.dart';

/// Insignia de nivel y rango -- el corazón visual de la gamificación
/// del perfil. Muestra el nivel actual en un anillo de progreso, el
/// rango temático (Novato, Rodador, Escalador...) y cuánto XP falta
/// para el siguiente nivel.
class LevelBadge extends ConsumerWidget {
  const LevelBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelAsync = ref.watch(levelInfoProvider);

    return levelAsync.when(
      loading: () => const SizedBox(
        height: 90,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) => _LevelCard(info: info),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final LevelInfo info;
  const _LevelCard({required this.info});

  Color get _rankColor => switch (info.rank) {
        CyclistRank.novato => AppColors.textSecondaryOnPanel,
        CyclistRank.rodador => AppColors.accentTime,
        CyclistRank.escalador => AppColors.accentSlope,
        CyclistRank.fondista => AppColors.accentElevation,
        CyclistRank.elite => AppColors.accentPower,
        CyclistRank.leyenda => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final color = _rankColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _LevelRing(level: info.level, progress: info.progress, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      info.rank.label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Nivel ${info.level}',
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: info.progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${info.xpIntoLevel} / ${info.xpForThisLevel} XP · '
                  'faltan ${info.xpRemainingForNextLevel} para el nivel '
                  '${info.level + 1}',
                  style: const TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelRing extends StatelessWidget {
  final int level;
  final double progress;
  final Color color;

  const _LevelRing({
    required this.level,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            '$level',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
