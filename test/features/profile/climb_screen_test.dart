import 'package:cyclecore_core/database/app_database.dart';
import 'package:cyclecore_app/features/activities/presentation/activities_providers.dart';
import 'package:cyclecore_app/features/profile/domain/activity_climb_result.dart';
import 'package:cyclecore_app/features/profile/domain/level_info.dart';
import 'package:cyclecore_app/features/profile/presentation/climb_screen.dart';
import 'package:cyclecore_app/features/profile/presentation/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// XP total ~ nivel 12 (Escalador): `150 * (12 - 1)^2 = 18 150`.
const _escaladorXp = 20000;

int _xpForLevel(int level) => LevelCalculator.cumulativeXpToReach(level);

Widget _wrap({
  int totalXp = _escaladorXp,
  CyclistRank? focusRank,
  ActivityClimbResult? result,
}) {
  return ProviderScope(
    overrides: [
      effectiveTotalXpProvider.overrideWithValue(AsyncValue.data(totalXp)),
      activitiesListProvider.overrideWith(
        (ref) => Stream.value(const <Activity>[]),
      ),
    ],
    child: MaterialApp(
      home: ClimbScreen(focusRank: focusRank, activityResult: result),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('la vista de cámara detrás del ciclista se pinta sin explotar', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(ClimbScreen), findsOneWidget);
    expect(find.textContaining('NIVEL 12'), findsOneWidget);
    expect(find.textContaining('ESCALADOR'), findsOneWidget);
    expect(find.text('Mi progreso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entrar enfocando un rango planta la cámara en ese tramo', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(focusRank: CyclistRank.fondista));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.textContaining('FONDISTA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('modo post-actividad: muestra la XP ganada y el botón Seguir', (
    tester,
  ) async {
    final result = computeActivityClimbResult(
      totalXpBefore: _xpForLevel(12) + 200,
      totalXpAfter: _xpForLevel(12) + 900,
    );
    await tester.pumpWidget(
      _wrap(totalXp: _xpForLevel(12) + 900, result: result),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(find.textContaining('XP'), findsWidgets);
    expect(find.text('Seguir'), findsOneWidget);
    expect(find.textContaining('Alto de Patios'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cruzar un arco de rango dispara la cinemática sin explotar', (
    tester,
  ) async {
    // Nivel 8 -> 11: cruza el arco de rango del nivel 10 (Escalador).
    final result = computeActivityClimbResult(
      totalXpBefore: _xpForLevel(8) + 100,
      totalXpAfter: _xpForLevel(11) + 100,
    );
    await tester.pumpWidget(
      _wrap(totalXp: _xpForLevel(11) + 100, result: result),
    );
    await tester.pump();
    // Deja correr la subida + la cinemática + el festejo.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(ClimbScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Mi progreso" abre el popup con la altimetría real', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.text('Mi progreso'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Tu progreso'), findsOneWidget);
    expect(find.textContaining('POSTALES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
