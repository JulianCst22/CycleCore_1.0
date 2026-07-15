import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'features/geospatial/presentation/map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Necesario para que DateFormat(..., 'es') funcione en el historial de
  // actividades (nombres de meses/días en español). Sin esto, tira una
  // LocaleDataException la primera vez que se formatea una fecha.
  await initializeDateFormatting('es');

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
      // Todo el theming vive en core/theme -- cambiar colores de marca
      // se hace en app_colors.dart, no aquí.
      theme: AppTheme.light,
      home: const MapScreen(),
    );
  }
}
