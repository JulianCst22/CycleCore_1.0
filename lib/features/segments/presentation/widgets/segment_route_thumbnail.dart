import 'package:flutter/material.dart';

import 'package:core_ui/core_ui.dart';
import 'package:core_geo/core_geo.dart';

/// Huella del trazado de un segmento en un cuadro pequeño (la lista de
/// segmentos). No usa tiles de mapa a propósito -- cargar un
/// `FlutterMap` por cada fila sería lento; esto es solo la forma del
/// tramo, con banderas A/B.
class SegmentRouteThumbnail extends StatelessWidget {
  final List<SegmentProfilePoint> points;
  final double size;

  const SegmentRouteThumbnail({
    super.key,
    required this.points,
    this.size = 74,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CcColors.surfaceInset,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CcColors.lineSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: points.length < 2
          ? const Center(
              child: Icon(
                Icons.flag_outlined,
                size: 22,
                color: CcColors.inkFaint,
              ),
            )
          : CustomPaint(painter: _TracePainter(points)),
    );
  }
}

class _TracePainter extends CustomPainter {
  final List<SegmentProfilePoint> points;

  _TracePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;

    const pad = 11.0;
    final drawW = size.width - pad * 2;
    final drawH = size.height - pad * 2;
    // Escala común a ambos ejes -> conserva la proporción real del
    // trazado en vez de estirarlo para llenar el cuadro.
    final scale = (latSpan == 0 && lngSpan == 0)
        ? 0.0
        : (drawW / (lngSpan == 0 ? 1 : lngSpan)).clamp(
            0.0,
            drawH / (latSpan == 0 ? 1 : latSpan),
          );

    final dx = (size.width - lngSpan * scale) / 2;
    final dy = (size.height - latSpan * scale) / 2;
    Offset at(SegmentProfilePoint p) => Offset(
      dx + (p.longitude - minLng) * scale,
      dy + (maxLat - p.latitude) * scale,
    );

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = at(points[i]);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = CcColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = CcColors.segmentActiveTrack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    void dot(Offset o, Color color) {
      canvas.drawCircle(o, 3.6, Paint()..color = color);
      canvas.drawCircle(
        o,
        3.6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    dot(at(points.first), CcColors.segmentStart);
    dot(at(points.last), CcColors.danger);
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) =>
      oldDelegate.points != points;
}
