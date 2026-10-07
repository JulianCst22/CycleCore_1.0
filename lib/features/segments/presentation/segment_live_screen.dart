import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo.dart';
import '../../../core/ui/ui.dart';
import '../application/extension_points.dart';
import '../application/segment_cockpit_layout_providers.dart';
import '../application/segment_detection_providers.dart';
import '../application/segment_live_data_provider.dart';
import '../data/segment_cockpit_layout_repository.dart';
import '../domain/segment_cockpit_field.dart';
import '../domain/segment_cockpit_tile_config.dart';
import 'segment_data_settings_screen.dart';
import 'widgets/segment_cockpit_grid.dart';
import 'widgets/segment_route_header.dart';

/// Pantalla de segmento en vivo. Ocupa el lugar del cockpit de pantalla
/// completa (`CockpitFullscreenView`) en el panel deslizable del mapa
/// mientras el ciclista está dentro de un segmento vigilado.
///
/// Tres bloques, de arriba abajo y por orden de importancia:
///  1. dónde vas en el tramo (`SegmentRouteHeader`, siempre visible);
///  2. qué te pide el coach, en una franja (punto de extensión
///     `segmentLiveNoticeProvider`);
///  3. tus datos, los que elegiste en Ajustes → "Datos del segmento".
///
/// Antes el mapa, el perfil y la barra de progreso eran recuadros sueltos
/// de la cuadrícula, y el coach una tarjeta grande con notas al pie: la
/// pantalla quedaba tan cargada que no se leía pedaleando.
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
      return const Material(color: CcColors.surface, child: SizedBox.shrink());
    }

    final tiles = [
      for (final t
          in ref.watch(segmentCockpitLayoutProvider).valueOrNull ??
              SegmentCockpitLayoutRepository.defaultTiles)
        if (!t.field.isVisualBlock) t,
    ];
    final notice = ref.watch(segmentLiveNoticeProvider);

    return SegmentLiveView(
      segmentName: active.segment.name,
      profilePoints: active.profile.points,
      data: data,
      tiles: tiles,
      notice: notice,
      onCollapse: onCollapse,
      onEditData: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SegmentDataSettingsScreen()),
      ),
    );
  }
}

/// La pantalla de segmento ya con sus datos: sin providers, para que se
/// pueda dibujar igual en la salida y en una vista previa.
class SegmentLiveView extends StatelessWidget {
  final String segmentName;
  final List<SegmentProfilePoint> profilePoints;
  final SegmentLiveData data;
  final List<SegmentCockpitTileConfig> tiles;

  /// La franja del coach (punto de extensión), si la hay.
  final Widget? notice;
  final VoidCallback onCollapse;
  final VoidCallback onEditData;

  const SegmentLiveView({
    super.key,
    required this.segmentName,
    required this.profilePoints,
    required this.data,
    required this.tiles,
    required this.notice,
    required this.onCollapse,
    required this.onEditData,
  });

  @override
  Widget build(BuildContext context) {
    final notice = this.notice;
    return Material(
      color: CcColors.surface,
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
                padding: const EdgeInsets.fromLTRB(14, 2, 4, 0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CcColors.inkFaint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.flag,
                      size: 15,
                      color: CcColors.segmentActiveTrack,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        segmentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CcType.label(size: 14, color: CcColors.ink),
                      ),
                    ),
                    Text(
                      formatElapsedShort(data.elapsedInSegment),
                      style:
                          CcType.displayStyle(
                            size: 15,
                            weight: FontWeight.w700,
                          ).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.tune,
                        color: CcColors.inkDim,
                        size: 20,
                      ),
                      tooltip: 'Elegir qué datos se ven',
                      onPressed: onEditData,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: SegmentRouteHeader(points: profilePoints, data: data),
            ),
            if (notice != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: notice,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: tiles.isEmpty
                    ? _EmptyGridHint(onEdit: onEditData)
                    : SegmentCockpitGrid(tiles: tiles, data: data),
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
          Text(
            'No elegiste datos para ver acá.',
            style: CcType.label(size: 13, color: CcColors.inkDim),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onEdit, child: const Text('Elegir datos')),
        ],
      ),
    );
  }
}
