import '../../../../core/fuzzy_type2/fuzzy_type2.dart';
import '../coaching_parameters.dart';
import '../coaching_preferences.dart';
import '../engine/coaching_engine.dart';
import 'situation.dart';

/// Tono del mensaje: lo decide la forma de la figura del ajuste, no su
/// contenido.
enum Register {
  /// Orden directa con un número.
  asertivo,

  /// Orden más un límite («…y no bajes de 270»).
  conMatiz,

  /// Verbos suaves y rangos («afloja un poco»).
  cauto,

  /// Sin dirección: «mantén así; en 200 metros te digo».
  neutro,
}

/// Tono según la huella del ajuste:
///
///     neutro     si la figura superior es bimodal o Û ≥ 0,30
///     cauto      si Û ≥ 0,15 o la figura es baja (h < 0,75)
///     con matiz  si el consejo cae fuera de la región segura
///     asertivo   en otro caso
///
/// Û es el ancho del centroide de intervalo relativo al universo (0 en
/// tipo-1).
Register registerOf(
  OutputInference adjustment, [
  CoachingParameters parameters = const CoachingParameters(),
]) {
  final value = adjustment.value;
  if (value == null) return Register.neutro;
  final width = adjustment.relativeUncertainty ?? 0;
  if (adjustment.upperShape.isBimodal || width >= parameters.neutralWidth) {
    return Register.neutro;
  }
  if (width >= parameters.cautiousWidth ||
      adjustment.upperShape.height < parameters.assertiveHeight) {
    return Register.cauto;
  }
  final core = adjustment.lowerShape.alphaCut(0.7);
  if (core != null && (value < core.lo || value > core.hi)) {
    return Register.conMatiz;
  }
  return Register.asertivo;
}

/// Por qué el gobernador decidió hablar o callar.
enum GovernorReason {
  speak,
  lowUrgency,
  noSituation,
  tooSoon,
  repeated,
  hysteresis,
}

final class GovernorVerdict {
  final GovernorReason reason;
  final SituationKey? situation;
  final Interval? situationActivation;
  final Register register;

  const GovernorVerdict({
    required this.reason,
    required this.situation,
    required this.situationActivation,
    required this.register,
  });

  bool get speak => reason == GovernorReason.speak;
}

/// Decide si se habla y con qué tono. Callar es la salida normal.
///
/// Se habla solo si, a la vez:
///  1. el extremo inferior de la urgencia supera el umbral (en tipo-2 hay
///     que estar seguro de que es urgente); con la potencia estimada, el
///     centro del intervalo (ver
///     `CoachingParameters.urgencyAtMidpointWhenEstimated`),
///  2. pasó el tiempo mínimo desde el último mensaje,
///  3. la situación no se dijo hace poco,
///  4. si la situación cambió, la nueva supera a la anterior por un
///     margen (histéresis).
final class CoachingGovernor {
  final CoachingParameters parameters;

  /// Cada cuánto quiere el ciclista el aviso normal. Lo urgente no la
  /// respeta: avisar tarde de una rampa es no avisar.
  final CoachingPace pace;

  int? _lastSpokenAt;
  double? _lastSpokenMeters;
  SituationKey? _lastSituation;
  final _spokenAt = <SituationKey, int>{};

  CoachingGovernor([
    this.parameters = const CoachingParameters(),
    this.pace = CoachingPace.cadaDosMinutos,
  ]);

  GovernorVerdict consider({
    required int second,
    required CoachingDecision decision,
    required SituationTable table,
    double alongMeters = 0,
    bool powerIsEstimated = false,
  }) {
    final register = registerOf(decision.adjustment, parameters);
    final best = table.best;
    GovernorVerdict verdict(GovernorReason reason) => GovernorVerdict(
      reason: reason,
      situation: best?.key,
      situationActivation: best?.activation,
      register: register,
    );

    final urgency = decision.urgency.centroid;
    if (urgency == null) return verdict(GovernorReason.lowUrgency);
    final level = powerIsEstimated && parameters.urgencyAtMidpointWhenEstimated
        ? urgency.mid
        : urgency.lo;
    if (level <= parameters.urgencyThreshold) {
      return verdict(GovernorReason.lowUrgency);
    }
    if (best == null) return verdict(GovernorReason.noSituation);

    final urgent = urgency.lo >= parameters.urgentUrgency;
    final last = _lastSpokenAt;
    if (last != null && second - last < parameters.minGapSeconds) {
      return verdict(GovernorReason.tooSoon);
    }
    if (!urgent && _tooSoonForPace(second, alongMeters)) {
      return verdict(GovernorReason.tooSoon);
    }
    final sameAt = _spokenAt[best.key];
    if (sameAt != null && second - sameAt < parameters.repeatWindowSeconds) {
      return verdict(GovernorReason.repeated);
    }
    final previous = _lastSituation;
    if (previous != null && previous != best.key) {
      final margin = best.activation.mid - table.of(previous).mid;
      if (margin < parameters.situationHysteresis) {
        return verdict(GovernorReason.hysteresis);
      }
    }

    _lastSpokenAt = second;
    _lastSpokenMeters = alongMeters;
    _lastSituation = best.key;
    _spokenAt[best.key] = second;
    return verdict(GovernorReason.speak);
  }

  /// Si todavía no toca según la cadencia que eligió el ciclista.
  bool _tooSoonForPace(int second, double alongMeters) {
    final seconds = pace.seconds;
    if (seconds != null) {
      final last = _lastSpokenAt;
      return last != null && second - last < seconds;
    }
    final meters = pace.meters;
    final last = _lastSpokenMeters;
    return meters != null && last != null && alongMeters - last < meters;
  }

  void reset() {
    _lastSpokenAt = null;
    _lastSpokenMeters = null;
    _lastSituation = null;
    _spokenAt.clear();
  }
}
