import 'dart:math' as math;

import 'package:flutter/material.dart';

/// La "cámara detrás del ciclista".
///
/// Proyecta una distancia hacia adelante ([d], medida en unidades de
/// nivel: `d = 0` es donde está el ciclista, `d = 1` es el próximo
/// arco) a una posición y una escala en pantalla, con el amontonamiento
/// hiperbólico típico de la perspectiva. La comparten el pintor de la
/// carretera y el de los arcos para que todo caiga sobre la misma vía.
class ClimbCamera {
  final Size size;

  /// Nivel fraccionario en el que está el ciclista ahora mismo (ej.
  /// 12.62). Mueve la curva de la carretera y decide qué arcos se ven
  /// venir.
  final double displayedLevel;

  const ClimbCamera({required this.size, required this.displayedLevel});

  /// Altura en pantalla del horizonte -- coincide con
  /// `_DawnClimbPainter._horizonFactor`.
  double get horizonY => size.height * 0.42;

  /// Altura en pantalla donde las ruedas del ciclista tocan el asfalto.
  double get cyclistY => size.height * 0.66;

  /// Constante de perspectiva: más alta = el amontonamiento hacia el
  /// horizonte es más suave.
  static const double _k = 2.6;

  /// Amplitud del serpenteo horizontal de la vía.
  double get _bend => size.width * 0.17;

  /// 0.0 pegado al ciclista, -> 1.0 en el horizonte.
  double depth(double d) => d <= 0 ? 0.0 : (d / (d + _k)).clamp(0.0, 1.0);

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double screenY(double d) => _lerp(cyclistY, horizonY, depth(d));

  /// 1.0 pegado al ciclista, 0.0 en el horizonte -- para escalar arcos.
  double scale(double d) => (1 - depth(d)).clamp(0.0, 1.0);

  double roadHalfWidth(double d) =>
      _lerp(size.width * 0.44, size.width * 0.012, depth(d));

  double _curve(double worldLevel) => math.sin(worldLevel * 0.55) * _bend;

  double roadCenterX(double d) {
    // La curva se ANCLA en el ciclista: justo bajo él la vía siempre
    // está centrada en pantalla, y el trazado de más adelante ondula a
    // los lados (aplanándose hacia el horizonte por la perspectiva). El
    // ciclista nunca se sale del centro; es el mundo el que se mueve.
    final ahead = _curve(displayedLevel + d) * (1 - depth(d) * 0.75);
    final atCyclist = _curve(displayedLevel);
    return size.width / 2 + (ahead - atCyclist);
  }

  Offset roadPoint(double d) => Offset(roadCenterX(d), screenY(d));

  Offset roadEdge(double d, {required bool left}) {
    final hw = roadHalfWidth(d);
    return Offset(roadCenterX(d) + (left ? -hw : hw), screenY(d));
  }
}

/// La carretera en perspectiva: sale de debajo del ciclista y se pierde
/// en el horizonte, con bordes definidos, un filo del color del rango
/// actual y una línea central discontinua que "corre" hacia el
/// espectador a medida que `camera.displayedLevel` crece.
class ClimbRoadPainter extends CustomPainter {
  final ClimbCamera camera;
  final Color accent;

  const ClimbRoadPainter({required this.camera, required this.accent});

  /// Hasta dónde se dibuja el asfalto, en niveles hacia adelante. Los
  /// arcos usan el mismo tope ([ClimbArchesPainter]).
  static const double farAhead = 6.5;

  @override
  void paint(Canvas canvas, Size size) {
    const steps = 40;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final d = farAhead * (i / steps);
      left.add(camera.roadEdge(d, left: true));
      right.add(camera.roadEdge(d, left: false));
    }

    final surface = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      surface.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      surface.lineTo(p.dx, p.dy);
    }
    surface.close();

    // Asfalto: navy un poco más claro que el suelo, degradado a oscuro
    // hacia el horizonte para vender distancia.
    canvas.drawPath(
      surface,
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF2B323E), Color(0xFF171B24)],
            ).createShader(
              Rect.fromLTWH(
                0,
                camera.horizonY,
                size.width,
                camera.cyclistY - camera.horizonY + 60,
              ),
            ),
    );

    // Bordes de la vía.
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_poly(left), edgePaint);
    canvas.drawPath(_poly(right), edgePaint);

    // Filo del color del rango pegado al borde derecho -- el mismo
    // recurso de "mejor pavimento según el rango" del diseño anterior.
    canvas.drawPath(
      _poly(right),
      Paint()
        ..color = accent.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Línea central discontinua: cada guion vive a una distancia entera
    // menos la fracción de nivel ya recorrida, así "corre" hacia el
    // espectador cuando displayedLevel crece.
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final frac = camera.displayedLevel - camera.displayedLevel.floorToDouble();
    for (var n = 0; n < 8; n++) {
      final dStart = (n - frac) + 0.08;
      final dEnd = (n - frac) + 0.52;
      if (dEnd <= 0.04) continue;
      final a = camera.roadPoint(dStart.clamp(0.04, farAhead));
      final b = camera.roadPoint(dEnd.clamp(0.04, farAhead));
      canvas.drawLine(
        a,
        b,
        dashPaint
          ..strokeWidth = (camera.scale(dStart.clamp(0.0, farAhead)) * 6).clamp(
            1.0,
            6.0,
          ),
      );
    }
  }

  Path _poly(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant ClimbRoadPainter oldDelegate) =>
      oldDelegate.camera.displayedLevel != camera.displayedLevel ||
      oldDelegate.camera.size != camera.size ||
      oldDelegate.accent != accent;
}
