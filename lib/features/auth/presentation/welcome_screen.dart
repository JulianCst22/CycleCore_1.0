import 'package:flutter/material.dart';

import '../../../core/theme/accent_gradients.dart';
import 'account_setup_wizard.dart';
import 'login_screen.dart';

/// Primera pantalla que ve alguien que abre la app sin perfil ni
/// sesión -- el "momento de vender la app" antes de pedir cualquier
/// dato. Foto de fondo + overlay + 3 caminos, igual que apps modernas
/// (Strava, Spotify, etc): "Crear cuenta", "Iniciar sesión",
/// "Continuar como invitado". Ninguno es obligatorio ni bloquea nada
/// -- ver `core/navigation/app_gate.dart` para el porqué.
///
/// [onContinueAsGuest] es flexible a propósito: cuando el gate normal
/// (perfil inexistente) muestra este widget, ese callback activa el
/// modo invitado del `AppGate`. Cuando el `ProfileScreen` reabre esta
/// misma pantalla tras cerrar sesión (perfil YA existente), ese
/// callback simplemente cierra la pantalla y vuelve al perfil que ya
/// estaba ahí -- ver `_handleLogout` en `profile_screen.dart`.
class WelcomeScreen extends StatefulWidget {
  final VoidCallback onContinueAsGuest;

  const WelcomeScreen({super.key, required this.onContinueAsGuest});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // URL de foto de stock (Unsplash Source) como placeholder de fondo.
  // Cámbiala por un asset local en pubspec.yaml cuando tengas la
  // fotografía definitiva de marca. Si no hay internet o falla la
  // carga, el gradiente de marca solo (errorBuilder abajo) se ve
  // bien igual -- nunca deja la pantalla en blanco.
  static const _backgroundImageUrl =
      'https://images.unsplash.com/photo-1517649763962-0c623066013b'
      '?auto=format&fit=crop&w=1400&q=80';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AccentGradients.indigoDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ---- Foto de fondo ----
          Image.network(
            _backgroundImageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(color: AccentGradients.indigoDeep);
            },
            errorBuilder: (context, error, stack) => Container(
              decoration: const BoxDecoration(
                gradient: AccentGradients.backgroundGradient,
              ),
            ),
          ),
          // ---- Overlay de legibilidad ----
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AccentGradients.photoOverlay),
          ),
          // ---- Contenido ----
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 3),
                  _AnimatedEntry(
                    delay: Duration.zero,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AccentGradients.ctaGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.directions_bike_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'CycleCore',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  _AnimatedEntry(
                    delay: const Duration(milliseconds: 120),
                    child: const Text(
                      'Cada subida\ncuenta una historia.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _AnimatedEntry(
                    delay: const Duration(milliseconds: 220),
                    child: Text(
                      'Registra tus rutas, mide tu esfuerzo real y '
                      'funciona sin señal, hasta en el páramo.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  _AnimatedEntry(
                    delay: const Duration(milliseconds: 340),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AccentGradients.ctaGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AccentGradients.ctaGlow(),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AccountSetupWizard(),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Crear cuenta',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AnimatedEntry(
                    delay: const Duration(milliseconds: 420),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AnimatedEntry(
                    delay: const Duration(milliseconds: 500),
                    child: Center(
                      child: TextButton(
                        onPressed: widget.onContinueAsGuest,
                        child: Text(
                          'Continuar como invitado',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fade + slide-up de entrada, sin dependencias externas. Cada
/// elemento aparece con un pequeño delay respecto al anterior para
/// dar sensación de "revelado" en vez de aparecer todo de golpe.
class _AnimatedEntry extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedEntry({required this.child, required this.delay});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _started = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _started ? 1 : 0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
