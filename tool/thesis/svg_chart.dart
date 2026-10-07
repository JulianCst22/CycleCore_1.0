import 'dart:math' as math;

import 'package:cyclecore_app/core/fuzzy_type2/fuzzy_type2.dart';

import 'control_surface.dart';

/// Dibujo de figuras en SVG puro, sin dependencias.
///
/// SVG porque las figuras de la tesis se imprimen: son vectoriales, se
/// ven bien a cualquier tamaño y se abren en cualquier navegador o
/// editor. Fondo blanco y tinta oscura, para pegarlas en el documento.

const _ink = '#1A2230';
const _muted = '#6B7688';
const _grid = '#D8DEE8';
const kOrange = '#FF6B35';
const kBlue = '#2F80C4';
const kGreen = '#2F9E68';
const kPurple = '#8155C6';
const kGray = '#8C96A8';

typedef ChartPoint = ({double x, double y});

/// Una línea de un gráfico.
final class ChartSeries {
  final String name;
  final String color;
  final List<ChartPoint> points;
  final bool dashed;
  final double width;

  const ChartSeries({
    required this.name,
    required this.color,
    required this.points,
    this.dashed = false,
    this.width = 1.8,
  });
}

/// Una franja entre dos curvas: es como se dibuja un intervalo tipo-2.
final class ChartBand {
  final String name;
  final String color;
  final List<({double x, double lo, double hi})> points;

  const ChartBand({
    required this.name,
    required this.color,
    required this.points,
  });
}

/// Una marca vertical con etiqueta (por ejemplo, un aviso del coach).
typedef ChartMark = ({double x, String label});

/// Gráfico de líneas con ejes, rejilla y leyenda.
String lineChartSvg({
  required String title,
  required String xLabel,
  required String yLabel,
  required List<ChartSeries> series,
  List<ChartBand> bands = const [],
  List<ChartMark> marks = const [],
  double? yMin,
  double? yMax,
  String? note,
  double width = 880,
  double height = 420,
}) {
  final all = [
    for (final s in series) ...s.points,
    for (final b in bands)
      for (final p in b.points) ...[(x: p.x, y: p.lo), (x: p.x, y: p.hi)],
  ];
  if (all.isEmpty) return _empty(title, width, height);

  final xLo = all.map((p) => p.x).reduce(math.min);
  final xHi = all.map((p) => p.x).reduce(math.max);
  var yLo = yMin ?? all.map((p) => p.y).reduce(math.min);
  var yHi = yMax ?? all.map((p) => p.y).reduce(math.max);
  if (yHi - yLo < 1e-9) {
    yLo -= 1;
    yHi += 1;
  } else {
    final pad = (yHi - yLo) * 0.08;
    if (yMin == null) yLo -= pad;
    if (yMax == null) yHi += pad;
  }

  const left = 68.0, right = 24.0, top = 56.0;
  final bottom = note == null ? 62.0 : 78.0;
  final plotWidth = width - left - right;
  final plotHeight = height - top - bottom;
  double px(double x) =>
      left + (xHi - xLo == 0 ? 0 : (x - xLo) / (xHi - xLo)) * plotWidth;
  double py(double y) =>
      top + plotHeight - (y - yLo) / (yHi - yLo) * plotHeight;

  final out = StringBuffer();
  out.write(_header(width, height));
  out.write(_title(title, left));

  // Rejilla y ejes.
  for (final tick in _ticks(yLo, yHi)) {
    final y = py(tick);
    out.write(
      '<line x1="$left" y1="${_f(y)}" x2="${_f(left + plotWidth)}" '
      'y2="${_f(y)}" stroke="$_grid" stroke-width="1"/>',
    );
    out.write(
      '<text x="${_f(left - 8)}" y="${_f(y + 4)}" text-anchor="end" '
      'font-size="11" fill="$_muted">${_f(tick)}</text>',
    );
  }
  for (final tick in _ticks(xLo, xHi)) {
    final x = px(tick);
    out.write(
      '<line x1="${_f(x)}" y1="$top" x2="${_f(x)}" '
      'y2="${_f(top + plotHeight)}" stroke="$_grid" stroke-width="1"/>',
    );
    out.write(
      '<text x="${_f(x)}" y="${_f(top + plotHeight + 18)}" '
      'text-anchor="middle" font-size="11" fill="$_muted">${_f(tick)}</text>',
    );
  }

  for (final band in bands) {
    final up = band.points.map((p) => '${_f(px(p.x))},${_f(py(p.hi))}');
    final down = band.points.reversed.map(
      (p) => '${_f(px(p.x))},${_f(py(p.lo))}',
    );
    out.write(
      '<polygon points="${[...up, ...down].join(' ')}" fill="${band.color}" '
      'fill-opacity="0.18"/>',
    );
  }

  for (final mark in marks) {
    final x = px(mark.x);
    out.write(
      '<line x1="${_f(x)}" y1="$top" x2="${_f(x)}" '
      'y2="${_f(top + plotHeight)}" stroke="$kOrange" stroke-width="1" '
      'stroke-dasharray="3 3" stroke-opacity="0.65"/>',
    );
    if (mark.label.isNotEmpty) {
      out.write(
        '<text x="${_f(x + 3)}" y="${_f(top + 12)}" font-size="9" '
        'fill="$kOrange">${_escape(mark.label)}</text>',
      );
    }
  }

  for (final s in series) {
    if (s.points.isEmpty) continue;
    final points = s.points.map((p) => '${_f(px(p.x))},${_f(py(p.y))}');
    out.write(
      '<polyline points="${points.join(' ')}" fill="none" '
      'stroke="${s.color}" stroke-width="${s.width}" '
      'stroke-linejoin="round" stroke-linecap="round"'
      '${s.dashed ? ' stroke-dasharray="6 4"' : ''}/>',
    );
  }

  out.write(_axes(left, top, plotWidth, plotHeight));
  out.write(
    '<text x="${_f(left + plotWidth / 2)}" '
    'y="${_f(top + plotHeight + 38)}" text-anchor="middle" font-size="12" '
    'fill="$_ink">${_escape(xLabel)}</text>',
  );
  out.write(
    '<text transform="translate(18 ${_f(top + plotHeight / 2)}) rotate(-90)" '
    'text-anchor="middle" font-size="12" fill="$_ink">'
    '${_escape(yLabel)}</text>',
  );
  out.write(
    _legend(
      [
        for (final b in bands) (name: b.name, color: b.color),
        for (final s in series) (name: s.name, color: s.color),
      ],
      left,
      top - 14,
      plotWidth,
    ),
  );
  if (note != null) out.write(_note(note, left, height - 16));
  out.write('</svg>\n');
  return out.toString();
}

/// Mapa de calor de una superficie de control.
String surfaceSvg(ControlSurface surface, {double width = 720}) {
  final range = surface.range;
  const left = 74.0, top = 58.0, right = 96.0, bottom = 74.0;
  final plot = width - left - right;
  final height = plot + top + bottom;
  final cellWidth = plot / surface.xs.length;
  final cellHeight = plot / surface.ys.length;

  final out = StringBuffer();
  out.write(_header(width, height));
  out.write(_title('Superficie de control · ${surface.zLabel}', left));

  for (var i = 0; i < surface.ys.length; i++) {
    for (var j = 0; j < surface.xs.length; j++) {
      final value = surface.z[i][j];
      // Las filas van de abajo hacia arriba: y crece hacia arriba.
      final y = top + plot - (i + 1) * cellHeight;
      final x = left + j * cellWidth;
      final color = value == null
          ? '#EEF1F6'
          : _scale((value - range.lo) / (range.hi - range.lo));
      out.write(
        '<rect x="${_f(x)}" y="${_f(y)}" width="${_f(cellWidth + 0.6)}" '
        'height="${_f(cellHeight + 0.6)}" fill="$color"/>',
      );
    }
  }

  for (final tick in _ticks(surface.xs.first, surface.xs.last)) {
    final t = (tick - surface.xs.first) / (surface.xs.last - surface.xs.first);
    final x = left + t * plot;
    out.write(
      '<text x="${_f(x)}" y="${_f(top + plot + 18)}" text-anchor="middle" '
      'font-size="11" fill="$_muted">${_f(tick)}</text>',
    );
  }
  for (final tick in _ticks(surface.ys.first, surface.ys.last)) {
    final t = (tick - surface.ys.first) / (surface.ys.last - surface.ys.first);
    final y = top + plot - t * plot;
    out.write(
      '<text x="${_f(left - 8)}" y="${_f(y + 4)}" text-anchor="end" '
      'font-size="11" fill="$_muted">${_f(tick)}</text>',
    );
  }
  out.write(_axes(left, top, plot, plot));
  out.write(
    '<text x="${_f(left + plot / 2)}" y="${_f(top + plot + 38)}" '
    'text-anchor="middle" font-size="12" fill="$_ink">'
    '${_escape(surface.xLabel)}</text>',
  );
  out.write(
    '<text transform="translate(20 ${_f(top + plot / 2)}) rotate(-90)" '
    'text-anchor="middle" font-size="12" fill="$_ink">'
    '${_escape(surface.yLabel)}</text>',
  );

  // Barra de color.
  final barX = left + plot + 22;
  const barWidth = 14.0;
  for (var i = 0; i < 60; i++) {
    final t = i / 59;
    out.write(
      '<rect x="${_f(barX)}" y="${_f(top + plot - (i + 1) * plot / 60)}" '
      'width="$barWidth" height="${_f(plot / 60 + 0.6)}" '
      'fill="${_scale(t)}"/>',
    );
  }
  out.write(
    '<text x="${_f(barX + barWidth + 4)}" y="${_f(top + 10)}" font-size="10" '
    'fill="$_muted">${_f(range.hi)}</text>'
    '<text x="${_f(barX + barWidth + 4)}" y="${_f(top + plot)}" '
    'font-size="10" fill="$_muted">${_f(range.lo)}</text>',
  );
  out.write(_note('Fijo: ${surface.held}', left, height - 16));
  out.write('</svg>\n');
  return out.toString();
}

/// Las etiquetas de una variable lingüística: la partición completa.
String membershipSvg(
  LinguisticVariable<Enum> variable, {
  double width = 720,
  double height = 260,
}) {
  const left = 56.0, right = 24.0, top = 52.0, bottom = 58.0;
  final plotWidth = width - left - right;
  final plotHeight = height - top - bottom;
  final min = variable.min, max = variable.max;
  double px(double x) => left + (x - min) / (max - min) * plotWidth;
  double py(double mu) => top + plotHeight - mu * plotHeight;

  final colors = [kOrange, kBlue, kGreen, kPurple, kGray];
  final out = StringBuffer();
  out.write(_header(width, height));
  out.write(_title(variable.name, left));
  for (final tick in _ticks(min, max)) {
    out.write(
      '<line x1="${_f(px(tick))}" y1="$top" x2="${_f(px(tick))}" '
      'y2="${_f(top + plotHeight)}" stroke="$_grid" stroke-width="1"/>'
      '<text x="${_f(px(tick))}" y="${_f(top + plotHeight + 18)}" '
      'text-anchor="middle" font-size="11" fill="$_muted">${_f(tick)}</text>',
    );
  }

  final labels = variable.labels.toList();
  for (var i = 0; i < labels.length; i++) {
    final term = variable.term(labels[i]);
    final xs = <double>{
      min,
      max,
      for (final b in term.breakpoints)
        if (b > min && b < max) b,
    }.toList()..sort();
    final points = xs.map((x) => '${_f(px(x))},${_f(py(term.mu(x)))}');
    out.write(
      '<polyline points="${points.join(' ')}" fill="none" '
      'stroke="${colors[i % colors.length]}" stroke-width="2"/>',
    );
  }
  out.write(_axes(left, top, plotWidth, plotHeight));
  out.write(
    _legend(
      [
        for (var i = 0; i < labels.length; i++)
          (name: labels[i].name, color: colors[i % colors.length]),
      ],
      left,
      top - 14,
      plotWidth,
    ),
  );
  out.write('</svg>\n');
  return out.toString();
}

/// La huella de una salida: figura superior, inferior y el centroide de
/// intervalo `[y_l, y_r]`.
String footprintSvg(
  OutputInference output, {
  required String title,
  String? note,
  double width = 720,
  double height = 300,
}) {
  const left = 56.0, right = 24.0, top = 56.0;
  final bottom = note == null ? 54.0 : 70.0;
  final plotWidth = width - left - right;
  final plotHeight = height - top - bottom;
  final variable = output.variable;
  final min = variable.min, max = variable.max;
  double px(double x) => left + (x - min) / (max - min) * plotWidth;
  double py(double mu) => top + plotHeight - mu * plotHeight;
  String path(Polyline figure) =>
      figure.vertices.map((v) => '${_f(px(v.x))},${_f(py(v.y))}').join(' ');

  final out = StringBuffer();
  out.write(_header(width, height));
  out.write(_title(title, left));
  for (final tick in _ticks(min, max)) {
    out.write(
      '<line x1="${_f(px(tick))}" y1="$top" x2="${_f(px(tick))}" '
      'y2="${_f(top + plotHeight)}" stroke="$_grid" stroke-width="1"/>'
      '<text x="${_f(px(tick))}" y="${_f(top + plotHeight + 18)}" '
      'text-anchor="middle" font-size="11" fill="$_muted">${_f(tick)}</text>',
    );
  }

  final base = _f(top + plotHeight);
  out.write(
    '<polygon points="${path(output.upper)} ${_f(left + plotWidth)},$base '
    '${_f(left)},$base" fill="$kOrange" fill-opacity="0.18"/>',
  );
  out.write(
    '<polygon points="${path(output.lower)} ${_f(left + plotWidth)},$base '
    '${_f(left)},$base" fill="$kOrange" fill-opacity="0.30"/>',
  );
  out.write(
    '<polyline points="${path(output.upper)}" fill="none" stroke="$kOrange" '
    'stroke-width="2"/>',
  );
  out.write(
    '<polyline points="${path(output.lower)}" fill="none" stroke="$kOrange" '
    'stroke-width="1.4" stroke-dasharray="5 3"/>',
  );

  final centroid = output.centroid;
  if (centroid != null) {
    for (final x in [centroid.lo, centroid.hi]) {
      out.write(
        '<line x1="${_f(px(x))}" y1="$top" x2="${_f(px(x))}" y2="$base" '
        'stroke="$_ink" stroke-width="1"/>',
      );
    }
    out.write(
      '<line x1="${_f(px(centroid.mid))}" y1="$top" '
      'x2="${_f(px(centroid.mid))}" y2="$base" stroke="$_ink" '
      'stroke-width="2.2"/>',
    );
    out.write(
      '<text x="${_f(px(centroid.mid) + 5)}" y="${_f(top + 14)}" '
      'font-size="11" fill="$_ink">y* = ${_f(centroid.mid)}   '
      '[${_f(centroid.lo)} · ${_f(centroid.hi)}]</text>',
    );
  }
  out.write(_axes(left, top, plotWidth, plotHeight));
  out.write(
    _legend(
      const [
        (name: 'figura superior', color: kOrange),
        (name: 'figura inferior', color: kOrange),
      ],
      left,
      top - 14,
      plotWidth,
    ),
  );
  if (note != null) out.write(_note(note, left, height - 16));
  out.write('</svg>\n');
  return out.toString();
}

String _header(double width, double height) =>
    '<svg xmlns="http://www.w3.org/2000/svg" width="${_f(width)}" '
    'height="${_f(height)}" viewBox="0 0 ${_f(width)} ${_f(height)}" '
    'font-family="Helvetica, Arial, sans-serif">'
    '<rect width="100%" height="100%" fill="#FFFFFF"/>';

String _title(String text, double left) =>
    '<text x="${_f(left)}" y="28" font-size="15" font-weight="600" '
    'fill="$_ink">${_escape(text)}</text>';

String _note(String text, double left, double y) =>
    '<text x="${_f(left)}" y="${_f(y)}" font-size="10" fill="$_muted">'
    '${_escape(text)}</text>';

String _axes(double left, double top, double w, double h) =>
    '<line x1="${_f(left)}" y1="${_f(top + h)}" x2="${_f(left + w)}" '
    'y2="${_f(top + h)}" stroke="$_ink" stroke-width="1.2"/>'
    '<line x1="${_f(left)}" y1="${_f(top)}" x2="${_f(left)}" '
    'y2="${_f(top + h)}" stroke="$_ink" stroke-width="1.2"/>';

String _legend(
  List<({String name, String color})> entries,
  double left,
  double y,
  double width,
) {
  final out = StringBuffer();
  var x = left;
  for (final entry in entries) {
    out.write(
      '<rect x="${_f(x)}" y="${_f(y - 8)}" width="10" height="10" rx="2" '
      'fill="${entry.color}"/>'
      '<text x="${_f(x + 14)}" y="${_f(y + 1)}" font-size="11" '
      'fill="$_muted">${_escape(entry.name)}</text>',
    );
    x += 22 + entry.name.length * 6.2;
    if (x > left + width - 60) break;
  }
  return out.toString();
}

/// Escala de color secuencial (azul → naranja), legible también en gris.
String _scale(double t) {
  final x = t.isNaN ? 0.0 : t.clamp(0.0, 1.0);
  const from = [0x1F, 0x4E, 0x79];
  const to = [0xFF, 0xA5, 0x3B];
  final rgb = [
    for (var i = 0; i < 3; i++) (from[i] + (to[i] - from[i]) * x).round(),
  ];
  return '#${rgb.map((c) => c.toRadixString(16).padLeft(2, '0')).join()}';
}

/// Cinco marcas redondas dentro del rango.
List<double> _ticks(double lo, double hi) {
  if (hi <= lo) return [lo];
  final raw = (hi - lo) / 5;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  final step = [1.0, 2.0, 2.5, 5.0, 10.0]
      .map((m) => m * magnitude)
      .firstWhere((s) => s >= raw, orElse: () => 10 * magnitude);
  final first = (lo / step).ceil() * step;
  return [for (var t = first; t <= hi + 1e-9; t += step) t];
}

String _empty(String title, double width, double height) =>
    '${_header(width, height)}${_title(title, 56)}'
    '<text x="56" y="80" font-size="12" fill="$_muted">Sin datos</text></svg>\n';

String _f(double value) {
  if (value.abs() >= 100) return value.toStringAsFixed(0);
  if (value.abs() >= 10) return value.toStringAsFixed(1);
  final text = value.toStringAsFixed(2);
  return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
}

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// Matriz de confusión: el motor en las filas, el experto en las
/// columnas, con el conteo en cada celda.
String confusionSvg(
  List<List<int>> matrix,
  List<String> labels, {
  required String title,
  String? note,
  double width = 620,
}) {
  const left = 118.0, top = 62.0, right = 26.0;
  final bottom = note == null ? 78.0 : 96.0;
  final size = matrix.length;
  final cell = (width - left - right) / size;
  final height = top + cell * size + bottom;
  var worst = 1;
  for (final row in matrix) {
    for (final value in row) {
      if (value > worst) worst = value;
    }
  }

  final out = StringBuffer();
  out.write(_header(width, height));
  out.write(_title(title, left - 62));
  for (var i = 0; i < size; i++) {
    out.write(
      '<text x="${_f(left - 8)}" y="${_f(top + i * cell + cell / 2 + 4)}" '
      'text-anchor="end" font-size="11" fill="$_muted">'
      '${_escape(labels[i])}</text>',
    );
    out.write(
      '<text transform="translate(${_f(left + i * cell + cell / 2)} '
      '${_f(top - 10)}) rotate(-35)" font-size="11" fill="$_muted">'
      '${_escape(labels[i])}</text>',
    );
    for (var j = 0; j < size; j++) {
      final value = matrix[i][j];
      out.write(
        '<rect x="${_f(left + j * cell)}" y="${_f(top + i * cell)}" '
        'width="${_f(cell - 1)}" height="${_f(cell - 1)}" '
        'fill="${_scale(value / worst)}" fill-opacity="${i == j ? 1 : 0.75}"/>',
      );
      if (value > 0) {
        out.write(
          '<text x="${_f(left + j * cell + cell / 2)}" '
          'y="${_f(top + i * cell + cell / 2 + 4)}" text-anchor="middle" '
          'font-size="12" font-weight="600" '
          'fill="${value > worst * 0.55 ? '#FFFFFF' : _ink}">$value</text>',
        );
      }
    }
  }
  out.write(
    '<text x="${_f(left - 62)}" y="${_f(top + cell * size + 26)}" '
    'font-size="11" fill="$_ink">Filas: el motor · columnas: el experto. '
    'La diagonal es el acuerdo.</text>',
  );
  if (note != null) out.write(_note(note, left - 62, height - 16));
  out.write('</svg>\n');
  return out.toString();
}
