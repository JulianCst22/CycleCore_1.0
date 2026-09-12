import 'package:flutter/material.dart';

import 'package:cyclecore_core/theme/cyclecore_palette.dart';

/// Modo de seguimiento/orientación del mapa -- un solo eje de estado
/// para el control unificado.
enum MapFollowMode {
  /// El mapa no sigue tu posición (paneaste a mano). El botón invita a
  /// recentrar.
  free,

  /// El mapa sigue tu posición, "norte arriba".
  followNorthUp,

  /// El mapa sigue tu posición y rota para que tu rumbo quede hacia
  /// arriba (como en navegación).
  followHeadingUp,
}

/// Control de mapa unificado, estilo Google Maps / Waze: **un solo
/// botón** combina "recentrar", "seguir mi ubicación" y la brújula
/// (norte arriba / rumbo arriba).
///
/// Reemplaza los dos botones separados que había antes (`_CompassButton`
/// arriba a la izquierda + `_RecenterButton` a la derecha). Vive en
/// `shared_widgets` para ser EL control de cualquier pantalla con un
/// mapa en vivo, no solo la del mapa principal.
///
/// - **free** → ícono de recentrar. Tap: recentra y empieza a seguir.
/// - **followNorthUp** → ícono de ubicación. Tap: pasa a "rumbo arriba".
/// - **followHeadingUp** → ícono de navegación. Tap: vuelve a "norte
///   arriba".
///
/// La aguja de la brújula del ícono siempre contra-rota
/// [mapRotationDegrees], así que en cualquier estado señala el norte
/// real cuando el mapa está girado. Long-press: fuerza norte arriba +
/// seguir (reset rápido).
class MapControlsCluster extends StatelessWidget {
  final MapFollowMode mode;
  final double mapRotationDegrees;

  /// free → seguir (norte arriba). El llamador mueve la cámara.
  final VoidCallback onRecenter;

  /// followNorthUp ↔ followHeadingUp.
  final VoidCallback onToggleHeading;

  /// Long-press: norte arriba + seguir.
  final VoidCallback onResetNorthFollow;

  const MapControlsCluster({
    super.key,
    required this.mode,
    required this.mapRotationDegrees,
    required this.onRecenter,
    required this.onToggleHeading,
    required this.onResetNorthFollow,
  });

  bool get _following => mode != MapFollowMode.free;

  IconData get _icon {
    switch (mode) {
      case MapFollowMode.free:
        return Icons.location_searching;
      case MapFollowMode.followNorthUp:
        return Icons.my_location;
      case MapFollowMode.followHeadingUp:
        return Icons.navigation;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _following;
    return Material(
      color: active
          ? CyclecorePalette.ubicacionActiva
          : Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: mode == MapFollowMode.free ? onRecenter : onToggleHeading,
        onLongPress: onResetNorthFollow,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Transform.rotate(
            // "navigation" ya apunta al rumbo (arriba) en heading-up; en
            // los otros modos la aguja contra-rota para señalar el norte
            // real cuando el mapa está girado a mano.
            angle: mode == MapFollowMode.followHeadingUp
                ? 0
                : -mapRotationDegrees * (3.14159265 / 180),
            child: Icon(
              _icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
