import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/profile_stats.dart';
import '../profile_providers.dart';

/// Selector de periodo tipo pill-tabs -- semana / mes / año / total.
/// Cambia `statsPeriodProvider`, que filtra las estadísticas mostradas
/// en `ProfileStatsScreen`.
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  static const _labels = {
    StatsPeriod.week: 'Semana',
    StatsPeriod.month: 'Mes',
    StatsPeriod.year: 'Año',
    StatsPeriod.all: 'Total',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(statsPeriodProvider);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: StatsPeriod.values.map((period) {
          final isSelected = period == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(statsPeriodProvider.notifier).state = period,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[period]!,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondaryOnPanel,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
