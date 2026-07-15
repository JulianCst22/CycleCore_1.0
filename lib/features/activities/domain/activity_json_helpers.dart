import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import 'activity_summary.dart';

/// `routePointsJson` y `photoPathsJson` se guardan como texto plano en la
/// base de datos (Drift no tiene un tipo de columna "lista" nativo para
/// SQLite), así que centralizamos aquí la decodificación para no
/// repetirla en cada pantalla.
extension ActivityJsonFields on Activity {
  List<RoutePointSnapshot> get routePoints {
    final decoded = jsonDecode(routePointsJson) as List;
    return decoded
        .map((e) => RoutePointSnapshot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<String> get photoPaths {
    final decoded = jsonDecode(photoPathsJson) as List;
    return decoded.cast<String>();
  }
}

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
          color: AppColors.accentElevation,
        );
    }
  }
}
