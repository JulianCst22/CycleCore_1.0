import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/theme/app_colors.dart';
import '../domain/navigation_route.dart';

/// Devuelve las capas de `flutter_map` para dibujar la ruta sugerida:
/// una polilínea punteada (para distinguirla del trazado grabado, que
/// ya usa una polilínea sólida) más un marcador por cada instrucción
/// de giro. Se agrega tal cual a la lista `children` de tu
/// `FlutterMap`, después de la capa del trazado grabado.
List<Widget> buildNavigationRouteLayers(NavigationRoute route) {
  if (route.polyline.isEmpty) return const [];

  final points = route.polyline
      .map((n) => latlng.LatLng(n.lat, n.lng))
      .toList();

  return [
    PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          strokeWidth: 5,
          color: AppColors.accentElevation,
          // `pattern` (línea punteada) existe desde flutter_map ~7.
          // Si tu versión es más vieja y esto no compila, borrá esta
          // línea -- la ruta se ve sólida, sigue funcionando igual.
          pattern: const StrokePattern.dotted(),
        ),
      ],
    ),
    MarkerLayer(
      markers: route.instructions
          .where((i) => i.direction != TurnDirection.straight)
          .map(
            (instruction) => Marker(
              point: latlng.LatLng(instruction.lat, instruction.lng),
              width: 28,
              height: 28,
              child: Container(
                decoration: BoxDecoration(
                  color: instruction.direction == TurnDirection.arrive
                      ? AppColors.recordButtonActive
                      : AppColors.accentElevation,
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
