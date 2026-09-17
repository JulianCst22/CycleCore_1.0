import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_database/core_database.dart';
import '../domain/calendar_day_info.dart';
import '../domain/featured_photo.dart';
import '../domain/profile_stats.dart';
import '../domain/stats_trend.dart';
import '../domain/streak_calculator.dart';

/// Estado derivado del historial de actividades: periodo elegido,
/// totales, tendencia, rachas, calendario y fotos destacadas. Todo se
/// recalcula desde `allActivitiesProvider`; nada se persiste aparte.

/// Periodo seleccionado en la pantalla de estadísticas (semana/mes/año/
/// total). Vive en un StateProvider porque es solo un filtro de UI, no
/// algo que deba persistirse entre sesiones.
final statsPeriodProvider = StateProvider<StatsPeriod>(
  (ref) => StatsPeriod.month,
);

/// Modo de vista del calendario de actividad: semanal o mensual.
enum CalendarViewMode { week, month }

final calendarViewModeProvider = StateProvider<CalendarViewMode>(
  (ref) => CalendarViewMode.month,
);

/// Mes/semana de referencia que el calendario está mostrando -- permite
/// navegar hacia atrás sin afectar el resto del perfil.
final calendarReferenceDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

/// Estadísticas totales (todo el histórico) -- usadas en el resumen
/// compacto del perfil principal.
final profileStatsProvider = Provider<AsyncValue<ProfileStats>>((ref) {
  final activitiesAsync = ref.watch(allActivitiesProvider);
  return activitiesAsync.whenData(ProfileStats.fromActivities);
});

/// Estadísticas filtradas por el periodo elegido -- usadas en la
/// pantalla de estadísticas completa, estilo Strava.
final profileStatsForPeriodProvider = Provider<AsyncValue<ProfileStats>>((ref) {
  final activitiesAsync = ref.watch(allActivitiesProvider);
  final period = ref.watch(statsPeriodProvider);
  return activitiesAsync.whenData(
    (activities) => ProfileStats.fromActivitiesInPeriod(activities, period),
  );
});

/// Métrica que el gráfico de tendencia de la pantalla de estadísticas
/// está mostrando (distancia / desnivel / tiempo / salidas). Filtro de
/// UI: no se persiste.
final statsTrendMetricProvider = StateProvider<StatsTrendMetric>(
  (ref) => StatsTrendMetric.distance,
);

/// Barras del gráfico de tendencia: reparte las actividades en días,
/// semanas, meses o años según el periodo elegido, para la métrica
/// elegida.
final statsTrendProvider = Provider<AsyncValue<List<StatsTrendBucket>>>((ref) {
  final activitiesAsync = ref.watch(allActivitiesProvider);
  final period = ref.watch(statsPeriodProvider);
  final metric = ref.watch(statsTrendMetricProvider);
  return activitiesAsync.whenData(
    (activities) => computeStatsTrend(
      activities: activities,
      period: period,
      metric: metric,
    ),
  );
});

/// Racha actual y racha más larga, derivadas de las fechas de inicio de
/// cada actividad guardada.
final currentStreakProvider = Provider<AsyncValue<int>>((ref) {
  final activitiesAsync = ref.watch(allActivitiesProvider);
  return activitiesAsync.whenData(
    (activities) => StreakCalculator.currentStreak(
      activities.map((a) => a.startedAt).toList(),
    ),
  );
});

final longestStreakProvider = Provider<AsyncValue<int>>((ref) {
  final activitiesAsync = ref.watch(allActivitiesProvider);
  return activitiesAsync.whenData(
    (activities) => StreakCalculator.longestStreak(
      activities.map((a) => a.startedAt).toList(),
    ),
  );
});

/// Días (fecha sin hora) que forman la racha activa ahora mismo -- el
/// calendario los pinta con el ícono de fuego.
final activeStreakDaysProvider = Provider<AsyncValue<Set<DateTime>>>((ref) {
  final activitiesAsync = ref.watch(allActivitiesProvider);
  return activitiesAsync.whenData(
    (activities) => StreakCalculator.currentStreakDays(
      activities.map((a) => a.startedAt).toList(),
    ),
  );
});

/// Fotos destacadas: por cada tipo de actividad se toma la de mayor
/// distancia (mismo criterio de "récord personal" que ya usas en la
/// lista de actividades) y de ahí se extraen sus fotos. Si el récord de
/// un tipo no tiene fotos, o solo hay una actividad de ese tipo, se
/// ignora (no hay "récord" real que destacar con una sola actividad).
final featuredPhotosProvider = Provider<AsyncValue<List<FeaturedPhoto>>>((ref) {
  final activitiesAsync = ref.watch(allActivitiesProvider);
  return activitiesAsync.whenData((activities) {
    final maxDistanceByType = <String, double>{};
    final recordByType = <String, Activity>{};
    final countByType = <String, int>{};

    for (final a in activities) {
      countByType[a.activityType] = (countByType[a.activityType] ?? 0) + 1;
      final currentMax = maxDistanceByType[a.activityType];
      if (currentMax == null || a.distanceMeters > currentMax) {
        maxDistanceByType[a.activityType] = a.distanceMeters;
        recordByType[a.activityType] = a;
      }
    }

    final featured = <FeaturedPhoto>[];
    for (final entry in recordByType.entries) {
      if ((countByType[entry.key] ?? 0) <= 1) continue;
      final activity = entry.value;
      for (final path in activity.photoPaths) {
        featured.add(
          FeaturedPhoto(
            photoPath: path,
            activityId: activity.id,
            activityTitle: activity.title,
            activityType: activity.activityType,
            startedAt: activity.startedAt,
          ),
        );
      }
    }

    featured.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return featured;
  });
});

/// Días con actividad, agrupados por fecha (sin hora), con el total de
/// actividades de ese día -- usado por vistas que solo necesitan el
/// conteo (no el color ni el detalle).
final activityDaysProvider = Provider<AsyncValue<Map<DateTime, int>>>((ref) {
  final activitiesAsync = ref.watch(allActivitiesProvider);
  return activitiesAsync.whenData((activities) {
    final map = <DateTime, int>{};
    for (final a in activities) {
      final day = DateTime(
        a.startedAt.year,
        a.startedAt.month,
        a.startedAt.day,
      );
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  });
});

/// Actividades agrupadas por día -- consumido por la hoja de detalle
/// que se abre al tocar un día del calendario.
final activitiesByDayProvider =
    Provider<AsyncValue<Map<DateTime, List<Activity>>>>((ref) {
      final activitiesAsync = ref.watch(allActivitiesProvider);
      return activitiesAsync.whenData((activities) {
        final map = <DateTime, List<Activity>>{};
        for (final a in activities) {
          final day = DateTime(
            a.startedAt.year,
            a.startedAt.month,
            a.startedAt.day,
          );
          map.putIfAbsent(day, () => []).add(a);
        }
        return map;
      });
    });

/// Conteo + tipo dominante por día -- lo que consume directamente el
/// calendario para colorear cada celda.
final calendarDayInfoProvider =
    Provider<AsyncValue<Map<DateTime, CalendarDayInfo>>>((ref) {
      final activitiesAsync = ref.watch(allActivitiesProvider);
      return activitiesAsync.whenData(CalendarDayInfo.fromActivities);
    });
