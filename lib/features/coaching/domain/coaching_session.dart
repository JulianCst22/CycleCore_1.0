import '../../../core/fuzzy_type2/fuzzy_type2.dart';
import '../../../core/geo/geo.dart';
import '../../../core/physiology/physiology.dart' show cadenceInGear;
import 'advice/governor.dart';
import 'advice/hints.dart';
import 'advice/limiter.dart';
import 'advice/pacing_plan.dart';
import 'advice/physics_check.dart';
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
    final verdict = _governor.consider(
      second: second,
      decision: decision,
      table: table,
      alongMeters: _along,
      powerIsEstimated: features.powerIsEstimated,
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
    final power = base == null
        ? null
        : powerTarget(
            decision.adjustment,
            basePower: base,
            sustainable: features.sustainablePowerBand,
            sufficiency: features.sufficiency?.value,
            reserveDriven: _reserveDriven(decision),
            parameters: parameters,
          );
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

  /// Si el consejo lo manda la reserva, el objetivo tiene piso: aflojar
  /// por debajo de lo sostenible ya no guarda nada, solo pierde tiempo
  /// (ver `reserveDrivenAdjustmentRules`).
  static bool _reserveDriven(CoachingDecision decision) {
    final rule = decision.diagnosis?.rule.id;
    return rule != null && reserveDrivenAdjustmentRules.contains(rule);
  }
}
