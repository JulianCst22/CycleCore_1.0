import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:core_ui/core_ui.dart';
import 'package:core_database/core_database.dart';

/// Dibuja el trazado de la actividad como una línea coloreada por
/// pendiente (mapa de calor, mismo criterio que el detalle), escalada
/// para caber en su caja. Sin tiles de mapa reales -- para las
/// imágenes de compartir eso metería una carrera de carga y problemas
/// de atribución; una "huella" estilizada del recorrido se ve pulida y
/// es 100% determinística al exportar a PNG.
class ShareRouteArt extends StatelessWidget {
  final List<RoutePointSnapshot> points;
  final double strokeWidth;

  const ShareRouteArt({
    super.key,
    required this.points,
    this.strokeWidth = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const Center(
        child: Icon(
          Icons.route,
          color: CyclecorePalette.niebla,
          size: 64,
        ),
      );
    }
    return CustomPaint(
      painter: _SlopeRoutePainter(points: points, strokeWidth: strokeWidth),
      child: const SizedBox.expand(),
    );
  }
}

class _SlopeRoutePainter extends CustomPainter {
  final List<RoutePointSnapshot> points;
  final double strokeWidth;

  const _SlopeRoutePainter({required this.points, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    double minLat = points.first.latitude, maxLat = minLat;
    double minLng = points.first.longitude, maxLng = minLng;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    // Corrección de aspecto por latitud (equirectangular) para que el
    // trazado no salga "achatado".
    final latMid = (minLat + maxLat) / 2 * math.pi / 180;
    final lngSpan = (maxLng - minLng).abs() * math.cos(latMid);
    final latSpan = (maxLat - minLat).abs();

    const pad = 28.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final scale = (latSpan == 0 && lngSpan == 0)
        ? 0.0
        : math.min(
            w / (lngSpan == 0 ? 1 : lngSpan),
            h / (latSpan == 0 ? 1 : latSpan),
          );

    // Centrado.
    final drawW = lngSpan * scale;
    final drawH = latSpan * scale;
    final offX = pad + (w - drawW) / 2;
    final offY = pad + (h - drawH) / 2;

    Offset project(RoutePointSnapshot p) {
      final dx =
          offX + (p.longitude - minLng) * math.cos(latMid) * scale;
      final dy = offY + (maxLat - p.latitude) * scale;
      return Offset(dx, dy);
    }

    // Suavizado corto de pendiente para que el color no salte.
    final slopes = _smoothSlopes(points, 5);

    // Halo oscuro debajo (mismo truco que el detalle).
    final halo = Path();
    for (int i = 0; i < points.length; i++) {
      final o = project(points[i]);
      i == 0 ? halo.moveTo(o.dx, o.dy) : halo.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      halo,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Tramos coloreados por pendiente.
    for (int i = 0; i < points.length - 1; i++) {
      final a = project(points[i]);
      final b = project(points[i + 1]);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = CyclecorePalette.slopeColorFor(slopes[i])
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    // Puntos de inicio (verde) y fin (rojo).
    final start = project(points.first);
    final end = project(points.last);
    void dot(Offset c, Color color) {
      canvas.drawCircle(c, strokeWidth * 0.9, Paint()..color = Colors.white);
      canvas.drawCircle(c, strokeWidth * 0.65, Paint()..color = color);
    }

    dot(start, const Color(0xFF2ECC71));
    dot(end, const Color(0xFFE0663D));
  }

  List<double> _smoothSlopes(List<RoutePointSnapshot> pts, int window) {
    final half = window ~/ 2;
    return List<double>.generate(pts.length, (i) {
      final s = math.max(0, i - half);
      final e = math.min(pts.length - 1, i + half);
      double sum = 0;
      for (int j = s; j <= e; j++) {
        sum += pts[j].slopePercent;
      }
      return sum / (e - s + 1);
    });
  }

  @override
  bool shouldRepaint(covariant _SlopeRoutePainter old) =>
      old.points != points || old.strokeWidth != strokeWidth;
}

/// Perfil de altimetría (área) coloreado por pendiente, para la tarjeta
/// "Altimetría" de compartir.
class ShareElevationArt extends StatelessWidget {
  final List<RoutePointSnapshot> points;

  const ShareElevationArt({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const Center(
        child: Icon(Icons.show_chart, color: CyclecorePalette.niebla, size: 64),
      );
    }
    return CustomPaint(
      painter: _ElevationAreaPainter(points),
      child: const SizedBox.expand(),
    );
  }
}

class _ElevationAreaPainter extends CustomPainter {
  final List<RoutePointSnapshot> points;
  const _ElevationAreaPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final total = points.last.distanceFromStartMeters;
    if (total <= 0) return;

    double minA = points.first.altitude, maxA = minA;
    for (final p in points) {
      minA = math.min(minA, p.altitude);
      maxA = math.max(maxA, p.altitude);
    }
    final span = maxA - minA;

    Offset o(RoutePointSnapshot p) {
      final x = (p.distanceFromStartMeters / total) * size.width;
      final t = span <= 0 ? 0.4 : (p.altitude - minA) / span;
      // 12% de aire arriba para que la cima no toque el borde.
      return Offset(x, size.height - t * size.height * 0.86 - size.height * 0.06);
    }

    // Área rellena por tramos de color según pendiente.
    for (int i = 0; i < points.length - 1; i++) {
      final a = o(points[i]);
      final b = o(points[i + 1]);
      final seg = Path()
        ..moveTo(a.dx, size.height)
        ..lineTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(b.dx, size.height)
        ..close();
      canvas.drawPath(
        seg,
        Paint()
          ..color = CyclecorePalette.slopeColorFor(points[i].slopePercent)
              .withValues(alpha: 0.85),
      );
    }

    // Línea de cresta blanca sutil.
    final crest = Path();
    for (int i = 0; i < points.length; i++) {
      final p = o(points[i]);
      i == 0 ? crest.moveTo(p.dx, p.dy) : crest.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      crest,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ElevationAreaPainter old) =>
      old.points != points;
}
