import 'dart:math' as math;

import '../advice/governor.dart';
import '../advice/hints.dart';
import '../advice/situation.dart';
import '../coaching_session.dart';
import '../variables/labels.dart';
import 'message_bank.dart';
import 'message_piece.dart';
import 'message_values.dart';

/// Largo del mensaje.
///
/// No es un capricho de estilo: pedaleando en el límite no se procesan
/// cuarenta palabras. El formato lo decide el momento, no la voz.
enum MessageFormat {
  /// Solo lo imprescindible: qué pasa y qué hacer. Es lo que cabe
  /// cuando hay que corregir ya.
  corto,

  /// El aviso de siempre: estado, acción, motivo y un cierre.
  normal,

  /// Momento clave: la subida se decide acá, así que se explica el
  /// plan y se llama al ciclista por su nombre. Tiene que ser raro: si
  /// todo es clave, nada lo es.
  clave,
}

/// Un mensaje ya armado, listo para decirse.
final class SpokenMessage {
  /// Lo que se dice, con adornos y números.
  final String text;

  /// Solo el núcleo: estado, acción y motivo.
  final String core;

  /// Piezas que lo formaron, en orden (para depurar y para la tesis).
  final List<String> pieceIds;
  final MessageNumbers numbers;

  /// Variables que la frase nombró de verdad (los huecos que rellenó).
  /// La pantalla resalta su recuadro mientras la voz las dice, así el
  /// oído y la vista van al mismo lugar (ADR-6).
  final Set<MessageValue> mentioned;
  final Register register;
  final SituationKey situation;
  final MessageFormat format;

  /// Urgencia con la que salió el consejo (extremo inferior). La usa la
  /// voz para decidir si interrumpe y si suena un toque antes.
  final double urgency;

  /// Es un seguimiento del consejo anterior, no un consejo nuevo.
  final bool isFollowUp;

  SpokenMessage({
    required this.text,
    required this.core,
    required List<String> pieceIds,
    required this.numbers,
    required Set<MessageValue> mentioned,
    required this.register,
    required this.situation,
    required this.urgency,
    this.format = MessageFormat.normal,
    this.isFollowUp = false,
  }) : pieceIds = List.unmodifiable(pieceIds),
       mentioned = Set.unmodifiable(mentioned);

  /// Hay que decirlo ya, aunque esté sonando otra cosa.
  bool get isUrgent => urgency >= 0.80;

  int get wordCount =>
      text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  @override
  String toString() => text;
}

/// Arma la frase de un consejo con las piezas del banco.
///
/// Tres reglas: los números salen del motor (nunca del banco), el
/// adorno de la persona se encoge cuando hay urgencia, y una pieza no
/// se repite mientras quede otra sin usar.
final class MessageComposer {
  final MessageBank bank;

  /// Segundos que una pieza queda «gastada» después de usarse.
  final int repeatWindowSeconds;

  /// Umbrales de urgencia (extremo inferior) para recortar el adorno:
  /// por encima del primero se dice solo el núcleo; por encima del
  /// segundo, núcleo y cierre.
  final double bareUrgency;
  final double shortUrgency;

  /// Grado de limitante desde el que un instante es «momento clave».
  final double keyLimiter;

  /// Espacio mínimo entre dos momentos clave. Sin esto todo termina
  /// siendo clave y el ciclista deja de oír.
  final int keyGapSeconds;

  final math.Random _random;
  final Map<String, int> _usedAt = {};
  int? _lastKeyAt;

  MessageComposer(
    this.bank, {
    int seed = 1,
    this.repeatWindowSeconds = 600,
    this.bareUrgency = 0.80,
    this.shortUrgency = 0.70,
    this.keyLimiter = 0.75,
    this.keyGapSeconds = 300,
  }) : _random = math.Random(seed);

  /// Arma el mensaje de [advice]. Devuelve `null` si el consejo no
  /// tiene situación o si al banco le falta alguna pieza del núcleo
  /// para este instante (mejor callar que decir media frase).
  SpokenMessage? compose(
    Advice advice, {
    required int second,
    Goal goal = Goal.pr,
    String? riderName,
  }) {
    final situation = advice.situation;
    if (situation == null) return null;
    final numbers = numbersOf(advice);
    final register = advice.register;
    final diagnosis = advice.diagnosis?.rule.id;
    final action = advice.decision.advisedAdjustment;

    final said = <String>{};
    MessagePiece? pick(PieceSlot slot) => _pick(
      slot: slot,
      exclude: said,
      situation: situation,
      register: register,
      goal: goal,
      adjustment: action,
      diagnosis: diagnosis,
      numbers: numbers,
      second: second,
      hints: advice.hints,
      riderName: riderName,
    );

    final urgency = advice.urgency?.lo ?? 0;
    final format = formatFor(advice, second: second, urgency: urgency);

    final core = <MessagePiece>[];
    // Si el estado contradice lo que se pide («tanque vacío: exíjase»,
    // «tiene margen: afloje»), el estado no se dice y la frase va directo
    // a la acción. Pasa cuando el estado sale de evidencia débil —sin
    // potenciómetro la reserva estimada es muy incierta— y a la acción la
    // empuja otra cosa (el remate, el terreno que viene): manda lo que hay
    // que hacer, y nombrar un estado que lo desmiente solo confunde.
    final skipState = contradicts(situation.state, action);
    for (final slot in const [PieceSlot.estado, PieceSlot.accion]) {
      if (slot == PieceSlot.estado && skipState) continue;
      final piece = pick(slot);
      if (piece == null) return null;
      said.add(piece.family);
      core.add(piece);
    }
    // El segundo consejo va pegado a la acción. En un aviso urgente no
    // hay tiempo para él, salvo en el tono «con matiz», donde el límite
    // es parte de la orden: «bájale, pero sin bajar de 270 vatios».
    // En un momento clave caben dos: el límite y la respiración, la
    // cadencia y el piñón. Más de dos ya es una lista de tareas.
    final extras = format == MessageFormat.clave ? 2 : 1;
    if (format != MessageFormat.corto || register == Register.conMatiz) {
      for (var i = 0; i < extras; i++) {
        final extra = pick(PieceSlot.secundaria);
        if (extra == null) break;
        said.add(extra.family);
        core.add(extra);
      }
    }
    // En corto tampoco se explica el porqué: se corrige y ya.
    if (format != MessageFormat.corto) {
      final reason = pick(PieceSlot.motivo);
      if (reason == null) return null;
      core.add(reason);
    }
    if (format == MessageFormat.clave) {
      final plan = pick(PieceSlot.plan);
      if (plan != null) core.add(plan);
      _lastKeyAt = second;
    }

    var decorations = switch (format) {
      MessageFormat.corto => 0,
      MessageFormat.normal => urgency >= shortUrgency ? 1 : 2,
      MessageFormat.clave => 2,
    };
    // El tono «con matiz» es justamente orden más límite: ese cierre no
    // se pierde aunque la urgencia recorte el adorno.
    if (register == Register.conMatiz && decorations == 0) decorations = 1;
    final opening = decorations >= 2 ? pick(PieceSlot.apertura) : null;
    final closing = decorations >= 1 ? pick(PieceSlot.cierre) : null;

    return _build(
      opening: opening,
      core: core,
      closing: closing,
      numbers: numbers,
      register: register,
      situation: situation,
      urgency: urgency,
      second: second,
      format: format,
      riderName: riderName,
    );
  }

  /// El estado y la acción tiran para lados opuestos: ir al límite (o
  /// vacío) y que se pida apretar, o ir cómodo (o sobrado) y que se pida
  /// aflojar.
  static bool contradicts(EffortState state, Adjustment? action) {
    if (action == null) return false;
    final easing =
        action == Adjustment.soltar || action == Adjustment.soltarMucho;
    final pushing =
        action == Adjustment.apretar || action == Adjustment.apretarMucho;
    return switch (state) {
      EffortState.fundido || EffortState.alLimite => pushing,
      EffortState.comodo || EffortState.sobrado => easing,
      EffortState.justo => false,
    };
  }

  /// Qué tan largo puede ser el mensaje de este instante.
  ///
  /// Manda la urgencia: si hay que corregir ya, se dice lo mínimo. Si
  /// no, es clave cuando el instante decide la subida —queda un tramo
  /// más duro por delante o lo que topa está topando de verdad— y hace
  /// rato que no se dice uno.
  MessageFormat formatFor(
    Advice advice, {
    required int second,
    required double urgency,
  }) {
    if (urgency >= bareUrgency) return MessageFormat.corto;
    final decisive =
        advice.plan.hasHarderAhead || advice.limiter.degree >= keyLimiter;
    final spaced = _lastKeyAt == null || second - _lastKeyAt! >= keyGapSeconds;
    return decisive && spaced ? MessageFormat.clave : MessageFormat.normal;
  }

  /// Mensaje corto de seguimiento: se usa cuando el consejo anterior
  /// sigue en pie y solo hay que decir si va bien o no.
  SpokenMessage? followUp(
    Advice advice, {
    required int second,
    required bool complying,
    Goal goal = Goal.pr,
    String? riderName,
  }) {
    final situation = advice.situation;
    if (situation == null) return null;
    final numbers = numbersOf(advice);
    final piece = _pick(
      slot: PieceSlot.seguimiento,
      situation: situation,
      register: advice.register,
      goal: goal,
      adjustment: advice.decision.advisedAdjustment,
      diagnosis: complying ? 'cumple' : 'no-cumple',
      numbers: numbers,
      second: second,
      hints: advice.hints,
      riderName: riderName,
    );
    if (piece == null) return null;
    return _build(
      opening: null,
      core: [piece],
      closing: null,
      numbers: numbers,
      register: advice.register,
      situation: situation,
      urgency: advice.urgency?.lo ?? 0,
      second: second,
      format: MessageFormat.corto,
      riderName: riderName,
      isFollowUp: true,
    );
  }

  /// Piezas dichas hace poco, de la más vieja a la más reciente.
  List<String> get recentPieces {
    final ids = _usedAt.keys.toList()
      ..sort((a, b) => _usedAt[a]!.compareTo(_usedAt[b]!));
    return List.unmodifiable(ids);
  }

  /// Olvida lo dicho (otra salida, otro segmento).
  void reset() => _usedAt.clear();

  SpokenMessage? _build({
    required MessagePiece? opening,
    required List<MessagePiece> core,
    required MessagePiece? closing,
    required MessageNumbers numbers,
    required Register register,
    required SituationKey situation,
    required double urgency,
    required int second,
    required MessageFormat format,
    String? riderName,
    bool isFollowUp = false,
  }) {
    final used = [?opening, ...core, ?closing];
    final parts = <String>[];
    for (final piece in used) {
      final text = piece.fill(numbers, name: riderName);
      if (text == null) return null;
      parts.add(text);
      _usedAt[piece.id] = second;
    }
    final coreText = _join(
      parts.sublist(
        opening == null ? 0 : 1,
        parts.length - (closing == null ? 0 : 1),
      ),
    );
    return SpokenMessage(
      text: _join(parts),
      core: coreText,
      pieceIds: [for (final p in used) p.id],
      numbers: numbers,
      mentioned: {for (final p in used) ...p.values},
      register: register,
      situation: situation,
      urgency: urgency,
      format: format,
      isFollowUp: isFollowUp,
    );
  }

  /// Une las piezas en una frase.
  ///
  /// Cada pieza trae la puntuación con la que engancha lo que sigue
  /// («ojo,», «vas al límite:»); la que no trae ninguna se cierra con
  /// punto, y la siguiente arranca en mayúscula. Sin esto un mensaje
  /// largo sale de corrido y la voz lo lee sin respirar.
  static String _join(List<String> parts) {
    final out = StringBuffer();
    for (final raw in parts) {
      final part = raw.trim();
      if (part.isEmpty) continue;
      final start = out.isEmpty || _closes.hasMatch(out.toString());
      if (out.isNotEmpty) out.write(' ');
      out.write(start ? _capitalize(part) : part);
      if (!_punctuated.hasMatch(part)) out.write('.');
    }
    return out.toString();
  }

  static String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  /// La frase anterior ya cerró: lo que siga empieza en mayúscula.
  static final _closes = RegExp(r'[.!?]$');

  /// La pieza trae su propia puntuación al final.
  static final _punctuated = RegExp(r'[.,:;!?…]$');

  /// Elige una pieza del hueco: entre las que sirven y tienen todos sus
  /// números, las menos repetidas primero.
  MessagePiece? _pick({
    required PieceSlot slot,
    required SituationKey situation,
    required Register register,
    required Goal goal,
    required Adjustment? adjustment,
    required String? diagnosis,
    required MessageNumbers numbers,
    required int second,
    Set<AdviceHint> hints = const {},

    /// Familias ya dichas en esta frase.
    Set<String> exclude = const {},
    String? riderName,
  }) {
    final hasName = riderName != null && riderName.isNotEmpty;
    final candidates = [
      for (final piece in bank.slot(slot))
        if (piece.tags.fit(
              persona: bank.persona,
              state: situation.state,
              demand: situation.demand,
              phase: situation.phase,
              register: register,
              goal: goal,
              adjustment: adjustment,
              diagnosis: diagnosis,
              available: hints,
            ) &&
            piece.values.every(numbers.containsKey) &&
            (hasName || !piece.usesName) &&
            !exclude.contains(piece.family))
          piece,
    ];
    if (candidates.isEmpty) return null;

    // Una pieza escrita para este tono dice más que una genérica.
    final specific = [
      for (final piece in candidates)
        if (piece.tags.registers.contains(register)) piece,
    ];
    if (specific.isNotEmpty) candidates.retainWhere(specific.contains);

    final fresh = [
      for (final piece in candidates)
        if (second - (_usedAt[piece.id] ?? -repeatWindowSeconds) >=
            repeatWindowSeconds)
          piece,
    ];
    if (fresh.isNotEmpty) return fresh[_random.nextInt(fresh.length)];

    // Todas dichas hace poco: la que lleve más tiempo sin decirse.
    candidates.sort(
      (a, b) => (_usedAt[a.id] ?? 0).compareTo(_usedAt[b.id] ?? 0),
    );
    return candidates.first;
  }
}
