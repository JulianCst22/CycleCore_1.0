import 'package:core_database/core_database.dart';
import 'package:cyclecore_app/features/stats/domain/profile_stats.dart';
import 'package:cyclecore_app/features/stats/domain/stats_trend.dart';
import 'package:flutter_test/flutter_test.dart';

Activity _a({
  required DateTime startedAt,
  double distanceMeters = 10000,
  double elevationGainMeters = 100,
  int durationSeconds = 3600,
}) {
  return Activity(
    id: 1,
    title: 'Recorrido',
    activityType: 'training',
    bikeName: 'Bici de ruta',
    startedAt: startedAt,
    endedAt: startedAt.add(Duration(seconds: durationSeconds)),
    durationSeconds: durationSeconds,
    distanceMeters: distanceMeters,
    avgSpeedKmh: 20,
    maxSpeedKmh: 40,
    elevationGainMeters: elevationGainMeters,
    routePointsJson: '[]',
    photoPathsJson: '[]',
  );
}

void main() {
  // Miércoles 26 de agosto de 2026.
  final now = DateTime(2026, 8, 26, 10);

  test('week: 7 barras, una por día, la de hoy marcada', () {
    final buckets = computeStatsTrend(
      activities: [
        _a(startedAt: DateTime(2026, 8, 24, 7), distanceMeters: 20000), // lun
        _a(
          startedAt: DateTime(2026, 8, 26, 6),
          distanceMeters: 15000,
        ), // mié (hoy)
        _a(
          startedAt: DateTime(2026, 8, 19),
          distanceMeters: 99000,
        ), // semana pasada
      ],
      period: StatsPeriod.week,
      metric: StatsTrendMetric.distance,
      now: now,
    );

    expect(buckets.length, 7);
    expect(buckets[0].label, 'L');
    expect(buckets[0].value, 20); // km
    expect(buckets[2].value, 15);
    expect(buckets[2].isCurrent, isTrue);
    expect(buckets[0].isCurrent, isFalse);
  });

  test('month: una barra por bloque de 7 días', () {
    final buckets = computeStatsTrend(
      activities: [
        _a(startedAt: DateTime(2026, 8, 3), distanceMeters: 10000), // S1
        _a(startedAt: DateTime(2026, 8, 10), distanceMeters: 25000), // S2
        _a(startedAt: DateTime(2026, 8, 26), distanceMeters: 40000), // S4
        _a(startedAt: DateTime(2026, 7, 15), distanceMeters: 99000), // otro mes
      ],
      period: StatsPeriod.month,
      metric: StatsTrendMetric.distance,
      now: now,
    );

    expect(buckets.length, 5); // agosto tiene 31 días -> 5 bloques
    expect(buckets[0].value, 10);
    expect(buckets[1].value, 25);
    expect(buckets[3].value, 40);
    expect(buckets[3].isCurrent, isTrue); // el 26 cae en S4
  });

  test('year: 12 barras, métrica desnivel', () {
    final buckets = computeStatsTrend(
      activities: [
        _a(startedAt: DateTime(2026, 1, 5), elevationGainMeters: 300),
        _a(startedAt: DateTime(2026, 8, 5), elevationGainMeters: 800),
        _a(startedAt: DateTime(2025, 8, 5), elevationGainMeters: 999),
      ],
      period: StatsPeriod.year,
      metric: StatsTrendMetric.elevation,
      now: now,
    );

    expect(buckets.length, 12);
    expect(buckets[0].value, 300); // enero
    expect(buckets[7].value, 800); // agosto
    expect(buckets[7].isCurrent, isTrue);
  });

  test('all: una barra por año desde el primero con actividad', () {
    final buckets = computeStatsTrend(
      activities: [
        _a(startedAt: DateTime(2024, 6, 1), distanceMeters: 5000),
        _a(startedAt: DateTime(2026, 6, 1), distanceMeters: 8000),
      ],
      period: StatsPeriod.all,
      metric: StatsTrendMetric.rides,
      now: now,
    );

    expect(buckets.map((b) => b.label).toList(), ['2024', '2025', '2026']);
    expect(buckets[0].value, 1); // conteo de salidas
    expect(buckets[1].value, 0);
    expect(buckets[2].value, 1);
    expect(buckets[2].isCurrent, isTrue);
  });

  test('sin actividades -> barras en cero, no lanza', () {
    final buckets = computeStatsTrend(
      activities: const [],
      period: StatsPeriod.year,
      metric: StatsTrendMetric.distance,
      now: now,
    );
    expect(buckets.length, 12);
    expect(buckets.every((b) => b.value == 0), isTrue);
  });
}
