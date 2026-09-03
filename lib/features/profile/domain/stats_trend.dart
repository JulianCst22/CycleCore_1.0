import '../../../core/database/app_database.dart';
import 'profile_stats.dart';

/// Qué métrica se está mirando en el gráfico de tendencia de la pantalla
/// de estadísticas. El valor de cada barra sale en la unidad natural de
/// la métrica (km, m, horas, conteo).
enum StatsTrendMetric {
  distance('Distancia', 'km'),
  elevation('Desnivel', 'm'),
  movingTime('Tiempo', 'h'),
  rides('Salidas', '');

  const StatsTrendMetric(this.label, this.unit);

  final String label;
  final String unit;
}

/// Una barra del gráfico de tendencia: su etiqueta de eje ("L", "S2",
/// "ago", "2025"), su valor y si es el periodo en curso (se resalta).
class StatsTrendBucket {
  final String label;
  final double value;
  final bool isCurrent;

  const StatsTrendBucket({
    required this.label,
    required this.value,
    this.isCurrent = false,
  });
}

const _monthAbbr = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

const _weekdayAbbr = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

/// Reparte [activities] en las barras que correspondan a [period]:
///
/// - `week`  -> 7 barras, una por día (lunes a domingo de la semana en curso).
/// - `month` -> una barra por bloque de 7 días del mes en curso (S1..S5/S6).
/// - `year`  -> 12 barras, una por mes del año en curso.
/// - `all`   -> una barra por año, desde el primero con actividad hasta hoy.
///
/// Puro: `now` es inyectable para las pruebas.
List<StatsTrendBucket> computeStatsTrend({
  required List<Activity> activities,
  required StatsPeriod period,
  required StatsTrendMetric metric,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();

  double metricValue(Activity a) {
    switch (metric) {
      case StatsTrendMetric.distance:
        return a.distanceMeters / 1000;
      case StatsTrendMetric.elevation:
        return a.elevationGainMeters;
      case StatsTrendMetric.movingTime:
        return a.durationSeconds / 3600;
      case StatsTrendMetric.rides:
        return 1;
    }
  }

  switch (period) {
    case StatsPeriod.week:
      final monday = DateTime(
        reference.year,
        reference.month,
        reference.day,
      ).subtract(Duration(days: reference.weekday - 1));
      final totals = List<double>.filled(7, 0);
      for (final a in activities) {
        final day = DateTime(
          a.startedAt.year,
          a.startedAt.month,
          a.startedAt.day,
        );
        final offset = day.difference(monday).inDays;
        if (offset >= 0 && offset < 7) totals[offset] += metricValue(a);
      }
      final todayOffset = DateTime(
        reference.year,
        reference.month,
        reference.day,
      ).difference(monday).inDays;
      return [
        for (var i = 0; i < 7; i++)
          StatsTrendBucket(
            label: _weekdayAbbr[i],
            value: totals[i],
            isCurrent: i == todayOffset,
          ),
      ];

    case StatsPeriod.month:
      final daysInMonth = DateTime(reference.year, reference.month + 1, 0).day;
      final bucketCount = ((daysInMonth - 1) ~/ 7) + 1;
      final totals = List<double>.filled(bucketCount, 0);
      for (final a in activities) {
        if (a.startedAt.year != reference.year ||
            a.startedAt.month != reference.month) {
          continue;
        }
        final idx = (a.startedAt.day - 1) ~/ 7;
        totals[idx] += metricValue(a);
      }
      final currentIdx = (reference.day - 1) ~/ 7;
      return [
        for (var i = 0; i < bucketCount; i++)
          StatsTrendBucket(
            label: 'S${i + 1}',
            value: totals[i],
            isCurrent: i == currentIdx,
          ),
      ];

    case StatsPeriod.year:
      final totals = List<double>.filled(12, 0);
      for (final a in activities) {
        if (a.startedAt.year != reference.year) continue;
        totals[a.startedAt.month - 1] += metricValue(a);
      }
      return [
        for (var i = 0; i < 12; i++)
          StatsTrendBucket(
            label: _monthAbbr[i],
            value: totals[i],
            isCurrent: i == reference.month - 1,
          ),
      ];

    case StatsPeriod.all:
      var firstYear = reference.year;
      for (final a in activities) {
        if (a.startedAt.year < firstYear) firstYear = a.startedAt.year;
      }
      final years = reference.year - firstYear + 1;
      final totals = List<double>.filled(years, 0);
      for (final a in activities) {
        final idx = a.startedAt.year - firstYear;
        if (idx >= 0 && idx < years) totals[idx] += metricValue(a);
      }
      return [
        for (var i = 0; i < years; i++)
          StatsTrendBucket(
            label: '${firstYear + i}',
            value: totals[i],
            isCurrent: firstYear + i == reference.year,
          ),
      ];
  }
}
