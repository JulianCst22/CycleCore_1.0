import '../../../core/database/app_database.dart';
import '../../activities/domain/activity_json_helpers.dart';

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

  const ProfileStats({
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.totalElevationGainMeters,
    required this.activityCount,
    required this.totalPhotoCount,
    required this.byType,
  });

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
    final byType = <String, _MutableTypeTotals>{};

    for (final a in activities) {
      distance += a.distanceMeters;
      duration += a.durationSeconds;
      elevation += a.elevationGainMeters;
      photos += a.photoPaths.length;

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
  static ProfileStats fromActivitiesInPeriod(
    List<Activity> activities,
    StatsPeriod period, {
    DateTime? now,
  }) {
    if (period == StatsPeriod.all) {
      return ProfileStats.fromActivities(activities);
    }

    final reference = now ?? DateTime.now();
    late final DateTime cutoff;
    switch (period) {
      case StatsPeriod.week:
        final today = DateTime(reference.year, reference.month, reference.day);
        cutoff = today.subtract(Duration(days: today.weekday - 1));
      case StatsPeriod.month:
        cutoff = DateTime(reference.year, reference.month, 1);
      case StatsPeriod.year:
        cutoff = DateTime(reference.year, 1, 1);
      case StatsPeriod.all:
        cutoff = DateTime(1970);
    }

    final filtered =
        activities.where((a) => !a.startedAt.isBefore(cutoff)).toList();
    return ProfileStats.fromActivities(filtered);
  }
}

class _MutableTypeTotals {
  double distance = 0;
  int duration = 0;
  double elevation = 0;
  int count = 0;
}
