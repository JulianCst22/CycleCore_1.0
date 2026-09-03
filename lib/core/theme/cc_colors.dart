import 'package:flutter/material.dart';

/// Tokens de color de CycleCore -- **la única fuente de verdad**.
///
/// Antes había tres paletas conviviendo y contradiciéndose (`AppColors`,
/// `CyclecorePalette`, `AccentGradients`). Ahora esas tres siguen
/// existiendo por compatibilidad, pero sus valores se derivan de aquí:
/// cambiar la identidad de toda la app se hace en este archivo.
///
/// Identidad: **navy + azul + naranja**. Fondo carbón azulado, un azul
/// de acento (estructura, foco, enlaces) y el naranja de marca para la
/// acción principal y la navegación activa. Se abandonó el índigo del
/// login y el verde-musgo que los comentarios de `CyclecorePalette`
/// describían pero que nunca se llegó a usar.
class CcColors {
  CcColors._();

  // --- Fondos y superficies ---------------------------------------
  /// Fondo base de la app (lo más profundo).
  static const bg = Color(0xFF0E1116);

  /// Superficie de scaffolds y paneles ("el navy").
  static const surface = Color(0xFF171B24);

  /// Superficie elevada -- tarjetas, hojas, badges.
  static const surfaceHi = Color(0xFF1E2431);

  /// Fondo hundido -- campos de texto, tracks.
  static const surfaceInset = Color(0xFF12161E);

  /// Borde de 1px estándar.
  static const line = Color(0xFF2C3444);

  /// Borde/divisor más tenue.
  static const lineSoft = Color(0xFF222A36);

  // --- Texto -----------------------------------------------------
  /// Texto primario y números -- alto contraste, casi blanco.
  static const ink = Color(0xFFEEF2F8);

  /// Texto secundario, etiquetas, íconos inactivos.
  static const inkDim = Color(0xFF8C96A8);

  /// Texto terciario / muy sutil.
  static const inkFaint = Color(0xFF5B6577);

  // --- Marca ---------------------------------------------------
  /// Naranja de marca -- CTA principal, grabación, navegación activa.
  static const orange = Color(0xFFFF6B35);

  /// Naranja un punto más claro, para texto naranja sobre navy
  /// (el naranja puro no siempre da contraste como texto pequeño).
  static const orangeText = Color(0xFFFF7A45);

  /// Azul de acento -- foco de campo, enlaces, elementos interactivos,
  /// gauges. (= `AppColors.accentSpeed`.)
  static const blue = Color(0xFF4FC3F7);

  /// Azul intenso -- para superficies rellenas de azul con contenido
  /// blanco encima (el azul de acento es demasiado claro para eso).
  static const blueDeep = Color(0xFF1E5F8C);

  /// Azul brillante -- relleno de la barra de avance de velocidad.
  static const blueHi = Color(0xFF16B8F3);

  /// Verde de navegación -- se usa **solo** en la línea de la ruta
  /// sugerida sobre el mapa. Ahí compiten el trazado grabado (naranja) y
  /// el segmento en vivo (turquesa), así que la ruta necesita un tercer
  /// color inconfundible. NO se usa en botones, textos ni fondos: para
  /// eso siguen el naranja/azul del sistema.
  static const route = Color(0xFF3FC46B);

  /// Superficie translúcida para overlays sobre el mapa (píldoras de
  /// estado, banners de giro/segmento) -- navy del sistema al ~82 %, en
  /// vez del negro puro que se usaba antes.
  static const glass = Color(0xD1171B24);

  // --- Semánticos --------------------------------------------------
  /// Grabando / error / acción destructiva.
  static const danger = Color(0xFFE5484D);

  /// Aviso -- pendiente fuerte, altitud aproximada.
  static const warn = Color(0xFFE0A93C);

  /// Confirmación / "por delante del récord" / iniciar.
  static const ok = Color(0xFF3FC46B);

  // --- Tipos de actividad ----------------------------------------
  static const entreno = Color(0xFF00BFFF);
  static const carrera = orange;

  // --- Colores de métrica (series de datos en gráficos y cockpit;
  //     uso categórico legítimo, NO decoración) --------------------
  static const mTime = Color(0xFF64B5F6);
  static const mDist = Color(0xFFFFB74D);
  static const mSpeed = Color(0xFF4FC3F7);
  static const mHeartRate = Color(0xFFEF5350);
  static const mElevation = Color(0xFF81C784);
  static const mSlope = Color(0xFFFFA726);
  static const mPower = Color(0xFFAB47BC);
  static const mCadence = Color(0xFF26A69A);

  // --- Segmentos y mapa ----------------------------------------
  static const segmentStart = Color(0xFF3FC46B);
  static const segmentActiveTrack = Color(0xFF00E0C6);
  static const segmentIdleTrack = Color(0xFF5C6B7A);
  static const ghostAhead = Color(0xFF3FC46B);
  static const ghostBehind = Color(0xFFE0663D);

  // --- Rampa de pendiente (interpola magnitud por color) ---------
  static const slopeFlat = Color(0xFF3E7D5A);
  static const slopeMid = Color(0xFFD9A441);
  static const slopeHard = Color(0xFFE0663D);

  // --- Récord personal ------------------------------------------
  /// Dorado -- resalta la cifra concreta que batió una marca personal
  /// (distancia máxima, más desnivel, etc.). Se usa solo en el número,
  /// no en fondos ni bordes: el resto del dato queda en [ink].
  static const gold = Color(0xFFF2C14E);
}
