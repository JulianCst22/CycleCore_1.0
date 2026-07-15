import 'fuzzy_rule.dart';

/// Motor de inferencia difusa Sugeno de orden cero: genérico, no sabe
/// nada de altitud ni de pendiente -- solo combina reglas con sus
/// grados de disparo en una única salida numérica ponderada.
///
/// Se reutiliza tal cual en las 2 capas del modelo geoespacial
/// (fusión de altitud y plausibilidad de pendiente), y está pensado
/// para reutilizarse después en el motor de esfuerzo (FC/potencia).
class FuzzyInferenceEngine {
  final List<FuzzyRule> rules;

  /// Salida cuando ninguna regla dispara (todas las fuerzas dan 0) --
  /// caso borde poco común (p.ej. el primerísimo punto de la sesión)
  /// pero hay que definirlo explícitamente para no dividir por cero.
  final double fallbackOutput;

  const FuzzyInferenceEngine({
    required this.rules,
    this.fallbackOutput = 0.5,
  });

  /// Evalúa todas las reglas contra los grados ya calculados y devuelve
  /// la salida ponderada por la fuerza de disparo de cada una.
  double infer(Map<String, double> degrees) {
    double weightedSum = 0;
    double totalWeight = 0;

    for (final rule in rules) {
      final strength = rule.firingStrength(degrees);
      if (strength <= 0) continue;
      weightedSum += strength * rule.outputValue;
      totalWeight += strength;
    }

    if (totalWeight <= 0) return fallbackOutput;
    return weightedSum / totalWeight;
  }
}
