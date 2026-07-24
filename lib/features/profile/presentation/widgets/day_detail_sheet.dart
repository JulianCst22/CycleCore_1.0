import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../activities/domain/activity_json_helpers.dart';
import '../../../activities/presentation/activity_detail_screen.dart';
import '../../domain/xp_calculator.dart';
import '../profile_providers.dart';
import '../../domain/personal_records.dart';

/// Hoja inferior con el detalle de las actividades de un día del
/// calendario -- se abre al tocar una celda con actividad. Muestra
/// tipo, distancia/duración, y el XP que aportó cada una, con acceso
/// directo al detalle completo.
Future<void> showDayDetailSheet(BuildContext context, DateTime day) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.panelBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DayDetailSheet(day: day),
  );
}

class DayDetailSheet extends ConsumerWidget {
  final DateTime day;
  const DayDetailSheet({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesByDayAsync = ref.watch(activitiesByDayProvider);
    final xpByActivityAsync = ref.watch(activityXpProvider);

    final activities = activitiesByDayAsync.valueOrNull?[day] ?? const [];
    final xpMap = xpByActivityAsync.valueOrNull ?? const {};

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textSecondaryOnPanel.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '${day.day}/${day.month}/${day.year}',
              style: const TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Sin actividades este día.',
                  style: TextStyle(color: AppColors.textSecondaryOnPanel),
                ),
              )
            else
              ...activities.map(
                (a) => _DayActivityTile(activity: a, xp: xpMap[a.id]),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayActivityTile extends StatelessWidget {
  final Activity activity;
  final ActivityXpBreakdown? xp;

  const _DayActivityTile({required this.activity, required this.xp});

  @override
  Widget build(BuildContext context) {
    final typeUi = ActivityTypeUi.fromValue(activity.activityType);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActivityDetailScreen(activityId: activity.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: typeUi.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: typeUi.color, width: 3)),
        ),
        child: Row(
          children: [
            Icon(typeUi.icon, color: typeUi.color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimaryOnPanel,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatDistanceKm(activity.distanceMeters)} km · '
                    '${formatDuration(Duration(seconds: activity.durationSeconds))}',
                    style: const TextStyle(
                      color: AppColors.textSecondaryOnPanel,
                      fontSize: 11.5,
                    ),
                  ),
                  if (xp != null && xp!.recordDimensions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: xp!.recordDimensions
                          .map(
                            (d) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '🏆 ${d.label}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (xp != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${xp!.totalXp} XP',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
