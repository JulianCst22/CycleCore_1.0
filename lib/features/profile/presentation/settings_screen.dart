import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/soft_fade_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/account_setup_wizard.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/welcome_screen.dart';
import '../../elevation/presentation/elevation_settings_screen.dart';
import '../../navigation/presentation/navigation_settings_screen.dart';
import '../../segments/presentation/segment_data_settings_screen.dart';
import '../../sensors/presentation/sensors_screen.dart';
import '../../voice/presentation/voice_selection_screen.dart';
import 'profile_edit_screen.dart';
import 'training_zones_screen.dart';

/// Pantalla de Ajustes -- todo lo que antes vivía suelto dentro de
/// `ProfileScreen` (sección Cuenta) más lo nuevo (editar perfil y
/// zonas, antes sin un lugar propio) vive acá.
///
/// `ProfileScreen` queda como "vitrina" (mirar tus logros: nivel,
/// racha, fotos). Esta pantalla es "control" (tocar cosas: tu cuenta,
/// tus datos, tus zonas) -- la misma separación que ya tienen apps
/// como Strava o Garmin Connect, y la razón por la que el correo +
/// botón "Salir" se sentían fuera de lugar antes.
///
/// Sección "MAPA": Elevación y Navegación se administran acá en vez
/// de aparecer como diálogos sorpresa en medio de una grabación -- el
/// usuario prepara sus descargas offline con calma, desde un solo
/// lugar.
///
/// Sección "SENSORES" (nueva): conectar sensores BLE
/// (FC/potencia/velocidad-cadencia) dejó de ser una pestaña de la
/// barra de navegación inferior (ese lugar ahora lo ocupa
/// "Segmentos") y pasó a vivir acá, como una acción de configuración
/// puntual en vez de una sección que se visita todo el tiempo.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        elevation: 0,
        title: const Text(
          'Ajustes',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _SectionLabel('CUENTA'),
            const SizedBox(height: 8),
            const _AccountSection(),
            const SizedBox(height: 28),
            const _SectionLabel('PERFIL'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.person_outline,
              label: 'Editar perfil',
              subtitle: 'Nombre, foto, ciudad y biografía',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.speed_outlined,
              label: 'Zonas de entrenamiento',
              subtitle: 'Potencia y frecuencia cardíaca',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TrainingZonesScreen()),
              ),
            ),
            const SizedBox(height: 28),
            const _SectionLabel('MAPA'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.terrain_outlined,
              label: 'Elevación',
              subtitle: 'Mapas de altimetría descargados (.hgt)',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ElevationSettingsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.alt_route,
              label: 'Navegación',
              subtitle: 'Rutas y direcciones por voz, sin conexión',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NavigationSettingsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const _SectionLabel('SEGMENTOS'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.dashboard_customize_outlined,
              label: 'Datos del segmento',
              subtitle: 'Qué se ve mientras recorrés un segmento',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SegmentDataSettingsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const _SectionLabel('VOZ'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.record_voice_over_outlined,
              label: 'Voz de guía',
              subtitle: 'Activarla y elegir la personalidad',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VoiceSelectionScreen(),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const _SectionLabel('SENSORES'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.sensors,
              label: 'Sensores BLE',
              subtitle: 'Frecuencia cardíaca, potencia, velocidad-cadencia',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SensorsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondaryOnPanel,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnPanel,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondaryOnPanel),
            ],
          ),
        ),
      ),
    );
  }
}

// --- De aquí para abajo: exactamente lo que ya tenías (cierre de
// sesión, hoja de vinculación, tiles de cuenta) -- no se tocó nada de
// esta parte. ---

Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
  await ref.read(authProvider.notifier).logout();
  if (!context.mounted) return;

  Navigator.of(context).pushAndRemoveUntil(
    SoftFadeRoute(
      builder: (routeContext) => WelcomeScreen(
        onContinueAsGuest: () {
          if (routeContext.mounted) Navigator.of(routeContext).pop();
        },
      ),
    ),
    (route) => route.isFirst,
  );
}

Future<void> _showAuthChoiceSheet(BuildContext context) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.panelBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AuthChoiceSheet(),
  );

  if (choice == null || !context.mounted) return;

  if (choice == 'login') {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  } else if (choice == 'register') {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AccountSetupWizard(linkOnly: true),
      ),
    );
  }
}

class _AuthChoiceSheet extends StatelessWidget {
  const _AuthChoiceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondaryOnPanel.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Vincula tu cuenta',
              style: TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tus datos locales no se pierden -- solo se respaldan.',
              style: TextStyle(
                color: AppColors.textSecondaryOnPanel,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            _SheetOption(
              icon: Icons.login_rounded,
              label: 'Iniciar sesión',
              subtitle: 'Ya tengo una cuenta CycleCore',
              onTap: () => Navigator.of(context).pop('login'),
            ),
            const SizedBox(height: 10),
            _SheetOption(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Crear cuenta',
              subtitle: 'Respaldar este perfil con una cuenta nueva',
              onTap: () => Navigator.of(context).pop('register'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnPanel,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondaryOnPanel),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sección "Cuenta". Lee `authProvider` y muestra uno de dos estados
/// -- nunca bloquea el resto de Ajustes mientras carga o falla.
class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    return authAsync.when(
      loading: () => const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      error: (_, __) =>
          _NoSessionTile(onTap: () => _showAuthChoiceSheet(context)),
      data: (session) {
        if (session != null) {
          return _AccountLinkedTile(
            email: session.email,
            onLogout: () => _handleLogout(context, ref),
          );
        }
        return _NoSessionTile(onTap: () => _showAuthChoiceSheet(context));
      },
    );
  }
}

class _NoSessionTile extends StatelessWidget {
  final VoidCallback onTap;

  const _NoSessionTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.login_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Iniciar sesión — respalda tus datos en la nube',
                  style: TextStyle(
                    color: AppColors.textPrimaryOnPanel,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondaryOnPanel),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountLinkedTile extends StatelessWidget {
  final String email;
  final VoidCallback onLogout;

  const _AccountLinkedTile({required this.email, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: AppColors.accentElevation,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onLogout,
            child: const Text('Salir',
                style: TextStyle(color: AppColors.textSecondaryOnPanel)),
          ),
        ],
      ),
    );
  }
}