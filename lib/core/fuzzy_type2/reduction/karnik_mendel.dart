import '../sets/polyline.dart';

/// Resultado de la reducción de tipo: el centroide de la huella es el
/// intervalo `[left, right]`; se guardan las iteraciones para poder
/// explicar y probar la convergencia.
typedef TypeReduction = ({
  double left,
  double right,
  double nieTan,
  List<double> leftIterations,
  List<double> rightIterations,
});

/// Reducción de tipo de Karnik–Mendel sobre la huella delimitada por
/// [upper] y [lower], resuelta en continuo.
///
/// Para el extremo izquierdo se toma la figura superior a la izquierda de
/// un punto de cambio θ y la inferior a la derecha; el centroide de esa
/// combinación es el nuevo θ (el derecho, al revés). Cada paso usa las
/// integrales exactas por tramos de [Polyline], así que no se discretiza
/// el universo. La iteración arranca en el centroide de Nie–Tan (figura
/// promedio) y converge en pocos pasos.
///
/// Devuelve `null` si la huella no tiene área.
TypeReduction? karnikMendel(
  Polyline upper,
  Polyline lower, {
  double tolerance = 1e-10,
  int maxIterations = 50,
}) {
  assert(upper.lo == lower.lo && upper.hi == lower.hi);
  final lo = upper.lo, hi = upper.hi;
  final u = upper.integrals(), l = lower.integrals();
  final totalArea = u.area + l.area;
  if (totalArea <= 0) return null;
  final nieTan = (u.moment + l.moment) / totalArea;

  List<double> iterate(Polyline leftFigure, Polyline rightFigure) {
    var theta = nieTan;
    final steps = [theta];
    for (var k = 0; k < maxIterations; k++) {
      final a = leftFigure.integrals(lo, theta);
      final b = rightFigure.integrals(theta, hi);
      final area = a.area + b.area;
      if (area <= 0) break;
      final next = (a.moment + b.moment) / area;
      steps.add(next);
      if ((next - theta).abs() < tolerance) break;
      theta = next;
    }
    return steps;
  }

  final leftSteps = iterate(upper, lower);
  final rightSteps = iterate(lower, upper);
  return (
    left: leftSteps.last,
    right: rightSteps.last,
    nieTan: nieTan,
    leftIterations: List.unmodifiable(leftSteps),
    rightIterations: List.unmodifiable(rightSteps),
  );
}
