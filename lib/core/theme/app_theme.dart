import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tema visual centralizado de CycleCore.
///
/// Si más adelante quieres soportar modo oscuro/claro alternable por el
/// usuario, este es el lugar para agregar un segundo ThemeData (`dark`)
/// y exponer un provider de Riverpod que decida cuál usar.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
  }
}
