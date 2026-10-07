import 'dart:math' as math;

import '../sets/polyline.dart';

/// Máximo local de una figura: una meseta `[from, to]` a altura [height].
typedef Peak = ({double from, double to, double height});

/// Lo que dice la forma de una figura difusa además de su centroide.
///
/// Se calcula una sola vez por figura; el motor lo expone para la figura
/// superior y la inferior de cada salida, y quien lo consume decide cuál
/// mirar (por ejemplo, el rango con la superior y el núcleo con la
/// inferior).
final class ShapeDescriptors {
  /// Umbral de bimodalidad: el segundo pico debe llegar a esta fracción
  /// del principal, y el valle entre ambos debe quedar por debajo.
  static const bimodalRatio = 0.6;

  final Polyline figure;
  final double height;
  final double area;
  final double? centroid;
  final double? standardDeviation;
  final List<Peak> peaks;

  ShapeDescriptors._(
    this.figure,
    this.height,
    this.area,
    this.centroid,
    this.standardDeviation,
    this.peaks,
  );

  factory ShapeDescriptors.of(Polyline figure) {
    final i = figure.integrals();
    final centroid = i.area > 0 ? i.moment / i.area : null;
    final variance = centroid == null
        ? null
        : i.second / i.area - centroid * centroid;
    return ShapeDescriptors._(
      figure,
      figure.height,
      i.area,
      centroid,
      variance == null ? null : math.sqrt(math.max(0, variance)),
      List.unmodifiable(_peaks(figure)),
    );
  }

  ({double lo, double hi})? alphaCut(double alpha) => figure.alphaCut(alpha);

  int? get _mainIndex {
    if (peaks.isEmpty) return null;
    var best = 0;
    for (var i = 1; i < peaks.length; i++) {
      if (peaks[i].height > peaks[best].height) best = i;
    }
    return best;
  }

  /// Pico principal (el más alto; ante empate, el primero).
  Peak? get mainPeak {
    final i = _mainIndex;
    return i == null ? null : peaks[i];
  }

  /// Segundo pico más alto, si existe.
  Peak? get secondaryPeak {
    final main = _mainIndex;
    if (main == null || peaks.length < 2) return null;
    int? best;
    for (var i = 0; i < peaks.length; i++) {
      if (i == main) continue;
      if (best == null || peaks[i].height > peaks[best].height) best = i;
    }
    return peaks[best!];
  }

  /// Altura del segundo pico relativa al principal (0 si no hay).
  double get secondaryRatio {
    final main = mainPeak, second = secondaryPeak;
    if (main == null || second == null || main.height == 0) return 0;
    return second.height / main.height;
  }

  /// Punto más bajo de la figura entre los dos picos principales.
  double? get valley {
    final main = mainPeak, second = secondaryPeak;
    if (main == null || second == null) return null;
    final from = math.min(main.to, second.to);
    final to = math.max(main.from, second.from);
    var lowest = double.infinity;
    for (final v in figure.vertices) {
      if (v.x > from && v.x < to) lowest = math.min(lowest, v.y);
    }
    return lowest.isFinite ? lowest : null;
  }

  /// Dos jorobas comparables separadas por un valle: el centroide caería
  /// en un valor que ninguna regla apoyó.
  bool get isBimodal {
    final main = mainPeak, v = valley;
    if (main == null || v == null) return false;
    return secondaryRatio >= bimodalRatio && v < bimodalRatio * main.height;
  }

  /// Centro de la meseta del pico principal.
  double? get mode {
    final main = mainPeak;
    return main == null ? null : (main.from + main.to) / 2;
  }

  /// Primer coeficiente de asimetría de Pearson: `(centroide − moda)/σ`.
  /// Positivo si la cola tira hacia valores mayores.
  double? get skewness {
    final c = centroid, m = mode, s = standardDeviation;
    if (c == null || m == null || s == null || s == 0) return null;
    return (c - m) / s;
  }

  static List<Peak> _peaks(Polyline figure) {
    final vs = figure.vertices;
    final out = <Peak>[];
    var i = 0;
    while (i < vs.length) {
      final y = vs[i].y;
      var j = i;
      while (j < vs.length - 1 && vs[j + 1].y == y) {
        j++;
      }
      final risesInto = i == 0 || vs[i - 1].y < y;
      final fallsFrom = j == vs.length - 1 || vs[j + 1].y < y;
      if (y > 0 && risesInto && fallsFrom) {
        out.add((from: vs[i].x, to: vs[j].x, height: y));
      }
      i = j + 1;
    }
    return out;
  }
}
