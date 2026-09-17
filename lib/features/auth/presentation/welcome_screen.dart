import 'package:flutter/material.dart';

import 'package:core_ui/core_ui.dart';
import 'account_setup_wizard.dart';
import 'login_screen.dart';
import 'widgets/dawn_hero.dart';

/// Primera pantalla que ve alguien que abre la app sin perfil ni
/// sesión -- el "momento de vender la app" antes de pedir cualquier
/// dato. Tres caminos: "Crear cuenta", "Iniciar sesión", "Continuar
/// como invitado". Ninguno es obligatorio -- ver
/// `AppGate` (lib/app).
///
/// Rediseño: se abandona la foto de stock enlazada por internet (rompía
/// el offline-first). El fondo es ahora una ilustración de amanecer
/// sobre un puerto de montaña dibujada en código ([DawnHero]) -- con
/// profundidad y luz, pero sin imágenes externas ni licencias. El brillo
/// cálido del horizonte es el mismo naranja de marca. Las animaciones de
/// entrada escalonada se conservan. Si más adelante hay una fotografía
/// de marca real, entra sobre el `DawnHero`, bajo el `DawnHeroVeil`.
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinueAsGuest;

  const WelcomeScreen({super.key, required this.onContinueAsGuest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CcColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DawnHero(),
          // Velo: arriba y en el medio queda despejado para que se
          // aprecie la ilustración; solo oscurece la franja de abajo,
          // donde van los botones.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x220E1116),
                  Color(0x000E1116),
                  Color(0x3D0E1116),
                  Color(0xE60E1116),
                  CcColors.bg,
                ],
                stops: [0.0, 0.34, 0.62, 0.82, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 6, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimatedEntry(
                    delay: Duration.zero,
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: CcColors.surfaceHi.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.directions_bike_rounded,
                            color: CcColors.orange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Text(
                          'CycleCore',
                          style: CcType.displayStyle(
                            size: 19,
                            weight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  _AnimatedEntry(
                    delay: const Duration(milliseconds: 140),
                    child: Text(
                      'Cada subida\ncuenta una historia.',
                      style:
                          CcType.displayStyle(
                            size: 26,
                            weight: FontWeight.w700,
                            height: 1.16,
                            letterSpacing: -0.015,
                          ).copyWith(
                            shadows: const [
                              Shadow(color: Color(0xB3000000), blurRadius: 18),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AnimatedEntry(
                    delay: const Duration(milliseconds: 240),
                    child: Text(
                      'Registra tus rutas, mide tu esfuerzo real y funciona '
                      'sin señal — hasta en el páramo.',
                      style: TextStyle(
                        color: CcColors.ink.withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.45,
                        shadows: const [
                          Shadow(color: Color(0x99000000), blurRadius: 14),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  _AnimatedEntry(
                    delay: const Duration(milliseconds: 360),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AccountSetupWizard(),
                          ),
                        ),
                        child: const Text('Crear cuenta'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AnimatedEntry(
                    delay: const Duration(milliseconds: 440),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        child: const Text('Iniciar sesión'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _AnimatedEntry(
                    delay: const Duration(milliseconds: 520),
                    child: Center(
                      child: TextButton(
                        onPressed: onContinueAsGuest,
                        style: TextButton.styleFrom(
                          foregroundColor: CcColors.inkDim,
                        ),
                        child: const Text.rich(
                          TextSpan(
                            text: 'o ',
                            children: [
                              TextSpan(
                                text: 'entra como invitado',
                                style: TextStyle(
                                  color: CcColors.ink,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: CcColors.inkFaint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
