import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/navigation/soft_fade_route.dart';
import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import '../features/auth/presentation/account_setup_wizard.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/elevation/presentation/elevation_settings_screen.dart';
import '../features/navigation/presentation/navigation_settings_screen.dart';
import '../features/navigation/presentation/saved_places_screen.dart';
import '../features/profile/presentation/profile_edit_screen.dart';
import '../features/profile/presentation/training_zones_screen.dart';
import '../features/segments/presentation/segment_data_settings_screen.dart';
import '../features/sensors/presentation/sensors_screen.dart';
import '../features/voice/presentation/voice_selection_screen.dart';

/// Pantalla de Ajustes -- el "panel de control" del usuario, separado de
/// `ProfileScreen` (que es pura "vitrina": nivel, racha, fotos).
///
/// Cinco secciones, cada una con un tema claro:
///  - **Cuenta**: sesión / vincular / cerrar sesión.
///  - **Perfil**: editar tus datos y tus zonas de entrenamiento.
///  - **Navegación**: rutas, lugares guardados y mapas de altimetría.
///  - **En la salida**: lo que ves y oyes mientras ruedas (voz, datos
///    del segmento).
///  - **Sensores**: conectar sensores BLE.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void push(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      backgroundColor: CcColors.bg,
      appBar: AppBar(title: const Text('Ajustes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            const _Section('CUENTA'),
            const _AccountSection(),

            const _Section('PERFIL'),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.badge_outlined,
                  label: 'Editar perfil',
                  subtitle: 'Nombre, foto, ciudad y tus medidas',
                  onTap: () => push(const ProfileEditScreen()),
                ),
                _SettingsTile(
                  icon: Icons.donut_large_outlined,
                  label: 'Zonas de entrenamiento',
                  subtitle: 'Potencia y frecuencia cardíaca',
                  onTap: () => push(const TrainingZonesScreen()),
                ),
              ],
            ),

            const _Section('NAVEGACIÓN'),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.alt_route,
                  label: 'Navegación',
                  subtitle: 'Rutas y direcciones por voz, sin conexión',
                  onTap: () => push(const NavigationSettingsScreen()),
                ),
                _SettingsTile(
                  icon: Icons.star_outline,
                  label: 'Ubicaciones',
                  subtitle: 'Tus lugares guardados para navegar rápido',
                  onTap: () => push(const SavedPlacesScreen()),
                ),
                _SettingsTile(
                  icon: Icons.terrain_outlined,
                  label: 'Elevación',
                  subtitle: 'Mapas de altimetría descargados (.hgt)',
                  onTap: () => push(const ElevationSettingsScreen()),
                ),
              ],
            ),

            const _Section('EN LA SALIDA'),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.record_voice_over_outlined,
                  label: 'Voz de guía',
                  subtitle: 'Activarla y elegir la voz',
                  onTap: () => push(const VoiceSelectionScreen()),
                ),
                _SettingsTile(
                  icon: Icons.dashboard_customize_outlined,
                  label: 'Datos del segmento',
                  subtitle: 'Qué se ve mientras recorres un segmento',
                  onTap: () => push(const SegmentDataSettingsScreen()),
                ),
              ],
            ),

            const _Section('SENSORES'),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.sensors,
                  label: 'Sensores BLE',
                  subtitle:
                      'Frecuencia cardíaca, potencia, velocidad y cadencia',
                  onTap: () => push(const SensorsScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 26, 4, 9),
      child: Text(
        text,
        style: CcType.label(
          size: 11,
          color: CcColors.inkFaint,
        ).copyWith(letterSpacing: 1.2),
      ),
    );
  }
}

/// Tarjeta que agrupa varias filas con divisores entre ellas.
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CcColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 52,
                color: CcColors.lineSoft,
              ),
            children[i],
          ],
        ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        child: Row(
          children: [
            Icon(icon, color: CcColors.orange, size: 21),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: CcType.displayStyle(size: 14.5)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: CcType.label(size: 11, color: CcColors.inkDim),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: CcColors.inkFaint, size: 20),
          ],
        ),
      ),
    );
  }
}

// --- Cuenta ------------------------------------------------------

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
    backgroundColor: CcColors.surfaceHi,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AuthChoiceSheet(),
  );

  if (choice == null || !context.mounted) return;

  if (choice == 'login') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
                  color: CcColors.inkFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Vincula tu cuenta', style: CcType.displayStyle(size: 18)),
            const SizedBox(height: 6),
            const Text(
              'Tus datos locales no se pierden — solo se respaldan.',
              style: TextStyle(color: CcColors.inkDim, fontSize: 13),
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
      color: CcColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: CcColors.orange, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: CcType.displayStyle(size: 14)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: CcType.label(size: 11, color: CcColors.inkDim),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: CcColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sección "Cuenta". Lee `authProvider` y muestra uno de dos estados --
/// nunca bloquea el resto de Ajustes mientras carga o falla. Con sesión
/// activa añade "Cambiar contraseña".
class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    return authAsync.when(
      loading: () => const _AccountCard(
        child: SizedBox(
          height: 56,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CcColors.orange,
              ),
            ),
          ),
        ),
      ),
      error: (_, _) => _AccountCard(
        child: _NoSessionTile(onTap: () => _showAuthChoiceSheet(context)),
      ),
      data: (session) {
        if (session == null) {
          return _AccountCard(
            child: _NoSessionTile(onTap: () => _showAuthChoiceSheet(context)),
          );
        }
        return _SettingsGroup(
          children: [
            _AccountLinkedTile(
              email: session.email,
              onLogout: () => _handleLogout(context, ref),
            ),
            _SettingsTile(
              icon: Icons.lock_reset_outlined,
              label: 'Cambiar contraseña',
              subtitle: 'Pide tu contraseña actual primero',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Widget child;
  const _AccountCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CcColors.line),
      ),
      child: child,
    );
  }
}

class _NoSessionTile extends StatelessWidget {
  final VoidCallback onTap;

  const _NoSessionTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(14, 15, 12, 15),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: CcColors.orange, size: 21),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'Iniciar sesión — respalda tus datos en la nube',
                style: TextStyle(
                  color: CcColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: CcColors.inkFaint, size: 20),
          ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: CcColors.route, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CcColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onLogout,
            style: TextButton.styleFrom(foregroundColor: CcColors.inkDim),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}
