import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../domain/profile_stats.dart';
import '../profile_stats_screen.dart';

/// Resumen compacto de estadísticas totales, tocable para ir a la
/// pantalla completa de estadísticas (estilo Strava). Vive aparte de
/// `StatTile` (el widget de datos en vivo del mapa) porque este es de
/// solo lectura histórica, no un dato que cambie en tiempo real.
class StatSummaryRow extends StatelessWidget {
  final ProfileStats stats;

  const StatSummaryRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileStatsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                value: stats.activityCount.toString(),
                label: 'Actividades',
                color: AppColors.accentTime,
              ),
            ),
            const _VDivider(),
            Expanded(
              child: _SummaryItem(
                value: formatDistanceKm(stats.totalDistanceMeters),
                label: 'km totales',
                color: AppColors.accentDistance,
              ),
            ),
            const _VDivider(),
            Expanded(
              child: _SummaryItem(
                value: formatDuration(
                  Duration(seconds: stats.totalDurationSeconds),
                ),
                label: 'Tiempo',
                color: AppColors.accentSpeed,
              ),
            ),
            const _VDivider(),
            Expanded(
              child: _SummaryItem(
                value: stats.totalElevationGainMeters.toStringAsFixed(0),
                label: 'm desnivel',
                color: AppColors.accentElevation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.textSecondaryOnPanel.withValues(alpha: 0.15),
    );
  }
}
