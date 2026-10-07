import 'package:flutter/material.dart';

import 'cc_colors.dart';

/// Tipografía de CycleCore.
///
/// Una sola familia: **Rubik** ([family]) -- un sans humanista con las
/// esquinas sutilmente redondeadas. Es amigable y cálida sin sentirse
/// infantil, de proporción ancha (lo contrario de una condensada) y muy
/// legible a cualquier tamaño. Va empaquetada local (`pubspec.yaml`) y
/// es variable: `fontWeight` interpola el eje de peso.
///
/// La jerarquía se hace con **tamaño y peso**, no con familias ni con
/// color: los números van siempre en [CcColors.ink]; el color de la
/// métrica vive en el ícono o el borde, nunca en la cifra.
class CcType {
  CcType._();

  static const family = 'Rubik';

  /// Alias histórico -- antes había dos familias (body/display). Ahora
  /// las dos son Rubik; lo que cambia es el peso.
  static const body = family;
  static const display = family;

  /// Estilo para una cifra o titular grande -- Rubik en peso alto,
  /// tabular y con el tracking un poco cerrado.
  static TextStyle displayStyle({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color color = CcColors.ink,
    double height = 1.05,
    double letterSpacing = -0.02,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Etiqueta en versalitas -- encabezados de sección y labels de dato
  /// ("DISTANCIA", "TIEMPO").
  static TextStyle label({
    double size = 11,
    Color color = CcColors.inkFaint,
    FontWeight weight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.1,
    );
  }

  /// Aplica Rubik sobre un `TextTheme` de Material. Los estilos de
  /// display/headline van con tracking cerrado; los títulos, en semibold.
  static TextTheme textTheme(TextTheme base) {
    TextStyle t(TextStyle? s) => (s ?? const TextStyle()).copyWith(
      fontFamily: family,
      color: CcColors.ink,
    );
    TextStyle tight(TextStyle? s) => t(s).copyWith(letterSpacing: -0.02);

    return base.copyWith(
      displayLarge: tight(base.displayLarge),
      displayMedium: tight(base.displayMedium),
      displaySmall: tight(base.displaySmall),
      headlineLarge: tight(base.headlineLarge),
      headlineMedium: tight(base.headlineMedium),
      headlineSmall: t(base.headlineSmall),
      titleLarge: t(base.titleLarge).copyWith(fontWeight: FontWeight.w600),
      titleMedium: t(base.titleMedium).copyWith(fontWeight: FontWeight.w600),
      titleSmall: t(base.titleSmall).copyWith(fontWeight: FontWeight.w600),
      bodyLarge: t(base.bodyLarge),
      bodyMedium: t(base.bodyMedium),
      bodySmall: t(base.bodySmall).copyWith(color: CcColors.inkDim),
      labelLarge: t(base.labelLarge).copyWith(fontWeight: FontWeight.w600),
      labelMedium: t(base.labelMedium).copyWith(color: CcColors.inkDim),
      labelSmall: t(base.labelSmall).copyWith(color: CcColors.inkFaint),
    );
  }
}
