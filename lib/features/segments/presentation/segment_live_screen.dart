import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlng;

import 'package:cyclecore_core/theme/app_colors.dart';
import 'package:cyclecore_core/theme/cyclecore_palette.dart';
import '../data/segment_cockpit_layout_repository.dart';
import 'segment_cockpit_layout_providers.dart';
import 'segment_data_settings_screen.dart';
import 'segment_detection_providers.dart';
import 'segment_live_data_provider.dart';
import 'widgets/segment_cockpit_grid.dart';

/// Pantalla de segmento en vivo (Fase D). Ocupa el lugar del cockpit de
/// pantalla completa (`CockpitFullscreenView`) en el panel deslizable
/// del mapa mientras el ciclista está dentro de un segmento vigilado.
///
/// **Todo es configurable** desde Perfil → Ajustes → "Datos del
/// segmento": el mapa con la polilínea, el perfil de altimetría, la
/// barra de progreso y cada dato numérico son elementos que el usuario
/// puede poner, quitar, reordenar y redimensionar. Esta pantalla solo
/// pone la manija de arriba y deja que la grilla haga el resto.
class SegmentLiveScreen extends ConsumerWidget {
  /// El panel deslizable del mapa pide colapsarse por acá cuando el
  /// usuario arrastra hacia abajo la franja de arriba.
  final VoidCallback onCollapse;

  const SegmentLiveScreen({super.key, required this.onCollapse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(segmentDetectionProvider).active;
    final data = ref.watch(segmentLiveDataProvider);

    if (active == null || data == null) {
      return const Material(
        color: AppColors.panelBackground,
        child: SizedBox.shrink(),
      );
    }

    final profilePoints = active.profile.points;
    final pos = active.profile.positionAtDistance(data.alongMeters);
    final currentLatLng =
        pos == null ? null : latlng.LatLng(pos.lat, pos.lng);

    final tiles = ref.watch(segmentCockpitLayoutProvider).valueOrNull ??
        SegmentCockpitLayoutRepository.defaultTiles;

    return Material(
      color: AppColors.panelBackground,
      child: SafeArea(
        child: Column(
          children: [
            // --- Franja de arriba: manija + nombre + editar datos.
            // Solo esta franja escucha el gesto de deslizar hacia abajo
            // para cerrar (mismo criterio que CockpitFullscreenView).
            GestureDetector(
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > 200) onCollapse();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondaryOnPanel
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        active.segment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimaryOnPanel,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.tune,
                        color: AppColors.textSecondaryOnPanel,
                        size: 20,
                      ),
                      tooltip: 'Editar qué se ve acá',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SegmentDataSettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: tiles.isEmpty
                    ? _EmptyGridHint(
                        onEdit: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SegmentDataSettingsScreen(),
                          ),
                        ),
                      )
                    : SegmentCockpitGrid(
                        tiles: tiles,
                        data: data,
                        profilePoints: profilePoints,
                        currentPosition: currentLatLng,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGridHint extends StatelessWidget {
  final VoidCallback onEdit;
  const _EmptyGridHint({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No configuraste nada para ver acá.',
            style: TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onEdit,
            child: const Text(
              'Elegir qué mostrar',
              style: TextStyle(color: CyclecorePalette.paramo),
            ),
          ),
        ],
      ),
    );
  }
}
