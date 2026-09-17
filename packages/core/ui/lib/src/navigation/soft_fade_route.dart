import 'package:flutter/material.dart';

/// Transición fade + slide-up sutil, usada para momentos que deben
/// sentirse como un "cambio de escena" intencional en vez de la
/// navegación estándar de "empujar una pantalla más" -- por ejemplo,
/// volver al [WelcomeScreen] después de cerrar sesión.
class SoftFadeRoute<T> extends PageRouteBuilder<T> {
  SoftFadeRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: Transform.translate(
                offset: Offset(0, (1 - curved.value) * 24),
                child: child,
              ),
            );
          },
        );
}
