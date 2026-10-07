import '../sets/interval.dart';
import '../sets/trapezoid.dart';

/// Variable lingüística: un universo `[min, max]` y un trapecio por
/// etiqueta.
///
/// Las etiquetas son un `enum`, así que una regla no puede nombrar una
/// etiqueta que no pertenezca a su variable: el compilador lo impide.
///
/// Cuando la variable es de salida, [consequentFou] es el ancho de la
/// huella de incertidumbre de sus etiquetas (0 = tipo-1).
final class LinguisticVariable<L extends Enum> {
  final String name;
  final double min;
  final double max;
  final Map<L, Trapezoid> terms;
  final double consequentFou;

  LinguisticVariable({
    required this.name,
    required this.min,
    required this.max,
    required Map<L, Trapezoid> terms,
    this.consequentFou = 0,
  }) : assert(min < max),
       assert(consequentFou >= 0),
       terms = Map.unmodifiable(terms);

  Iterable<L> get labels => terms.keys;

  Trapezoid term(L label) {
    final t = terms[label];
    if (t == null) {
      throw ArgumentError('La etiqueta $label no está definida en $name.');
    }
    return t;
  }

  /// Grado de cada etiqueta para un valor que puede estar en cualquier
  /// punto de [x]. Con un intervalo de ancho cero es la fuzzificación
  /// tipo-1 de siempre.
  Map<L, Interval> fuzzify(Interval x) => {
    for (final e in terms.entries) e.key: e.value.degreeOver(x),
  };

  /// La misma variable con todos los quiebres multiplicados por
  /// [factor]. El universo se ensancha si hace falta para que ningún
  /// quiebre quede afuera.
  ///
  /// Es la palanca del análisis de sensibilidad: correr el motor con las
  /// etiquetas un 10 % más arriba o más abajo sin tocar las reglas.
  LinguisticVariable<L> withBreakpointsScaled(double factor) {
    if (factor == 1) return this;
    final scaled = {
      for (final e in terms.entries) e.key: e.value.scaled(factor),
    };
    var lo = min, hi = max;
    for (final trapezoid in scaled.values) {
      for (final x in trapezoid.breakpoints) {
        if (x < lo) lo = x;
        if (x > hi) hi = x;
      }
    }
    return LinguisticVariable(
      name: name,
      min: lo,
      max: hi,
      terms: scaled,
      consequentFou: consequentFou,
    );
  }

  /// Curva superior de la etiqueta de salida [label].
  Trapezoid upperTerm(L label) =>
      term(label).dilate(consequentFou, min: min, max: max);

  /// Curva inferior de la etiqueta de salida [label].
  Trapezoid lowerTerm(L label) =>
      term(label).erode(consequentFou, min: min, max: max);

  @override
  String toString() => 'LinguisticVariable($name)';
}
