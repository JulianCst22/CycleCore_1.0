import 'package:cyclecore_app/core/providers/heart_rate_provider.dart';
import 'package:cyclecore_app/features/sensors/presentation/power_providers.dart';
import 'package:cyclecore_app/features/sensors/presentation/sensors_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('pinta el resumen y los 4 slots sin excepción', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SensorsScreen())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sensores'), findsOneWidget);
    expect(find.text('Frecuencia cardíaca'), findsOneWidget);
    expect(find.text('Potencia'), findsOneWidget);
    expect(find.text('Velocidad'), findsOneWidget);
    expect(find.text('Cadencia'), findsOneWidget);
    expect(find.text('Ningún sensor conectado'), findsOneWidget);
    expect(find.text('Sin conectar'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('el resumen cuenta los sensores con lectura en vivo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heartRateBpmProvider.overrideWith((ref) => 148),
          powerWattsProvider.overrideWith((ref) => 210),
        ],
        child: const MaterialApp(home: SensorsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // El resumen ("N de 4 listos") sólo cuenta sensores CONECTADOS, no
    // el mero valor del provider -- aquí ninguno está conectado.
    expect(find.text('Ningún sensor conectado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
