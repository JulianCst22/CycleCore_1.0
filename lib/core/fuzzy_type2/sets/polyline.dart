import 'dart:math' as math;

import '../logic/norms.dart';
import 'trapezoid.dart';

/// Un vértice de una [Polyline].
typedef Vertex = ({double x, double y});

/// Primer y segundo momento, y área, de una figura sobre un tramo.
typedef Integrals = ({double area, double moment, double second});

/// Un consecuente con su fuerza de disparo: la [Implication] decide si
/// se recorta o se escala a esa altura.
typedef ActivatedTerm = ({Trapezoid term, double height});

/// Función lineal a trozos definida por vértices ordenados en `x`.
///
/// Todas las figuras del motor son polilíneas: un trapecio recortado lo
/// es, y la unión por máximo de polilíneas también lo es si se insertan
/// los cruces entre ellas. Por eso las integrales del centroide y de la
/// reducción de tipo se resuelven en forma cerrada, sin muestrear.
final class Polyline {
  final List<Vertex> vertices;

  Polyline._(this.vertices);

  /// Figura nula sobre `[lo, hi]`.
  factory Polyline.zero(double lo, double hi) =>
      Polyline._(List.unmodifiable([(x: lo, y: 0.0), (x: hi, y: 0.0)]));

  factory Polyline.fromVertices(List<Vertex> vertices) {
    assert(vertices.length >= 2);
    for (var i = 1; i < vertices.length; i++) {
      assert(vertices[i].x >= vertices[i - 1].x);
    }
    return Polyline._(List.unmodifiable(vertices));
  }

  /// Unión exacta por máximo de consecuentes activados, sobre `[lo, hi]`.
  ///
  /// Dentro de cada intervalo entre quiebres consecutivos todas las
  /// funciones son rectas, así que basta con agregar los puntos donde se
  /// cruzan dos de ellas y evaluar el máximo en cada nodo.
  ///
  /// Los consecuentes no pueden tener escalones verticales dentro del
  /// universo (solo en sus bordes): la unión dejaría de ser continua.
  factory Polyline.unionOf(
    Iterable<ActivatedTerm> activated, {
    required double lo,
    required double hi,
    Implication implication = Implication.clip,
  }) {
    final terms = activated.where((t) => t.height > 0).toList();
    if (terms.isEmpty) return Polyline.zero(lo, hi);
    assert(
      terms.every((t) => !t.term.hasStepInside(lo, hi)),
      'Consecuente con un escalón dentro de [$lo, $hi].',
    );

    double f(ActivatedTerm t, double x) => implication(t.height, t.term.mu(x));

    final knots = <double>[lo, hi];
    for (final t in terms) {
      final tr = t.term;
      knots.addAll(tr.breakpoints);
      if (implication == Implication.clip) {
        if (tr.a.isFinite && tr.b.isFinite) {
          knots.add(tr.a + t.height * (tr.b - tr.a));
        }
        if (tr.c.isFinite && tr.d.isFinite) {
          knots.add(tr.d - t.height * (tr.d - tr.c));
        }
      }
    }
    final xs = _sortedUnique(knots.where((x) => x >= lo && x <= hi));

    final nodes = <double>[];
    for (var i = 0; i < xs.length - 1; i++) {
      final x1 = xs[i], x2 = xs[i + 1];
      nodes.add(x1);
      for (var p = 0; p < terms.length; p++) {
        for (var q = p + 1; q < terms.length; q++) {
          final d1 = f(terms[p], x1) - f(terms[q], x1);
          final d2 = f(terms[p], x2) - f(terms[q], x2);
          if (d1 * d2 < 0) nodes.add(x1 + d1 / (d1 - d2) * (x2 - x1));
        }
      }
    }
    nodes.add(xs.last);

    final vertices = [
      for (final x in _sortedUnique(nodes))
        (x: x, y: terms.map((t) => f(t, x)).reduce(math.max)),
    ];
    return Polyline._(List.unmodifiable(_dropCollinear(vertices)));
  }

  double get lo => vertices.first.x;
  double get hi => vertices.last.x;

  /// Altura máxima de la figura.
  double get height => vertices.map((v) => v.y).reduce(math.max);

  /// Valor de la figura en [x] (0 fuera del dominio).
  double valueAt(double x) {
    if (x < lo || x > hi) return 0;
    var low = 0, high = vertices.length - 1;
    while (high - low > 1) {
      final mid = (low + high) >> 1;
      if (vertices[mid].x <= x) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final v1 = vertices[low], v2 = vertices[high];
    if (v2.x == v1.x) return math.max(v1.y, v2.y);
    return v1.y + (v2.y - v1.y) * (x - v1.x) / (v2.x - v1.x);
  }

  /// Área `∫μ`, momento `∫y·μ` y segundo momento `∫y²·μ` sobre
  /// `[from, to]` (todo el dominio por defecto), tramo por tramo:
  ///
  ///     A = h(μ₁+μ₂)/2
  ///     M = h/6 · [x₁(2μ₁+μ₂) + x₂(μ₁+2μ₂)]
  ///     Q = h/12 · [μ₁(3x₁²+2x₁x₂+x₂²) + μ₂(x₁²+2x₁x₂+3x₂²)]
  Integrals integrals([double? from, double? to]) {
    final start = from ?? lo, end = to ?? hi;
    var area = 0.0, moment = 0.0, second = 0.0;
    for (var i = 0; i < vertices.length - 1; i++) {
      var x1 = vertices[i].x, y1 = vertices[i].y;
      var x2 = vertices[i + 1].x, y2 = vertices[i + 1].y;
      if (x2 <= start || x1 >= end) continue;
      if (x1 < start) {
        y1 = valueAt(start);
        x1 = start;
      }
      if (x2 > end) {
        y2 = valueAt(end);
        x2 = end;
      }
      final h = x2 - x1;
      area += h * (y1 + y2) / 2;
      moment += h / 6 * (x1 * (2 * y1 + y2) + x2 * (y1 + 2 * y2));
      second +=
          h /
          12 *
          (y1 * (3 * x1 * x1 + 2 * x1 * x2 + x2 * x2) +
              y2 * (x1 * x1 + 2 * x1 * x2 + 3 * x2 * x2));
    }
    return (area: area, moment: moment, second: second);
  }

  /// Centroide exacto; `null` si la figura no tiene área.
  double? get centroid {
    final i = integrals();
    return i.area > 0 ? i.moment / i.area : null;
  }

  /// Extremos del conjunto `{y : μ(y) ≥ alpha}` (su envolvente, si no es
  /// convexo); `null` si la figura nunca llega a [alpha].
  ({double lo, double hi})? alphaCut(double alpha) {
    double? left, right;
    for (var i = 0; i < vertices.length - 1 && left == null; i++) {
      left = _crossing(vertices[i], vertices[i + 1], alpha, fromLeft: true);
    }
    for (var i = vertices.length - 1; i > 0 && right == null; i--) {
      right = _crossing(vertices[i - 1], vertices[i], alpha, fromLeft: false);
    }
    if (left == null || right == null) return null;
    return (lo: left, hi: right);
  }

  static double? _crossing(
    Vertex v1,
    Vertex v2,
    double alpha, {
    required bool fromLeft,
  }) {
    final a = fromLeft ? v1 : v2, b = fromLeft ? v2 : v1;
    if (a.y >= alpha) return a.x;
    if (b.y < alpha) return null;
    return a.x + (alpha - a.y) / (b.y - a.y) * (b.x - a.x);
  }

  static List<double> _sortedUnique(Iterable<double> values) {
    final sorted = values.toList()..sort();
    final out = <double>[];
    for (final v in sorted) {
      if (out.isEmpty || (v - out.last).abs() > 1e-9) out.add(v);
    }
    return out;
  }

  static List<Vertex> _dropCollinear(List<Vertex> vs) {
    if (vs.length <= 2) return vs;
    final out = <Vertex>[vs.first];
    for (var i = 1; i < vs.length - 1; i++) {
      final p = out.last, q = vs[i], r = vs[i + 1];
      final cross = (r.y - p.y) * (q.x - p.x) - (q.y - p.y) * (r.x - p.x);
      if (cross.abs() > 1e-12) out.add(q);
    }
    out.add(vs.last);
    return out;
  }

  @override
  String toString() =>
      'Polyline(${vertices.map((v) => '(${v.x}, ${v.y})').join(' ')})';
}
