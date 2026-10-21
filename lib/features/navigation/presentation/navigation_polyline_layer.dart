import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/ui/ui.dart';
import '../domain/navigation_route.dart';
import '../domain/route_progress.dart';

/// Devuelve las capas de `flutter_map` para dibujar la ruta sugerida:
/// una polilínea (para distinguirla del trazado grabado -- naranja -- y
/// del segmento en vivo -- turquesa -- va en verde, ver
/// [CcColors.route]) más un marcador por cada instrucción de giro. Se
/// agrega tal cual a la lista `children` de tu `FlutterMap`, después de
/// la capa del trazado grabado.
///
/// [preview] `true` cuando la ruta todavía no está activa (se está
/// mostrando en la tarjeta de confirmar): se dibuja un poco más tenue.
///
/// Con [progress] (navegando) se dibuja solo lo que falta: desde donde
/// va el ciclista hasta el destino, como en Waze; los giros ya pasados
/// tampoco se marcan.
List<Widget> buildNavigationRouteLayers(
  NavigationRoute route, {
  bool preview = false,
  RouteProgress? progress,
}) {
  if (route.polyline.isEmpty) return const [];

  final from = progress == null
      ? 0
      : (progress.segmentIndex + 1).clamp(0, route.polyline.length);
  final points = [
    if (progress != null) latlng.LatLng(progress.lat, progress.lng),
    for (final n in route.polyline.skip(from)) latlng.LatLng(n.lat, n.lng),
  ];
  final along = progress?.alongMeters ?? double.negativeInfinity;

  return [
    PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          strokeWidth: 6,
          color: preview
              ? CcColors.route.withValues(alpha: 0.65)
              : CcColors.route,
          borderStrokeWidth: 2,
          borderColor: Colors.black.withValues(alpha: 0.25),
        ),
      ],
    ),
    MarkerLayer(
      markers: route.instructions
          .where(
            (i) =>
                i.direction != TurnDirection.straight &&
                i.distanceFromStartMeters > along,
          )
          .map(
            (instruction) => Marker(
              point: latlng.LatLng(instruction.lat, instruction.lng),
              width: 28,
              height: 28,
              child: Container(
                decoration: BoxDecoration(
                  color: instruction.direction == TurnDirection.arrive
                      ? AppColors.recordButtonActive
                      : CcColors.route,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  _iconFor(instruction.direction),
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          )
          .toList(),
    ),
  ];
}

IconData _iconFor(TurnDirection direction) {
  switch (direction) {
    case TurnDirection.left:
    case TurnDirection.sharpLeft:
    case TurnDirection.slightLeft:
      return Icons.turn_left;
    case TurnDirection.right:
    case TurnDirection.sharpRight:
    case TurnDirection.slightRight:
      return Icons.turn_right;
    case TurnDirection.uTurn:
      return Icons.u_turn_left;
    case TurnDirection.arrive:
      return Icons.flag;
    case TurnDirection.straight:
      return Icons.straight;
  }
}
