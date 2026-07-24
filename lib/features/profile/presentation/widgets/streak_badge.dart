import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../profile_providers.dart';

/// Insignia de racha activa -- refuerza la gamificación que ya existe
/// en la lista de actividades (récords personales) con un segundo
/// mecanismo de motivación: días consecutivos con actividad.
class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentStreakProvider).valueOrNull ?? 0;
    final longest = ref.watch(longestStreakProvider).valueOrNull ?? 0;
    final isActive = current > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)]
              : [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: isActive ? Colors.white : AppColors.textSecondaryOnPanel,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive
                      ? '$current ${current == 1 ? 'día' : 'días'} seguidos'
                      : 'Sin racha activa',
                  style: TextStyle(
                    color:
                        isActive ? Colors.white : AppColors.textPrimaryOnPanel,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Récord: $longest ${longest == 1 ? 'día' : 'días'}',
                  style: TextStyle(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textSecondaryOnPanel,
                    fontSize: 12,
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
