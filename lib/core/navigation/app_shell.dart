import 'package:flutter/material.dart';

import '../../features/geospatial/presentation/map_screen.dart';
import '../../features/activities/presentation/activities_list_screen.dart';
import '../../features/sensors/presentation/sensors_screen.dart';
import '../../features/profile/presentation/onboarding_screen.dart';
import '../../shared_widgets/app_bottom_nav_bar.dart';
import '../theme/app_colors.dart';

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
/// Cada sección (`MapScreen`, `SensorsScreen`, etc.) conserva su
/// propio `Scaffold` interno -- eso es intencional y no genera
/// conflicto: un `Scaffold` anidado dentro del `body` de otro
/// `Scaffold` es un patrón normal en Flutter: cada uno pinta su fondo
/// y su propio `AppBar` dentro del área que le da este shell.
///
/// El orden de `_screens` debe coincidir exactamente con el orden de
/// ítems de `AppBottomNavBar` (Mapa, Sensores, Actividad, Perfil).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _screens = [
    MapScreen(),
    SensorsScreen(),
    ActivitiesListScreen(),
    OnboardingScreen(isEditing: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
