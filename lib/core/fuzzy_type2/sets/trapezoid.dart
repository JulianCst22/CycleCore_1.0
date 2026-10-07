import 'dart:math' as math;

import 'interval.dart';

/// Función de pertenencia trapezoidal: sube de [a] a [b], vale 1 entre
/// [b] y [c] y baja de [c] a [d].
///
/// Es la única forma que usa el motor: un triángulo es `b == c` y un
/// hombro abierto se escribe con `a = b = -∞` o `c = d = +∞` (ver
/// [Trapezoid.leftShoulder] y [Trapezoid.rightShoulder]).
///
/// Se admite `b > c` solo en trapecios erosionados (la curva inferior de
/// una huella de incertidumbre): ahí las dos rampas se cruzan antes de
/// llegar a 1 y la figura queda como un triángulo más bajo.
final class Trapezoid {
  final double a;
  final double b;
  final double c;
  final double d;

  const Trapezoid(this.a, this.b, this.c, this.d) : assert(a <= b && c <= d);

  /// Vale 1 hasta [c] y baja a 0 en [d].
  const Trapezoid.leftShoulder(this.c, this.d)
    : a = double.negativeInfinity,
      b = double.negativeInfinity,
      assert(c <= d);

  /// Sube de [a] a [b] y vale 1 desde ahí en adelante.
  const Trapezoid.rightShoulder(this.a, this.b)
    : c = double.infinity,
      d = double.infinity,
      assert(a <= b);

  double _rise(double x) {
    if (a == double.negativeInfinity) return 1;
    if (b == a) return x >= a ? 1 : 0;
    return (x - a) / (b - a);
  }

  double _fall(double x) {
    if (d == double.infinity) return 1;
    if (d == c) return x <= d ? 1 : 0;
    return (d - x) / (d - c);
  }

  /// Grado de pertenencia de [x].
  double mu(double x) {
    final v = math.min(1.0, math.min(_rise(x), _fall(x)));
    return v < 0 ? 0 : v;
  }

  /// Vértice de un trapecio erosionado (`b > c`): dónde se cruzan la
  /// rampa de subida y la de bajada.
  double get _apexX {
    assert(b > c);
    final rise = b - a, fall = d - c;
    return (a * fall + d * rise) / (fall + rise);
  }

  /// Tiene un escalón vertical (`a == b` o `c == d` finitos) en algún
  /// punto estrictamente dentro de `(lo, hi)`.
  bool hasStepInside(double lo, double hi) =>
      (a.isFinite && a == b && a > lo && a < hi) ||
      (d.isFinite && c == d && d > lo && d < hi);

  /// Pertenencia de un valor incierto que puede estar en cualquier punto
  /// de [x]: `[mínimo, máximo]` de [mu] sobre el intervalo.
  ///
  /// Como el trapecio sube y baja una sola vez, el mínimo está siempre
  /// en un extremo y el máximo en un extremo o en el vértice.
  Interval degreeOver(Interval x) {
    final atLo = mu(x.lo), atHi = mu(x.hi);
    final lower = math.min(atLo, atHi);
    var upper = math.max(atLo, atHi);
    if (b <= c) {
      if (x.hi >= b && x.lo <= c) upper = 1;
    } else if (x.contains(_apexX)) {
      upper = math.max(upper, mu(_apexX));
    }
    return Interval(lower, upper);
  }

  /// Trapecio ensanchado una distancia [u] a cada lado: la curva
  /// superior de su huella de incertidumbre. Los bordes que ya están en
  /// el límite del universo (`min`/`max`) o son infinitos no se mueven.
  Trapezoid dilate(double u, {double? min, double? max}) =>
      _shift(-u, u, min: min, max: max);

  /// Trapecio estrechado una distancia [u] a cada lado: la curva
  /// inferior de su huella de incertidumbre.
  Trapezoid erode(double u, {double? min, double? max}) =>
      _shift(u, -u, min: min, max: max);

  Trapezoid _shift(double left, double right, {double? min, double? max}) {
    if (left == 0 && right == 0) return this;
    final pinLeft = min != null && a <= min && b <= min;
    final pinRight = max != null && c >= max && d >= max;
    return Trapezoid(
      pinLeft ? a : a + left,
      pinLeft ? b : b + left,
      pinRight ? c : c + right,
      pinRight ? d : d + right,
    );
  }

  /// El mismo trapecio con sus quiebres finitos multiplicados por
  /// [factor]: mueve los umbrales sin cambiar la forma de la partición.
  ///
  /// Se usa en el análisis de sensibilidad («¿y si los quiebres
  /// estuvieran un 10 % más arriba?»). Como todos los quiebres se mueven
  /// igual, dos trapecios vecinos que compartían un quiebre lo siguen
  /// compartiendo: la partición de Ruspini se conserva.
  Trapezoid scaled(double factor) {
    assert(factor > 0);
    if (factor == 1) return this;
    double at(double x) => x.isFinite ? x * factor : x;
    return Trapezoid(at(a), at(b), at(c), at(d));
  }

  /// Abscisas donde la figura cambia de pendiente, incluido el vértice
  /// de un trapecio erosionado. Solo las finitas.
  Iterable<double> get breakpoints sync* {
    for (final v in [a, b, c, d]) {
      if (v.isFinite) yield v;
    }
    if (b > c) yield _apexX;
  }

  @override
  bool operator ==(Object other) =>
      other is Trapezoid &&
      other.a == a &&
      other.b == b &&
      other.c == c &&
      other.d == d;

  @override
  int get hashCode => Object.hash(a, b, c, d);

  @override
  String toString() => 'Trapezoid($a, $b, $c, $d)';
}
