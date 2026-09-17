import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/activities/activities.dart';
import '../features/profile/profile.dart';
import '../features/ride/ride.dart';
import '../features/segments/segments.dart';
import 'app_bottom_nav_bar.dart';
import 'app_tab_provider.dart';
import 'settings_screen.dart';

/// Shell de navegación raíz de la app -- reemplaza la navegación
/// anterior basada en `Navigator.push` desde adentro de `RideScreen`.
///
/// Usa `IndexedStack` (no `Navigator`) para que las 4 secciones
/// principales mantengan su estado vivo al cambiar de pestaña: el
/// mapa no pierde su `MapController` ni su posición de cámara al
/// entrar a Actividades y volver, un formulario a medio llenar en
/// Perfil no se resetea, etc. `IndexedStack` construye las 4 una sola
/// vez y solo cambia cuál es visible.
///
/// Cada sección (`RideScreen`, `SegmentsListScreen`, etc.) conserva su
/// propio `Scaffold` interno -- eso es intencional y no genera
/// conflicto: un `Scaffold` anidado dentro del `body` de otro
/// `Scaffold` es un patrón normal en Flutter: cada uno pinta su fondo
/// y su propio `AppBar` dentro del área que le da este shell.
///
/// El orden de las pantallas debe coincidir exactamente con el orden de
/// ítems de `AppBottomNavBar` (Mapa, Segmentos, Actividad, Perfil).
///
/// También es el punto de composición de las pestañas: las features no
/// conocen la capa `app`, así que lo que cruza de una pestaña a otra
/// (ir a Actividad desde Segmentos, abrir Ajustes desde Perfil) se
/// inyecta acá como callback.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _activitiesTab = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(appTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          const RideScreen(),
          SegmentsListScreen(
            onBrowseActivities: () =>
                ref.read(appTabIndexProvider.notifier).state = _activitiesTab,
          ),
          const ActivitiesListScreen(),
          ProfileScreen(settingsScreenBuilder: (_) => const SettingsScreen()),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(appTabIndexProvider.notifier).state = index,
      ),
    );
  }
}
