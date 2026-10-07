import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/fuzzy_type2/fuzzy_type2.dart';
import '../../../../core/ui/ui.dart';

/// Dibuja la huella de incertidumbre de una salida del motor: la figura
/// superior, la inferior y la franja entre las dos, con el centroide de
/// intervalo `[y_l, y_r]` marcado.
///
/// Es la imagen que explica el tipo-2 de un vistazo: en tipo-1 las dos
/// figuras coinciden y la franja desaparece.
class FootprintPainter extends CustomPainter {
  final OutputInference output;
  final Color accent;

  /// Trapecios de las etiquetas, de fondo: ayudan a leer en qué etiqueta
  /// cayó el resultado.
  final bool showTerms;

  const FootprintPainter({
    required this.output,
    required this.accent,
    this.showTerms = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final variable = output.variable;
    final min = variable.min, max = variable.max;
    final span = max - min;
    if (span <= 0 || size.width <= 0 || size.height <= 0) return;

    const top = 6.0;
    final base = size.height - 14;
    double dx(double x) => (x - min) / span * size.width;
    double dy(double mu) => base - mu * (base - top);

    // Eje.
    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = CcColors.line
        ..strokeWidth = 1,
    );

    if (showTerms) {
      final termPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = CcColors.line;
      for (final label in variable.labels) {
        final trapezoid = variable.term(label);
        final path = Path();
        var first = true;
        for (final x in [
          min,
          ...trapezoid.breakpoints.where((v) => v > min && v < max),
          max,
        ]) {
          final point = Offset(dx(x), dy(trapezoid.mu(x)));
          first
              ? path.moveTo(point.dx, point.dy)
              : path.lineTo(point.dx, point.dy);
          first = false;
        }
        canvas.drawPath(path, termPaint);
      }
    }

    final upper = _pathOf(output.upper, dx, dy);
    final lower = _pathOf(output.lower, dx, dy);

    // La franja de incertidumbre es lo que hay entre las dos figuras.
    final band = Path.combine(
      PathOperation.difference,
      _closed(upper, base),
      _closed(lower, base),
    );
    canvas.drawPath(band, Paint()..color = accent.withValues(alpha: 0.22));
    canvas.drawPath(
      _closed(lower, base),
      Paint()..color = accent.withValues(alpha: 0.42),
    );
    canvas.drawPath(
      upper,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = accent,
    );
    canvas.drawPath(
      lower,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = accent.withValues(alpha: 0.7),
    );

    final centroid = output.centroid;
    if (centroid == null) return;
    final marker = Paint()
      ..color = CcColors.ink
      ..strokeWidth = 1;
    for (final x in [centroid.lo, centroid.hi]) {
      canvas.drawLine(Offset(dx(x), top), Offset(dx(x), base), marker);
    }
    canvas.drawLine(
      Offset(dx(centroid.mid), top),
      Offset(dx(centroid.mid), base),
      Paint()
        ..color = CcColors.ink
        ..strokeWidth = 2.2,
    );
    _text(canvas, _round(min), Offset(2, base + 2), Alignment.centerLeft);
    _text(
      canvas,
      _round(max),
      Offset(size.width - 2, base + 2),
      Alignment.centerRight,
    );
  }

  static Path _pathOf(
    Polyline figure,
    double Function(double) dx,
    double Function(double) dy,
  ) {
    final path = Path();
    for (var i = 0; i < figure.vertices.length; i++) {
      final v = figure.vertices[i];
      final point = Offset(dx(v.x), dy(v.y));
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  /// La misma figura cerrada contra el eje, para poder rellenarla.
  static Path _closed(Path figure, double base) {
    final bounds = figure.getBounds();
    return Path.from(figure)
      ..lineTo(bounds.right, base)
      ..lineTo(bounds.left, base)
      ..close();
  }

  static String _round(double x) =>
      x.abs() >= 10 ? x.toStringAsFixed(0) : x.toStringAsFixed(1);

  static void _text(Canvas canvas, String text, Offset at, Alignment align) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: CcColors.inkFaint, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = align == Alignment.centerRight ? at.dx - painter.width : at.dx;
    painter.paint(canvas, Offset(math.max(0, dx), at.dy));
  }

  @override
  bool shouldRepaint(FootprintPainter old) =>
      old.output != output || old.accent != accent;
}
