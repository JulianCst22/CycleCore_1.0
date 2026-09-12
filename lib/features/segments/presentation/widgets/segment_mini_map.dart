import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import 'package:cyclecore_core/theme/app_colors.dart';
import '../../domain/segment_profile.dart';

/// Mapa estático (sin arrastre de marcadores) con la polilínea
/// congelada de un segmento y banderas fijas A/B. Se usa en el detalle
/// del segmento y en la previsualización de import. Opcionalmente
/// dibuja un marcador de posición actual (Fase D).
class SegmentMiniMap extends StatelessWidget {
  final List<SegmentProfilePoint> profilePoints;
  final latlng.LatLng? currentPosition;
  final double height;

  const SegmentMiniMap({
    super.key,
    required this.profilePoints,
    this.currentPosition,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final latLngs = profilePoints
        .map((p) => latlng.LatLng(p.latitude, p.longitude))
        .toList();

    if (latLngs.length < 2) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No hay trazado disponible para este segmento.',
            style: TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ),
      );
    }

    final bounds = LatLngBounds.fromPoints(latLngs);

    return SizedBox(
      height: height,
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(36),
          ),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.cyclecore_app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: latLngs,
                strokeWidth: 5,
                color: AppColors.primary,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: latLngs.first,
                width: 32,
                height: 32,
                child: const _EndpointDot(
                  label: 'A',
                  color: AppColors.segmentStart,
                ),
              ),
              Marker(
                point: latLngs.last,
                width: 32,
                height: 32,
                child: const _EndpointDot(
                  label: 'B',
                  color: AppColors.segmentEnd,
                ),
              ),
              if (currentPosition != null)
                Marker(
                  point: currentPosition!,
                  width: 26,
                  height: 26,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.segmentActiveTrack,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EndpointDot extends StatelessWidget {
  final String label;
  final Color color;

  const _EndpointDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
