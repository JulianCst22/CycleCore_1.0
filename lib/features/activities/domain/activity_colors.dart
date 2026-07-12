import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Interpola un color continuo según la pendiente, tipo "mapa de calor":
/// azul en bajadas fuertes, verde en tramos planos, naranja/rojo en
/// subidas fuertes. Se usa tanto para colorear la polilínea de la ruta
/// en el mapa como el área del gráfico de altimetría, para que ambos
/// lenguajes visuales coincidan.
Color slopeToColor(double slopePercent) {
  final clamped = slopePercent.clamp(-15.0, 15.0);
  if (clamped >= 0) {
    final t = clamped / 15.0;
    return Color.lerp(AppColors.accentElevation, AppColors.recordButtonActive, t)!;
  } else {
    final t = -clamped / 15.0;
    return Color.lerp(AppColors.accentElevation, AppColors.accentSpeed, t)!;
  }
}
