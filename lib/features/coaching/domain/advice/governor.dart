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

  /// Le tocaba el turno: nada urgente, pero ya pasó el intervalo que
  /// eligió el ciclista y se dice el consejo del momento en tono suave.
  turno,
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

  bool get speak =>
      reason == GovernorReason.speak || reason == GovernorReason.turno;

  /// Es un turno de compañía, no un consejo que la urgencia pidió.
  bool get isTurn => reason == GovernorReason.turno;
}

/// Decide si se habla y con qué tono.
///
/// Un consejo sale cuando, a la vez:
///  1. el extremo inferior de la urgencia supera el umbral (en tipo-2 hay
///     que estar seguro de que es urgente); con la potencia estimada, el
///     centro del intervalo (ver
///     `CoachingParameters.urgencyAtMidpointWhenEstimated`),
///  2. pasó el tiempo mínimo desde el último mensaje,
///  3. la situación no se dijo hace poco,
///  4. si la situación cambió, la nueva supera a la anterior por un
///     margen (histéresis).
///
/// Sin urgencia, el coach igual habla una vez por intervalo de [pace]
/// (el turno): en la primera salida al campo, yendo parejo, la urgencia
/// nunca pasó el umbral y en 28 minutos de subida habló dos veces. El
/// intervalo que elige el ciclista es una promesa de compañía, no solo
/// una espera mínima entre consejos.
final class CoachingGovernor {
  final CoachingParameters parameters;

  /// Cada cuánto quiere el ciclista el aviso normal. Lo urgente no la
  /// respeta: avisar tarde de una rampa es no avisar.
  final CoachingPace pace;

  int? _lastSpokenAt;
  double? _lastSpokenMeters;
  SituationKey? _lastSituation;
  final _spokenAt = <SituationKey, int>{};

  /// Dónde empezó la sesión: el primer turno se cuenta desde acá, para
  /// no pisar el aviso de entrada al segmento.
  int? _firstSecond;
  double? _firstMeters;

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

    _firstSecond ??= second;
    _firstMeters ??= alongMeters;

    final urgency = decision.urgency.centroid;
    if (urgency == null ||
        (powerIsEstimated && parameters.urgencyAtMidpointWhenEstimated
                ? urgency.mid
                : urgency.lo) <=
            parameters.urgencyThreshold) {
      final last = _lastSpokenAt;
      if (best == null ||
          !_turnDue(second, alongMeters) ||
          (last != null && second - last < parameters.minGapSeconds)) {
        return verdict(GovernorReason.lowUrgency);
      }
      // El turno solo marca el reloj: no cuenta como «esta situación ya
      // se dijo», para que un consejo de verdad no quede bloqueado por
      // repetido justo después.
      _lastSpokenAt = second;
      _lastSpokenMeters = alongMeters;
      return verdict(GovernorReason.turno);
    }
    if (best == null) return verdict(GovernorReason.noSituation);
    // Recién entrado al segmento la potencia base todavía no llena su
    // ventana: con seis segundos de datos el motor leía «vas sobrado» y
    // pedía subir fuerte, encima del aviso de entrada al segmento.
    if (second < parameters.basePowerWindowSeconds) {
      return verdict(GovernorReason.tooSoon);
    }

    final urgent = urgency.lo >= parameters.urgentUrgency;
    final last = _lastSpokenAt;
    if (last != null && second - last < parameters.minGapSeconds) {
      return verdict(GovernorReason.tooSoon);
    }
    if (!urgent && _tooSoonForPace(second, alongMeters)) {
      return verdict(GovernorReason.tooSoon);
    }
    GovernorReason? held;
    final sameAt = _spokenAt[best.key];
    if (sameAt != null && second - sameAt < parameters.repeatWindowSeconds) {
      held = GovernorReason.repeated;
    } else {
      final previous = _lastSituation;
      if (previous != null && previous != best.key) {
        final margin = best.activation.mid - table.of(previous).mid;
        if (margin < parameters.situationHysteresis) {
          held = GovernorReason.hysteresis;
        }
      }
    }
    if (held != null) {
      // Repetido o sin margen sobre lo anterior no es consejo nuevo,
      // pero si ya se cumplió el intervalo el turno se da igual.
      if (!_turnDue(second, alongMeters)) return verdict(held);
      _lastSpokenAt = second;
      _lastSpokenMeters = alongMeters;
      return verdict(GovernorReason.turno);
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

  /// Si ya pasó un intervalo entero desde lo último que se dijo (o desde
  /// que empezó la sesión, si todavía no se dijo nada).
  bool _turnDue(int second, double alongMeters) {
    final seconds = pace.seconds;
    if (seconds != null) {
      final since = _lastSpokenAt ?? _firstSecond ?? second;
      return second - since >= seconds;
    }
    final meters = pace.meters;
    if (meters == null) return false;
    final since = _lastSpokenMeters ?? _firstMeters ?? alongMeters;
    return alongMeters - since >= meters;
  }

  void reset() {
    _lastSpokenAt = null;
    _lastSpokenMeters = null;
    _lastSituation = null;
    _spokenAt.clear();
    _firstSecond = null;
    _firstMeters = null;
  }
}
