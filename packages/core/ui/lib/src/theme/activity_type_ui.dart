import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Etiqueta, ícono y color de cada tipo de actividad ('race' /
/// 'training') -- los dos tipos son parte de la identidad visual de la
/// app (ver `CcColors.carrera` / `CcColors.entreno`).
class ActivityTypeUi {
  final String label;
  final IconData icon;
  final Color color;

  const ActivityTypeUi({
    required this.label,
    required this.icon,
    required this.color,
  });

  static ActivityTypeUi fromValue(String activityType) {
    switch (activityType) {
      case 'race':
        return const ActivityTypeUi(
          label: 'Carrera',
          icon: Icons.emoji_events_outlined,
          color: AppColors.primary,
        );
      case 'training':
      default:
        return const ActivityTypeUi(
          label: 'Entrenamiento',
          icon: Icons.fitness_center,
          color: AppColors.accentTraining,
        );
    }
  }
}
