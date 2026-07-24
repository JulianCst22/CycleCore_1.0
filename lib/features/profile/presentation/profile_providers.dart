import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../activities/domain/activity_json_helpers.dart';
import '../../activities/presentation/activities_providers.dart';
import '../data/profile_repository.dart';
import '../domain/calendar_day_info.dart';
import '../domain/cyclist_profile.dart';
import '../domain/featured_photo.dart';
import '../domain/level_info.dart';
import '../domain/profile_stats.dart';
import '../domain/streak_calculator.dart';
import '../domain/xp_calculator.dart';
import 'xp_debug_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Estado async del perfil: null significa "no hay perfil guardado todavía"
/// (dispara el onboarding), no un error.
class ProfileNotifier extends AsyncNotifier<CyclistProfile?> {
  @override
  Future<CyclistProfile?> build() async {
    return ref.read(profileRepositoryProvider).loadProfile();
  }

  Future<void> saveProfile(CyclistProfile profile) async {
    await ref.read(profileRepositoryProvider).saveProfile(profile);
    state = AsyncValue.data(profile);
  }

  Future<void> clearProfile() async {
    await ref.read(profileRepositoryProvider).clearProfile();
    state = const AsyncValue.data(null);
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, CyclistProfile?>(
  ProfileNotifier.new,
);

/// Periodo seleccionado en la pantalla de estadísticas (semana/mes/año/
/// total). Vive en un StateProvider porque es solo un filtro de UI, no
/// algo que deba persistirse entre sesiones.
final statsPeriodProvider =
    StateProvider<StatsPeriod>((ref) => StatsPeriod.month);

/// Modo de vista del calendario de actividad: semanal o mensual.
enum CalendarViewMode { week, month }

final calendarViewModeProvider =
    StateProvider<CalendarViewMode>((ref) => CalendarViewMode.month);

/// Mes/semana de referencia que el calendario está mostrando -- permite
/// navegar hacia atrás sin afectar el resto del perfil.
final calendarReferenceDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

/// Estadísticas totales (todo el histórico) -- usadas en el resumen
/// compacto del perfil principal.
final profileStatsProvider = Provider<AsyncValue<ProfileStats>>((ref) {
  final activitiesAsync = ref.watch(activitiesListProvider);
  return activitiesAsync.whenData(ProfileStats.fromActivities);
});

/// Estadísticas filtradas por el periodo elegido -- usadas en la
/// pantalla de estadísticas completa, estilo Strava.
final profileStatsForPeriodProvider =
    Provider<AsyncValue<ProfileStats>>((ref) {
  final activitiesAsync = ref.watch(activitiesListProvider);
  final period = ref.watch(statsPeriodProvider);
  return activitiesAsync.whenData(
    (activities) => ProfileStats.fromActivitiesInPeriod(activities, period),
  );
});

/// Racha actual y racha más larga, derivadas de las fechas de inicio de
/// cada actividad guardada.
final currentStreakProvider = Provider<AsyncValue<int>>((ref) {
  final activitiesAsync = ref.watch(activitiesListProvider);
  return activitiesAsync.whenData(
    (activities) => StreakCalculator.currentStreak(
      activities.map((a) => a.startedAt).toList(),
    ),
  );
});

final longestStreakProvider = Provider<AsyncValue<int>>((ref) {
  final activitiesAsync = ref.watch(activitiesListProvider);
  return activitiesAsync.whenData(
    (activities) => StreakCalculator.longestStreak(
      activities.map((a) => a.startedAt).toList(),
    ),
  );
});

/// Días (fecha sin hora) que forman la racha activa ahora mismo -- el
/// calendario los pinta con el ícono de fuego.
final activeStreakDaysProvider = Provider<AsyncValue<Set<DateTime>>>((ref) {
  final activitiesAsync = ref.watch(activitiesListProvider);
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
final featuredPhotosProvider =
    Provider<AsyncValue<List<FeaturedPhoto>>>((ref) {
  final activitiesAsync = ref.watch(activitiesListProvider);
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
  final activitiesAsync = ref.watch(activitiesListProvider);
  return activitiesAsync.whenData((activities) {
    final map = <DateTime, int>{};
    for (final a in activities) {
      final day =
          DateTime(a.startedAt.year, a.startedAt.month, a.startedAt.day);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  });
});

/// Actividades agrupadas por día -- consumido por la hoja de detalle
/// que se abre al tocar un día del calendario.
final activitiesByDayProvider =
    Provider<AsyncValue<Map<DateTime, List<Activity>>>>((ref) {
  final activitiesAsync = ref.watch(activitiesListProvider);
  return activitiesAsync.whenData((activities) {
    final map = <DateTime, List<Activity>>{};
    for (final a in activities) {
      final day =
          DateTime(a.startedAt.year, a.startedAt.month, a.startedAt.day);
      map.putIfAbsent(day, () => []).add(a);
    }
    return map;
  });
});

/// Conteo + tipo dominante por día -- lo que consume directamente el
/// calendario para colorear cada celda.
final calendarDayInfoProvider =
    Provider<AsyncValue<Map<DateTime, CalendarDayInfo>>>((ref) {
  final activitiesAsync = ref.watch(activitiesListProvider);
  return activitiesAsync.whenData(CalendarDayInfo.fromActivities);
});

/// XP de cada actividad, indexado por su id -- para mostrar "+XX XP" en
/// el detalle del día y en cualquier otro lugar que lo necesite.
final activityXpProvider =
    Provider<AsyncValue<Map<int, ActivityXpBreakdown>>>((ref) {
  final activitiesAsync = ref.watch(activitiesListProvider);
  return activitiesAsync.whenData((activities) {
    final breakdowns = XpCalculator.computeForActivities(activities);
    return {for (final b in breakdowns) b.activityId: b};
  });
});

/// XP total acumulado del usuario -- suma del XP de todas sus
/// actividades. Nunca se persiste aparte: se recalcula siempre desde
/// las actividades guardadas.
final totalXpProvider = Provider<AsyncValue<int>>((ref) {
  final activitiesAsync = ref.watch(activitiesListProvider);
  return activitiesAsync.whenData(XpCalculator.totalXpFor);
});

/// XP "efectivo": el real, salvo que haya un override de testing activo
/// (ver `xp_debug_provider.dart`), en cuyo caso todo lo visual de nivel
/// usa ese valor en su lugar. `totalXpProvider` sigue siendo el XP real
/// sin tocar, por si en algún lugar necesitas mostrar el dato genuino.
final effectiveTotalXpProvider = Provider<AsyncValue<int>>((ref) {
  final debugOverride = ref.watch(xpDebugOverrideProvider);
  if (debugOverride != null) {
    return AsyncValue.data(debugOverride);
  }
  return ref.watch(totalXpProvider);
});

/// Nivel, rango y progreso actual, derivados del XP efectivo (real u
/// override de testing).
final levelInfoProvider = Provider<AsyncValue<LevelInfo>>((ref) {
  final totalXpAsync = ref.watch(effectiveTotalXpProvider);
  return totalXpAsync.whenData(LevelCalculator.fromTotalXp);
});

/// Recuerda el último nivel que la UI ya "reconoció", para detectar
/// subidas de nivel (nivel anterior vs nuevo) y disparar la animación
/// de celebración una sola vez por subida.
///
/// Vive solo en memoria: se resetea al reiniciar la app. Es una
/// simplificación intencional -- si más adelante quieres que sobreviva
/// a un reinicio, es cuestión de persistir `state` con
/// shared_preferences igual que hace `ProfileRepository`.
class LevelAcknowledgementNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  /// Compara [currentLevel] contra el último nivel reconocido y
  /// actualiza el estado. Devuelve `true` solo si es una subida real
  /// (no la primera vez que se consulta, para no disparar la animación
  /// apenas se abre la app).
  bool consumeLevelUp(int currentLevel) {
    final previous = state;
    state = currentLevel;
    if (previous == null) return false;
    return currentLevel > previous;
  }
}

final levelAcknowledgementProvider =
    NotifierProvider<LevelAcknowledgementNotifier, int?>(
  LevelAcknowledgementNotifier.new,
);
