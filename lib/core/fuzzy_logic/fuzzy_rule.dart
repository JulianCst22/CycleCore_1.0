/// Una regla difusa tipo Sugeno de orden cero: combina varios grados de
/// pertenencia (uno por entrada, ya calculados con fuzzy_membership.dart)
/// con un AND/OR difuso, y asocia esa "fuerza de disparo" a un valor de
/// salida constante.
///
/// El motor de inferencia (ver fuzzy_inference_engine.dart) combina
/// todas las reglas con un promedio ponderado por su fuerza de disparo
/// -- exactamente la defuzzificación estándar de un Sugeno de orden
/// cero. Es barato de calcular (sin centroides ni integrales), lo cual
/// importa porque esto corre en el hot path del GPS, sin async.
class FuzzyRule {
  final String name;
  final double Function(Map<String, double> degrees) firingStrength;
  final double outputValue;

  const FuzzyRule({
    required this.name,
    required this.firingStrength,
    required this.outputValue,
  });

  /// AND difuso (mínimo): la regla dispara tan fuerte como su condición
  /// MÁS débil.
  static double and(List<double> degrees) {
    if (degrees.isEmpty) return 0.0;
    return degrees.reduce((a, b) => a < b ? a : b);
  }

  /// OR difuso (máximo): la regla dispara tan fuerte como su condición
  /// MÁS fuerte.
  static double or(List<double> degrees) {
    if (degrees.isEmpty) return 0.0;
    return degrees.reduce((a, b) => a > b ? a : b);
  }
}
