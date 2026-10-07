import '../../../core/database/database.dart';

/// Periodo de agregación para la pantalla de estadísticas, estilo
/// Strava: semana / mes / año / histórico completo.
enum StatsPeriod { week, month, year, all }

/// Totales de un tipo de actividad específico ('race', 'training', ...),
/// usados para el desglose por tipo en la pantalla de estadísticas.
class ActivityTypeTotals {
  final String activityType;
  final double distanceMeters;
  final int durationSeconds;
  final double elevationGainMeters;
  final int activityCount;

  const ActivityTypeTotals({
    required this.activityType,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.elevationGainMeters,
    required this.activityCount,
  });
}

/// Estadísticas agregadas de un conjunto de actividades. Es un objeto de
/// dominio puro (sin dependencias de Riverpod ni de UI) para que sea
/// trivial de testear con listas de `Activity` construidas a mano.
class ProfileStats {
  final double totalDistanceMeters;
  final int totalDurationSeconds;
  final double totalElevationGainMeters;
  final int activityCount;
  final int totalPhotoCount;
  final Map<String, ActivityTypeTotals> byType;

  /// Récords del conjunto (para la sección "Récords del periodo"): la
  /// salida más larga, la de más desnivel y la de mayor velocidad media.
  final double longestRideMeters;
  final double mostClimbingMeters;
  final double fastestRideKmh;

  const ProfileStats({
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.totalElevationGainMeters,
    required this.activityCount,
    required this.totalPhotoCount,
    required this.byType,
    this.longestRideMeters = 0,
    this.mostClimbingMeters = 0,
    this.fastestRideKmh = 0,
  });

  /// Velocidad media del conjunto -- distancia total sobre tiempo total,
  /// no el promedio de los promedios (que sesgaría hacia las salidas
  /// cortas).
  double get avgSpeedKmh => totalDurationSeconds == 0
      ? 0
      : (totalDistanceMeters / 1000) / (totalDurationSeconds / 3600);

  static const empty = ProfileStats(
    totalDistanceMeters: 0,
    totalDurationSeconds: 0,
    totalElevationGainMeters: 0,
    activityCount: 0,
    totalPhotoCount: 0,
    byType: {},
  );

  factory ProfileStats.fromActivities(List<Activity> activities) {
    if (activities.isEmpty) return empty;

    double distance = 0;
    int duration = 0;
    double elevation = 0;
    int photos = 0;
    double longestRide = 0;
    double mostClimbing = 0;
    double fastestRide = 0;
    final byType = <String, _MutableTypeTotals>{};

    for (final a in activities) {
      distance += a.distanceMeters;
      duration += a.durationSeconds;
      elevation += a.elevationGainMeters;
      photos += a.photoPaths.length;

      if (a.distanceMeters > longestRide) longestRide = a.distanceMeters;
      if (a.elevationGainMeters > mostClimbing) {
        mostClimbing = a.elevationGainMeters;
      }
      if (a.avgSpeedKmh > fastestRide) fastestRide = a.avgSpeedKmh;

      final bucket = byType.putIfAbsent(
        a.activityType,
        () => _MutableTypeTotals(),
      );
      bucket.distance += a.distanceMeters;
      bucket.duration += a.durationSeconds;
      bucket.elevation += a.elevationGainMeters;
      bucket.count += 1;
    }

    return ProfileStats(
      totalDistanceMeters: distance,
      totalDurationSeconds: duration,
      totalElevationGainMeters: elevation,
      activityCount: activities.length,
      totalPhotoCount: photos,
      longestRideMeters: longestRide,
      mostClimbingMeters: mostClimbing,
      fastestRideKmh: fastestRide,
      byType: byType.map(
        (type, totals) => MapEntry(
          type,
          ActivityTypeTotals(
            activityType: type,
            distanceMeters: totals.distance,
            durationSeconds: totals.duration,
            elevationGainMeters: totals.elevation,
            activityCount: totals.count,
          ),
        ),
      ),
    );
  }

  /// Filtra actividades por periodo antes de agregarlas -- usado por el
  /// selector semana/mes/año/total de `ProfileStatsScreen`.
  /// Totales del periodo [period] desplazado [offset] veces hacia
  /// atrás: 0 es el que corre, −1 el anterior, y así.
  static ProfileStats fromActivitiesInPeriod(
    List<Activity> activities,
    StatsPeriod period, {
    int offset = 0,
    DateTime? now,
  }) {
    final range = statsPeriodRange(period, now ?? DateTime.now(), offset);
    final from = range.from, to = range.to;
    if (from == null || to == null) {
      return ProfileStats.fromActivities(activities);
    }
    final filtered = activities
        .where((a) => !a.startedAt.isBefore(from) && a.startedAt.isBefore(to))
        .toList();
    return ProfileStats.fromActivities(filtered);
  }
}

/// Un instante dentro del periodo [period] desplazado [offset] veces
/// hacia atrás desde [now].
///
/// Para los periodos pasados devuelve el **final** del periodo, no su
/// principio: así nada queda marcado como «lo que falta» en una semana
/// que ya terminó.
DateTime statsReferenceFor(StatsPeriod period, int offset, DateTime now) {
  if (offset >= 0) return now;
  switch (period) {
    case StatsPeriod.week:
      final monday = statsPeriodStart(StatsPeriod.week, now)!;
      return monday.add(Duration(days: 7 * offset + 6, hours: 23, minutes: 59));
    case StatsPeriod.month:
      // El día cero de un mes es el último del anterior.
      return DateTime(now.year, now.month + offset + 1, 0, 23, 59);
    case StatsPeriod.year:
      return DateTime(now.year + offset, 12, 31, 23, 59);
    case StatsPeriod.all:
      return now;
  }
}

/// Los dos extremos del periodo, `[from, to)`. Ambos `null` para el
/// total, que no tiene bordes.
({DateTime? from, DateTime? to}) statsPeriodRange(
  StatsPeriod period,
  DateTime now,
  int offset,
) {
  if (period == StatsPeriod.all) return (from: null, to: null);
  final reference = statsReferenceFor(period, offset, now);
  final from = statsPeriodStart(period, reference)!;
  final to = switch (period) {
    StatsPeriod.week => from.add(const Duration(days: 7)),
    StatsPeriod.month => DateTime(from.year, from.month + 1, 1),
    StatsPeriod.year => DateTime(from.year + 1, 1, 1),
    StatsPeriod.all => from,
  };
  return (from: from, to: to);
}

/// Cómo se llama el periodo que se está viendo: «Esta semana», «Semana
/// pasada», «del 8 al 14 de septiembre», «Septiembre», «2025».
String statsPeriodLabel(StatsPeriod period, int offset, DateTime now) {
  if (period == StatsPeriod.all) return 'Todo';
  if (offset == 0) {
    return switch (period) {
      StatsPeriod.week => 'Esta semana',
      StatsPeriod.month => 'Este mes',
      StatsPeriod.year => 'Este año',
      StatsPeriod.all => 'Todo',
    };
  }
  if (offset == -1) {
    return switch (period) {
      StatsPeriod.week => 'Semana pasada',
      StatsPeriod.month => 'Mes pasado',
      StatsPeriod.year => 'Año pasado',
      StatsPeriod.all => 'Todo',
    };
  }
  final range = statsPeriodRange(period, now, offset);
  final from = range.from!;
  switch (period) {
    case StatsPeriod.week:
      final last = from.add(const Duration(days: 6));
      final sameMonth = last.month == from.month;
      return sameMonth
          ? '${from.day}–${last.day} ${_monthAbbr[from.month - 1]}'
          : '${from.day} ${_monthAbbr[from.month - 1]} – '
                '${last.day} ${_monthAbbr[last.month - 1]}';
    case StatsPeriod.month:
      final name = _monthNames[from.month - 1];
      return from.year == now.year ? name : '$name ${from.year}';
    case StatsPeriod.year:
      return '${from.year}';
    case StatsPeriod.all:
      return 'Todo';
  }
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

const _monthNames = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

/// Primer instante del periodo que contiene a [now] (la semana empieza el
/// lunes); `null` para el total.
DateTime? statsPeriodStart(StatsPeriod period, DateTime now) {
  switch (period) {
    case StatsPeriod.week:
      final today = DateTime(now.year, now.month, now.day);
      return today.subtract(Duration(days: today.weekday - 1));
    case StatsPeriod.month:
      return DateTime(now.year, now.month, 1);
    case StatsPeriod.year:
      return DateTime(now.year, 1, 1);
    case StatsPeriod.all:
      return null;
  }
}

class _MutableTypeTotals {
  double distance = 0;
  int duration = 0;
  double elevation = 0;
  int count = 0;
}
