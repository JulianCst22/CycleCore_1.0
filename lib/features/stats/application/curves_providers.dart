import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/physiology/physiology.dart';
import '../data/activity_curves_repository.dart';
import '../domain/climbing_cadence.dart';
import '../domain/profile_stats.dart';
import '../domain/ride_curves.dart';
import 'stats_providers.dart';

final activityCurvesRepositoryProvider = Provider<ActivityCurvesRepository>((
  ref,
) {
  return ActivityCurvesRepository(ref.watch(appDatabaseProvider));
});

/// Mantiene las curvas al día: cada vez que cambia la lista de
/// actividades, calcula las que falten. Lo vigila todo lo que muestra
/// curvas, así que basta con abrir una pantalla que las use.
final curvesSyncProvider = FutureProvider<int>((ref) async {
  final activities = ref.watch(allActivitiesProvider);
  if (!activities.hasValue) return 0;
  return ref.watch(activityCurvesRepositoryProvider).syncCurves();
});

/// Arranca (y mantiene viva) la sincronización sin reconstruir a quien la
/// llama cada vez que termina una pasada: las curvas nuevas llegan solas
/// por el stream de la base de datos.
void _keepCurvesInSync(Ref ref) {
  ref.listen(curvesSyncProvider, (_, _) {});
}

/// Qué curva histórica: su señal y desde cuándo (todo el historial si
/// `since` es `null`). Los dos extremos deben caer en un día exacto
/// para que la clave no cambie a cada rato.
typedef BestCurveQuery = ({CurveKind kind, DateTime? since, DateTime? until});

/// Curva histórica: la mejor media de cada duración, con la actividad de
/// la que salió (ver `originOf`).
final bestCurveProvider = StreamProvider.family<MeanMaxCurve, BestCurveQuery>((
  ref,
  query,
) {
  _keepCurvesInSync(ref);
  return ref
      .watch(activityCurvesRepositoryProvider)
      .watchBestCurve(query.kind, since: query.since, until: query.until);
});

/// SOLO PARA PRUEBAS: llena las curvas de Rendimiento con valores de
/// ejemplo (el candado de esa pantalla), igual que el «desbloquear
/// todo» de la gamificación. No se guarda nada ni toca al coach: solo
/// cambia lo que se dibuja. Quitar antes de entregar.
final curvesSampleProvider = StateProvider<bool>((ref) => false);

/// Curvas de un ciclista aficionado fuerte (CP ~285 W, FC máx ~190).
MeanMaxCurve _sampleCurve(CurveKind kind) {
  const power = {
    5: 960,
    10: 870,
    15: 790,
    30: 610,
    60: 470,
    120: 405,
    180: 372,
    300: 338,
    600: 312,
    720: 306,
    1200: 294,
    1800: 281,
    3600: 262,
  };
  const heartRate = {
    5: 186,
    10: 186,
    15: 185,
    30: 184,
    60: 183,
    120: 181,
    180: 180,
    300: 178,
    600: 175,
    720: 174,
    1200: 171,
    1800: 168,
    3600: 163,
  };
  final values = kind == CurveKind.power ? power : heartRate;
  return MeanMaxCurve.fromPoints({
    for (final e in values.entries)
      e.key: (value: e.value.toDouble(), startSecond: 0, source: null),
  });
}

/// Curva histórica del periodo elegido en la pantalla de rendimiento.
final periodBestCurveProvider =
    Provider.family<AsyncValue<MeanMaxCurve>, CurveKind>((ref, kind) {
      if (ref.watch(curvesSampleProvider)) {
        return AsyncValue.data(_sampleCurve(kind));
      }
      final period = ref.watch(curvesPeriodProvider);
      final offset = ref.watch(curvesPeriodOffsetProvider);
      final range = statsPeriodRange(period, DateTime.now(), offset);
      return ref.watch(
        bestCurveProvider((kind: kind, since: range.from, until: range.to)),
      );
    });

/// Cadencia de subida que el ciclista ha mostrado en los últimos 90
/// días, o `null` mientras no haya salidas suficientes.
///
/// Es la mediana de las medianas de cada salida: aguanta que una mañana
/// haya sido rara sin dejar de moverse cuando la costumbre cambia de
/// verdad.
final learnedClimbingCadenceProvider = Provider<double?>((ref) {
  _keepCurvesInSync(ref);
  final since = DateTime.now().subtract(const Duration(days: 90));
  final cadences = ref
      .watch(climbingCadencesProvider(since))
      .valueOrNull;
  return cadences == null ? null : learnedClimbingCadence(cadences);
});

final climbingCadencesProvider =
    StreamProvider.family<List<double>, DateTime?>((ref, since) {
      _keepCurvesInSync(ref);
      return ref
          .watch(activityCurvesRepositoryProvider)
          .watchClimbingCadences(since: since);
    });

/// Curvas de una actividad guardada.
final activityCurvesProvider =
    StreamProvider.family<Map<CurveKind, MeanMaxCurve>, int>((ref, activityId) {
      _keepCurvesInSync(ref);
      return ref
          .watch(activityCurvesRepositoryProvider)
          .watchActivityCurves(activityId);
    });
