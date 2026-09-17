import 'package:flutter/material.dart';

import 'cc_colors.dart';
import 'cc_type.dart';

/// Tema visual centralizado de CycleCore.
///
/// La app es **oscura a propósito**: un ciclocomputador se usa al aire
/// libre y el panel oscuro se lee mejor bajo sol directo (y gasta menos
/// batería en pantallas OLED durante salidas largas). El `ThemeData`
/// "claro" que había antes no se usaba -- todo estaba hardcodeado
/// oscuro. Ahora hay un solo tema de verdad, construido desde
/// [CcColors] y [CcType].
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: CcColors.orange,
      onPrimary: Colors.white,
      secondary: CcColors.blue,
      onSecondary: Color(0xFF06222E),
      surface: CcColors.surface,
      onSurface: CcColors.ink,
      surfaceContainerHighest: CcColors.surfaceHi,
      outline: CcColors.line,
      outlineVariant: CcColors.lineSoft,
      error: CcColors.danger,
      onError: Colors.white,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: CcType.body,
      // El fondo de las pantallas es el más profundo (`bg`); las
      // tarjetas, hojas y diálogos van sobre él en `surface`/`surfaceHi`
      // -- así hay una jerarquía de capas real y no todo plano en un
      // solo tono.
      scaffoldBackgroundColor: CcColors.bg,
      canvasColor: CcColors.bg,
      dividerColor: CcColors.line,
      splashColor: CcColors.blue.withValues(alpha: 0.08),
      highlightColor: CcColors.blue.withValues(alpha: 0.06),
    );

    return base.copyWith(
      textTheme: CcType.textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: CcColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: CcColors.ink),
        titleTextStyle: TextStyle(
          fontFamily: CcType.body,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: CcColors.ink,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CcColors.orange,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: CcColors.surfaceHi,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CcColors.surfaceHi,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: CcColors.surfaceHi,
        contentTextStyle: TextStyle(color: CcColors.ink),
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: CcColors.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: CcColors.orange.withValues(alpha: 0.45),
          textStyle: const TextStyle(
            fontFamily: CcType.body,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.04,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      // `ElevatedButton` sin `elevatedButtonTheme` usaba los defaults de
      // Material 3: texto = `colorScheme.primary` (naranja). En pantallas
      // que sólo sobrescriben `backgroundColor` con ese mismo naranja, el
      // texto quedaba naranja sobre naranja -- invisible (ej. "Guardar
      // segmento" al importar un GPX). Se alinea con `filledButtonTheme`.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CcColors.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: CcColors.orange.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
          textStyle: const TextStyle(
            fontFamily: CcType.body,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.04,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CcColors.ink,
          side: const BorderSide(color: CcColors.line, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: CcType.body,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: CcColors.blue),
      ),
    );
  }

  /// Alias de compatibilidad -- la app siempre fue oscura. `main.dart`
  /// y cualquier referencia vieja a `AppTheme.light` siguen funcionando.
  static ThemeData get light => dark;
}
