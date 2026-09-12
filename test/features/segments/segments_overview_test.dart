import 'package:cyclecore_core/database/app_database.dart';
import 'package:cyclecore_app/features/segments/domain/segments_overview.dart';
import 'package:flutter_test/flutter_test.dart';

Segment _segment(int id, String name, {bool isActive = true}) => Segment(
  id: id,
  name: name,
  source: 'activity',
  isPublic: false,
  isActive: isActive,
  startLat: 4.7,
  startLng: -74.0,
  endLat: 4.8,
  endLng: -74.1,
  startBearingDegrees: 90,
  distanceMeters: 6000,
  elevationGainMeters: 400,
  avgSlopePercent: 6.5,
  maxSlopePercent: 11,
  profileJson: '[]',
  createdAt: DateTime(2026, 1, 1),
);

SegmentEffort _effort(
  int id,
  int segmentId, {
  required int durationSeconds,
  required DateTime completedAt,
  int activityId = 1,
}) => SegmentEffort(
  id: id,
  segmentId: segmentId,
  activityId: activityId,
  durationSeconds: durationSeconds,
  avgSpeedKmh: 15,
  completedAt: completedAt,
  splitsJson: '[]',
);

void main() {
  final now = DateTime(2026, 8, 28, 12);

  test('resumen: activos, PR del mes y total de esfuerzos', () {
    final overview = computeSegmentsOverview(
      segments: [
        _segment(1, 'Patios'),
        _segment(2, 'Sprint', isActive: false),
        _segment(3, 'Verjón'),
      ],
      efforts: [
        // Patios: PR este mes
        _effort(
          1,
          1,
          durationSeconds: 1500,
          completedAt: DateTime(2026, 8, 10),
        ),
        _effort(
          2,
          1,
          durationSeconds: 1455,
          completedAt: DateTime(2026, 8, 27),
        ),
        // Sprint: PR viejo (julio)
        _effort(3, 2, durationSeconds: 110, completedAt: DateTime(2026, 7, 3)),
      ],
      now: now,
    );

    expect(overview.total, 3);
    expect(overview.active, 2);
    expect(overview.totalEfforts, 3);
    expect(overview.personalBestsThisMonth, 1); // solo Patios
  });

  test('tarjeta: mejor marca, conteo y última fecha por segmento', () {
    final overview = computeSegmentsOverview(
      segments: [_segment(1, 'Patios')],
      efforts: [
        _effort(
          1,
          1,
          durationSeconds: 1500,
          completedAt: DateTime(2026, 8, 10),
        ),
        _effort(
          2,
          1,
          durationSeconds: 1455,
          completedAt: DateTime(2026, 8, 27),
        ),
        _effort(
          3,
          1,
          durationSeconds: 1480,
          completedAt: DateTime(2026, 8, 20),
        ),
      ],
      now: now,
    );

    final summary = overview.summaries.single;
    expect(summary.effortCount, 3);
    expect(summary.best!.durationSeconds, 1455);
    expect(summary.lastEffortAt, DateTime(2026, 8, 27));
  });

  test(
    'feed: el PR muestra cuánto batió la marca anterior; los demás, el retraso',
    () {
      final overview = computeSegmentsOverview(
        segments: [_segment(1, 'Patios')],
        activities: [
          Activity(
            id: 7,
            title: 'Salida matutina',
            activityType: 'training',
            bikeName: 'Ruta',
            startedAt: DateTime(2026, 8, 27, 6),
            endedAt: DateTime(2026, 8, 27, 8),
            durationSeconds: 7200,
            distanceMeters: 40000,
            avgSpeedKmh: 20,
            maxSpeedKmh: 40,
            elevationGainMeters: 500,
            routePointsJson: '[]',
            photoPathsJson: '[]',
          ),
        ],
        efforts: [
          _effort(
            1,
            1,
            durationSeconds: 1500,
            completedAt: DateTime(2026, 8, 10),
            activityId: 3,
          ),
          _effort(
            2,
            1,
            durationSeconds: 1455,
            completedAt: DateTime(2026, 8, 27),
            activityId: 7,
          ),
        ],
        now: now,
      );

      // Más reciente primero.
      final top = overview.recent.first;
      expect(top.effort.id, 2);
      expect(top.isPersonalBest, isTrue);
      expect(top.isFirstEffort, isFalse);
      expect(top.deltaSeconds, -45); // batió 1500 -> 1455
      expect(top.activityTitle, 'Salida matutina');

      final older = overview.recent[1];
      expect(older.isPersonalBest, isFalse);
      expect(older.deltaSeconds, 45); // 1500 vs PR 1455
    },
  );

  test('feed: primer esfuerzo de un segmento', () {
    final overview = computeSegmentsOverview(
      segments: [_segment(1, 'Patios')],
      efforts: [
        _effort(
          1,
          1,
          durationSeconds: 1500,
          completedAt: DateTime(2026, 8, 27),
        ),
      ],
      now: now,
    );
    expect(overview.recent.single.isFirstEffort, isTrue);
    expect(overview.recent.single.deltaSeconds, 0);
  });

  test('sin segmentos -> isEmpty', () {
    expect(
      computeSegmentsOverview(segments: [], efforts: [], now: now).isEmpty,
      isTrue,
    );
  });
}
