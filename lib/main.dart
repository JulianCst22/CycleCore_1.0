import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:cyclecore_core/theme/app_theme.dart';

import 'app/app_gate.dart';
import 'features/profile/presentation/extension_points.dart';
import 'features/voice/presentation/voice_profile_extension_points.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Necesario para que DateFormat(..., 'es') funcione en el historial de
  // actividades (nombres de meses/días en español). Sin esto, tira una
  // LocaleDataException la primera vez que se formatea una fecha.
  await initializeDateFormatting('es');

  runApp(
    // ProviderScope debe envolver toda la app para que Riverpod funcione
    // en cualquier pantalla, sin importar qué tan anidada esté.
    //
    // Los overrides conectan los puntos de extensión de `profile` (ver
    // extension_points.dart) con la implementación real de `voice` --
    // este es el ÚNICO lugar de toda la app donde algo importa a la vez
    // profile y voice para esto. Ni profile ni voice se importan entre
    // sí directamente.
    ProviderScope(
      overrides: [
        unlockCelebrationSourcesProvider.overrideWithValue(
          [checkVoiceUnlockCelebration],
        ),
        wardrobeExtraTabsProvider.overrideWithValue([voiceWardrobeTab]),
        unseenUnlockIndicatorsProvider.overrideWithValue(
          [voiceHasUnseenUnlocksProvider],
        ),
      ],
      child: const CycleCoreApp(),
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
      // Todo el theming vive en core/theme -- los tokens de color están
      // en cc_colors.dart y la tipografía en cc_type.dart. La app es
      // oscura a propósito (uso al aire libre).
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      // AppGate decide entre Onboarding y AppShell según exista perfil
      // local. Ver core/navigation/app_gate.dart.
      home: const AppGate(),
    );
  }
}