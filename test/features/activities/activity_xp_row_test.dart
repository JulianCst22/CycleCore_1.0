import 'package:cyclecore_app/core/database/app_database.dart';
import 'package:cyclecore_app/features/activities/presentation/activities_providers.dart';
import 'package:cyclecore_app/features/activities/presentation/widgets/activity_xp_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Activity _a(int id) => Activity(
  id: id,
  title: 'Amanecer en Patios',
  activityType: 'training',
  bikeName: 'Bici de ruta',
  startedAt: DateTime(2026, 8, 20, 6),
  endedAt: DateTime(2026, 8, 20, 8),
  durationSeconds: 7200,
  distanceMeters: 42000,
  avgSpeedKmh: 21,
  maxSpeedKmh: 40,
  elevationGainMeters: 730,
  routePointsJson: '[]',
  photoPathsJson: '[]',
);

Widget _wrap(Widget child, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('muestra el XP y abre la hoja de "cómo se calcula"', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const ActivityXpRow(activityId: 7), [
        activitiesListProvider.overrideWith((ref) => Stream.value([_a(7)])),
      ]),
    );
    await tester.pump();

    expect(find.textContaining('XP'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('XP de esta actividad'), findsOneWidget);
    expect(find.text('CÓMO SE CALCULA'), findsOneWidget);
    expect(find.textContaining('por kilómetro recorrido'), findsOneWidget);
    expect(find.textContaining('no se guarda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no pinta nada si aún no hay datos de XP', (tester) async {
    await tester.pumpWidget(
      _wrap(const ActivityXpRow(activityId: 7), [
        activitiesListProvider.overrideWith(
          (ref) => Stream.value(const <Activity>[]),
        ),
      ]),
    );
    await tester.pump();

    expect(find.textContaining('XP'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
