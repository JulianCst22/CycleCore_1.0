import '../../../core/database/app_database.dart';

/// Resumen de un día para el calendario de actividad: cuántas
/// actividades hubo y cuál tipo fue el "dominante" (el de mayor
/// distancia acumulada ese día), usado para teñir la celda del
/// calendario con el color de `ActivityTypeUi` correspondiente.
class CalendarDayInfo {
  final int activityCount;
  final String? dominantActivityType;

  const CalendarDayInfo({
    required this.activityCount,
    required this.dominantActivityType,
  });

  static Map<DateTime, CalendarDayInfo> fromActivities(
    List<Activity> activities,
  ) {
    final grouped = <DateTime, List<Activity>>{};
    for (final a in activities) {
      final day =
          DateTime(a.startedAt.year, a.startedAt.month, a.startedAt.day);
      grouped.putIfAbsent(day, () => []).add(a);
    }

    return grouped.map((day, dayActivities) {
      final distanceByType = <String, double>{};
      for (final a in dayActivities) {
        distanceByType[a.activityType] =
            (distanceByType[a.activityType] ?? 0) + a.distanceMeters;
      }
      final dominant = distanceByType.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      return MapEntry(
        day,
        CalendarDayInfo(
          activityCount: dayActivities.length,
          dominantActivityType: dominant,
        ),
      );
    });
  }
}
