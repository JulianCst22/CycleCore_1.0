import 'package:core_database/core_database.dart';
import 'package:core_ui/core_ui.dart';
import 'package:cyclecore_app/features/activities/presentation/activities_list_screen.dart';
import 'package:cyclecore_app/features/activities/application/activities_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Activity _activity(String title) => Activity(
      id: 1,
      title: title,
      activityType: 'training',
      bikeName: 'Bici de ruta',
      startedAt: DateTime(2026, 8, 25, 6),
      endedAt: DateTime(2026, 8, 25, 8),
      durationSeconds: 7200,
      distanceMeters: 42100,
      avgSpeedKmh: 18.8,
      maxSpeedKmh: 41.2,
      elevationGainMeters: 734,
      routePointsJson: '[]',
      photoPathsJson: '[]',
    );

Future<void> _pump(WidgetTester tester, List<Activity> activities) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        activitiesListProvider.overrideWith((ref) => Stream.value(activities)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const ActivitiesListScreen(),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('es');
  });

  testWidgets('encabezado + banner + tarjeta se pintan sin overflow', (
    tester,
  ) async {
    await _pump(tester, [_activity('Amanecer en Patios')]);
    await tester.pump();

    expect(find.text('Tu trayectoria'), findsOneWidget);
    expect(find.text('Amanecer en Patios'), findsOneWidget);
    expect(find.text('ESTA SEMANA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('estado vacío cuando no hay actividades', (tester) async {
    await _pump(tester, const []);
    await tester.pump();

    expect(find.text('Aún no tienes actividades'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
