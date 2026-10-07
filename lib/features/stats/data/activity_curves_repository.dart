import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:drift/drift.dart' show Value;

import '../../../core/database/database.dart';
import '../../../core/physiology/physiology.dart';
import '../domain/ride_curves.dart';

/// Cálculo de las curvas de una actividad a partir de su trazado.
typedef RideCurvesCalculator =
    Future<RideCurves> Function(String routePointsJson, int movingSeconds);

/// Guarda y consulta las curvas de medias máximas.
///
/// Las curvas se derivan del trazado, así que no las calcula quien guarda
/// una actividad: [syncCurves] busca las actividades que no las tienen (o
/// que las tienen de una versión anterior del cálculo) y las completa.
/// Así se llenan también las de las actividades que ya existían antes de
/// que hubiera curvas.
class ActivityCurvesRepository {
  final AppDatabase database;
  final RideCurvesCalculator _calculate;
  final DateTime Function() _now;
  Future<int> _queue = Future.value(0);

  ActivityCurvesRepository(
    this.database, {
    RideCurvesCalculator? calculate,
    DateTime Function()? now,
  }) : _calculate = calculate ?? _calculateInBackground,
       _now = now ?? DateTime.now;

  static Future<RideCurves> _calculateInBackground(
    String routePointsJson,
    int movingSeconds,
  ) => Isolate.run(
    () => RideCurves.fromRouteJson(routePointsJson, movingSeconds),
  );

  /// Calcula las curvas que falten y devuelve cuántas guardó. Las pasadas
  /// van en fila: si llega una mientras corre otra, espera y vuelve a
  /// buscar (pudo aparecer una actividad nueva).
  Future<int> syncCurves() {
    final run = _queue.then((_) => _syncOnce());
    _queue = run.catchError((Object _) => 0);
    return run;
  }

  Future<int> _syncOnce() async {
    final ids = await database.getActivityIdsNeedingCurves(
      curveAlgorithmVersion,
    );
    var saved = 0;
    for (final id in ids) {
      final activity = await database.getActivityById(id);
      if (activity == null) continue;
      RideCurves curves;
      try {
        curves = await _calculate(
          activity.routePointsJson,
          activity.durationSeconds,
        );
      } on Object catch (error, stack) {
        // Un trazado ilegible no debe frenar a las demás ni reintentarse
        // en cada arranque: queda marcado sin curvas.
        developer.log(
          'No se pudieron calcular las curvas de la actividad $id',
          name: 'stats',
          error: error,
          stackTrace: stack,
        );
        curves = const RideCurves(
          movingSeconds: 0,
          powerSeconds: 0,
          heartRateSeconds: 0,
          power: MeanMaxCurve.empty(),
          heartRate: MeanMaxCurve.empty(),
        );
      }
      if (await _save(id, curves)) saved++;
    }
    return saved;
  }

  Future<bool> _save(int activityId, RideCurves curves) {
    return database.replaceActivityCurves(
      ActivityCurvesCompanion.insert(
        activityId: Value(activityId),
        version: curveAlgorithmVersion,
        movingSeconds: curves.movingSeconds,
        powerSeconds: curves.powerSeconds,
        heartRateSeconds: curves.heartRateSeconds,
        climbingCadence: Value(curves.climbingCadence),
        computedAt: _now(),
      ),
      [
        for (final kind in CurveKind.values)
          for (final e in curves.of(kind).points.entries)
            ActivityCurvePointsCompanion.insert(
              activityId: activityId,
              kind: kind.name,
              durationSeconds: e.key,
              value: e.value.value,
              startSecond: e.value.startSecond,
            ),
      ],
    );
  }

  /// Cadencias de subida medidas en las salidas desde [since]: una por
  /// salida que haya traído suficiente subida pedaleando.
  Stream<List<double>> watchClimbingCadences({DateTime? since}) =>
      database.watchClimbingCadences(since: since);

  /// Curva histórica de [kind] con las actividades desde [since] (todas si
  /// es `null`).
  Stream<MeanMaxCurve> watchBestCurve(
    CurveKind kind, {
    DateTime? since,
    DateTime? until,
  }) => database
      .watchCurvePoints(kind: kind.name, since: since, until: until)
      .map(bestCurveOf);

  /// Curvas de una actividad.
  Stream<Map<CurveKind, MeanMaxCurve>> watchActivityCurves(int activityId) =>
      database
          .watchCurvePointsForActivity(activityId)
          .map(
            (rows) => {
              for (final kind in CurveKind.values)
                kind: activityCurveOf(rows, kind),
            },
          );
}
