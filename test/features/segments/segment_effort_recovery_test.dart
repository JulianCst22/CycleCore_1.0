import 'package:core_database/core_database.dart';
import 'package:cyclecore_app/features/recording/domain/route_point.dart';
import 'package:cyclecore_app/features/recording/application/ride_sensor_log.dart';
import 'package:core_geo/core_geo.dart';
import 'package:cyclecore_app/features/segments/application/segment_detection_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// ~100 m de latitud.
const _step = 0.000898;
const _startLat = 4.7;
final _t0 = DateTime(2026, 9, 12, 7, 0);

/// Segmento recto hacia el norte de 10 tramos (~1 km).
SegmentsCompanion _straightNorthSegment() {
  final profile = [
    for (var i = 0; i <= 10; i++)
      SegmentProfilePoint(
        distanceFromStartMeters: i * 100.0,
        latitude: _startLat + i * _step,
        longitude: -74.0,
        altitude: 2500,
        slopePercent: 0,
      ),
  ];
  return SegmentsCompanion.insert(
    name: 'Recta de prueba',
    startLat: _startLat,
    startLng: -74.0,
    endLat: _startLat + 10 * _step,
    endLng: -74.0,
    startBearingDegrees: 0,
    distanceMeters: 1000,
    elevationGainMeters: 0,
    avgSlopePercent: 0,
    maxSlopePercent: 0,
    profileJson: SegmentProfile.encode(profile),
    createdAt: _t0,
  );
}

/// Un punto cada 10 s a 36 km/h, desde 100 m antes del inicio hasta
/// 100 m después del final.
List<RoutePoint> _rideThroughSegment() => [
  for (var i = -1; i <= 11; i++)
    RoutePoint(
      latitude: _startLat + i * _step,
      longitude: -74.0,
      altitude: 2500,
      speedMetersPerSecond: 10,
      bearingDegrees: 0,
      accuracyMeters: 3,
      timestamp: _t0.add(Duration(seconds: (i + 1) * 10)),
    ),
];

void main() {
  // `routeRecordingProvider` (del que depende la detección) escucha el
  // ciclo de vida de la app.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('reconstruye el esfuerzo de una grabación recuperada, con los instantes '
      'y la FC de sus puntos', () async {
    final segmentId = await db.insertSegment(_straightNorthSegment());
    final activityId = await db.insertActivity(
      ActivitiesCompanion.insert(
        title: 'Recuperada',
        activityType: 'training',
        bikeName: 'Ruta',
        startedAt: _t0,
        endedAt: _t0.add(const Duration(minutes: 3)),
        durationSeconds: 180,
        distanceMeters: 1200,
        avgSpeedKmh: 36,
        maxSpeedKmh: 36,
        elevationGainMeters: 0,
      ),
    );

    final detection = container.read(segmentDetectionProvider.notifier);
    await detection.recoverEffortsFrom(
      points: _rideThroughSegment(),
      log: RideSensorLog(
        heartRate: [
          HeartRateSample(
            timestamp: _t0.add(const Duration(seconds: 30)),
            bpm: 150,
          ),
          HeartRateSample(
            timestamp: _t0.add(const Duration(seconds: 90)),
            bpm: 160,
          ),
          // Fuera del segmento -- no cuenta en el promedio.
          HeartRateSample(
            timestamp: _t0.add(const Duration(seconds: 125)),
            bpm: 100,
          ),
        ],
      ),
    );

    expect(detection.hasPendingEfforts, isTrue);
    await detection.flushPendingEfforts(activityId);

    final effort = (await db.getEffortsForActivity(activityId)).single;
    expect(effort.segmentId, segmentId);
    // Entra en el punto del inicio (t = 10 s) y termina en el del final
    // (t = 110 s).
    expect(effort.durationSeconds, 100);
    expect(effort.completedAt, _t0.add(const Duration(seconds: 110)));
    expect(effort.avgHeartRate, 155);
    expect(detection.hasPendingEfforts, isFalse);
  });

  test('sin segmentos activos no deja esfuerzos pendientes', () async {
    final detection = container.read(segmentDetectionProvider.notifier);
    await detection.recoverEffortsFrom(
      points: _rideThroughSegment(),
      log: const RideSensorLog(),
    );

    expect(detection.hasPendingEfforts, isFalse);
  });
}
