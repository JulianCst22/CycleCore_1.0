import 'package:flutter/material.dart';

import '../../domain/activity_summary.dart';

/// Dibuja el trazado de una ruta como una línea simple, escalada para
/// caber en un cuadro pequeño (ej. una tarjeta de lista). No usa tiles
/// de mapa reales a propósito: cargar un FlutterMap por cada fila de una
/// lista larga sería lento y consumiría datos innecesariamente. Esto es
/// solo una "huella" visual del recorrido, no un mapa navegable.
class RouteThumbnail extends StatelessWidget {
  final List<RoutePointSnapshot> points;
  final Color lineColor;
  final Color backgroundColor;

  const RouteThumbnail({
    super.key,
    required this.points,
    required this.lineColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: points.length < 2
          ? Icon(
              Icons.directions_bike,
              color: lineColor.withValues(alpha: 0.5),
            )
          : CustomPaint(
              painter: _RoutePainter(points: points, color: lineColor),
              child: const SizedBox.expand(),
            ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<RoutePointSnapshot> points;
  final Color color;

  _RoutePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);

    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);

    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();

    // Margen interno para que la línea no toque los bordes del cuadro.
    const padding = 8.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    // Evita división por cero en rutas casi rectas (norte-sur o
    // este-oeste puro) usando el mayor de los dos spans como referencia
    // para ambos ejes, preservando la proporción real del trazado.
    final scale = (latSpan == 0 && lngSpan == 0)
        ? 0.0
        : (drawWidth / (lngSpan == 0 ? 1 : lngSpan))
            .clamp(0.0, drawHeight / (latSpan == 0 ? 1 : latSpan));

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final dx = padding + (points[i].longitude - minLng) * scale;
      // Invertimos Y: latitud mayor = más al norte = arriba en pantalla.
      final dy = padding + (maxLat - points[i].latitude) * scale;
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
