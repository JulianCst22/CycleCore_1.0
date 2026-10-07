import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/physiology/physiology.dart';
import '../../../../core/ui/ui.dart';

/// Duración de un punto de la curva: «5 s», «1 min», «20 min».
String formatCurveDuration(int seconds) {
  if (seconds < 60) return '$seconds s';
  final minutes = seconds / 60;
  return minutes == minutes.roundToDouble()
      ? '${minutes.round()} min'
      : '${minutes.toStringAsFixed(1)} min';
}

/// Curva de medias máximas con el tiempo en escala logarítmica (de 5 s a
/// 60 min): la forma estándar de mirar una curva de potencia, donde los
/// esfuerzos cortos y los largos se leen igual de bien.
///
/// Opcionalmente dibuja una curva de comparación (más tenue), una curva
/// de modelo (punteada, p. ej. `CP + W′/t`) y una línea de referencia
/// horizontal (p. ej. la CP). Tocar o arrastrar elige la duración más
/// cercana.
class MeanMaxCurveChart extends StatelessWidget {
  final MeanMaxCurve curve;
  final MeanMaxCurve? comparison;
  final double Function(double seconds)? model;

  /// Desde qué duración se dibuja el [model] (fuera del rango donde vale
  /// no se muestra).
  final double modelFromSeconds;
  final double? reference;
  final String? referenceLabel;
  final Color color;
  final int? selected;
  final ValueChanged<int>? onSelect;

  /// Duraciones que se marcan en dorado (por ejemplo, récords).
  final Set<int> highlighted;
  final double height;

  const MeanMaxCurveChart({
    super.key,
    required this.curve,
    required this.color,
    this.comparison,
    this.model,
    this.modelFromSeconds = 120,
    this.reference,
    this.referenceLabel,
    this.selected,
    this.onSelect,
    this.highlighted = const {},
    this.height = 170,
  });

  static const _minSeconds = 5.0;
  static const _maxSeconds = 3600.0;
  static const _ticks = <int>[5, 60, 300, 1200, 3600];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, height);
          final layout = _ChartLayout(size);
          void select(Offset position) {
            final durations = {
              ...curve.points.keys,
              ...?comparison?.points.keys,
            };
            if (durations.isEmpty || onSelect == null) return;
            final nearest = durations.reduce(
              (a, b) =>
                  (layout.x(a.toDouble()) - position.dx).abs() <=
                      (layout.x(b.toDouble()) - position.dx).abs()
                  ? a
                  : b,
            );
            onSelect!(nearest);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => select(d.localPosition),
            onHorizontalDragStart: (d) => select(d.localPosition),
            onHorizontalDragUpdate: (d) => select(d.localPosition),
            child: CustomPaint(
              size: size,
              painter: _CurvePainter(
                layout: layout,
                curve: curve,
                comparison: comparison,
                model: model,
                modelFromSeconds: modelFromSeconds,
                reference: reference,
                referenceLabel: referenceLabel,
                color: color,
                selected: selected,
                highlighted: highlighted,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChartLayout {
  final Size size;
  static const left = 34.0;
  static const right = 6.0;
  static const top = 8.0;
  static const bottom = 18.0;

  const _ChartLayout(this.size);

  double get width => size.width - left - right;
  double get plotHeight => size.height - top - bottom;

  double x(double seconds) {
    final lo = math.log(MeanMaxCurveChart._minSeconds);
    final hi = math.log(MeanMaxCurveChart._maxSeconds);
    final t = (math.log(seconds) - lo) / (hi - lo);
    return left + t.clamp(0.0, 1.0) * width;
  }

  double y(double value, double min, double max) =>
      top + (1 - (value - min) / (max - min)) * plotHeight;
}

class _CurvePainter extends CustomPainter {
  final _ChartLayout layout;
  final MeanMaxCurve curve;
  final MeanMaxCurve? comparison;
  final double Function(double seconds)? model;
  final double modelFromSeconds;
  final double? reference;
  final String? referenceLabel;
  final Color color;
  final int? selected;
  final Set<int> highlighted;

  _CurvePainter({
    required this.layout,
    required this.curve,
    required this.comparison,
    required this.model,
    required this.modelFromSeconds,
    required this.reference,
    required this.referenceLabel,
    required this.color,
    required this.selected,
    required this.highlighted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final values = [
      for (final p in curve.points.values) p.value,
      for (final p in comparison?.points.values ?? const <MeanMaxPoint>[])
        p.value,
      ?reference,
    ];
    if (values.isEmpty) return;
    var min = values.reduce(math.min) * 0.92;
    var max = values.reduce(math.max) * 1.04;
    if (max - min < 1) {
      min -= 1;
      max += 1;
    }
    double y(double v) => layout.y(v, min, max);

    _paintGrid(canvas, min, max, y);

    final ref = reference;
    if (ref != null) {
      final yRef = y(ref);
      _dashedLine(
        canvas,
        Offset(_ChartLayout.left, yRef),
        Offset(size.width - _ChartLayout.right, yRef),
        Paint()
          ..color = CcColors.ink.withValues(alpha: 0.55)
          ..strokeWidth = 1,
      );
      if (referenceLabel != null) {
        _text(
          canvas,
          referenceLabel!,
          Offset(size.width - _ChartLayout.right, yRef - 2),
          CcColors.inkDim,
          alignRight: true,
          above: true,
        );
      }
    }

    final m = model;
    if (m != null) {
      final path = Path();
      const steps = 48;
      final lo = math.log(
        math.max(modelFromSeconds, MeanMaxCurveChart._minSeconds),
      );
      final hi = math.log(MeanMaxCurveChart._maxSeconds);
      for (var i = 0; i <= steps; i++) {
        final t = math.exp(lo + (hi - lo) * i / steps);
        final point = Offset(layout.x(t), y(m(t).clamp(min, max)));
        i == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      _dashedPath(
        canvas,
        path,
        Paint()
          ..color = CcColors.ink.withValues(alpha: 0.7)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
    }

    final other = comparison;
    if (other != null && !other.isEmpty) {
      canvas.drawPath(
        _pathOf(other, y),
        Paint()
          ..color = CcColors.inkDim.withValues(alpha: 0.6)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke,
      );
    }

    if (!curve.isEmpty) {
      canvas.drawPath(
        _pathOf(curve, y),
        Paint()
          ..color = color
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      );
      for (final e in curve.points.entries) {
        final center = Offset(layout.x(e.key.toDouble()), y(e.value.value));
        final gold = highlighted.contains(e.key);
        canvas.drawCircle(
          center,
          gold ? 3.6 : 2.6,
          Paint()..color = gold ? CcColors.gold : color,
        );
      }
    }

    final s = selected;
    if (s != null) {
      final xs = layout.x(s.toDouble());
      canvas.drawLine(
        Offset(xs, _ChartLayout.top),
        Offset(xs, size.height - _ChartLayout.bottom),
        Paint()
          ..color = CcColors.ink.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
      for (final c in [curve, ?comparison]) {
        final p = c[s];
        if (p == null) continue;
        canvas.drawCircle(
          Offset(xs, y(p.value)),
          4.5,
          Paint()
            ..color = identical(c, curve) ? color : CcColors.inkDim
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  Path _pathOf(MeanMaxCurve c, double Function(double) y) {
    final path = Path();
    var first = true;
    for (final e in c.points.entries) {
      final point = Offset(layout.x(e.key.toDouble()), y(e.value.value));
      if (first) {
        path.moveTo(point.dx, point.dy);
        first = false;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  void _paintGrid(
    Canvas canvas,
    double min,
    double max,
    double Function(double) y,
  ) {
    final grid = Paint()
      ..color = CcColors.lineSoft
      ..strokeWidth = 1;
    final right = layout.size.width - _ChartLayout.right;
    for (var i = 0; i <= 2; i++) {
      final v = min + (max - min) * i / 2;
      final yy = y(v);
      canvas.drawLine(Offset(_ChartLayout.left, yy), Offset(right, yy), grid);
      _text(
        canvas,
        v.round().toString(),
        Offset(_ChartLayout.left - 5, yy),
        CcColors.inkFaint,
        alignRight: true,
      );
    }
    final bottom = layout.size.height - _ChartLayout.bottom;
    for (final t in MeanMaxCurveChart._ticks) {
      final xx = layout.x(t.toDouble());
      canvas.drawLine(Offset(xx, _ChartLayout.top), Offset(xx, bottom), grid);
      _text(
        canvas,
        t < 60 ? '${t}s' : '${t ~/ 60}m',
        Offset(xx, bottom + 3),
        CcColors.inkFaint,
        center: true,
      );
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset anchor,
    Color color, {
    bool alignRight = false,
    bool center = false,
    bool above = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 9, fontFamily: CcType.body),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = anchor.dx;
    if (alignRight) dx -= painter.width;
    if (center) dx -= painter.width / 2;
    final dy = above
        ? anchor.dy - painter.height
        : (center ? anchor.dy : anchor.dy - painter.height / 2);
    painter.paint(canvas, Offset(dx, dy));
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0, gap = 4.0;
    final length = (b - a).distance;
    final direction = (b - a) / length;
    for (var d = 0.0; d < length; d += dash + gap) {
      canvas.drawLine(
        a + direction * d,
        a + direction * math.min(d + dash, length),
        paint,
      );
    }
  }

  void _dashedPath(Canvas canvas, Path path, Paint paint) {
    const dash = 5.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.curve != curve ||
      old.comparison != comparison ||
      old.model != model ||
      old.reference != reference ||
      old.color != color ||
      old.selected != selected ||
      old.layout.size != layout.size ||
      old.highlighted != highlighted;
}
