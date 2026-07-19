import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/cyclecore_palette.dart';

/// Barra de navegación inferior global de la app.
///
/// Vive en `shared_widgets` (no en ninguna feature puntual) porque la
/// consume `AppShell`, que la renderiza una sola vez por encima de las
/// 4 secciones principales (Mapa, Sensores, Actividad, Perfil).
///
/// A diferencia de la versión anterior (`CockpitBottomNavBar`, que
/// vivía dentro de la feature de mapa y navegaba con `Navigator.push`
/// a cada sección desde ahí), esta versión es "tonta": solo reporta
/// qué índice se tocó vía `onTap`. El cambio de pantalla real lo
/// maneja `AppShell` con un `IndexedStack`, para que cada sección
/// mantenga su estado vivo al cambiar de pestaña (el mapa no reinicia
/// su cámara/`MapController` al ir a Actividades y volver).
///
/// El toggle de "seguir mi ubicación" que antes vivía aquí ya NO es un
/// ítem de esta barra -- no es una sección de la app, es una acción
/// contextual del mapa (ver botón flotante "recentrar" en
/// `MapScreen`), igual que en Google Maps/Waze.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Mapa'),
    (icon: Icons.sensors, activeIcon: Icons.sensors, label: 'Sensores'),
    (icon: Icons.list_alt, activeIcon: Icons.list_alt, label: 'Actividad'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CyclecorePalette.panel,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final active = index == currentIndex;
              return _NavBarItem(
                icon: active ? item.activeIcon : item.icon,
                label: item.label,
                active: active,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? CyclecorePalette.paramo : AppColors.textSecondaryOnPanel;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
