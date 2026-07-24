import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../activities/domain/activity_json_helpers.dart';
import '../../domain/profile_stats.dart';

/// Barra de proporción por tipo de actividad (carrera vs entrenamiento,
/// etc.) medida en distancia -- un vistazo rápido de en qué se ha ido
/// el kilometraje, sin necesitar una librería de gráficos externa.
class ActivityTypeBreakdownBar extends StatelessWidget {
  final ProfileStats stats;

  const ActivityTypeBreakdownBar({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = stats.byType.values.toList()
      ..sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));

    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Aún no hay actividades en este periodo',
          style: TextStyle(color: AppColors.textSecondaryOnPanel, fontSize: 12),
        ),
      );
    }

    final total = entries.fold<double>(0, (sum, e) => sum + e.distanceMeters);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(
              children: entries.map((e) {
                final typeUi = ActivityTypeUi.fromValue(e.activityType);
                final flex =
                    total > 0 ? (e.distanceMeters / total * 1000).round() : 1;
                return Expanded(
                  flex: flex.clamp(1, 1000),
                  child: Container(color: typeUi.color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...entries.map((e) {
          final typeUi = ActivityTypeUi.fromValue(e.activityType);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: typeUi.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    typeUi.label,
                    style: const TextStyle(
                      color: AppColors.textPrimaryOnPanel,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '${formatDistanceKm(e.distanceMeters)} km · ${e.activityCount}x',
                  style: const TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
