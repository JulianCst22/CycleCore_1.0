import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:core_ui/core_ui.dart';

import 'app/app_gate.dart';
import 'features/activities/activities.dart';
import 'features/profile/profile.dart';
import 'features/gamification/gamification.dart';
import 'features/voice/voice.dart';

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
    // Los overrides conectan los puntos de extensión de `gamification` y
    // `profile` (sus `extension_points.dart`) con las implementaciones
    // reales de `voice`, `activities` y `profile` -- este es el ÚNICO
    // lugar de toda la app que conoce a ambos lados. Esas features no se
    // importan entre sí en ese sentido.
    ProviderScope(
      overrides: [
        unlockCelebrationSourcesProvider.overrideWithValue(
          [checkVoiceUnlockCelebration],
        ),
        wardrobeExtraTabsProvider.overrideWithValue([voiceWardrobeTab]),
        unseenUnlockIndicatorsProvider.overrideWithValue(
          [voiceHasUnseenUnlocksProvider],
        ),
        openActivityDetailProvider.overrideWithValue(openActivityDetail),
        riderNameProvider.overrideWith(
          (ref) => ref.watch(profileProvider).valueOrNull?.name,
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
      // Todo el theming vive en el módulo core_ui -- los tokens de color
      // están en cc_colors.dart y la tipografía en cc_type.dart. La app es
      // oscura a propósito (uso al aire libre).
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      // AppGate decide entre Onboarding y AppShell según exista perfil
      // local. Ver lib/app/app_gate.dart.
      home: const AppGate(),
    );
  }
}