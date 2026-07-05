import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cyclecore_app/main.dart';

void main() {
  testWidgets('CycleCoreApp arranca y muestra el AppBar del mapa',
      (WidgetTester tester) async {
    // ProviderScope es obligatorio para envolver la app en los tests,
    // igual que en main().
    await tester.pumpWidget(
      const ProviderScope(
        child: CycleCoreApp(),
      ),
    );

    // No esperamos a que resuelva el GPS real (no existe en el entorno
    // de test), solo verificamos que el Scaffold y el título cargan.
    expect(find.text('CycleCore — Mapa de ruta'), findsOneWidget);
  });
}