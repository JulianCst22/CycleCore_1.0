import 'package:core_database/core_database.dart';
import 'package:cyclecore_app/features/elevation/domain/elevation_lookup.dart';
import 'package:cyclecore_app/features/recording/domain/activity_altitude_flattener.dart';
import 'package:cyclecore_app/features/recording/domain/activity_summary_builder.dart';
import 'package:cyclecore_app/features/recording/domain/route_point.dart';
import 'package:flutter_test/flutter_test.dart';

final _start = DateTime(2026, 9, 12, 7, 0);

RoutePoint _point(int secondsFromStart, {double altitude = 2500}) => RoutePoint(
  latitude: 4.70 + secondsFromStart / 100000,
  longitude: -74.0,
  altitude: altitude,
  speedMetersPerSecond: 5,
  bearingDegrees: 0,
  accuracyMeters: 4,
  timestamp: _start.add(Duration(seconds: secondsFromStart)),
);

/// Aplanado "identidad": deja la altitud tal cual y pendiente 0 -- el
/// constructor del resumen no debe depender de cómo se aplanó.
FlattenedAltitudeResult _flat(List<RoutePoint> points, {double gain = 0}) =>
    FlattenedAltitudeResult(
      altitudes: [for (final p in points) p.altitude + 1],
      slopePercents: [for (final _ in points) 0],
      sources: [for (final _ in points) ElevationSource.hgt],
      isApproximate: [for (final _ in points) false],
      elevationGainMeters: gain,
      elevationLossMeters: 0,
    );

void main() {
  test('usa distancia/velocidad priorizadas y el tiempo en movimiento', () {
    final points = [_point(0), _point(60), _point(120)];

    final summary = buildActivitySummary(
      points: points,
      distances: const [0, 450, 1000],
      speeds: const [0, 32.5, 28],
      flattened: _flat(points, gain: 42),
      startedAt: _start,
      endedAt: _start.add(const Duration(minutes: 3)),
      movingTime: const Duration(minutes: 2),
      heartRateSamples: const [],
      powerSamples: const [],
      cadenceSamples: const [],
    );

    expect(summary.distanceMeters, 1000);
    expect(summary.duration, const Duration(minutes: 2));
    // 1 km en 2 min = 30 km/h, sobre el tiempo en movimiento.
    expect(summary.avgSpeedKmh, closeTo(30, 0.001));
    expect(summary.maxSpeedKmh, 32.5);
    expect(summary.elevationGainMeters, 42);

    final last = summary.routePoints.last;
    expect(last.distanceFromStartMeters, 1000);
    expect(last.speedKmh, 28);
    expect(last.secondsFromStart, 120);
    // Altitud aplanada en `altitude`, la de en vivo en `rawAltitude`.
    expect(last.altitude, 2501);
    expect(last.rawAltitude, 2500);
    expect(last.heartRateBpm, isNull);
  });

  test('casa cada punto con la última lectura de sensor hasta su instante', () {
    final points = [_point(0), _point(10), _point(20)];

    final summary = buildActivitySummary(
      points: points,
      distances: const [0, 50, 100],
      speeds: const [20, 20, 20],
      flattened: _flat(points),
      startedAt: _start,
      endedAt: _start.add(const Duration(seconds: 20)),
      movingTime: const Duration(seconds: 20),
      heartRateSamples: [
        HeartRateSample(
          timestamp: _start.add(const Duration(seconds: 5)),
          bpm: 120,
        ),
        HeartRateSample(
          timestamp: _start.add(const Duration(seconds: 20)),
          bpm: 150,
        ),
      ],
      powerSamples: [
        PowerSample(timestamp: _start, watts: 200),
        PowerSample(
          timestamp: _start.add(const Duration(seconds: 15)),
          watts: 300,
        ),
      ],
      cadenceSamples: [
        CadenceSample(
          timestamp: _start.add(const Duration(seconds: 12)),
          rpm: 88.6,
        ),
      ],
    );

    final hr = [for (final p in summary.routePoints) p.heartRateBpm];
    final power = [for (final p in summary.routePoints) p.powerWatts];
    final cadence = [for (final p in summary.routePoints) p.cadenceRpm];
    expect(hr, [null, 120, 150]);
    expect(power, [200, 200, 300]);
    expect(cadence, [null, null, 88.6]);

    expect(summary.avgHeartRate, 135);
    expect(summary.maxHeartRate, 150);
    expect(summary.avgPower, 250);
    expect(summary.maxPower, 300);
    expect(summary.avgCadence, 89);
    expect(summary.maxCadence, 89);
  });

  test('sin puntos ni sensores da un resumen en ceros', () {
    final summary = buildActivitySummary(
      points: const [],
      distances: const [],
      speeds: const [],
      flattened: FlattenedAltitudeResult.empty,
      startedAt: _start,
      endedAt: _start,
      movingTime: Duration.zero,
      heartRateSamples: const [],
      powerSamples: const [],
      cadenceSamples: const [],
    );

    expect(summary.distanceMeters, 0);
    expect(summary.avgSpeedKmh, 0);
    expect(summary.maxSpeedKmh, 0);
    expect(summary.routePoints, isEmpty);
    expect(summary.avgHeartRate, isNull);
    expect(summary.avgPower, isNull);
    expect(summary.avgCadence, isNull);
  });
}
