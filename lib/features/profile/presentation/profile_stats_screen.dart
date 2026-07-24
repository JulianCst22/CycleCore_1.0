import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import 'profile_providers.dart';
import 'widgets/activity_type_breakdown_bar.dart';
import 'widgets/period_selector.dart';

/// Pantalla de estadísticas completas -- equivalente a la sección
/// "Stats" de Strava, pero con la identidad visual "cockpit oscuro" del
/// resto de CycleCore en vez de tarjetas blancas.
class ProfileStatsScreen extends ConsumerWidget {
  const ProfileStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsForPeriodProvider);

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        elevation: 0,
        title: const Text(
          'Estadísticas',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PeriodSelector(),
            const SizedBox(height: 20),
            statsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (error, _) => Center(
                child: Text(
                  'No se pudieron cargar las estadísticas:\n$error',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: AppColors.textSecondaryOnPanel),
                ),
              ),
              data: (stats) => Column(
                children: [
                  _BigStatCard(
                    icon: Icons.straighten,
                    color: AppColors.accentDistance,
                    value: '${formatDistanceKm(stats.totalDistanceMeters)} km',
                    label: 'Distancia total',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _BigStatCard(
                          icon: Icons.timer_outlined,
                          color: AppColors.accentSpeed,
                          value: formatDuration(
                            Duration(seconds: stats.totalDurationSeconds),
                          ),
                          label: 'Tiempo',
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _BigStatCard(
                          icon: Icons.terrain,
                          color: AppColors.accentElevation,
                          value:
                              '${stats.totalElevationGainMeters.toStringAsFixed(0)} m',
                          label: 'Desnivel',
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _BigStatCard(
                          icon: Icons.list_alt,
                          color: AppColors.accentTime,
                          value: stats.activityCount.toString(),
                          label: 'Actividades',
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _BigStatCard(
                          icon: Icons.photo_camera_outlined,
                          color: AppColors.accentCadence,
                          value: stats.totalPhotoCount.toString(),
                          label: 'Fotos subidas',
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Por tipo de actividad',
                          style: TextStyle(
                            color: AppColors.textPrimaryOnPanel,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ActivityTypeBreakdownBar(stats: stats),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool compact;

  const _BigStatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: compact ? 20 : 24),
          SizedBox(height: compact ? 10 : 14),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimaryOnPanel,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 20 : 28,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
