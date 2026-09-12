import 'package:cyclecore_core/database/app_database.dart';
import 'package:cyclecore_app/features/activities/presentation/activities_providers.dart';
import 'package:cyclecore_app/features/profile/domain/kit_catalog.dart';
import 'package:cyclecore_app/features/profile/domain/level_info.dart';
import 'package:cyclecore_app/features/profile/presentation/profile_providers.dart';
import 'package:cyclecore_app/features/profile/presentation/wardrobe_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Activity _a(DateTime at, {double km = 40, double gain = 500, double kmh = 24}) {
  return Activity(
    id: at.millisecondsSinceEpoch ~/ 1000,
    title: 'Salida',
    activityType: 'training',
    bikeName: 'Bici',
    startedAt: at,
    endedAt: at.add(const Duration(hours: 2)),
    durationSeconds: 7200,
    distanceMeters: km * 1000,
    avgSpeedKmh: kmh,
    maxSpeedKmh: kmh + 12,
    elevationGainMeters: gain,
    routePointsJson: '[]',
    photoPathsJson: '[]',
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget wrap() => ProviderScope(
    overrides: [
      effectiveTotalXpProvider.overrideWithValue(
        AsyncValue.data(LevelCalculator.cumulativeXpToReach(12) + 500),
      ),
      activitiesListProvider.overrideWith(
        (ref) => Stream.value([
          _a(DateTime.now().subtract(const Duration(days: 1))),
          _a(DateTime.now().subtract(const Duration(days: 3))),
        ]),
      ),
    ],
    child: const MaterialApp(home: WardrobeScreen()),
  );

  testWidgets(
    'el Vestidor pinta el preview, las 5 pestañas y equipa una pieza',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Vestidor'), findsOneWidget);
      expect(find.text('Maillot'), findsOneWidget);
      expect(find.text('Sets'), findsOneWidget);

      // El maillot de rango más bajo está desbloqueado siempre: equiparlo.
      final r0 = KitCatalog.byId['maillot_r0']!;
      await tester.tap(find.text(r0.name).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Equipado'), findsWidgets);

      // La pestaña de sets se abre sin excepción.
      await tester.tap(find.text('Sets'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('SET'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
