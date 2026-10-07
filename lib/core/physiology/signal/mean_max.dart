/// Duraciones de la curva de medias máximas: de 5 s a 60 min.
const standardDurations = <int>[
  5,
  10,
  15,
  30,
  60,
  120,
  180,
  300,
  600,
  720,
  1200,
  1800,
  3600,
];

/// Mejor media de una duración, con dónde y de dónde salió.
///
/// [source] identifica el origen (por ejemplo, el id de la actividad) sin
/// que este módulo sepa qué es una actividad.
typedef MeanMaxPoint = ({double value, int startSecond, Object? source});

/// Curva de medias máximas: la mejor media sostenida de cada duración.
///
/// Sirve para cualquier señal de 1 Hz: potencia (curva de potencia) o
/// pulso (curva de FC). Es la entrada de la regresión de potencia crítica.
final class MeanMaxCurve {
  final Map<int, MeanMaxPoint> points;

  MeanMaxCurve._(Map<int, MeanMaxPoint> points)
    : points = Map.unmodifiable(
        Map.fromEntries(
          points.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        ),
      );

  const MeanMaxCurve.empty() : points = const {};

  /// Curva a partir de puntos ya calculados (por ejemplo, leídos de la
  /// base de datos).
  factory MeanMaxCurve.fromPoints(Map<int, MeanMaxPoint> points) {
    assert(points.keys.every((d) => d > 0), 'Duraciones no positivas');
    return MeanMaxCurve._(points);
  }

  /// Curva de una serie de 1 Hz. Una ventana que contiene algún segundo
  /// `null` (sin lectura) no cuenta: una media con huecos no es un
  /// esfuerzo sostenido.
  ///
  /// Con sumas prefijas cada duración cuesta O(n).
  factory MeanMaxCurve.fromSeries(
    List<double?> series, {
    List<int> durations = standardDurations,
    Object? source,
  }) {
    final n = series.length;
    final sums = List<double>.filled(n + 1, 0);
    final gaps = List<int>.filled(n + 1, 0);
    for (var i = 0; i < n; i++) {
      final v = series[i];
      sums[i + 1] = sums[i] + (v ?? 0);
      gaps[i + 1] = gaps[i] + (v == null ? 1 : 0);
    }
    final out = <int, MeanMaxPoint>{};
    for (final d in durations) {
      assert(d > 0);
      if (d > n) continue;
      double? best;
      var bestStart = 0;
      for (var k = 0; k + d <= n; k++) {
        if (gaps[k + d] - gaps[k] > 0) continue;
        final mean = (sums[k + d] - sums[k]) / d;
        if (best == null || mean > best) {
          best = mean;
          bestStart = k;
        }
      }
      if (best != null) {
        out[d] = (value: best, startSecond: bestStart, source: source);
      }
    }
    return MeanMaxCurve._(out);
  }

  MeanMaxPoint? operator [](int duration) => points[duration];

  bool get isEmpty => points.isEmpty;

  /// Curva que conserva, para cada duración, el mejor valor de las dos.
  /// Así se arma el histórico: se combinan las curvas de cada actividad.
  MeanMaxCurve mergeWith(MeanMaxCurve other) {
    final out = Map<int, MeanMaxPoint>.of(points);
    for (final e in other.points.entries) {
      final mine = out[e.key];
      if (mine == null || e.value.value > mine.value) out[e.key] = e.value;
    }
    return MeanMaxCurve._(out);
  }

  /// Mejor curva de un conjunto de curvas.
  static MeanMaxCurve best(Iterable<MeanMaxCurve> curves) =>
      curves.fold(const MeanMaxCurve.empty(), (a, b) => a.mergeWith(b));
}
