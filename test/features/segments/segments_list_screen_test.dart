import 'package:core_database/core_database.dart';
import 'package:core_ui/core_ui.dart';
import 'package:cyclecore_app/features/activities/application/activities_providers.dart';
import 'package:cyclecore_app/features/segments/presentation/segment_detail_screen.dart';
import 'package:cyclecore_app/features/segments/presentation/segments_list_screen.dart';
import 'package:cyclecore_app/features/segments/application/segments_providers.dart';
import 'package:cyclecore_app/features/segments/presentation/widgets/segment_progress_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Segment _segment(int id, String name) => Segment(
  id: id,
  name: name,
  source: 'activity',
  isPublic: false,
  isActive: true,
  startLat: 4.7,
  startLng: -74.0,
  endLat: 4.8,
  endLng: -74.1,
  startBearingDegrees: 90,
  distanceMeters: 6100,
  elevationGainMeters: 412,
  avgSlopePercent: 6.8,
  maxSlopePercent: 11.2,
  profileJson: '[]',
  createdAt: DateTime(2026, 1, 1),
);

SegmentEffort _effort(int id, int segmentId, int seconds, DateTime at) =>
    SegmentEffort(
      id: id,
      segmentId: segmentId,
      activityId: 1,
      durationSeconds: seconds,
      avgSpeedKmh: 14.2,
      completedAt: at,
      splitsJson: '[]',
    );

Widget _wrap(Widget child, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(theme: AppTheme.dark, home: child),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('lista: encabezado + panel + tarjeta sin excepción', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const SegmentsListScreen(), [
        segmentsListProvider.overrideWith(
          (ref) => Stream.value([_segment(1, 'Alto de Patios')]),
        ),
        allSegmentEffortsProvider.overrideWith(
          (ref) => Stream.value([
            _effort(1, 1, 1500, DateTime(2026, 8, 20)),
            _effort(2, 1, 1455, DateTime(2026, 8, 27)),
          ]),
        ),
        activitiesListProvider.overrideWith((ref) => Stream.value(const [])),
      ]),
    );
    await tester.pump();

    expect(find.text('Segmentos'), findsOneWidget);
    expect(find.text('Alto de Patios'), findsWidgets);
    expect(find.text('Esfuerzos recientes'.toUpperCase()), findsOneWidget);
    expect(find.text('Activo'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lista: estado vacío con botones', (tester) async {
    await tester.pumpWidget(
      _wrap(const SegmentsListScreen(), [
        segmentsListProvider.overrideWith((ref) => Stream.value(const [])),
        allSegmentEffortsProvider.overrideWith((ref) => Stream.value(const [])),
        activitiesListProvider.overrideWith((ref) => Stream.value(const [])),
      ]),
    );
    await tester.pump();

    expect(find.text('Marca tus tramos favoritos'), findsOneWidget);
    expect(find.text('Explorar segmentos de tu zona'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progreso: se dibuja en modo puntos y en modo línea', (
    tester,
  ) async {
    final efforts = [
      _effort(1, 1, 1600, DateTime(2026, 6, 1)),
      _effort(2, 1, 1540, DateTime(2026, 6, 20)),
      _effort(3, 1, 1490, DateTime(2026, 7, 10)),
      _effort(4, 1, 1455, DateTime(2026, 8, 27)),
    ];
    await tester.pumpWidget(
      _wrap(Scaffold(body: SegmentProgressChart(efforts: efforts)), const []),
    );
    await tester.pump();
    expect(find.text('Puntos'), findsOneWidget);
    expect(find.text('Línea'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Línea'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('detalle: stats + tarjeta de mejor marca + progreso + historial', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const SegmentDetailScreen(segmentId: 1), [
        segmentsListProvider.overrideWith(
          (ref) => Stream.value([_segment(1, 'Alto de Patios')]),
        ),
        segmentEffortsProvider(1).overrideWith(
          (ref) => Stream.value([
            _effort(2, 1, 1455, DateTime(2026, 8, 27)),
            _effort(1, 1, 1500, DateTime(2026, 8, 20)),
          ]),
        ),
      ]),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(find.text('Alto de Patios'), findsWidgets);
    expect(find.textContaining('PROGRESO'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // El historial y la marca están más abajo -- se construyen al hacer scroll.
    await tester.scrollUntilVisible(
      find.text('Mejor marca'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mejor marca'), findsOneWidget);
    expect(find.textContaining('HISTORIAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
