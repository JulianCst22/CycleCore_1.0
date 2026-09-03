import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cc_colors.dart';

/// Telón de fondo FIJO (no se mueve con el avance del ciclista) de la
/// pantalla de la subida: el mismo amanecer de montaña de Welcome y
/// Login ([DawnHero]) para dar continuidad, pero recortado y encuadrado
/// para servir de horizonte a la cámara detrás del ciclista.
///
/// [progress] va de 0 (base del Alto de Patios, en Belisario) a 1 (la
/// cima real, 3 001 msnm). A medida que sube, el cielo se aclara y se
/// enfría un poco y la neblina del horizonte se hace más densa -- se
/// siente que se gana altura y que amanece más.
class DawnClimbBackdrop extends StatelessWidget {
  final double progress;

  const DawnClimbBackdrop({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _DawnClimbPainter(progress: progress.clamp(0.0, 1.0)),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DawnClimbPainter extends CustomPainter {
  final double progress;

  _DawnClimbPainter({required this.progress});

  /// La línea del horizonte, como fracción del alto. Coincide con
  /// `ClimbCamera.horizonY` para que la carretera nazca justo sobre las
  /// sierras.
  static const double _horizonFactor = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * _horizonFactor;
    final t = progress;

    // --- Cielo: paleta del amanecer de dawn_hero.dart, corrida un
    // punto hacia el frío/claro con la altura ---
    final skyTop = Color.lerp(
      const Color(0xFF0C0F14),
      const Color(0xFF11161F),
      t,
    )!;
    final skyMid = Color.lerp(
      const Color(0xFF20303F),
      const Color(0xFF2A3C4D),
      t,
    )!;
    final skyWarm1 = Color.lerp(
      const Color(0xFF5A3B36),
      const Color(0xFF6A4A52),
      t,
    )!;
    final skyWarm2 = Color.lerp(
      const Color(0xFF8A4A33),
      const Color(0xFF9A5C45),
      t,
    )!;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizon + 2),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyMid, skyWarm1, skyWarm2],
          stops: const [0.0, 0.55, 0.82, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, horizon + 2)),
    );

    // --- Resplandor del sol sobre el horizonte: el naranja de marca ---
    final glowCenter = Offset(w * 0.68, horizon);
    canvas.drawCircle(
      glowCenter,
      w * 0.85,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF8A4C).withValues(alpha: 0.5 - t * 0.16),
            const Color(0xFFFF6B35).withValues(alpha: 0.10),
            const Color(0xFFFF6B35).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: w * 0.85)),
    );
    canvas.drawCircle(
      glowCenter.translate(0, 6),
      w * 0.08,
      Paint()..color = const Color(0xFFFFD9B0).withValues(alpha: 0.85),
    );

    // --- Suelo bajo el horizonte: el navy de fondo de la app, para que
    // la carretera (que se pinta aparte) se apoye en algo coherente ---
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, w, h - horizon),
      Paint()..color = CcColors.bg,
    );

    // --- Tres sierras en silueta, de atrás hacia adelante ---
    _ridge(
      canvas,
      w,
      horizon - h * 0.005,
      h * 0.05,
      0.9,
      const Color(0xFF3A4A5C),
      11,
    );
    _ridge(
      canvas,
      w,
      horizon + h * 0.028,
      h * 0.075,
      1.15,
      const Color(0xFF26333F),
      4,
    );
    _ridge(
      canvas,
      w,
      horizon + h * 0.07,
      h * 0.11,
      1.4,
      const Color(0xFF161C25),
      7,
    );

    // --- Neblina fina sobre el horizonte, más densa cuanto más alto ---
    canvas.drawRect(
      Rect.fromLTWH(0, horizon - h * 0.05, w, h * 0.13),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.04 + t * 0.06),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, horizon - h * 0.05, w, h * 0.13)),
    );

    // --- Grano sutil sobre todo ---
    final rnd = math.Random(99);
    final grain = Paint()..color = Colors.white.withValues(alpha: 0.02);
    for (var i = 0; i < 240; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * w, rnd.nextDouble() * h),
        rnd.nextDouble() * 0.9,
        grain,
      );
    }
  }

  void _ridge(
    Canvas canvas,
    double w,
    double baseY,
    double amp,
    double freq,
    Color color,
    int seed,
  ) {
    final rnd = math.Random(seed);
    final path = Path()..moveTo(0, baseY + amp);
    var y = baseY;
    const steps = 7;
    for (var i = 0; i <= steps; i++) {
      final x = w * i / steps;
      final ny = baseY - amp * (0.3 + rnd.nextDouble()) * math.sin(i * freq);
      path.quadraticBezierTo(x - w / steps / 2, y, x, ny);
      y = ny;
    }
    path
      ..lineTo(w, baseY + amp * 3)
      ..lineTo(0, baseY + amp * 3)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _DawnClimbPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
