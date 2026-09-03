import 'package:cyclecore_app/core/database/app_database.dart';
import 'package:cyclecore_app/features/activities/domain/weekly_summary.dart';
import 'package:flutter_test/flutter_test.dart';

Activity _activity({
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
  // Miércoles 26 de agosto de 2026, 10:00 -> la semana en curso arranca
  // el lunes 24 de agosto.
  final now = DateTime(2026, 8, 26, 10);

  test('solo cuenta las actividades de la semana en curso', () {
    final summary = computeWeeklySummary([
      _activity(startedAt: DateTime(2026, 8, 24, 7)), // lunes, esta semana
      _activity(startedAt: DateTime(2026, 8, 26, 6)), // hoy
      _activity(startedAt: DateTime(2026, 8, 23, 18)), // domingo pasado
    ], now: now);

    expect(summary.rideCount, 2);
    expect(summary.distanceKm, 20);
    expect(summary.elevationGainMeters, 200);
    expect(summary.movingTime, const Duration(hours: 2));
  });

  test('el mini-gráfico ubica cada actividad en su cubo de semana', () {
    final summary = computeWeeklySummary([
      _activity(startedAt: DateTime(2026, 8, 25), distanceMeters: 30000),
      _activity(startedAt: DateTime(2026, 8, 18), distanceMeters: 12000),
      _activity(startedAt: DateTime(2026, 7, 21), distanceMeters: 5000),
      _activity(startedAt: DateTime(2026, 7, 10), distanceMeters: 99000),
    ], now: now);

    expect(summary.last6WeeksKm.length, 6);
    expect(summary.last6WeeksKm[5], 30); // semana en curso
    expect(summary.last6WeeksKm[4], 12); // hace una semana
    expect(summary.last6WeeksKm[0], 5); // hace cinco semanas
    // La de hace más de 6 semanas no entra en ningún cubo.
    expect(summary.last6WeeksKm.reduce((a, b) => a + b), 47);
  });

  test('isEmpty cuando no hay actividades', () {
    expect(computeWeeklySummary([], now: now).isEmpty, isTrue);
  });
}
