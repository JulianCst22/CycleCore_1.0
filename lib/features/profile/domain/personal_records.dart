import '../../../core/database/app_database.dart';

/// Dimensiones en las que una actividad puede ser récord personal
/// dentro de su propio tipo ('race', 'training', ...). Se usa tanto
/// para el bono de XP como para mostrar insignias de récord en el
/// detalle del día en el calendario.
enum RecordDimension { distance, duration, elevation, avgSpeed, avgPower }

extension RecordDimensionLabel on RecordDimension {
  String get label => switch (this) {
        RecordDimension.distance => 'Récord de distancia',
        RecordDimension.duration => 'Récord de duración',
        RecordDimension.elevation => 'Récord de desnivel',
        RecordDimension.avgSpeed => 'Récord de velocidad',
        RecordDimension.avgPower => 'Récord de potencia',
      };
}

/// Calcula, para un conjunto de actividades, cuáles son actualmente
/// récord personal de su tipo en cada dimensión medible. A diferencia
/// de la insignia de la lista de actividades (que solo mira
/// distancia), esto cubre todas las métricas que ya guardamos:
/// distancia, duración, desnivel, velocidad media y potencia media.
///
/// Requiere 2+ actividades del mismo tipo para que "ser el máximo"
/// cuente como récord real -- con una sola actividad no hay nada que
/// haya superado.
class PersonalRecords {
  PersonalRecords._();

  static Map<int, Set<RecordDimension>> computeRecordHolders(
    List<Activity> activities,
  ) {
    final byType = <String, List<Activity>>{};
    for (final a in activities) {
      byType.putIfAbsent(a.activityType, () => []).add(a);
    }

    final result = <int, Set<RecordDimension>>{};

    for (final group in byType.values) {
      if (group.length < 2) continue;

      void markMax(
        num Function(Activity) selector,
        RecordDimension dimension, {
        bool Function(Activity)? eligible,
      }) {
        Activity? best;
        num bestValue = double.negativeInfinity;
        for (final a in group) {
          if (eligible != null && !eligible(a)) continue;
          final value = selector(a);
          if (value > bestValue) {
            bestValue = value;
            best = a;
          }
        }
        if (best != null) {
          result.putIfAbsent(best.id, () => {}).add(dimension);
        }
      }

      markMax((a) => a.distanceMeters, RecordDimension.distance);
      markMax((a) => a.durationSeconds, RecordDimension.duration);
      markMax((a) => a.elevationGainMeters, RecordDimension.elevation);
      markMax((a) => a.avgSpeedKmh, RecordDimension.avgSpeed);
      markMax(
        (a) => a.avgPower ?? 0,
        RecordDimension.avgPower,
        eligible: (a) => a.avgPower != null,
      );
    }

    return result;
  }
}
