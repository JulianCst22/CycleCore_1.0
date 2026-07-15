import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import 'activities_providers.dart';
import 'activity_detail_screen.dart';
import '../domain/activity_json_helpers.dart';
import 'widgets/route_thumbnail.dart';

class ActivitiesListScreen extends ConsumerWidget {
  const ActivitiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesListProvider);

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        elevation: 0,
        title: const Text(
          'Tus actividades',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
      ),
      body: activitiesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'No se pudieron cargar tus actividades:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ),
        data: (activities) {
          if (activities.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return _ActivityCard(activity: activities[index]);
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.route_outlined,
              size: 56,
              color: AppColors.textSecondaryOnPanel.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes actividades guardadas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Graba tu primer recorrido desde el mapa y aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondaryOnPanel,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  final Activity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeUi = ActivityTypeUi.fromValue(activity.activityType);
    final dateLabel =
        DateFormat("d 'de' MMMM, HH:mm", 'es').format(activity.startedAt);

    return Dismissible(
      key: ValueKey(activity.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.recordButtonActive.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        ref.read(activitiesRepositoryProvider).deleteActivity(activity.id);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ActivityDetailScreen(activityId: activity.id),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: RouteThumbnail(
                    points: activity.routePoints,
                    lineColor: typeUi.color,
                    backgroundColor: typeUi.color.withValues(alpha: 0.10),
                  ),
                ),
                const SizedBox(width: 14),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(typeUi.icon, size: 12, color: typeUi.color),
                          const SizedBox(width: 4),
                          Text(
                            '${typeUi.label} · $dateLabel',
                            style: const TextStyle(
                              color: AppColors.textSecondaryOnPanel,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _MiniStat(
                            icon: Icons.straighten,
                            value: formatDistanceKm(activity.distanceMeters),
                            unit: 'km',
                          ),
                          const SizedBox(width: 14),
                          _MiniStat(
                            icon: Icons.timer_outlined,
                            value: formatDuration(
                              Duration(seconds: activity.durationSeconds),
                            ),
                            unit: '',
                          ),
                          const SizedBox(width: 14),
                          _MiniStat(
                            icon: Icons.terrain,
                            value: activity.elevationGainMeters
                                .toStringAsFixed(0),
                            unit: 'm',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panelBackground,
        title: const Text(
          '¿Eliminar actividad?',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.textSecondaryOnPanel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.recordButtonActive),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;

  const _MiniStat({required this.icon, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondaryOnPanel),
        const SizedBox(width: 3),
        Text(
          unit.isEmpty ? value : '$value $unit',
          style: const TextStyle(
            color: AppColors.textPrimaryOnPanel,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
