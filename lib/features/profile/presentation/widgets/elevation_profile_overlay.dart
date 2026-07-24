import 'package:flutter/material.dart';

import '../../domain/climb_route.dart';

/// Mini perfil de altimetría (pensado para ir arriba a la izquierda de
/// [ClimbScreen]) con un punto que marca en qué parte real de la
/// subida vas, más la altitud y pendiente local en ese punto exacto.
/// Los datos vienen de [ElevationProfile] -- el perfil real del
/// segmento "Belisario - Alto de Patios", no una curva decorativa.
class ElevationProfileOverlay extends StatelessWidget {
  /// 0.0 = base de la subida, 1.0 = cima (Alto de Patios, 3 001 msnm).
  final double progressFraction;
  final Color accentColor;

  const ElevationProfileOverlay({
    super.key,
    required this.progressFraction,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = progressFraction.clamp(0.0, 1.0);
    final altitude = ElevationProfile.altitudeForFraction(t);
    final grade = ElevationProfile.gradeForFraction(t);
    final distanceKm = ElevationProfile.distanceKmForFraction(t);

    return Container(
      width: 172,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terrain, size: 13, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 5),
              Text(
                'Alto de Patios',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: CustomPaint(
              painter: _ProfilePainter(progressFraction: t, accentColor: accentColor),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${altitude.round()} msnm',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${grade.toStringAsFixed(1)}%',
                  style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'km ${distanceKm.toStringAsFixed(1)} de ${ElevationProfile.totalDistanceKm.toStringAsFixed(1)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final double progressFraction;
  final Color accentColor;

  const _ProfilePainter({required this.progressFraction, required this.accentColor});

  Offset _pointFor(double km, double alt, Size size) {
    final minAlt = ElevationProfile.startAltitude;
    final maxAlt = ElevationProfile.summitAltitude;
    final totalKm = ElevationProfile.totalDistanceKm;
    final x = (km / totalKm) * size.width;
    final t = (alt - minAlt) / (maxAlt - minAlt);
    final y = size.height - (t * size.height);
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final samples = ElevationProfile.samples;

    final path = Path();
    final fillPath = Path()..moveTo(0, size.height);
    for (var i = 0; i < samples.length; i++) {
      final p = _pointFor(samples[i].distanceKm, samples[i].altitudeM, size);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()..color = accentColor.withValues(alpha: 0.18));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    final currentKm = ElevationProfile.distanceKmForFraction(progressFraction);
    final currentAlt = ElevationProfile.altitudeForFraction(progressFraction);
    final marker = _pointFor(currentKm, currentAlt, size);

    // Línea guía vertical hasta el marcador -- ayuda a leer "dónde vas".
    canvas.drawLine(
      Offset(marker.dx, size.height),
      marker,
      Paint()
        ..color = accentColor.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(marker, 5, Paint()..color = accentColor);
    canvas.drawCircle(
      marker,
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter oldDelegate) =>
      oldDelegate.progressFraction != progressFraction ||
      oldDelegate.accentColor != accentColor;
}
