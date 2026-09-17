import 'package:core_database/core_database.dart';

import 'activity_altitude_flattener.dart';
import 'route_point.dart';

/// Arma el [ActivitySummary] final de una grabación a partir de sus
/// series ya capturadas. Puro: no lee sensores ni el reloj.
///
/// Antes vivía dentro de `RouteRecordingController.finishRecording`; se
/// extrajo para que terminar una grabación en vivo y terminar una
/// recuperada del diario (tras un cierre inesperado de la app) produzcan
/// exactamente el mismo resumen.
///
/// - [distances]/[speeds] van alineados índice a índice con [points]:
///   la distancia y velocidad YA priorizadas (sensor o GPS) de cada
///   punto, que se reutilizan tal cual en vez de recalcularse con
///   Geolocator -- crítico en indoor, donde el GPS no se mueve pero el
///   sensor sí.
/// - [flattened] es el aplanado de altimetría sobre esos mismos puntos
///   (ver `ActivityAltitudeFlattener`); reemplaza la altitud y pendiente
///   vistas en vivo.
/// - FC/potencia/cadencia siguen el patrón "carry forward": cada punto
///   se casa con la última lectura conocida de ese sensor hasta su
///   instante. Listas vacías (sin sensor) dejan esos campos en null en
///   cada punto, y avg/max en null en el resumen.
ActivitySummary buildActivitySummary({
  required List<RoutePoint> points,
  required List<double> distances,
  required List<double> speeds,
  required FlattenedAltitudeResult flattened,
  required DateTime startedAt,
  required DateTime endedAt,
  required Duration movingTime,
  required List<HeartRateSample> heartRateSamples,
  required List<PowerSample> powerSamples,
  required List<CadenceSample> cadenceSamples,
}) {
  assert(
    distances.length == points.length && speeds.length == points.length,
    'distances/speeds deben ir alineados con points.',
  );

  int hrIndex = 0;
  int? carriedHr;
  int powerIndex = 0;
  int? carriedPower;
  int cadenceIndex = 0;
  double? carriedCadence;
  final enrichedPoints = <RoutePointSnapshot>[];

  for (int i = 0; i < points.length; i++) {
    final point = points[i];

    while (hrIndex < heartRateSamples.length &&
        !heartRateSamples[hrIndex].timestamp.isAfter(point.timestamp)) {
      carriedHr = heartRateSamples[hrIndex].bpm;
      hrIndex++;
    }

    while (powerIndex < powerSamples.length &&
        !powerSamples[powerIndex].timestamp.isAfter(point.timestamp)) {
      carriedPower = powerSamples[powerIndex].watts;
      powerIndex++;
    }

    while (cadenceIndex < cadenceSamples.length &&
        !cadenceSamples[cadenceIndex].timestamp.isAfter(point.timestamp)) {
      carriedCadence = cadenceSamples[cadenceIndex].rpm;
      cadenceIndex++;
    }

    enrichedPoints.add(
      RoutePointSnapshot(
        latitude: point.latitude,
        longitude: point.longitude,
        altitude: flattened.altitudes[i],
        // Altitud fusionada en vivo, ANTES de aplanar -- se guarda
        // para poder volver a aplanar más tarde ("Ajustar altimetría")
        // sobre el dato original y no sobre uno ya procesado.
        rawAltitude: point.altitude,
        distanceFromStartMeters: distances[i],
        slopePercent: flattened.slopePercents[i],
        speedKmh: speeds[i],
        secondsFromStart: point.timestamp.difference(startedAt).inSeconds,
        heartRateBpm: carriedHr,
        powerWatts: carriedPower,
        cadenceRpm: carriedCadence,
        isElevationApproximate: flattened.isApproximate[i],
      ),
    );
  }

  final finalDistance = distances.isEmpty ? 0.0 : distances.last;

  int? avgHeartRate;
  int? maxHeartRate;
  if (heartRateSamples.isNotEmpty) {
    final bpmValues = heartRateSamples.map((s) => s.bpm);
    avgHeartRate = (bpmValues.reduce((a, b) => a + b) / bpmValues.length)
        .round();
    maxHeartRate = bpmValues.reduce((a, b) => a > b ? a : b);
  }

  int? avgPower;
  int? maxPower;
  if (powerSamples.isNotEmpty) {
    final wattValues = powerSamples.map((s) => s.watts);
    avgPower = (wattValues.reduce((a, b) => a + b) / wattValues.length).round();
    maxPower = wattValues.reduce((a, b) => a > b ? a : b);
  }

  int? avgCadence;
  int? maxCadence;
  if (cadenceSamples.isNotEmpty) {
    final rpmValues = cadenceSamples.map((s) => s.rpm);
    avgCadence = (rpmValues.reduce((a, b) => a + b) / rpmValues.length).round();
    maxCadence = rpmValues.reduce((a, b) => a > b ? a : b).round();
  }

  final hours = movingTime.inSeconds / 3600;
  final avgSpeedKmh = finalDistance <= 0 || movingTime.inSeconds <= 0
      ? 0.0
      : (finalDistance / 1000) / hours;

  return ActivitySummary(
    startedAt: startedAt,
    endedAt: endedAt,
    duration: movingTime,
    distanceMeters: finalDistance,
    avgSpeedKmh: avgSpeedKmh,
    maxSpeedKmh: speeds.fold(0, (max, s) => s > max ? s : max),
    // Desnivel recalculado desde la serie aplanada -- ver Fase 1.
    elevationGainMeters: flattened.elevationGainMeters,
    avgHeartRate: avgHeartRate,
    maxHeartRate: maxHeartRate,
    avgPower: avgPower,
    maxPower: maxPower,
    avgCadence: avgCadence,
    maxCadence: maxCadence,
    routePoints: enrichedPoints,
  );
}
