import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/cyclecore_palette.dart';

/// Barra de navegación inferior fija -- reemplaza las píldoras
/// flotantes de utilidad que antes vivían arriba del mapa (sensores,
/// actividades, seguir ubicación, perfil). Deja el mapa despejado
/// arriba (solo queda el estado de grabación) y agrupa TODA la
/// navegación secundaria en un solo lugar predecible, como cualquier
/// app de referencia (no solo Garmin: Strava, Wahoo también usan
/// barra inferior fija).
///
/// `onToggleFollowMe` se muestra resaltado en Páramo cuando está
/// activo -- es el único ítem que no navega a otra pantalla, así que
/// se distingue visualmente del resto (que sí empujan una ruta nueva).
class CockpitBottomNavBar extends StatelessWidget {
  final bool isFollowingMe;
  final VoidCallback onToggleFollowMe;
  final VoidCallback onOpenSensors;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenProfile;

  const CockpitBottomNavBar({
    super.key,
    required this.isFollowingMe,
    required this.onToggleFollowMe,
    required this.onOpenSensors,
    required this.onOpenActivities,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CyclecorePalette.panel,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavBarItem(
                icon: Icons.sensors,
                label: 'Sensores',
                onTap: onOpenSensors,
              ),
              _NavBarItem(
                icon: Icons.list_alt,
                label: 'Actividad',
                onTap: onOpenActivities,
              ),
              _NavBarItem(
                icon: isFollowingMe
                    ? Icons.my_location
                    : Icons.location_searching,
                label: 'Ubicación',
                active: isFollowingMe,
                onTap: onToggleFollowMe,
              ),
              _NavBarItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                onTap: onOpenProfile,
              ),
            ],
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
