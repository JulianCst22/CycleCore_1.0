import 'package:flutter/material.dart';

import 'package:core_database/core_database.dart';
import 'package:core_ui/core_ui.dart';
import '../domain/activity_records.dart';

/// Ícono, etiqueta, color y valor formateado de cada [RecordType] --
/// la parte visual de los récords, separada del cálculo (dominio).
extension RecordTypeUi on RecordType {
  IconData get icon {
    switch (this) {
      case RecordType.distance:
        return Icons.straighten;
      case RecordType.duration:
        return Icons.timer_outlined;
      case RecordType.maxSpeed:
        return Icons.speed;
      case RecordType.maxPower:
        return Icons.electric_bolt;
      case RecordType.elevationGain:
        return Icons.terrain;
    }
  }

  String get label {
    switch (this) {
      case RecordType.distance:
        return 'Distancia';
      case RecordType.duration:
        return 'Duración';
      case RecordType.maxSpeed:
        return 'Vel. máxima';
      case RecordType.maxPower:
        return 'Potencia máx.';
      case RecordType.elevationGain:
        return 'Desnivel';
    }
  }

  /// Mismo color que ya usa cada dato en el resto de la app (ver
  /// `activity_detail_screen.dart`), para que el banner de récord se
  /// sienta parte del mismo sistema visual y no algo aparte.
  Color get accentColor {
    switch (this) {
      case RecordType.distance:
        return AppColors.accentDistance;
      case RecordType.duration:
        return AppColors.accentTime;
      case RecordType.maxSpeed:
        return AppColors.accentSpeed;
      case RecordType.maxPower:
        return AppColors.accentPower;
      case RecordType.elevationGain:
        return AppColors.accentElevation;
    }
  }

  String formattedValue(Activity activity) {
    switch (this) {
      case RecordType.distance:
        return '${formatDistanceKm(activity.distanceMeters)} km';
      case RecordType.duration:
        return formatDuration(Duration(seconds: activity.durationSeconds));
      case RecordType.maxSpeed:
        return '${formatSpeedKmh(activity.maxSpeedKmh)} km/h';
      case RecordType.maxPower:
        return activity.maxPower != null ? '${activity.maxPower} W' : '--';
      case RecordType.elevationGain:
        return '${activity.elevationGainMeters.toStringAsFixed(0)} m';
    }
  }
}
