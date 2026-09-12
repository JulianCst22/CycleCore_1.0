import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/navigation/navigation_providers.dart';

import '../features/activities/presentation/activities_list_screen.dart';
import '../features/geospatial/presentation/map_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/segments/presentation/segments_list_screen.dart';
import '../shared_widgets/app_bottom_nav_bar.dart';

/// Shell de navegación raíz de la app -- reemplaza la navegación
/// anterior basada en `Navigator.push` desde adentro de `MapScreen`.
///
/// Usa `IndexedStack` (no `Navigator`) para que las 4 secciones
/// principales mantengan su estado vivo al cambiar de pestaña: el
/// mapa no pierde su `MapController` ni su posición de cámara al
/// entrar a Actividades y volver, un formulario a medio llenar en
/// Perfil no se resetea, etc. `IndexedStack` construye las 4 una sola
/// vez y solo cambia cuál es visible.
///
/// Cada sección (`MapScreen`, `SegmentsListScreen`, etc.) conserva su
/// propio `Scaffold` interno -- eso es intencional y no genera
/// conflicto: un `Scaffold` anidado dentro del `body` de otro
/// `Scaffold` es un patrón normal en Flutter: cada uno pinta su fondo
/// y su propio `AppBar` dentro del área que le da este shell.
///
/// El orden de `_screens` debe coincidir exactamente con el orden de
/// ítems de `AppBottomNavBar` (Mapa, Segmentos, Actividad, Perfil).
///
/// La pestaña activa vive en [appTabIndexProvider] (no en `setState`)
/// para que otras pantallas puedan cambiarla -- ver el botón "grabar"
/// de `ActivitiesListScreen`.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = [
    MapScreen(),
    SegmentsListScreen(),
    ActivitiesListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(appTabIndexProvider);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(appTabIndexProvider.notifier).state = index,
      ),
    );
  }
}
