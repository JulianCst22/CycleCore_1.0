import '../../../core/database/app_database.dart';

/// Resumen de la semana en curso, para el banner de la pantalla de
/// actividades (la que apunta a ser el "home").
///
/// Todo se deriva de las actividades ya guardadas -- no se persiste
/// nada aparte, igual que las estadísticas del perfil.
class WeeklySummary {
  final double distanceMeters;
  final double elevationGainMeters;
  final int rideCount;
  final Duration movingTime;

  /// Distancia (en km) de las últimas 6 semanas, de la más antigua
  /// (índice 0) a la semana en curso (índice 5). Alimenta el
  /// mini-gráfico de barras del banner.
  final List<double> last6WeeksKm;

  const WeeklySummary({
    required this.distanceMeters,
    required this.elevationGainMeters,
    required this.rideCount,
    required this.movingTime,
    required this.last6WeeksKm,
  });

  double get distanceKm => distanceMeters / 1000;

  /// Sin nada que mostrar: ni salidas esta semana ni historial en las
  /// 6 semanas de barras.
  bool get isEmpty => rideCount == 0 && last6WeeksKm.every((km) => km == 0);
}

/// Lunes de la semana que contiene [date], anclado al mediodía para que
/// un eventual cambio de horario de verano no desplace el conteo de días
/// (Colombia no usa DST, pero así el helper es correcto en cualquier
/// zona).
DateTime _weekStart(DateTime date) {
  final noon = DateTime(date.year, date.month, date.day, 12);
  return noon.subtract(Duration(days: noon.weekday - 1));
}

/// Agrega las [activities] en un [WeeklySummary]. [now] es inyectable
/// para las pruebas; por defecto, el momento actual.
WeeklySummary computeWeeklySummary(List<Activity> activities, {DateTime? now}) {
  final thisWeekStart = _weekStart(now ?? DateTime.now());

  var distance = 0.0;
  var elevation = 0.0;
  var rides = 0;
  var seconds = 0;

  // 6 cubos de distancia (km): índice 0 = hace 5 semanas, 5 = actual.
  final buckets = List<double>.filled(6, 0);

  for (final activity in activities) {
    final weeksAgo =
        thisWeekStart.difference(_weekStart(activity.startedAt)).inDays ~/ 7;

    if (weeksAgo == 0) {
      distance += activity.distanceMeters;
      elevation += activity.elevationGainMeters;
      rides += 1;
      seconds += activity.durationSeconds;
    }
    if (weeksAgo >= 0 && weeksAgo < 6) {
      buckets[5 - weeksAgo] += activity.distanceMeters / 1000;
    }
  }

  return WeeklySummary(
    distanceMeters: distance,
    elevationGainMeters: elevation,
    rideCount: rides,
    movingTime: Duration(seconds: seconds),
    last6WeeksKm: buckets,
  );
}
