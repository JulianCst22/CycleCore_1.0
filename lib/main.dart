import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/geospatial/presentation/map_screen.dart';

void main() {
  runApp(
    // ProviderScope debe envolver toda la app para que Riverpod funcione
    // en cualquier pantalla, sin importar qué tan anidada esté.
    const ProviderScope(
      child: CycleCoreApp(),
    ),
  );
}

class CycleCoreApp extends StatelessWidget {
  const CycleCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CycleCore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      // Por ahora abrimos directo en el mapa para probar esta primera
      // pieza. Más adelante esto pasa a ser la pantalla post-login.
      home: const MapScreen(),
    );
  }
}
