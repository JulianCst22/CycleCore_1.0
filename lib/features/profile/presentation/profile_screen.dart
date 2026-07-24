import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import 'profile_providers.dart';
import 'widgets/activity_calendar.dart';
import 'widgets/featured_photos_grid.dart';
import 'widgets/level_roadmap.dart';
import 'widgets/profile_header.dart';
import 'widgets/stat_summary_row.dart';
import 'widgets/streak_badge.dart';
import 'widgets/xp_debug_panel.dart';

/// Pantalla principal de Perfil -- estilo Strava/Garmin Connect:
/// encabezado con foto/nombre/ciudad, nivel y rango de gamificación,
/// resumen de estadísticas totales, racha de días activos, calendario
/// de actividad interactivo y fotos destacadas.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(profileStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => Center(
            child: Text(
              'No se pudo cargar tu perfil:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return const _NoProfileState();
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                ProfileHeader(profile: profile),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerRight,
                  child: XpDebugEntryButton(),
                ),
                const SizedBox(height: 8),
                const LevelRoadmap(),
                const SizedBox(height: 18),
                statsAsync.when(
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (stats) => StatSummaryRow(stats: stats),
                ),
                const SizedBox(height: 18),
                const StreakBadge(),
                const SizedBox(height: 18),
                const ActivityCalendar(),
                const SizedBox(height: 24),
                const Text(
                  'Fotos destacadas',
                  style: TextStyle(
                    color: AppColors.textPrimaryOnPanel,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                const FeaturedPhotosGrid(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NoProfileState extends StatelessWidget {
  const _NoProfileState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Completa tu perfil desde el onboarding para ver tus '
          'estadísticas aquí.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondaryOnPanel),
        ),
      ),
    );
  }
}
