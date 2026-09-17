import 'package:flutter/material.dart';

import 'cc_colors.dart';

/// Paleta histórica del flujo de bienvenida y alta de cuenta.
///
/// **Reapuntada a [CcColors].** La versión anterior era un universo
/// visual aparte (índigo, botones con degradado ember + glow, blobs de
/// color difuminados) que no cuadraba con el resto de la app. Ahora los
/// valores vienen del sistema navy + azul + naranja, y los "degradados"
/// son casi planos y el "glow" es una sombra sutil. Las pantallas de
/// auth ya migraron a usar `CcColors` directamente; esto queda para
/// consumidores viejos (p. ej. el badge de `OnboardingScreen`).
class AccentGradients {
  AccentGradients._();

  static const Color indigoDeep = CcColors.bg;
  static const Color indigoMid = CcColors.surfaceHi;
  static const Color violetGlow = CcColors.blueDeep;
  static const Color emberGlow = CcColors.orange;
  static const Color errorRed = CcColors.danger;

  /// Overlay sobre una imagen de fondo -- oscurece hacia abajo hasta el
  /// fondo de la app.
  static const LinearGradient photoOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x000E1116),
      Color(0x660E1116),
      Color(0xE60E1116),
      Color(0xFF0E1116),
    ],
    stops: [0.0, 0.45, 0.8, 1.0],
  );

  /// Fondo de pantallas de marca -- navy, muy sutil.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [CcColors.bg, CcColors.surface],
  );

  /// "Degradado" del CTA principal -- prácticamente plano (naranja).
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [CcColors.orange, Color(0xFFFF7A45)],
  );

  /// Sombra sutil a juego con [ctaGradient] -- ya no un "glow".
  static List<BoxShadow> ctaGlow({double opacity = 0.22, double blur = 14}) {
    return [
      BoxShadow(
        color: CcColors.orange.withValues(alpha: opacity),
        blurRadius: blur,
        offset: const Offset(0, 8),
      ),
    ];
  }

  /// Resplandor decorativo muy tenue detrás de un avatar/logo.
  static BoxDecoration glow(Color color, {double opacity = 0.16}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 44,
          spreadRadius: 10,
        ),
      ],
    );
  }
}
