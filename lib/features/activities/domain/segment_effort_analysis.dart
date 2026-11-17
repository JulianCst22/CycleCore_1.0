import '../../../core/database/database.dart';

/// Los puntos de una salida que corresponden a un esfuerzo en un segmento,
/// con la distancia y el tiempo contados desde la entrada al segmento.
///
/// El esfuerzo guarda cuándo terminó y cuánto duró, y cada punto guarda
/// sus segundos de reloj desde el inicio de la salida: con eso se recorta
/// el tramo sin volver a buscar el segmento en el mapa. Vacío si la salida
/// no tiene puntos en ese rango.
List<RoutePointSnapshot> effortPoints({
  required List<RoutePointSnapshot> points,
  required DateTime activityStartedAt,
  required DateTime completedAt,
  required int durationSeconds,
}) {
  if (points.length < 2) return const [];
  final end = completedAt.difference(activityStartedAt).inSeconds;
  final start = end - durationSeconds;
  var from = -1;
  var to = -1;
  for (var i = 0; i < points.length; i++) {
    final t = points[i].secondsFromStart;
    if (from < 0 && t >= start) from = i;
    if (t <= end) to = i;
  }
  if (from < 0 || to - from < 1) return const [];
  final d0 = points[from].distanceFromStartMeters;
  final t0 = points[from].secondsFromStart;
  return [
    for (var i = from; i <= to; i++)
      RoutePointSnapshot(
        latitude: points[i].latitude,
        longitude: points[i].longitude,
        altitude: points[i].altitude,
        rawAltitude: points[i].rawAltitude,
        distanceFromStartMeters: points[i].distanceFromStartMeters - d0,
        slopePercent: points[i].slopePercent,
        speedKmh: points[i].speedKmh,
        secondsFromStart: points[i].secondsFromStart - t0,
        heartRateBpm: points[i].heartRateBpm,
        powerWatts: points[i].powerWatts,
        cadenceRpm: points[i].cadenceRpm,
        isElevationApproximate: points[i].isElevationApproximate,
        pressureHpa: points[i].pressureHpa,
      ),
  ];
}

/// Las cifras de un esfuerzo que salen de sus puntos (los promedios de
/// pulso y potencia ya vienen en el esfuerzo, medidos con cada lectura del
/// sensor).
class EffortFigures {
  final double maxSpeedKmh;
  final int? maxHeartRate;
  final int? avgHeartRate;
  final int? maxPower;
  final int? avgPower;

  /// Sin los ceros de cuando se deja de pedalear (bajando), como Strava.
  final int? avgCadence;

  const EffortFigures({
    required this.maxSpeedKmh,
    this.maxHeartRate,
    this.avgHeartRate,
    this.maxPower,
    this.avgPower,
    this.avgCadence,
  });
}

EffortFigures effortFiguresOf(List<RoutePointSnapshot> points) {
  int? maxOf(Iterable<int?> values) {
    int? best;
    for (final v in values) {
      if (v != null && (best == null || v > best)) best = v;
    }
    return best;
  }

  int? meanOf(Iterable<num?> values) {
    var sum = 0.0;
    var count = 0;
    for (final v in values) {
      if (v == null) continue;
      sum += v;
      count++;
    }
    return count == 0 ? null : (sum / count).round();
  }

  var maxSpeed = 0.0;
  for (final p in points) {
    if (p.speedKmh > maxSpeed) maxSpeed = p.speedKmh;
  }
  return EffortFigures(
    maxSpeedKmh: maxSpeed,
    maxHeartRate: maxOf(points.map((p) => p.heartRateBpm)),
    avgHeartRate: meanOf(points.map((p) => p.heartRateBpm)),
    maxPower: maxOf(points.map((p) => p.powerWatts)),
    avgPower: meanOf(points.map((p) => p.powerWatts)),
    avgCadence: meanOf([
      for (final p in points)
        if ((p.cadenceRpm ?? 0) > 0) p.cadenceRpm,
    ]),
  );
}

/// Velocidad de ascenso (m/h): el desnivel del segmento entre el tiempo.
/// Con el desnivel del segmento y no el de cada grabación, para que dos
/// esfuerzos se comparen con la misma vara.
double vamOf(double gainMeters, int durationSeconds) =>
    durationSeconds <= 0 ? 0 : gainMeters / (durationSeconds / 3600);

/// Segundos de ventaja sobre [reference] en cada punto de [effort]
/// (positivo = ibas adelante). Los dos se alinean por la fracción del
/// segmento recorrida: cada grabación mide el segmento con unos metros de
/// diferencia, y comparar metro a metro corría la meta de uno respecto
/// del otro.
List<double> advantageSeconds(
  List<RoutePointSnapshot> effort,
  List<RoutePointSnapshot> reference,
) {
  if (effort.isEmpty) return const [];
  final effortTotal = effort.last.distanceFromStartMeters;
  final referenceTotal = reference.isEmpty
      ? 0.0
      : reference.last.distanceFromStartMeters;
  if (effortTotal <= 0 || referenceTotal <= 0) {
    return List.filled(effort.length, 0);
  }
  var j = 0;
  return [
    for (final p in effort)
      () {
        final target = p.distanceFromStartMeters / effortTotal * referenceTotal;
        while (j < reference.length - 2 &&
            reference[j + 1].distanceFromStartMeters < target) {
          j++;
        }
        final a = reference[j];
        final b = reference[(j + 1).clamp(0, reference.length - 1)];
        final span = b.distanceFromStartMeters - a.distanceFromStartMeters;
        final t = span > 0
            ? ((target - a.distanceFromStartMeters) / span).clamp(0.0, 1.0)
            : 0.0;
        final referenceSeconds =
            a.secondsFromStart + (b.secondsFromStart - a.secondsFromStart) * t;
        return referenceSeconds - p.secondsFromStart;
      }(),
  ];
}
