import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/segment_profile.dart';

/// Perfil de altimetría de un segmento completo (área + línea), con un
/// marcador opcional "estás aquí" en una fracción [progress] del
/// recorrido -- se usa tanto en el detalle del segmento como en la
/// previsualización de import y en la pantalla de segmento en vivo
/// (Fase D). Antes esto estaba duplicado como un `CustomPainter`
/// privado dentro de `segment_detail_screen.dart`.
class SegmentAltitudeProfile extends StatelessWidget {
  final List<SegmentProfilePoint> points;

  /// 0.0-1.0 -- dónde dibujar el marcador "estás aquí". `null` = sin
  /// marcador (detalle / preview de import).
  final double? progress;

  final double height;

  const SegmentAltitudeProfile({
    super.key,
    required this.points,
    this.progress,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Sin datos de altimetría.',
            style: TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SegmentAltitudeProfilePainter(
          points: points,
          progress: progress,
        ),
      ),
    );
  }
}

class _SegmentAltitudeProfilePainter extends CustomPainter {
  final List<SegmentProfilePoint> points;
  final double? progress;

  const _SegmentAltitudeProfilePainter({
    required this.points,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalDistance = points.last.distanceFromStartMeters;
    if (totalDistance <= 0) return;

    double minAltitude = points.first.altitude;
    double maxAltitude = points.first.altitude;
    for (final p in points) {
      if (p.altitude < minAltitude) minAltitude = p.altitude;
      if (p.altitude > maxAltitude) maxAltitude = p.altitude;
    }
    final altitudeSpan = maxAltitude - minAltitude;

    Offset offsetFor(SegmentProfilePoint p) {
      final x = (p.distanceFromStartMeters / totalDistance) * size.width;
      final t =
          altitudeSpan <= 0 ? 0.5 : (p.altitude - minAltitude) / altitudeSpan;
      final y = size.height - (t * size.height);
      return Offset(x, y);
    }

    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < points.length; i++) {
      final o = offsetFor(points[i]);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
        fillPath.moveTo(o.dx, size.height);
        fillPath.lineTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
        fillPath.lineTo(o.dx, o.dy);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()..color = AppColors.primary.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Marcador "estás aquí".
    final p = progress;
    if (p != null) {
      final clamped = p.clamp(0.0, 1.0);
      final x = clamped * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = AppColors.segmentActiveTrack
          ..strokeWidth = 2,
      );
      // Altura interpolada del perfil en esa distancia, para el punto.
      final distHere = clamped * totalDistance;
      SegmentProfilePoint ref = points.first;
      for (final pt in points) {
        if (pt.distanceFromStartMeters <= distHere) {
          ref = pt;
        } else {
          break;
        }
      }
      final o = offsetFor(
        SegmentProfilePoint(
          distanceFromStartMeters: distHere,
          latitude: ref.latitude,
          longitude: ref.longitude,
          altitude: ref.altitude,
          slopePercent: ref.slopePercent,
        ),
      );
      canvas.drawCircle(
        Offset(x, o.dy),
        4.5,
        Paint()..color = AppColors.segmentActiveTrack,
      );
      canvas.drawCircle(
        Offset(x, o.dy),
        4.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentAltitudeProfilePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.progress != progress;
}
