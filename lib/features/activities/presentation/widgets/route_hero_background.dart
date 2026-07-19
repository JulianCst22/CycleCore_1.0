import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/activity_summary.dart';

/// Fondo "hero" para la tarjeta grande de actividad -- dibuja el
/// trazado de la ruta a mayor escala que `RouteThumbnail` (línea con
/// resplandor + marcadores de inicio/fin), sobre un degradado teñido
/// con el color del tipo de actividad.
///
/// Sigue sin usar tiles de mapa reales (FlutterMap) a propósito: hay
/// varias tarjetas grandes en una lista scrolleable, y cargar un mapa
/// interactivo por cada una sería costoso en memoria/batería y
/// requeriría red. Esto es una "huella" estilizada de la ruta, no un
/// mapa navegable -- el mapa real ya vive en el detalle.
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppColors.panelBackground, accentColor, 0.30)!,
            AppColors.panelBackground,
          ],
        ),
      ),
      child: points.length < 2
          ? Center(
              child: Icon(
                Icons.directions_bike,
                size: 42,
                color: accentColor.withValues(alpha: 0.5),
              ),
            )
          : CustomPaint(
              painter: _HeroRoutePainter(points: points, color: accentColor),
              child: const SizedBox.expand(),
            ),
    );
  }
}

class _HeroRoutePainter extends CustomPainter {
  final List<RoutePointSnapshot> points;
  final Color color;

  _HeroRoutePainter({required this.points, required this.color});

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

    // Margen generoso -- esta tarjeta es grande, la línea puede
    // "respirar" más que en el thumbnail chico de la lista antigua.
    const padding = 30.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    final scale = (latSpan == 0 && lngSpan == 0)
        ? 0.0
        : (drawWidth / (lngSpan == 0 ? 1 : lngSpan))
            .clamp(0.0, drawHeight / (latSpan == 0 ? 1 : latSpan));

    // Centra el trazado dentro del área disponible (si la ruta es más
    // angosta que alta o viceversa, no queda pegada a una esquina).
    final usedWidth = lngSpan * scale;
    final usedHeight = latSpan * scale;
    final offsetX = padding + (drawWidth - usedWidth) / 2;
    final offsetY = padding + (drawHeight - usedHeight) / 2;

    Offset offsetFor(int i) {
      final dx = offsetX + (points[i].longitude - minLng) * scale;
      final dy = offsetY + (maxLat - points[i].latitude) * scale;
      return Offset(dx, dy);
    }

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final offset = offsetFor(i);
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    // Resplandor debajo de la línea principal -- le da profundidad,
    // el mismo lenguaje visual que usan Strava/Komoot para las rutas.
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glowPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Marcador de inicio: punto blanco con borde de color.
    final start = offsetFor(0);
    canvas.drawCircle(start, 6, Paint()..color = Colors.white);
    canvas.drawCircle(
      start,
      6,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Marcador de fin: punto sólido de color con borde blanco.
    final end = offsetFor(points.length - 1);
    canvas.drawCircle(end, 5, Paint()..color = color);
    canvas.drawCircle(
      end,
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _HeroRoutePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
