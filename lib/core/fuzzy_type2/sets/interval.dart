/// Intervalo cerrado `[lo, hi]` de números reales.
///
/// Es la unidad de trabajo de todo el módulo: en tipo-2 de intervalo cada
/// grado de pertenencia, cada fuerza de disparo y el centroide final son
/// intervalos. El tipo-1 es el caso degenerado `lo == hi`, así que el
/// mismo código sirve para los dos.
final class Interval {
  final double lo;
  final double hi;

  const Interval(this.lo, this.hi) : assert(lo <= hi);

  /// Intervalo de ancho cero: un valor exacto (tipo-1).
  const Interval.point(double value) : lo = value, hi = value;

  /// Intervalo simétrico `[center - halfWidth, center + halfWidth]`.
  Interval.around(double center, double halfWidth)
    : assert(halfWidth >= 0),
      lo = center - halfWidth,
      hi = center + halfWidth;

  static const zero = Interval.point(0);

  double get mid => (lo + hi) / 2;
  double get width => hi - lo;
  bool get isPoint => lo == hi;

  bool contains(double x, {double tolerance = 0}) =>
      x >= lo - tolerance && x <= hi + tolerance;

  /// Multiplica ambos extremos por un factor no negativo (certeza,
  /// credibilidad): conserva el orden de los extremos.
  Interval scale(double factor) {
    assert(factor >= 0);
    return Interval(lo * factor, hi * factor);
  }

  /// Unión por máximo, extremo a extremo: la activación de una etiqueta
  /// que proponen varias reglas.
  Interval maxWith(Interval other) =>
      Interval(lo > other.lo ? lo : other.lo, hi > other.hi ? hi : other.hi);

  @override
  bool operator ==(Object other) =>
      other is Interval && other.lo == lo && other.hi == hi;

  @override
  int get hashCode => Object.hash(lo, hi);

  @override
  String toString() => isPoint ? '[$lo]' : '[$lo, $hi]';
}
