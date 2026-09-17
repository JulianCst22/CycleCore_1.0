import 'package:core_ui/core_ui.dart';
import 'package:cyclecore_app/features/recording/domain/recording_snapshot.dart';
import 'package:cyclecore_app/features/recording/domain/route_point.dart';
import 'package:cyclecore_app/features/recording/presentation/recording_recovery_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _start = DateTime(2026, 9, 12, 7, 5);

RecordingSnapshot _snapshot({DateTime? endedAt}) {
  JournalPoint point(int minute, double distance) => JournalPoint(
    point: RoutePoint(
      latitude: 4.7,
      longitude: -74.0,
      altitude: 2500,
      speedMetersPerSecond: 7,
      bearingDegrees: 0,
      accuracyMeters: 4,
      timestamp: _start.add(Duration(minutes: minute)),
    ),
    distanceMeters: distance,
    speedKmh: 25,
  );

  return RecordingSnapshot(
    sessionId: 1,
    startedAt: _start,
    movingTime: const Duration(minutes: 52, seconds: 10),
    isPaused: false,
    endedAt: endedAt,
    points: [point(0, 0), point(57, 23410)],
  );
}

/// Abre el diálogo desde un botón y deja la elección en [onResult].
Future<void> _open(
  WidgetTester tester,
  RecordingSnapshot snapshot,
  void Function(RecordingRecoveryChoice?) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async =>
                onResult(await showRecordingRecoveryDialog(context, snapshot)),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('grabación sin terminar: muestra lo guardado y ofrece seguir', (
    tester,
  ) async {
    RecordingRecoveryChoice? result;
    await _open(tester, _snapshot(), (c) => result = c);

    expect(find.text('Tu recorrido sigue aquí'), findsOneWidget);
    expect(find.textContaining('hasta las 08:02'), findsOneWidget);
    expect(find.text('23.41'), findsOneWidget);
    expect(find.text('52:10'), findsOneWidget);
    expect(find.text('07:05'), findsOneWidget);
    expect(find.text('Terminar y guardar'), findsOneWidget);

    await tester.tap(find.text('Seguir grabando'));
    await tester.pumpAndSettle();

    expect(result, RecordingRecoveryChoice.resume);
    expect(find.byType(RecordingRecoveryDialog), findsNothing);
  });

  testWidgets('grabación ya terminada: solo guardar o descartar', (
    tester,
  ) async {
    RecordingRecoveryChoice? result;
    await _open(
      tester,
      _snapshot(endedAt: _start.add(const Duration(hours: 1))),
      (c) => result = c,
    );

    expect(find.text('Tu actividad te está esperando'), findsOneWidget);
    expect(find.text('Seguir grabando'), findsNothing);

    await tester.tap(find.text('Guardar actividad'));
    await tester.pumpAndSettle();

    expect(result, RecordingRecoveryChoice.save);
  });

  testWidgets('no se cierra con "atrás"', (tester) async {
    await _open(tester, _snapshot(), (_) {});

    final popped = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(find.byType(RecordingRecoveryDialog), findsOneWidget);
  });

  testWidgets('descartar pide confirmación y arrepentirse vuelve atrás', (
    tester,
  ) async {
    RecordingRecoveryChoice? result;
    await _open(tester, _snapshot(), (c) => result = c);

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar el recorrido?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.byType(RecordingRecoveryDialog), findsOneWidget);

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar').last);
    await tester.pumpAndSettle();

    expect(result, RecordingRecoveryChoice.discard);
    expect(find.byType(RecordingRecoveryDialog), findsNothing);
  });
}
