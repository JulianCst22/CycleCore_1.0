import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';

/// Métricas de "toda la actividad" que pueden ser récord personal.
///
/// Nota: esto NO incluye "mejor potencia en X minutos" estilo curva de
/// potencia (Strava) -- eso requiere tiempo por punto GPS y procesar el
/// historial completo con ventanas móviles, que es un cálculo más
/// pesado y queda para un siguiente lote.
enum RecordType { distance, duration, maxSpeed, maxPower, elevationGain }

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

class ActivityRecordsResult {
  final Set<RecordType> records;
  const ActivityRecordsResult(this.records);
  bool get isEmpty => records.isEmpty;
}

/// Determina si [target] es la mejor marca (empates incluidos) para
/// [selector] dentro de [sameTypeActivities]. `null` en el valor de una
/// actividad no la descalifica a ella, pero tampoco cuenta como "gana".
bool _isBestAmong(
  List<Activity> sameTypeActivities,
  Activity target,
  double? Function(Activity) selector,
) {
  final targetValue = selector(target);
  if (targetValue == null) return false;
  for (final a in sameTypeActivities) {
    final v = selector(a);
    if (v != null && v > targetValue) return false;
  }
  return true;
}

/// Calcula qué métricas de [activity] son récord personal, comparando
/// contra el resto de actividades del mismo `activityType`. Solo cuenta
/// como récord si hay 2+ actividades de ese tipo -- si es la primera de
/// un tipo nuevo, no ha "superado" nada todavía.
ActivityRecordsResult computeActivityRecords({
  required Activity activity,
  required List<Activity> allActivities,
}) {
  final sameType = allActivities
      .where((a) => a.activityType == activity.activityType)
      .toList();
  if (sameType.length < 2) return const ActivityRecordsResult({});

  final records = <RecordType>{};
  if (_isBestAmong(sameType, activity, (a) => a.distanceMeters)) {
    records.add(RecordType.distance);
  }
  if (_isBestAmong(
    sameType,
    activity,
    (a) => a.durationSeconds.toDouble(),
  )) {
    records.add(RecordType.duration);
  }
  if (_isBestAmong(sameType, activity, (a) => a.maxSpeedKmh)) {
    records.add(RecordType.maxSpeed);
  }
  if (_isBestAmong(sameType, activity, (a) => a.maxPower?.toDouble())) {
    records.add(RecordType.maxPower);
  }
  if (_isBestAmong(sameType, activity, (a) => a.elevationGainMeters)) {
    records.add(RecordType.elevationGain);
  }

  return ActivityRecordsResult(records);
}
