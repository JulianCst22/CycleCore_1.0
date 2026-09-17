import 'package:core_database/core_database.dart';

/// Métricas de "toda la actividad" que pueden ser récord personal.
///
/// Nota: esto NO incluye "mejor potencia en X minutos" estilo curva de
/// potencia (Strava) -- eso requiere tiempo por punto GPS y procesar el
/// historial completo con ventanas móviles, que es un cálculo más
/// pesado y queda para un siguiente lote.
enum RecordType { distance, duration, maxSpeed, maxPower, elevationGain }

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
