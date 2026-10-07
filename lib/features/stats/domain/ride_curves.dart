import 'dart:convert';

import '../../../core/database/database.dart';
import '../../../core/physiology/physiology.dart';
import 'climbing_cadence.dart';
import 'activity_series.dart';

/// Señal que describe una curva de medias máximas.
enum CurveKind { power, heartRate }

/// Versión del cálculo de curvas. Si cambia (otras duraciones, otra forma
/// de armar la serie), las curvas de todas las actividades se recalculan.
const curveAlgorithmVersion = 2;

/// Actividad de la que salió un punto de una curva.
typedef CurveOrigin = ({int activityId, DateTime startedAt, String title});

/// Curvas de una actividad: la mejor potencia y el mejor pulso sostenidos
/// de 5 s a 60 min.
final class RideCurves {
  final int movingSeconds;
  final int powerSeconds;
  final int heartRateSeconds;
  final MeanMaxCurve power;
  final MeanMaxCurve heartRate;

  /// Mediana de la cadencia subiendo en esta salida; `null` si no trajo
  /// suficiente subida pedaleando (ver `climbingCadenceOf`).
  final double? climbingCadence;

  const RideCurves({
    required this.movingSeconds,
    required this.powerSeconds,
    required this.heartRateSeconds,
    required this.power,
    required this.heartRate,
    this.climbingCadence,
  });

  factory RideCurves.fromSeries(
    ActivitySeries series, {
    double? climbingCadence,
  }) => RideCurves(
    movingSeconds: series.movingSeconds,
    powerSeconds: series.powerSeconds,
    heartRateSeconds: series.heartRateSeconds,
    power: MeanMaxCurve.fromSeries(series.power),
    heartRate: MeanMaxCurve.fromSeries(series.heartRate),
    climbingCadence: climbingCadence,
  );

  /// Curvas a partir del trazado guardado (`routePointsJson`). Es la
  /// parte pesada: se puede correr en otro isolate.
  factory RideCurves.fromRouteJson(String routePointsJson, int movingSeconds) {
    final points = [
      for (final e in jsonDecode(routePointsJson) as List)
        RoutePointSnapshot.fromJson(e as Map<String, dynamic>),
    ];
    return RideCurves.fromSeries(
      ActivitySeries.fromRoutePoints(points, movingSeconds: movingSeconds),
      climbingCadence: climbingCadenceOf(points),
    );
  }

  MeanMaxCurve of(CurveKind kind) => switch (kind) {
    CurveKind.power => power,
    CurveKind.heartRate => heartRate,
  };
}

/// Curva histórica a partir de las filas guardadas: para cada duración,
/// la mejor media entre las actividades, con su origen. En un empate se
/// queda la actividad más antigua (la que puso la marca primero).
MeanMaxCurve bestCurveOf(Iterable<CurvePointWithActivity> rows) {
  final byActivity =
      <int, ({DateTime startedAt, Map<int, MeanMaxPoint> points})>{};
  for (final row in rows) {
    final p = row.point;
    final origin = (
      activityId: p.activityId,
      startedAt: row.startedAt,
      title: row.title,
    );
    byActivity
        .putIfAbsent(
          p.activityId,
          () => (startedAt: row.startedAt, points: <int, MeanMaxPoint>{}),
        )
        .points[p.durationSeconds] = (
      value: p.value,
      startSecond: p.startSecond,
      source: origin,
    );
  }
  final ordered = byActivity.entries.toList()
    ..sort((a, b) {
      final byDate = a.value.startedAt.compareTo(b.value.startedAt);
      return byDate != 0 ? byDate : a.key.compareTo(b.key);
    });
  return MeanMaxCurve.best([
    for (final e in ordered) MeanMaxCurve.fromPoints(e.value.points),
  ]);
}

/// Curva de una sola actividad a partir de sus filas.
MeanMaxCurve activityCurveOf(
  Iterable<ActivityCurvePoint> rows,
  CurveKind kind,
) => MeanMaxCurve.fromPoints({
  for (final p in rows)
    if (p.kind == kind.name)
      p.durationSeconds: (
        value: p.value,
        startSecond: p.startSecond,
        source: p.activityId,
      ),
});

/// Origen de un punto de una curva histórica (`null` si el punto no vino
/// de [bestCurveOf]).
CurveOrigin? originOf(MeanMaxPoint point) => switch (point.source) {
  final CurveOrigin origin => origin,
  _ => null,
};
