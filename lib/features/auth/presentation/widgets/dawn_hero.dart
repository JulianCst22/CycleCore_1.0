import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';

/// Ilustración de fondo para Welcome y Login: un amanecer sobre un
/// puerto de montaña, con capas de sierra, la carretera trepando y un
/// ciclista en silueta. Todo dibujado en código -- **sin imágenes
/// enlazadas** (offline-first) y sin problemas de licencia.
///
/// El objetivo es que la pantalla "atraiga": algo con profundidad y luz
/// en vez de un navy plano, pero manteniendo el navy y el naranja de
/// marca (el brillo cálido del horizonte es el mismo naranja).
///
/// [heightFactor] > 1 alarga la escena hacia abajo (útil cuando el
/// widget se recorta arriba, como en la banda del Login).
class DawnHero extends StatelessWidget {
  final double heightFactor;

  const DawnHero({super.key, this.heightFactor = 1.0});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _DawnHeroPainter(heightFactor: heightFactor),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DawnHeroPainter extends CustomPainter {
  final double heightFactor;

  _DawnHeroPainter({required this.heightFactor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height * heightFactor;
    final horizon = h * 0.60;

    // --- Cielo: navy arriba -> franja cálida en el horizonte ---
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0C0F14),
          Color(0xFF141B27),
          Color(0xFF20303F),
          Color(0xFF5A3B36),
          Color(0xFF8A4A33),
        ],
        stops: [0.0, 0.32, 0.5, 0.58, 0.62],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, horizon + 2), sky);

    // --- Resplandor del sol, cálido, justo sobre el horizonte ---
    final glowCenter = Offset(w * 0.66, horizon);
    canvas.drawCircle(
      glowCenter,
      w * 0.7,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF8A4C).withValues(alpha: 0.55),
            const Color(0xFFFF6B35).withValues(alpha: 0.12),
            const Color(0xFFFF6B35).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: w * 0.7)),
    );
    canvas.drawCircle(
      glowCenter.translate(0, 4),
      w * 0.09,
      Paint()..color = const Color(0xFFFFD9B0).withValues(alpha: 0.9),
    );

    // --- Suelo bajo el horizonte ---
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, w, h - horizon),
      Paint()..color = const Color(0xFF10141B),
    );

    // --- Sierras, de atrás (clara/atmosférica) a delante (casi el fondo) ---
    _ridge(
      canvas,
      w,
      horizon - h * 0.02,
      h * 0.055,
      0.9,
      const Color(0xFF3A4A5C),
      seed: 11,
    );
    _ridge(
      canvas,
      w,
      horizon + h * 0.015,
      h * 0.075,
      1.15,
      const Color(0xFF263442),
      seed: 4,
    );
    _ridge(
      canvas,
      w,
      horizon + h * 0.06,
      h * 0.11,
      1.4,
      const Color(0xFF161C25),
      seed: 7,
    );

    // Neblina fina sobre las uniones de las capas.
    canvas.drawRect(
      Rect.fromLTWH(0, horizon - h * 0.03, w, h * 0.08),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, horizon - h * 0.03, w, h * 0.08)),
    );

    // --- Carretera: cinta que trepa desde abajo hacia el puerto ---
    final roadTop = horizon + h * 0.02;
    final roadPath = Path()
      ..moveTo(w * 0.42, h)
      ..cubicTo(w * 0.40, h * 0.86, w * 0.62, h * 0.82, w * 0.60, h * 0.72)
      ..cubicTo(w * 0.585, h * 0.65, w * 0.44, h * 0.62, w * 0.47, roadTop + 6)
      ..lineTo(w * 0.50, roadTop)
      ..lineTo(w * 0.505, roadTop + 6)
      ..cubicTo(w * 0.49, h * 0.63, w * 0.64, h * 0.66, w * 0.655, h * 0.73)
      ..cubicTo(w * 0.70, h * 0.83, w * 0.47, h * 0.9, w * 0.52, h)
      ..close();
    canvas.drawPath(
      roadPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF44515F),
            const Color(0xFF2E3945).withValues(alpha: 0.4),
          ],
        ).createShader(Rect.fromLTWH(0, roadTop, w, h - roadTop)),
    );

    // --- Ciclista en silueta, subiendo ---
    _cyclist(canvas, Offset(w * 0.55, h * 0.73), math.min(h * 0.02, 14.0));

    // --- Grano sutil sobre todo ---
    final rnd = math.Random(99);
    final grain = Paint()..color = Colors.white.withValues(alpha: 0.025);
    for (int i = 0; i < 320; i++) {
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
    Color color, {
    required int seed,
  }) {
    final rnd = math.Random(seed);
    final path = Path()..moveTo(0, baseY + amp);
    var y = baseY;
    const steps = 7;
    for (int i = 0; i <= steps; i++) {
      final x = w * i / steps;
      final ny = baseY - amp * (0.3 + rnd.nextDouble()) * math.sin(i * freq);
      path.quadraticBezierTo((x - w / steps / 2), y, x, ny);
      y = ny;
    }
    path
      ..lineTo(w, baseY + amp * 3)
      ..lineTo(0, baseY + amp * 3)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  /// Ciclista de ruta en silueta, inclinado sobre el manillar, visto de
  /// costado. [at] es el punto de contacto de la rueda trasera con el
  /// suelo; [s] es el radio de rueda.
  void _cyclist(Canvas canvas, Offset at, double s) {
    final rear = at.translate(-s * 0.05, -s);
    final front = at.translate(s * 2.1, -s);
    final bb = Offset((rear.dx + front.dx) / 2, at.dy - s * 0.9); // pedalier
    final saddle = bb.translate(-s * 0.55, -s * 1.35);
    final bar = front.translate(-s * 0.15, -s * 1.05);

    final stroke = Paint()
      ..color = const Color(0xFF0A0D12)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.22;

    canvas.drawCircle(rear, s, stroke);
    canvas.drawCircle(front, s, stroke);

    // cuadro
    final frame = Path()
      ..moveTo(rear.dx, rear.dy)
      ..lineTo(bb.dx, bb.dy)
      ..lineTo(saddle.dx, saddle.dy)
      ..lineTo(rear.dx, rear.dy)
      ..moveTo(bb.dx, bb.dy)
      ..lineTo(bar.dx, bar.dy)
      ..lineTo(front.dx, front.dy)
      ..moveTo(saddle.dx, saddle.dy)
      ..lineTo(bar.dx, bar.dy);
    canvas.drawPath(frame, stroke..strokeWidth = s * 0.16);

    // ciclista inclinado: cadera en el sillín, tronco hacia el manillar,
    // cabeza un poco más adelante.
    final hip = saddle.translate(0, -s * 0.2);
    final shoulder = bar.translate(-s * 0.35, -s * 0.75);
    final head = shoulder.translate(s * 0.45, -s * 0.35);
    canvas.drawLine(hip, shoulder, stroke..strokeWidth = s * 0.26);
    canvas.drawLine(shoulder, bar, stroke..strokeWidth = s * 0.18);
    canvas.drawCircle(
      head,
      s * 0.34,
      Paint()
        ..color = const Color(0xFF0A0D12)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _DawnHeroPainter oldDelegate) =>
      oldDelegate.heightFactor != heightFactor;
}

/// Velo que oscurece la parte baja de la ilustración hacia el fondo de
/// la app, para que el texto y los botones sean legibles encima.
class DawnHeroVeil extends StatelessWidget {
  const DawnHeroVeil({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x140E1116),
            Color(0x5C0E1116),
            Color(0xE60E1116),
            CcColors.bg,
          ],
          stops: [0.0, 0.42, 0.72, 1.0],
        ),
      ),
    );
  }
}
