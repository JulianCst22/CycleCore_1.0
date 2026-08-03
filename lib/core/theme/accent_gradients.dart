import 'package:flutter/material.dart';

/// Paleta y gradientes "premium" compartidos por todo el flujo de
/// alta: Welcome, Login, el asistente de creación de cuenta y el
/// badge de bienvenida del Onboarding de invitado.
///
/// Antes vivía solo dentro de `features/auth` (como si fuera exclusivo
/// del login), pero ahora el Onboarding de invitado también lo usa
/// para el badge del encabezado -- así que se promovió a `core/theme`,
/// que es donde debe vivir cualquier cosa compartida entre features.
///
/// A propósito NO reemplaza a `AppColors` ni a `CyclecorePalette`: el
/// resto de la app (cockpit, mapa, actividades) sigue siendo grafito
/// oscuro con datos legibles al sol. Este set de colores es solo para
/// los "momentos de marca" -- bienvenida y alta de cuenta -- donde
/// buscamos más energía visual sin dejar de sentirse CycleCore.
class AccentGradients {
  AccentGradients._();

  static const Color indigoDeep = Color(0xFF0B0B1F);
  static const Color indigoMid = Color(0xFF1A1440);
  static const Color violetGlow = Color(0xFF6C4CE0);
  static const Color emberGlow = Color(0xFFFF6B35); // = AppColors.primary
  static const Color errorRed = Color(0xFFFF5A5A);

  /// Overlay que va sobre la foto de fondo del WelcomeScreen: oscurece
  /// hacia abajo para que el texto y los botones sean legibles sin
  /// tapar del todo la imagen arriba.
  static const LinearGradient photoOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x66000000),
      Color(0xE60B0B1F),
      Color(0xFF0B0B1F),
    ],
    stops: [0.0, 0.45, 0.8, 1.0],
  );

  /// Fondo de Login / asistente de cuenta: mismo universo cromático
  /// que el Welcome, para que la transición entre pantallas se sienta
  /// continua en vez de un salto de estilo.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigoDeep, indigoMid],
  );

  /// Gradiente del botón / badge primario (CTA principal y avatar por
  /// defecto).
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [emberGlow, Color(0xFFFF8A5C)],
  );

  /// Sombra "glow" a juego con [ctaGradient], para botones y badges.
  static List<BoxShadow> ctaGlow({double opacity = 0.45, double blur = 24}) {
    return [
      BoxShadow(
        color: emberGlow.withValues(alpha: opacity),
        blurRadius: blur,
        offset: const Offset(0, 10),
      ),
    ];
  }

  /// Resplandor decorativo (blob difuminado) para dar profundidad
  /// detrás del avatar/logo en Login y el asistente de cuenta.
  static BoxDecoration glow(Color color, {double opacity = 0.35}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 80,
          spreadRadius: 20,
        ),
      ],
    );
  }
}
