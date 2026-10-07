import 'dart:math' as math;

import '../logic/norms.dart';
import '../reduction/karnik_mendel.dart';
import '../rules/antecedent.dart';
import '../rules/linguistic_variable.dart';
import '../rules/rule_base.dart';
import '../sets/interval.dart';
import '../sets/polyline.dart';
import 'fuzzy_inputs.dart';
import 'inference_result.dart';

/// Credibilidad de una variable de entrada en este instante (0–1).
typedef Credibility = double Function(LinguisticVariable<Enum> variable);

double _fullCredibility(LinguisticVariable<Enum> _) => 1;

/// Motor Mamdani tipo-2 de intervalo.
///
/// Implicación por recorte (o escalado), agregación por máximo y
/// reducción de tipo de Karnik–Mendel exacta. Con entradas exactas y
/// salidas sin huella ([LinguisticVariable.consequentFou] = 0) se
/// comporta exactamente como un Mamdani tipo-1 con centroide.
///
/// El motor no guarda estado entre inferencias: con las mismas entradas
/// devuelve siempre el mismo resultado.
final class MamdaniEngine {
  final RuleBase rules;
  final TNorm and;
  final SNorm or;
  final Implication implication;

  const MamdaniEngine(
    this.rules, {
    this.and = TNorm.minimum,
    this.or = SNorm.maximum,
    this.implication = Implication.clip,
  });

  InferenceResult infer(
    FuzzyInputs inputs, {
    Credibility credibility = _fullCredibility,
  }) {
    final trace = <FiredRule>[];
    final activations =
        <LinguisticVariable<Enum>, Map<Enum, Interval>>{}; // por salida

    for (final rule in rules.rules) {
      final truth = _evaluate(rule.when, inputs);
      var kappa = 1.0;
      for (final variable in rule.when.variables) {
        final k = credibility(variable);
        if (k.isNaN || k < 0 || k > 1) {
          throw ArgumentError.value(
            k,
            'credibility',
            'Credibilidad de ${variable.name} fuera de [0, 1]',
          );
        }
        kappa = math.min(kappa, k);
      }
      final strength = truth.scale(rule.certainty * kappa);
      trace.add(
        FiredRule(
          rule: rule,
          truth: truth,
          credibility: kappa,
          strength: strength,
        ),
      );
      if (strength.hi <= 0) continue;
      final byLabel = activations.putIfAbsent(rule.then.variable, () => {});
      final label = rule.then.label;
      byLabel[label] = byLabel[label]?.maxWith(strength) ?? strength;
    }

    return InferenceResult({
      for (final v in rules.outputs) v: _output(v, activations[v] ?? const {}),
    }, trace);
  }

  Interval _evaluate(Antecedent a, FuzzyInputs inputs) => switch (a) {
    Is(:final variable, :final label, :final hedge) => hedge.onInterval(
      inputs.degreeOf(variable, label),
    ),
    All(:final terms) =>
      terms.map((t) => _evaluate(t, inputs)).reduce(and.onIntervals),
    Any(:final terms) =>
      terms.map((t) => _evaluate(t, inputs)).reduce(or.onIntervals),
    Not(:final term) => negate(_evaluate(term, inputs)),
  };

  OutputInference _output(
    LinguisticVariable<Enum> variable,
    Map<Enum, Interval> activations,
  ) {
    final upper = Polyline.unionOf(
      [
        for (final e in activations.entries)
          (term: variable.upperTerm(e.key), height: e.value.hi),
      ],
      lo: variable.min,
      hi: variable.max,
      implication: implication,
    );
    final lower = Polyline.unionOf(
      [
        for (final e in activations.entries)
          (term: variable.lowerTerm(e.key), height: e.value.lo),
      ],
      lo: variable.min,
      hi: variable.max,
      implication: implication,
    );
    return OutputInference(
      variable: variable,
      activations: activations,
      upper: upper,
      lower: lower,
      reduction: karnikMendel(upper, lower),
    );
  }
}
