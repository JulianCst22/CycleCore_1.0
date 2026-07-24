import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../../core/theme/app_colors.dart';
import '../../domain/activity_summary.dart';

/// Fondo "hero" para la tarjeta grande de actividad -- muestra el
/// mapa real (tiles de OpenStreetMap) con la ruta dibujada encima en
/// el color del tipo de actividad, igual que en la pantalla de
/// grabación.
///
/// El mapa es NO interactivo (sin gestos) porque vive dentro de un
/// `PageView` horizontal en una lista scrolleable -- si aceptara
/// gestos, competiría con el swipe del carrusel y con el scroll de
/// la lista. Es solo una "vista previa" fija, encuadrada
/// automáticamente para mostrar toda la ruta.
class RouteHeroBackground extends StatelessWidget {
  final List<RoutePointSnapshot> points;
  final Color accentColor;

  const RouteHeroBackground({
    super.key,
    required this.points,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        color: AppColors.panelBackground,
        child: Center(
          child: Icon(
            Icons.directions_bike,
            size: 42,
            color: accentColor.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final routeLatLngs =
        points.map((p) => latlng.LatLng(p.latitude, p.longitude)).toList();

    return IgnorePointer(
      // Bloquea cualquier gesto sobre el mapa -- ver nota de la clase.
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: routeLatLngs.length > 1
              ? CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(routeLatLngs),
                  padding: const EdgeInsets.all(28),
                )
              : CameraFit.coordinates(
                  coordinates: routeLatLngs,
                  padding: const EdgeInsets.all(28),
                  minZoom: 15,
                  maxZoom: 16,
                ),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.cyclecore_app',
          ),
          if (routeLatLngs.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routeLatLngs,
                  strokeWidth: 5,
                  color: accentColor,
                  borderStrokeWidth: 2,
                  borderColor: Colors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              Marker(
                point: routeLatLngs.first,
                width: 16,
                height: 16,
                child: _EndpointDot(
                  fillColor: Colors.white,
                  borderColor: accentColor,
                ),
              ),
              if (routeLatLngs.length > 1)
                Marker(
                  point: routeLatLngs.last,
                  width: 14,
                  height: 14,
                  child: _EndpointDot(
                    fillColor: accentColor,
                    borderColor: Colors.white,
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
  final Color fillColor;
  final Color borderColor;

  const _EndpointDot({required this.fillColor, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}