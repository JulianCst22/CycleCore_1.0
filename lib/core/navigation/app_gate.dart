import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/profile/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_providers.dart';
import '../theme/app_colors.dart';
import 'app_shell.dart';

/// Punto de entrada real de la app -- reemplaza el `home: const
/// AppShell()` directo en `main.dart`.
///
/// El único requisito real para usar la app sigue siendo el perfil
/// local (objetivo #2 del proyecto: funcionar offline desde el primer
/// uso). La cuenta sigue siendo 100% opcional. Lo único que cambia
/// respecto a la versión anterior es QUÉ se muestra a quien nunca ha
/// abierto la app antes de llegar al Onboarding:
///
///   perfil == null Y sesión == null    -> WelcomeScreen (elige camino)
///   perfil == null Y sesión != null    -> Onboarding directo (ya se
///                                          autenticó, solo falta perfil)
///   perfil == null Y "invitado" tocado -> Onboarding directo
///   perfil != null                     -> AppShell (como siempre)
///
/// "Invitado" se maneja con un flag local (`_guestMode`), no con
/// Navigator.push, para que este widget siga siendo la única fuente
/// de verdad reactiva del gate -- igual que antes.
class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  bool _guestMode = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final authAsync = ref.watch(authProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text(
            'No se pudo cargar tu perfil:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ),
      ),
      data: (profile) {
        if (profile != null) {
          return const AppShell();
        }

        final hasSession = authAsync.valueOrNull != null;
        if (_guestMode || hasSession) {
          return const OnboardingScreen(isEditing: false);
        }

        return WelcomeScreen(
          onContinueAsGuest: () => setState(() => _guestMode = true),
        );
      },
    );
  }
}
