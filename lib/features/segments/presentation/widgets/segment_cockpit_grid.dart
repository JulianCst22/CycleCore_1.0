import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../geospatial/domain/cockpit_tile_packing.dart';
import '../../domain/segment_cockpit_field.dart';
import '../../domain/segment_cockpit_tile_config.dart';
import '../../domain/segment_profile.dart';
import '../segment_cockpit_field_ui.dart';
import 'segment_altitude_profile.dart';
import 'segment_mini_map.dart';

/// Renderiza [tiles] (lo que el usuario eligió para la pantalla de
/// segmento) usando el mismo empaquetado que el cockpit del mapa
/// (`packCockpitTiles`). Cada tile es o un **campo de dato** (número) o
/// un **bloque visual** (mapa / perfil / barra de progreso).
///
/// Sin modo edición -- eso vive en la pantalla de ajustes. Lo usan la
/// vista previa de esa pantalla ([preview] = true, con placeholders
/// para los bloques visuales) y la pantalla de segmento en vivo.
class SegmentCockpitGrid extends StatelessWidget {
  final List<SegmentCockpitTileConfig> tiles;
  final SegmentLiveData data;

  /// Perfil del segmento y tu posición -- necesarios para los bloques
  /// visuales en vivo. `null` en modo [preview].
  final List<SegmentProfilePoint>? profilePoints;
  final latlng.LatLng? currentPosition;

  /// true en la pantalla de ajustes: los bloques visuales (mapa/perfil)
  /// se dibujan como un cartel con su nombre, no como el widget real
  /// (sería pesado y no hay datos reales).
  final bool preview;

  final double spacing;

  const SegmentCockpitGrid({
    super.key,
    required this.tiles,
    required this.data,
    this.profilePoints,
    this.currentPosition,
    this.preview = false,
    this.spacing = 8,
  });

  static const int _columns = 2;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return const Center(
        child: Text(
          'Sin elementos configurados.',
          style: TextStyle(color: AppColors.textSecondaryOnPanel),
        ),
      );
    }

    final packed = packCockpitTiles(
      tiles.map((t) => t.size).toList(),
      columns: _columns,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalRows = packed.totalRows.clamp(1, 999);
        final colWidth =
            (constraints.maxWidth - spacing * (_columns - 1)) / _columns;
        final rowHeight =
            (constraints.maxHeight - spacing * (totalRows - 1)) / totalRows;

        return Stack(
          children: [
            for (final p in packed.tiles)
              Positioned(
                left: p.col * (colWidth + spacing),
                top: p.row * (rowHeight + spacing),
                width: p.colSpan * colWidth + (p.colSpan - 1) * spacing,
                height: p.rowSpan * rowHeight + (p.rowSpan - 1) * spacing,
                child: _Tile(
                  field: tiles[p.tileIndex].field,
                  data: data,
                  profilePoints: profilePoints,
                  currentPosition: currentPosition,
                  preview: preview,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final SegmentCockpitField field;
  final SegmentLiveData data;
  final List<SegmentProfilePoint>? profilePoints;
  final latlng.LatLng? currentPosition;
  final bool preview;

  const _Tile({
    required this.field,
    required this.data,
    required this.profilePoints,
    required this.currentPosition,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    if (field.isVisualBlock) {
      return _VisualBlock(
        field: field,
        data: data,
        profilePoints: profilePoints,
        currentPosition: currentPosition,
        preview: preview,
      );
    }
    return _DataTile(field: field, data: data);
  }
}

class _VisualBlock extends StatelessWidget {
  final SegmentCockpitField field;
  final SegmentLiveData data;
  final List<SegmentProfilePoint>? profilePoints;
  final latlng.LatLng? currentPosition;
  final bool preview;

  const _VisualBlock({
    required this.field,
    required this.data,
    required this.profilePoints,
    required this.currentPosition,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final border = BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: field.color.withValues(alpha: 0.28), width: 1.2),
    );

    // El mapa y el perfil necesitan datos reales; en la vista previa
    // (o si por alguna razón no hay perfil) se muestran como un cartel.
    // La barra de progreso funciona igual con datos de ejemplo.
    final needsPlaceholder = (field == SegmentCockpitField.mapaSegmento ||
            field == SegmentCockpitField.perfilAltimetria) &&
        (preview || profilePoints == null || profilePoints!.length < 2);

    if (needsPlaceholder) {
      return Container(
        decoration: border,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(field.icon, color: field.color, size: 22),
            const SizedBox(height: 6),
            Text(
              field.label,
              style: const TextStyle(
                color: AppColors.textSecondaryOnPanel,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    switch (field) {
      case SegmentCockpitField.mapaSegmento:
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LayoutBuilder(
            builder: (context, c) => SegmentMiniMap(
              profilePoints: profilePoints!,
              currentPosition: currentPosition,
              height: c.maxHeight,
            ),
          ),
        );
      case SegmentCockpitField.perfilAltimetria:
        return Container(
          decoration: border,
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (context, c) => SegmentAltitudeProfile(
              points: profilePoints!,
              progress: data.progressFraction,
              height: c.maxHeight - 16,
            ),
          ),
        );
      case SegmentCockpitField.barraProgreso:
        return Container(
          decoration: border,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: data.progressFraction,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.segmentActiveTrack,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Faltan ${formatDistanceKm(data.remainingMeters)} km',
                    style: const TextStyle(
                      color: AppColors.textSecondaryOnPanel,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '+${data.remainingElevationGainMeters.toStringAsFixed(0)} m',
                    style: const TextStyle(
                      color: AppColors.textSecondaryOnPanel,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _DataTile extends StatelessWidget {
  final SegmentCockpitField field;
  final SegmentLiveData data;

  const _DataTile({required this.field, required this.data});

  @override
  Widget build(BuildContext context) {
    final d = field.display(data);
    return LayoutBuilder(
      builder: (context, constraints) {
        final valueFontSize = (constraints.maxHeight * 0.34).clamp(16.0, 56.0);
        final labelFontSize = (constraints.maxHeight * 0.09).clamp(9.0, 13.0);
        final unitFontSize = (constraints.maxHeight * 0.11).clamp(10.0, 16.0);
        final iconSize = (constraints.maxHeight * 0.12).clamp(13.0, 20.0);
        final padding = (constraints.maxHeight * 0.09).clamp(7.0, 18.0);

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: d.color.withValues(alpha: 0.28),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(d.icon, size: iconSize, color: d.color),
                  SizedBox(width: iconSize * 0.35),
                  Flexible(
                    child: Text(
                      d.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        d.value,
                        style: TextStyle(
                          color: AppColors.textPrimaryOnPanel,
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  if (d.unit.isNotEmpty) ...[
                    SizedBox(width: padding * 0.4),
                    Text(
                      d.unit,
                      style: TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: unitFontSize,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Datos de ejemplo plausibles para la vista previa de la pantalla de
/// ajustes -- así el usuario ve cómo queda el layout con números
/// reales, sin necesidad de estar dentro de un segmento.
SegmentLiveData sampleSegmentLiveData() {
  return const SegmentLiveData(
    elapsedInSegment: Duration(minutes: 4, seconds: 12),
    alongMeters: 2400,
    remainingMeters: 1520,
    totalMeters: 3920,
    progressFraction: 0.61,
    remainingElevationGainMeters: 92,
    currentSlopePercent: 7.4,
    avgSegmentSlopePercent: 6.1,
    currentSpeedKmh: 14.8,
    avgSpeedInSegmentKmh: 15.6,
    currentAltitudeMeters: 2712,
    heartRateBpm: 156,
    powerWatts: 243,
    cadenceRpm: 82,
    deltaVsPr: Duration(seconds: -7),
    projectedFinish: Duration(minutes: 6, seconds: 48),
    bestTime: Duration(minutes: 6, seconds: 55),
  );
}
