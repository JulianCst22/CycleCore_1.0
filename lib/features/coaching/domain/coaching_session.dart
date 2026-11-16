import 'dart:math' as math;

import '../../../core/fuzzy_type2/fuzzy_type2.dart';
import '../../../core/geo/geo.dart';
import '../../../core/physiology/physiology.dart' show cadenceInGear;
import 'advice/governor.dart';
import 'advice/hints.dart';
import 'advice/limiter.dart';
import 'advice/pacing_plan.dart';
import 'advice/physics_check.dart';
import 'advice/segment_pace.dart';
import 'advice/situation.dart';
import 'advice/targets.dart';
import 'athlete.dart';
import 'coaching_parameters.dart';
import 'coaching_preferences.dart';
import 'engine/coaching_engine.dart';
import 'extraction/effort_tracker.dart';
import 'extraction/ride_features.dart';
import 'extraction/sensor_credibility.dart';
import 'extraction/terrain_reader.dart';
import 'rules/coaching_rules.dart' show reserveDrivenAdjustmentRules;
import 'variables/labels.dart';

/// Lo que el coach concluye en un instante.
final class Advice {
  final int second;
  final RideFeatures features;
  final SensorCredibility credibility;
  final CoachingDecision decision;
  final SituationTable situations;
  final GovernorVerdict verdict;

  /// Objetivo de potencia en vatios (sin potenciómetro no hay).
  final Target? power;
  final Target? cadence;

  /// Qué está topando y cuánto. El mensaje lo nombra: sin eso, «afloja»
  /// no le dice al ciclista qué corregir.
  final LimiterReading limiter;

  /// Pulso al que conviene bajar cuando el corazón va alto. `null` si
  /// no lo va, o si ya está por debajo y no hay nada que pedir. Se
  /// llama distinto del de [features] a propósito: aquel es el que
  /// lleva, este es al que debería ir.
  final double? targetHeartRate;

  /// Cómo repartir lo que queda: regular acá, sostener o soltar todo.
  final PacingPlan plan;

  /// Avisos de al lado que caben ahora: respirar, subir un piñón, el
  /// plan. Lo que no esté acá no se puede decir.
  final Set<AdviceHint> hints;

  /// Contraste con la física: lo que pidieron las reglas contra lo que
  /// dice la ecuación de la reserva (F12). `null` si falta alguno.
  final PhysicsCheck? physics;

  /// Lo que al final se le pide con la potencia: la etiqueta del ajuste
  /// que va de lo que lleva al objetivo en vatios. Casi siempre es la
  /// que concluyeron las reglas; cambia cuando el ritmo del modo o la
  /// reserva movieron el objetivo, para que el verbo de la frase y el
  /// número digan lo mismo.
  final Adjustment? action;

  /// Va en el tramo final del segmento: el coach habla más seguido y
  /// el mensaje busca lo que el modo quiere al coronar.
  final bool finalStretch;

  /// El estado bajo de reserva es el que el modo esperaba a esta
  /// altura (va en su ritmo y le alcanza): no es una alarma, y la frase
  /// no lo anuncia como si lo fuera.
  final bool expectedState;

  const Advice({
    required this.second,
    required this.features,
    required this.credibility,
    required this.decision,
    required this.situations,
    required this.verdict,
    required this.power,
    required this.cadence,
    this.limiter = noLimiter,
    this.targetHeartRate,
    this.plan = PacingPlan.finished,
    this.hints = const {},
    this.physics,
    this.action,
    this.finalStretch = false,
    this.expectedState = false,
  });

  bool get speak => verdict.speak;
  Register get register => verdict.register;
  SituationKey? get situation => verdict.situation;

  /// Urgencia como intervalo (un punto en tipo-1).
  Interval? get urgency => decision.urgency.centroid;

  /// Regla que explica el consejo.
  FiredRule? get diagnosis => decision.diagnosis;

  /// En subida la velocidad no informa: el mensaje debe decir que no se
  /// mire.
  bool get ignoreSpeed => credibility.speed == 0;
}

/// Una pasada del coach por un segmento: acumula el esfuerzo segundo a
/// segundo y, cuando se le pide, evalúa los motores y el gobernador.
///
/// No tiene reloj ni acceso a sensores: recibe los datos ya leídos. Así
/// se puede reproducir una actividad grabada y obtener exactamente los
/// mismos consejos.
final class CoachingSession {
  final CoachAthlete athlete;
  final SegmentProfile profile;
  final ReferenceEffort? reference;
  final Goal goal;
  final CoachingParameters parameters;
  final CoachingEngine engine;
  final EffortTracker _effort;
  final CoachingGovernor _governor;
  final PhysicsReview _physics = PhysicsReview();
  double _along = 0;

  /// Ritmo a tope del segmento; se calcula una vez, al primer consejo.
  late final double _segmentPace = allOutPaceOf(profile, athlete).power;

  /// Ya va en el tramo final del segmento.
  bool get _finalStretch =>
      _along >= finalStretchStart(profile.totalDistanceMeters, parameters);

  CoachingSession({
    required this.athlete,
    required this.profile,
    this.reference,
    this.goal = Goal.pr,
    InferenceMode mode = InferenceMode.type2,
    CoachingPace pace = CoachingPace.cadaDosMinutos,
    this.parameters = const CoachingParameters(),
  }) : engine = CoachingEngine(mode: mode, parameters: parameters),
       _effort = EffortTracker(athlete: athlete, parameters: parameters),
       _governor = CoachingGovernor(parameters, pace);

  int get seconds => _effort.seconds;

  /// Cómo van coincidiendo las reglas y la física en esta subida.
  PhysicsReview get physicsReview => _physics;

  /// Agrega un segundo de datos. La pendiente la pone la sesión, que es
  /// la que tiene el perfil: con ella se estima la potencia si no hay
  /// potenciómetro.
  void addTick(RideTick tick) {
    _effort.add(
      tick.slopePercent != null
          ? tick
          : tick.withSlope(
              profile.slopePercentAtDistance(tick.alongMeters) ?? 0,
            ),
    );
    _along = tick.alongMeters;
  }

  /// La potencia con la que está trabajando viene de la velocidad.
  bool get powerIsEstimated => _effort.powerIsEstimated;

  /// Evalúa el instante actual.
  Advice evaluate(SensorStatus status) {
    final terrain = TerrainWindow.read(
      profile,
      _along,
      lookahead: parameters.lookaheadMeters,
    );
    final features = RideFeatures.extract(
      effort: _effort,
      terrain: terrain,
      reference: reference,
      alongMeters: _along,
      athlete: athlete,
      segmentPace: _segmentPace,
      modePlan: _modePlan(),
      goal: goal,
      parameters: parameters,
    );
    return advise(
      second: seconds,
      features: features,
      credibility: SensorCredibility.from(
        status.withEstimatedPower(_effort.powerIsEstimated),
      ),
    );
  }

  /// Evalúa con variables ya calculadas (útil para reproducir o probar un
  /// instante concreto).
  Advice advise({
    required int second,
    required RideFeatures features,
    required SensorCredibility credibility,
    PacingPlan? plan,
  }) {
    final decision = engine.decide(features, credibility, goal: goal);
    final table = SituationTable.of(decision);
    final limiter = limiterOf(features, parameters: parameters);
    final finalStretch = _finalStretch;
    final verdict = _governor.consider(
      second: second,
      decision: decision,
      table: table,
      alongMeters: _along,
      powerIsEstimated: features.powerIsEstimated,
      finalStretch: finalStretch,
    );
    final base = features.basePower;
    final pacing =
        plan ?? PacingPlan.of(profile, _along, parameters: parameters);
    // La cadencia que se pide no puede pasar de la que da el desarrollo
    // más suave a la velocidad que lleva: más que eso no existe.
    final speed = features.speed;
    final resistance = athlete.resistance;
    final easiest = resistance.lowestGearMeters;
    final hardest = resistance.highestGearMeters;
    final cadence = cadenceTarget(
      decision.cadence,
      reachable: speed == null || easiest == null
          ? null
          : cadenceInGear(speed, easiest) - parameters.cadenceMargin,
      atLeast: speed == null || hardest == null
          ? null
          : cadenceInGear(speed, hardest) + parameters.cadenceMargin,
    );
    final hints = hintsOf(
      stance: pacing.stance,
      resistance: resistance,
      state: table.best?.key.state,
      heartRateReserve: features.heartRateReserve?.value,
      torque: features.torque?.value,
      cadenceTarget: cadence?.spoken,
      speed: speed,
      parameters: parameters,
    );
    // El cuerpo manda sobre el plan cuando el pulso o el torque están
    // de verdad en el tope; en el tramo final de duro y a tope no: ahí
    // lo que se busca es justamente llegar exigido.
    final bodyOverrides =
        (limiter.limiter == Limiter.pulso ||
            limiter.limiter == Limiter.torque) &&
        limiter.degree >= parameters.planOverrideLimiter;
    final pushing = finalStretch && goal != Goal.recuperacion;
    final modePlan = features.planPower;
    final power = base == null
        ? null
        : powerTarget(
            decision.adjustment,
            basePower: base,
            sustainable: features.sustainablePowerBand,
            sufficiency: pushing ? null : features.sufficiency?.value,
            reserveDriven: _reserveDriven(decision),
            plan: modePlan,
            holdPlan: pushing || !bodyOverrides,
            parameters: parameters,
          );
    final action = base == null || power == null
        ? decision.advisedAdjustment
        : decision.adjustmentLabelOf(
            100 * (power.value / base - 1) / parameters.maxAdjustment,
          );
    final state = table.best?.key.state;
    final expectedState =
        (state == EffortState.alLimite || state == EffortState.fundido) &&
        power != null &&
        (pushing ||
            (!bodyOverrides &&
                (features.sufficiency?.value ?? 0) >=
                    parameters.sufficiencyCeiling));
    // Los dos caminos se contrastan en cada evaluación, se hable o no:
    // es la verificación independiente de la especificación (F12). Va
    // contra el tanque entero, no contra el que deja libre el modo del
    // día: lo que se revisa es la base de reglas, y en fondo la reserva
    // guardada haría parecer excesivo cualquier consejo.
    final physics = physicsCheckOf(
      advised: power?.requested,
      sustainable: features.physicalSustainablePower,
      tolerance: parameters.physicsTolerance,
    );
    _physics.add(physics);

    return Advice(
      second: second,
      features: features,
      credibility: credibility,
      decision: decision,
      situations: table,
      verdict: verdict,
      power: power,
      physics: physics,
      cadence: cadence,
      limiter: limiter,
      plan: pacing,
      hints: hints,
      action: action,
      finalStretch: finalStretch,
      expectedState: expectedState,
      targetHeartRate:
          !hints.contains(AdviceHint.respirar) || features.heartRate == null
          ? null
          : heartRateTarget(
              current: features.heartRate!,
              maxHeartRate: athlete.maxHeartRate.toDouble(),
              restingHeartRate: athlete.restingHeartRate.toDouble(),
            ),
    );
  }

  /// Ritmo que toca en este punto, en vatios.
  ///
  ///  - A tope: lo que gasta su tanque (un poco más que el calibrado)
  ///    de acá a la cima, apartando desde antes lo del remate: en el
  ///    tramo final va un [CoachingParameters.finalBoost] más fuerte, y
  ///    ya en él se gasta todo lo que quede.
  ///  - Duro: su parte del ritmo a tope del segmento; en el tramo final
  ///    sube al ritmo a tope. Nunca baja la reserva de su límite.
  ///  - Fondo: su parte del ritmo a tope, sin bajar de su límite.
  double? _modePlan() {
    if (_effort.seconds == 0) return null;
    final wPrime = athlete.power.wPrime.toDouble();
    final balance = _effort.balance.toDouble();
    final finalStretch = _finalStretch;
    double untilFloor(Goal mode, {bool kick = false}) => pacedPowerOf(
      profile,
      athlete,
      budget: balance - mode.reserveFloor * wPrime,
      fromMeters: _along,
      kickFromMeters: kick
          ? finalStretchStart(profile.totalDistanceMeters, parameters)
          : null,
      kick: kick ? parameters.finalBoost : 0,
    ).power;
    return switch (goal) {
      Goal.pr => untilFloor(Goal.pr, kick: !finalStretch),
      Goal.ritmo => math.min(
        finalStretch ? _segmentPace : goal.intensity * _segmentPace,
        untilFloor(goal),
      ),
      Goal.recuperacion => math.min(
        goal.intensity * _segmentPace,
        untilFloor(goal),
      ),
    };
  }

  /// Si el consejo lo manda la reserva, el objetivo tiene piso: aflojar
  /// por debajo de lo sostenible ya no guarda nada, solo pierde tiempo
  /// (ver `reserveDrivenAdjustmentRules`).
  static bool _reserveDriven(CoachingDecision decision) {
    final rule = decision.diagnosis?.rule.id;
    return rule != null && reserveDrivenAdjustmentRules.contains(rule);
  }
}
