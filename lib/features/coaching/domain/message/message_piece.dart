import '../advice/governor.dart';
import '../advice/hints.dart';
import '../variables/labels.dart';
import 'message_values.dart';

/// Qué parte del mensaje arma una pieza. El orden del enum es el orden
/// en que se dicen, y es la gramática acordada:
///
///     [apertura] estado → acción [secundaria] → motivo [plan] [cierre]
///
/// El núcleo (estado, acción, motivo) es lo único obligatorio; lo demás
/// entra según el formato: la apertura y el cierre son el adorno de la
/// persona, la [secundaria] es el segundo consejo concreto (la
/// cadencia, el piñón, la respiración) y el [plan] dice qué hacer con
/// lo que falta. En un aviso urgente no hay tiempo para nada de eso.
///
/// [seguimiento] es aparte: la frase corta que confirma (o no) que el
/// ciclista hizo caso al consejo anterior.
enum PieceSlot {
  apertura,
  estado,
  accion,
  secundaria,
  motivo,
  plan,
  cierre,
  seguimiento,
}

/// Cuándo se puede usar una pieza. Un conjunto vacío significa «sirve
/// para cualquiera»: así una frase neutra no hay que etiquetarla cinco
/// veces.
final class PieceTags {
  final Set<String> personas;
  final Set<EffortState> states;
  final Set<Demand> demands;
  final Set<PhaseLevel> phases;
  final Set<Register> registers;
  final Set<Goal> goals;

  /// Acción del consejo (la etiqueta que describe el ajuste). Es lo que
  /// hace que una pieza de acción diga «bájale» y no «aprieta».
  final Set<Adjustment> adjustments;

  /// Reglas del motor que justifican el mensaje (los ids del
  /// diagnóstico, por ejemplo `C2`). Sirve para que el motivo diga lo
  /// que de verdad decidió el consejo. En las piezas de
  /// [PieceSlot.seguimiento] lleva `cumple` o `no-cumple`.
  final Set<String> diagnoses;

  /// Aviso secundario que la pieza da por cierto. Una pieza que dice
  /// «sube un piñón» solo sirve si el ciclista de verdad tiene piñón
  /// para subir, y eso no lo sabe el banco: lo dice el consejo.
  final Set<AdviceHint> hints;

  const PieceTags({
    this.personas = const {},
    this.states = const {},
    this.demands = const {},
    this.phases = const {},
    this.registers = const {},
    this.goals = const {},
    this.adjustments = const {},
    this.diagnoses = const {},
    this.hints = const {},
  });

  static bool _fits<T>(Set<T> allowed, T value) =>
      allowed.isEmpty || allowed.contains(value);

  /// Si la pieza sirve para este instante.
  bool fit({
    required String persona,
    required EffortState state,
    required Demand demand,
    required PhaseLevel phase,
    required Register register,
    required Goal goal,
    required Adjustment? adjustment,
    required String? diagnosis,
    Set<AdviceHint> available = const {},
  }) =>
      _fits(personas, persona) &&
      _fits(states, state) &&
      _fits(demands, demand) &&
      _fits(phases, phase) &&
      _fits(registers, register) &&
      _fits(goals, goal) &&
      (adjustments.isEmpty ||
          (adjustment != null && adjustments.contains(adjustment))) &&
      (diagnoses.isEmpty ||
          (diagnosis != null && diagnoses.contains(diagnosis))) &&
      (hints.isEmpty || hints.any(available.contains));
}

/// Una pieza del banco: un pedazo de frase con sus huecos.
///
/// El texto lleva los números como huecos (`{potencia}`), nunca
/// escritos: los rellena el compositor con lo que calculó el motor.
final class MessagePiece {
  final String id;
  final PieceSlot slot;
  final String text;
  final PieceTags tags;

  /// Huecos que usa el texto. Si alguno no tiene número en ese
  /// instante, la pieza no se puede usar.
  final Set<MessageValue> values;

  const MessagePiece({
    required this.id,
    required this.slot,
    required this.text,
    this.tags = const PieceTags(),
    this.values = const {},
  });

  /// Palabras del texto ya sin huecos (cada hueco cuenta como una
  /// palabra: es un número dicho).
  int get wordCount => text
      .replaceAll(RegExp(r'\{[a-zA-Z]+\}'), 'X')
      .split(RegExp(r'\s+'))
      .where((w) => w.trim().isNotEmpty)
      .length;

  /// Familia de la pieza: su id sin el número de variante
  /// (`pro.sc.piso.3` → `pro.sc.piso`).
  ///
  /// Dos variantes de lo mismo no pueden sonar en la misma frase: «sin
  /// bajar de 273 vatios, con piso en 273 vatios» es la misma idea
  /// dicha dos veces.
  String get family {
    final cut = id.lastIndexOf('.');
    return cut <= 0 ? id : id.substring(0, cut);
  }

  /// Hueco del nombre del ciclista. No es un número: lo rellena el
  /// compositor, y una pieza que lo lleve no se usa si no hay nombre.
  static const nameHole = '{nombre}';

  bool get usesName => text.contains(nameHole);

  /// Texto con los huecos rellenos. Devuelve `null` si falta alguno.
  String? fill(MessageNumbers numbers, {String? name}) {
    var out = text;
    for (final value in values) {
      final number = numbers[value];
      if (number == null) return null;
      out = out.replaceAll('{${value.name}}', '$number');
    }
    if (usesName) {
      if (name == null || name.isEmpty) return null;
      out = out.replaceAll(nameHole, name);
    }
    return out;
  }

  @override
  String toString() => '$id (${slot.name}): $text';
}
