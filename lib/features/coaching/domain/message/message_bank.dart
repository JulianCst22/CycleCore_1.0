import 'dart:convert';

import '../advice/governor.dart';
import '../advice/hints.dart';
import '../advice/situation.dart';
import '../variables/labels.dart';
import 'message_piece.dart';
import 'message_values.dart';

/// Banco de piezas de una voz, tal como viene del archivo JSON.
///
/// El banco se genera fuera de la app y se revisa con
/// `MessageBankValidator`; en carretera solo se leen piezas, nunca se
/// inventan frases.
final class MessageBank {
  final int version;

  /// Voces a las que sirve este archivo.
  final String persona;

  /// Situaciones que el archivo se compromete a cubrir.
  final List<SituationKey> covers;
  final List<MessagePiece> pieces;

  MessageBank({
    required this.version,
    required this.persona,
    required this.covers,
    required List<MessagePiece> pieces,
  }) : pieces = List.unmodifiable(pieces);

  /// Piezas de un hueco de la gramática.
  Iterable<MessagePiece> slot(PieceSlot slot) =>
      pieces.where((p) => p.slot == slot);

  static MessageBank parse(String source) {
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('El banco debe ser un objeto JSON.');
    }
    final persona = _string(json, 'persona');
    return MessageBank(
      version: (json['version'] as num?)?.toInt() ?? 1,
      persona: persona,
      covers: [
        for (final c in (json['covers'] as List? ?? const []))
          _situation(c as Map<String, dynamic>),
      ],
      pieces: [
        for (final p in (json['pieces'] as List? ?? const []))
          _piece(p as Map<String, dynamic>, persona),
      ],
    );
  }

  static SituationKey _situation(Map<String, dynamic> json) => (
    state: _enumOf(EffortState.values, _string(json, 'state')),
    demand: _enumOf(Demand.values, _string(json, 'demand')),
    phase: _enumOf(PhaseLevel.values, _string(json, 'phase')),
  );

  static MessagePiece _piece(Map<String, dynamic> json, String persona) {
    final id = _string(json, 'id');
    try {
      return MessagePiece(
        id: id,
        slot: _enumOf(PieceSlot.values, _string(json, 'slot')),
        text: _string(json, 'text'),
        values: _set(json, 'values', MessageValue.values),
        tags: PieceTags(
          personas: {persona},
          states: _set(json, 'states', EffortState.values),
          demands: _set(json, 'demands', Demand.values),
          phases: _set(json, 'phases', PhaseLevel.values),
          registers: _set(json, 'registers', Register.values),
          goals: _set(json, 'goals', Goal.values),
          adjustments: _set(json, 'adjustments', Adjustment.values),
          diagnoses: {
            for (final d in (json['diagnoses'] as List? ?? const []))
              d as String,
          },
          hints: _set(json, 'hints', AdviceHint.values),
        ),
      );
    } on FormatException catch (e) {
      throw FormatException('Pieza $id: ${e.message}');
    }
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('falta «$key»');
    }
    return value;
  }

  static Set<T> _set<T extends Enum>(
    Map<String, dynamic> json,
    String key,
    List<T> values,
  ) => {
    for (final v in (json[key] as List? ?? const []))
      _enumOf(values, v as String),
  };

  static T _enumOf<T extends Enum>(List<T> values, String name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    throw FormatException(
      '«$name» no existe (opciones: ${values.map((v) => v.name).join(', ')})',
    );
  }
}

/// Un defecto encontrado en un banco.
typedef BankIssue = ({String piece, String problem});

/// Revisiones del banco de frases. Corren en los tests y en el
/// validador de línea de comandos: una frase mal etiquetada, con un
/// número escrito a mano o demasiado larga no debería llegar nunca a la
/// carretera.
abstract final class MessageBankValidator {
  /// Núcleo máximo del mensaje (estado + acción + motivo).
  ///
  /// Eran 12 palabras, unos cinco segundos. Subió a 14 cuando se exigió
  /// que todo número dijera su unidad: «bájale a 285» pasó a «bájale a
  /// 285 vatios», y esa palabra de más se paga en cada frase. Vale la
  /// pena: un número sin unidad obliga a pensar, y pensando con el
  /// pulso arriba no se entiende nada.
  static const maxCoreWords = 14;

  /// Máximo de cada adorno de la persona (apertura o cierre).
  static const maxDecorationWords = 5;

  /// Máximo del segundo consejo y del plan. Son frases de apoyo: si se
  /// alargan, tapan lo que de verdad hay que hacer.
  static const maxExtraWords = 8;

  /// Mensaje de momento clave completo. Unas quince segundos hablados:
  /// es lo más largo que se puede oír pedaleando sin perder el hilo, y
  /// solo se usa cuando el tramo decide la subida.
  static const maxKeyWords = 40;

  static const _coreSlots = [
    PieceSlot.estado,
    PieceSlot.accion,
    PieceSlot.motivo,
  ];

  /// Todo lo que puede llegar a sonar en un momento clave. La
  /// secundaria va dos veces porque ahí caben dos consejos de apoyo.
  static const _keySlots = [
    PieceSlot.apertura,
    PieceSlot.estado,
    PieceSlot.accion,
    PieceSlot.secundaria,
    PieceSlot.secundaria,
    PieceSlot.motivo,
    PieceSlot.plan,
    PieceSlot.cierre,
  ];

  static final _hole = RegExp(r'\{([a-zA-Z]+)\}');

  /// El nombre del ciclista no es un número del motor: no se declara
  /// en `values` ni lleva unidad.
  static const _nameHole = 'nombre';
  static final _digit = RegExp(r'\d');

  static List<BankIssue> check(MessageBank bank) => [
    ..._pieceIssues(bank),
    ..._lengthIssues(bank),
    ..._coverageIssues(bank),
  ];

  static Iterable<BankIssue> _pieceIssues(MessageBank bank) sync* {
    final seen = <String>{};
    for (final piece in bank.pieces) {
      if (!seen.add(piece.id)) {
        yield (piece: piece.id, problem: 'id repetido');
      }
      if (_digit.hasMatch(piece.text)) {
        yield (
          piece: piece.id,
          problem: 'tiene un número escrito: los números solo van en huecos',
        );
      }
      final used = _hole
          .allMatches(piece.text)
          .map((m) => m.group(1)!)
          .where((h) => h != _nameHole)
          .toSet();
      final declared = piece.values.map((v) => v.name).toSet();
      for (final hole in used.difference(declared)) {
        yield (piece: piece.id, problem: 'el hueco {$hole} no está declarado');
      }
      for (final hole in declared.difference(used)) {
        yield (piece: piece.id, problem: 'declara {$hole} pero no lo usa');
      }
      // Todo número dicho tiene que venir con su unidad: «285» no se
      // entiende, «285 vatios» sí.
      // El nombre del hueco no cuenta como unidad: «{cadencia}» ya
      // trae la palabra dentro, y lo que importa es lo que se oye.
      final spoken = piece.text.toLowerCase().replaceAll(_hole, ' ');
      for (final value in piece.values) {
        final units = unitWordsOf(value);
        if (!units.any(spoken.contains)) {
          yield (
            piece: piece.id,
            problem:
                'dice {${value.name}} sin su unidad '
                '(${units.first})',
          );
        }
      }
      if (piece.text.trim() != piece.text) {
        yield (
          piece: piece.id,
          problem: 'sobran espacios al principio o al final',
        );
      }
      final isDecoration =
          piece.slot == PieceSlot.apertura || piece.slot == PieceSlot.cierre;
      if (isDecoration && piece.wordCount > maxDecorationWords) {
        yield (
          piece: piece.id,
          problem:
              'el adorno son ${piece.wordCount} palabras '
              '(máximo $maxDecorationWords)',
        );
      }
      final isExtra =
          piece.slot == PieceSlot.secundaria || piece.slot == PieceSlot.plan;
      if (isExtra && piece.wordCount > maxExtraWords) {
        yield (
          piece: piece.id,
          problem:
              'el apoyo son ${piece.wordCount} palabras '
              '(máximo $maxExtraWords)',
        );
      }
      // Una pieza de apoyo sin etiqueta de aviso se podría decir
      // siempre, y ahí es donde salen los consejos imposibles.
      if (isExtra && piece.tags.hints.isEmpty && piece.values.isEmpty) {
        yield (
          piece: piece.id,
          problem: 'pieza de apoyo sin aviso ni número: se diría siempre',
        );
      }
    }
  }

  /// Ni el núcleo ni el mensaje de momento clave más largos que el
  /// banco puede llegar a armar pueden pasarse de lo acordado.
  static Iterable<BankIssue> _lengthIssues(MessageBank bank) sync* {
    yield* _longest(bank, _coreSlots, maxCoreWords, 'el núcleo');
    yield* _longest(bank, _keySlots, maxKeyWords, 'el momento clave');
  }

  static Iterable<BankIssue> _longest(
    MessageBank bank,
    List<PieceSlot> slots,
    int limit,
    String what,
  ) sync* {
    var longest = 0;
    final pieces = <String>[];
    // Un hueco puede repetirse (la secundaria va dos veces en un
    // momento clave), y entonces son las dos piezas más largas de
    // familias distintas: la misma frase no suena dos veces.
    for (final entry in _countBySlot(slots).entries) {
      final ordered = bank.slot(entry.key).toList()
        ..sort((a, b) => b.wordCount.compareTo(a.wordCount));
      final families = <String>{};
      for (final piece in ordered) {
        if (families.length >= entry.value) break;
        if (!families.add(piece.family)) continue;
        longest += piece.wordCount;
        pieces.add(piece.id);
      }
    }
    if (longest > limit) {
      yield (
        piece: pieces.join(' + '),
        problem: '$what más largo son $longest palabras (máximo $limit)',
      );
    }
  }

  static Map<PieceSlot, int> _countBySlot(List<PieceSlot> slots) {
    final counts = <PieceSlot, int>{};
    for (final slot in slots) {
      counts[slot] = (counts[slot] ?? 0) + 1;
    }
    return counts;
  }

  /// Cobertura mínima para que el compositor nunca se quede a medias:
  ///
  ///  - cada situación cubierta, en cada tono, con estado y motivo;
  ///  - cada acción posible, en cada tono, con su pieza de acción.
  static Iterable<BankIssue> _coverageIssues(MessageBank bank) sync* {
    bool has(
      PieceSlot slot, {
      required SituationKey situation,
      required Register register,
      Adjustment? adjustment,
    }) => bank
        .slot(slot)
        .any(
          (p) => p.tags.fit(
            persona: bank.persona,
            state: situation.state,
            demand: situation.demand,
            phase: situation.phase,
            register: register,
            goal: Goal.pr,
            adjustment: adjustment,
            diagnosis: null,
          ),
        );

    for (final situation in bank.covers) {
      final name =
          '${situation.state.name}/${situation.demand.name}/'
          '${situation.phase.name}';
      for (final register in Register.values) {
        for (final slot in const [PieceSlot.estado, PieceSlot.motivo]) {
          if (!has(slot, situation: situation, register: register)) {
            yield (
              piece: name,
              problem:
                  'sin pieza de ${slot.name} para el tono ${register.name}',
            );
          }
        }
        for (final adjustment in Adjustment.values) {
          if (!has(
            PieceSlot.accion,
            situation: situation,
            register: register,
            adjustment: adjustment,
          )) {
            yield (
              piece: name,
              problem:
                  'sin pieza de acción «${adjustment.name}» para el tono '
                  '${register.name}',
            );
          }
        }
      }
    }
  }
}
