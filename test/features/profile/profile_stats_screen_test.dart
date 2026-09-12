import 'package:cyclecore_core/database/app_database.dart';
import 'package:cyclecore_app/features/activities/presentation/activities_providers.dart';
import 'package:cyclecore_app/features/profile/domain/cyclist_profile.dart';
import 'package:cyclecore_app/features/profile/domain/profile_stats.dart'
    show ProfileStats, StatsPeriod;
import 'package:cyclecore_app/features/profile/presentation/profile_providers.dart';
import 'package:cyclecore_app/features/profile/presentation/profile_stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Activity _a({
  required DateTime startedAt,
  String type = 'training',
  double distanceMeters = 30000,
  double elevationGainMeters = 400,
  int durationSeconds = 5400,
  double avgSpeedKmh = 20,
}) {
  return Activity(
    id: startedAt.millisecondsSinceEpoch ~/ 1000,
    title: 'Recorrido',
    activityType: type,
    bikeName: 'Bici de ruta',
    startedAt: startedAt,
    endedAt: startedAt.add(Duration(seconds: durationSeconds)),
    durationSeconds: durationSeconds,
    distanceMeters: distanceMeters,
    avgSpeedKmh: avgSpeedKmh,
    maxSpeedKmh: avgSpeedKmh + 15,
    elevationGainMeters: elevationGainMeters,
    routePointsJson: '[]',
    photoPathsJson: '[]',
  );
}

class _FakeProfile extends ProfileNotifier {
  _FakeProfile(this._profile);
  final CyclistProfile? _profile;
  @override
  Future<CyclistProfile?> build() async => _profile;
}

Widget _wrap(List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: const MaterialApp(home: ProfileStatsScreen()),
);

void main() {
  final profile = const CyclistProfile(
    name: 'Julián',
    weightKg: 72,
    ftpWatts: 248,
    maxHr: 189,
  );

  testWidgets('pinta héroe, tendencia, rendimiento y récords sin excepción', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap([
        // Periodo "total" para que el test no dependa de en qué día del
        // mes se ejecute (si no, actividades de "hace 5 días" caen fuera
        // de "este mes" a comienzos de mes y sale el estado vacío).
        statsPeriodProvider.overrideWith((ref) => StatsPeriod.all),
        activitiesListProvider.overrideWith(
          (ref) => Stream.value([
            _a(startedAt: DateTime.now().subtract(const Duration(days: 2))),
            _a(
              startedAt: DateTime.now().subtract(const Duration(days: 5)),
              type: 'race',
              distanceMeters: 58000,
              avgSpeedKmh: 34,
            ),
            _a(startedAt: DateTime.now().subtract(const Duration(days: 12))),
          ]),
        ),
        profileProvider.overrideWith(() => _FakeProfile(profile)),
      ]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('TOTALES'), findsOneWidget);
    expect(find.textContaining('W/kg'), findsWidgets);
    expect(find.text('BUENO'), findsOneWidget);
    expect(find.textContaining('RÉCORDS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin actividades muestra el mensaje vacío', (tester) async {
    await tester.pumpWidget(
      _wrap([
        activitiesListProvider.overrideWith(
          (ref) => Stream.value(const <Activity>[]),
        ),
        profileProvider.overrideWith(() => _FakeProfile(null)),
      ]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Todavía no hay salidas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('ProfileStats agrega los récords del conjunto', () {
    final stats = ProfileStats.fromActivities([
      _a(
        startedAt: DateTime(2026, 8, 1),
        distanceMeters: 20000,
        elevationGainMeters: 200,
        avgSpeedKmh: 18,
      ),
      _a(
        startedAt: DateTime(2026, 8, 8),
        distanceMeters: 62000,
        elevationGainMeters: 1240,
        avgSpeedKmh: 22,
      ),
      _a(
        startedAt: DateTime(2026, 8, 15),
        distanceMeters: 40000,
        elevationGainMeters: 600,
        avgSpeedKmh: 31,
      ),
    ]);

    expect(stats.longestRideMeters, 62000);
    expect(stats.mostClimbingMeters, 1240);
    expect(stats.fastestRideKmh, 31);
  });
}
