import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/theme/app_colors.dart';
import 'profile_providers.dart';
import 'settings_screen.dart';
import 'widgets/activity_calendar.dart';
import 'widgets/featured_photos_grid.dart';
import 'widgets/level_roadmap.dart';
import 'widgets/profile_header.dart';
import 'widgets/stat_summary_row.dart';
import 'widgets/streak_badge.dart';
import 'widgets/xp_debug_panel.dart';

/// Pantalla principal de Perfil -- ahora es puramente "vitrina": foto,
/// nombre, nivel/rango, estadísticas, racha y fotos destacadas. Todo
/// lo que antes era "control" (cuenta, editar perfil, zonas) se movió
/// a [SettingsScreen], accesible por el ícono de engranaje arriba a
/// la izquierda.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(profileStatsProvider);

    return Scaffold(
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
                // Antes: el ⚙️ estaba en un Stack/Positioned encima
                // del header, pegado justo al borde de la foto. Se
                // veía "desacomodado" porque competía visualmente en
                // la misma franja que el avatar, aunque el header
                // seguía centrado por debajo. Ahora vive en su propia
                // fila, separado del header -- así el header queda
                // limpio y perfectamente centrado, y el ⚙️ y el
                // debug de XP quedan como una barra superior propia
                // (izquierda / derecha).
                Row(
                  children: const [
                    _SettingsButton(),
                    Spacer(),
                    XpDebugEntryButton(),
                  ],
                ),
                const SizedBox(height: 14),
                ProfileHeader(profile: profile),
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

/// Botón de acceso a Ajustes -- mismo lenguaje visual "chip
/// translúcido" de antes, ahora en su propia fila arriba a la
/// izquierda (ya no superpuesto sobre el header).
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: const Icon(
          Icons.settings_outlined,
          size: 16,
          color: AppColors.textSecondaryOnPanel,
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
