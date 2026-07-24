import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ciclista animado "pedaleando" de verdad: dos piernas que giran en
/// fase opuesta alrededor del eje de pedalier, más las ruedas con
/// radios que rotan al mismo ritmo. Está dibujado con [CustomPainter]
/// (sin sprites ni imágenes), así que es liviano y se puede recolorear
/// según el rango actual sin pedir assets nuevos.
///
/// [cadence] controla qué tan rápido pedalea: 1 = ritmo normal en
/// reposo, valores mayores (ej. 2.5) dan una ráfaga de pedaleo rápido
/// -- se usa mientras el ciclista avanza de un nivel a otro.
class PedalingCyclist extends StatefulWidget {
  final Color color;
  final double size;
  final double cadence;

  const PedalingCyclist({
    super.key,
    required this.color,
    this.size = 64,
    this.cadence = 1,
  });

  @override
  State<PedalingCyclist> createState() => _PedalingCyclistState();
}

class _PedalingCyclistState extends State<PedalingCyclist>
    with SingleTickerProviderStateMixin {
  static const _baseDuration = Duration(milliseconds: 900);
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _durationFor(widget.cadence))
      ..repeat();
  }

  Duration _durationFor(double cadence) => Duration(
        milliseconds: (_baseDuration.inMilliseconds / cadence.clamp(0.05, 4)).round(),
      );

  @override
  void didUpdateWidget(covariant PedalingCyclist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cadence != widget.cadence) {
      _controller.duration = _durationFor(widget.cadence);
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _CyclistPainter(
          color: widget.color,
          phase: _controller.value * 2 * math.pi,
        ),
      ),
    );
  }
}

class _CyclistPainter extends CustomPainter {
  final Color color;
  final double phase;

  const _CyclistPainter({required this.color, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.60);
    final wheelR = w * 0.28;
    final crankR = w * 0.095;

    final wheelRimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045;
    final spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018;
    final framePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.05;

    final rearWheel = center.translate(-w * 0.20, 0);
    final frontWheel = center.translate(w * 0.20, 0);

    canvas.drawCircle(rearWheel, wheelR, wheelRimPaint);
    canvas.drawCircle(frontWheel, wheelR, wheelRimPaint);

    // Radios girando -- vende la sensación de movimiento incluso si el
    // ciclista está quieto en la carretera.
    for (final wheelCenter in [rearWheel, frontWheel]) {
      for (var i = 0; i < 3; i++) {
        final angle = phase + i * (2 * math.pi / 3);
        canvas.drawLine(
          wheelCenter,
          wheelCenter + Offset(math.cos(angle), math.sin(angle)) * wheelR,
          spokePaint,
        );
      }
    }

    final crank = center.translate(0, -h * 0.015);
    final seat = center.translate(-w * 0.03, -h * 0.24);
    final handlebar = center.translate(w * 0.18, -h * 0.20);

    canvas.drawLine(rearWheel, seat, framePaint);
    canvas.drawLine(seat, crank, framePaint);
    canvas.drawLine(crank, frontWheel, framePaint);
    canvas.drawLine(crank, handlebar, framePaint);
    canvas.drawLine(rearWheel, crank, framePaint);

    // Piernas pedaleando: dos pedales en fase opuesta (180°) girando
    // alrededor del eje de pedalier.
    final legPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.042;
    final hip = seat.translate(w * 0.015, h * 0.02);

    for (final offset in [0.0, math.pi]) {
      final pedalAngle = phase + offset;
      final pedal =
          crank + Offset(math.cos(pedalAngle), math.sin(pedalAngle)) * crankR;
      final knee = Offset(
        (hip.dx + pedal.dx) / 2 + math.sin(pedalAngle) * (w * 0.05),
        (hip.dy + pedal.dy) / 2 - h * 0.03,
      );
      canvas.drawLine(hip, knee, legPaint);
      canvas.drawLine(knee, pedal, legPaint);
    }

    // Torso inclinado hacia el manubrio (postura de escalada) + cabeza.
    final torsoPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.055;
    final torsoEnd = handlebar.translate(-w * 0.05, h * 0.05);
    canvas.drawLine(hip, torsoEnd, torsoPaint);
    canvas.drawCircle(
      torsoEnd.translate(-w * 0.06, -h * 0.01),
      w * 0.085,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _CyclistPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.color != color;
}
