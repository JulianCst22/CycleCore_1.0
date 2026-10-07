import '../../../../core/fuzzy_type2/fuzzy_type2.dart';
import '../../../../core/physiology/physiology.dart';
import '../coaching_parameters.dart';
import '../extraction/ride_features.dart';
import '../extraction/sensor_credibility.dart';
import '../rules/coaching_rules.dart';
import '../variables/coaching_variables.dart';
import '../variables/labels.dart';

/// Resultado de los tres motores en un instante.
final class CoachingDecision {
  final InferenceMode mode;

  /// Motor A: estado del ciclista.
  final OutputInference effort;

  /// Motor B: demanda del terreno.
  final OutputInference demand;

  /// Motor C: ajuste de intensidad, cadencia y urgencia.
  final OutputInference adjustment;
  final OutputInference cadence;
  final OutputInference urgency;

  /// Grados de la fase del segmento (para elegir la situación).
  final Map<Enum, Interval> phase;

  /// Reglas de los tres motores, de la más fuerte a la más débil.
  final List<FiredRule> effortTrace;
  final List<FiredRule> demandTrace;
  final List<FiredRule> decisionTrace;

  const CoachingDecision({
    required this.mode,
    required this.effort,
    required this.demand,
    required this.adjustment,
    required this.cadence,
    required this.urgency,
    required this.phase,
    required this.effortTrace,
    required this.demandTrace,
    required this.decisionTrace,
  });

  /// Regla que explica el ajuste: es el motivo del mensaje.
  ///
  /// Es la más fuerte (por el punto medio de su activación) entre las que
  /// empujan hacia el mismo lado que el consejo: si el ajuste quedó en
  /// «soltar», el motivo no puede ser una regla de «mantener». El lado lo
  /// da la etiqueta que mejor describe el valor recomendado. Si ninguna
  /// regla empuja hacia ese lado, se toma la más fuerte de todas.
  FiredRule? get diagnosis {
    final value = adjustment.value;
    if (value == null) return null;
    final fired = [
      for (final f in decisionTrace)
        if (identical(f.rule.then.variable, adjustment.variable) &&
            f.strength.hi > 0)
          f,
    ];
    if (fired.isEmpty) return null;
    final side = _sideOf(advisedAdjustment!);
    final agreeing = [
      for (final f in fired)
        if (_sideOf(f.rule.then.label) == side) f,
    ];
    return _strongest(agreeing.isEmpty ? fired : agreeing);
  }

  /// Etiqueta que mejor describe el ajuste recomendado: es la acción que
  /// se dice en voz alta («soltar», «mantener»). `null` si ninguna regla
  /// aportó evidencia.
  Adjustment? get advisedAdjustment {
    final value = adjustment.value;
    if (value == null) return null;
    Adjustment? described;
    var best = -1.0;
    for (final e in adjustment.variable.terms.entries) {
      final mu = e.value.mu(value);
      if (mu > best && e.key is Adjustment) {
        best = mu;
        described = e.key as Adjustment;
      }
    }
    return described;
  }

  static int _sideOf(Enum label) =>
      (label.index - Adjustment.mantener.index).sign;

  static FiredRule _strongest(List<FiredRule> rules) {
    var top = rules.first;
    for (final f in rules.skip(1)) {
      final byMid = f.strength.mid.compareTo(top.strength.mid);
      if (byMid > 0 || (byMid == 0 && f.strength.hi > top.strength.hi)) {
        top = f;
      }
    }
    return top;
  }
}

/// Los tres motores difusos del coach en jerarquía:
///
///     A (estado, mínimo) ─┐
///                         ├─► C (decisión, producto) ─► ajuste, cadencia, urgencia
///     B (demanda, mínimo) ┘
///
/// A y B entregan al C sus activaciones sin reducirlas a un número; en
/// tipo-2 cada activación es un intervalo. En tipo-1 cada variable entra
/// con su valor exacto y las salidas no tienen huella.
final class CoachingEngine {
  final InferenceMode mode;
  final CoachingParameters parameters;
  final CoachingVariables variables;
  late final MamdaniEngine _effort = MamdaniEngine(
    effortRules(variables),
    and: parameters.effortAnd,
    implication: parameters.implication,
  );
  late final MamdaniEngine _terrain = MamdaniEngine(
    terrainRules(variables),
    and: parameters.terrainAnd,
    implication: parameters.implication,
  );
  late final MamdaniEngine _decision = MamdaniEngine(
    decisionRules(variables),
    and: parameters.decisionAnd,
    implication: parameters.implication,
  );

  CoachingEngine({
    this.mode = InferenceMode.type2,
    this.parameters = const CoachingParameters(),
  }) : variables = CoachingVariables(mode: mode, parameters: parameters);

  MamdaniEngine get effortEngine => _effort;
  MamdaniEngine get terrainEngine => _terrain;
  MamdaniEngine get decisionEngine => _decision;

  CoachingDecision decide(
    RideFeatures features,
    SensorCredibility sources, {
    Goal goal = Goal.pr,
  }) {
    final v = variables;
    final missing = Set<LinguisticVariable<Enum>>.identity();

    // Una variable sin dato entra con un valor cualquiera y credibilidad
    // cero: las reglas que la usan no aportan nada.
    void load<L extends Enum>(
      FuzzyInputs inputs,
      LinguisticVariable<L> variable,
      UncertainValue? value,
    ) {
      if (value == null) {
        missing.add(variable);
        inputs.crisp(variable, (variable.min + variable.max) / 2);
        return;
      }
      inputs.uncertain(
        variable,
        mode == InferenceMode.type2
            ? Interval(value.lo, value.hi)
            : Interval.point(value.value),
      );
    }

    final fromSources = v.credibilityFrom(sources.of);
    double credibility(LinguisticVariable<Enum> variable) =>
        missing.contains(variable) ? 0 : fromSources(variable);

    final effortInputs = FuzzyInputs();
    load(effortInputs, v.intensity, features.intensity);
    load(effortInputs, v.heartRateReserve, features.heartRateReserve);
    load(effortInputs, v.torque, features.torque);
    load(effortInputs, v.reserve, features.reserve);
    load(effortInputs, v.sufficiency, features.sufficiency);
    load(effortInputs, v.decoupling, features.decoupling);
    load(effortInputs, v.variability, features.variability);
    final a = _effort.infer(effortInputs, credibility: credibility);

    final terrainInputs = FuzzyInputs();
    load(terrainInputs, v.gradientAhead, features.gradientAhead);
    load(terrainInputs, v.maxRamp, features.maxRamp);
    load(terrainInputs, v.roughness, features.roughness);
    load(terrainInputs, v.climbLeft, features.climbLeft);
    load(terrainInputs, v.phase, features.progress);
    final b = _terrain.infer(terrainInputs, credibility: credibility);

    final decisionInputs = FuzzyInputs()
      ..degrees(v.effort, a[v.effort].activations.cast<EffortState, Interval>())
      ..degrees(v.demand, b[v.demand].activations.cast<Demand, Interval>())
      ..crisp(v.goal, goal.index.toDouble());
    load(decisionInputs, v.sufficiency, features.sufficiency);
    load(decisionInputs, v.climbLeft, features.climbLeft);
    load(decisionInputs, v.phase, features.progress);
    load(decisionInputs, v.recordPace, features.recordPace);
    load(decisionInputs, v.torque, features.torque);
    final c = _decision.infer(decisionInputs, credibility: credibility);

    return CoachingDecision(
      mode: mode,
      effort: a[v.effort],
      demand: b[v.demand],
      adjustment: c[v.adjustment],
      cadence: c[v.cadence],
      urgency: c[v.urgency],
      phase: terrainInputs.degreesOf(v.phase),
      effortTrace: a.trace,
      demandTrace: b.trace,
      decisionTrace: c.trace,
    );
  }
}
