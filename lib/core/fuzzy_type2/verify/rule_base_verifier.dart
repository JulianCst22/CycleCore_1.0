import '../inference/fuzzy_inputs.dart';
import '../inference/mamdani_engine.dart';
import '../logic/norms.dart';
import '../rules/antecedent.dart';
import '../rules/linguistic_variable.dart';
import '../rules/rule.dart';
import '../rules/rule_base.dart';

/// Punto del universo donde las etiquetas de una variable no suman 1.
typedef PartitionGap = ({double x, double sum});

/// Dos reglas con la misma condición y conclusiones distintas para la
/// misma salida.
typedef RuleConflict = ({Rule first, Rule second});

/// Dos reglas vecinas (sus condiciones difieren en una sola etiqueta, y
/// esa etiqueta es contigua) cuyas conclusiones se separan [jump]
/// etiquetas.
typedef RoughTransition = ({Rule first, Rule second, int jump});

/// Revisiones automáticas de una base de conocimiento. Están pensadas
/// para correr en los tests: un defecto en las reglas falla el build en
/// lugar de aparecer como un consejo raro en la carretera.
abstract final class RuleBaseVerifier {
  /// Puntos donde las etiquetas de [variable] no forman una partición de
  /// Ruspini (`Σμ = 1`). Una partición garantiza que ningún valor de
  /// entrada quede sin cobertura.
  static List<PartitionGap> partitionGaps(
    LinguisticVariable<Enum> variable, {
    int samples = 2000,
    double tolerance = 1e-9,
  }) {
    final gaps = <PartitionGap>[];
    for (var i = 0; i <= samples; i++) {
      final x = variable.min + (variable.max - variable.min) * i / samples;
      final sum = variable.terms.values.fold<double>(0, (s, t) => s + t.mu(x));
      if ((sum - 1).abs() > tolerance) gaps.add((x: x, sum: sum));
    }
    return gaps;
  }

  /// Pares de reglas contradictorias: misma condición, misma variable de
  /// salida y etiqueta distinta.
  static List<RuleConflict> conflicts(RuleBase base) {
    final found = <RuleConflict>[];
    final rules = base.rules;
    for (var i = 0; i < rules.length; i++) {
      for (var j = i + 1; j < rules.length; j++) {
        final a = rules[i], b = rules[j];
        if (a.when == b.when &&
            identical(a.then.variable, b.then.variable) &&
            a.then.label != b.then.label) {
          found.add((first: a, second: b));
        }
      }
    }
    return found;
  }

  /// Reglas que no dispararon en ninguno de los [scenarios]: o sobran, o
  /// los escenarios no cubren la situación para la que se escribieron.
  static List<Rule> deadRules(
    MamdaniEngine engine,
    Iterable<FuzzyInputs> scenarios,
  ) {
    final alive = <String>{};
    for (final inputs in scenarios) {
      for (final f in engine.infer(inputs).trace) {
        if (f.strength.hi > 0) alive.add(f.rule.id);
      }
    }
    return [
      for (final r in engine.rules.rules)
        if (!alive.contains(r.id)) r,
    ];
  }

  /// Variables de entrada de [base] que no forman partición.
  ///
  /// Las entradas que llegan como puerto de otro motor ([except]) no
  /// necesitan serlo: sus grados vienen ya calculados.
  static Map<LinguisticVariable<Enum>, List<PartitionGap>> inputPartitionGaps(
    RuleBase base, {
    int samples = 2000,
    Set<LinguisticVariable<Enum>> except = const {},
  }) {
    final out = <LinguisticVariable<Enum>, List<PartitionGap>>{};
    for (final v in base.inputs) {
      if (except.any((e) => identical(e, v))) continue;
      final gaps = partitionGaps(v, samples: samples);
      if (gaps.isNotEmpty) out[v] = gaps;
    }
    return out;
  }

  /// Saltos bruscos en una base escrita como tabla: dos celdas vecinas no
  /// deberían concluir etiquetas separadas por más de una posición, o la
  /// superficie de control tendría un acantilado (un consejo que cambia
  /// de golpe con un cambio pequeño de la entrada).
  ///
  /// Solo compara reglas cuya condición es una conjunción de hechos sin
  /// modificador (una etiqueta por variable). El orden de las etiquetas
  /// es el de declaración del `enum`, así que deben declararse de menor a
  /// mayor.
  static List<RoughTransition> roughTransitions(RuleBase base) {
    final cells = [for (final r in base.rules) _cellOf(r)];
    final found = <RoughTransition>[];
    for (var i = 0; i < base.rules.length; i++) {
      for (var j = i + 1; j < base.rules.length; j++) {
        final a = base.rules[i], b = base.rules[j];
        final ca = cells[i], cb = cells[j];
        if (ca == null || cb == null) continue;
        if (!identical(a.then.variable, b.then.variable)) continue;
        if (!_areNeighbours(ca, cb)) continue;
        final jump = (a.then.label.index - b.then.label.index).abs();
        if (jump > 1) found.add((first: a, second: b, jump: jump));
      }
    }
    return found;
  }

  static Map<LinguisticVariable<Enum>, Enum>? _cellOf(Rule rule) {
    final atoms = switch (rule.when) {
      final Is atom => [atom],
      All(:final terms) when terms.every((t) => t is Is) => terms.cast<Is>(),
      _ => null,
    };
    if (atoms == null) return null;
    final cell = Map<LinguisticVariable<Enum>, Enum>.identity();
    for (final atom in atoms) {
      if (atom.hedge != Hedge.none || cell.containsKey(atom.variable)) {
        return null;
      }
      cell[atom.variable] = atom.label;
    }
    return cell;
  }

  static bool _areNeighbours(
    Map<LinguisticVariable<Enum>, Enum> a,
    Map<LinguisticVariable<Enum>, Enum> b,
  ) {
    if (a.length != b.length) return false;
    var differences = 0;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null) return false;
      if (other == entry.value) continue;
      if ((other.index - entry.value.index).abs() != 1) return false;
      differences++;
    }
    return differences == 1;
  }

  /// Todas las condiciones atómicas de una regla, para inspección.
  static List<Is> atoms(Antecedent a) => switch (a) {
    final Is atom => [atom],
    All(:final terms) ||
    Any(:final terms) => [for (final t in terms) ...atoms(t)],
    Not(:final term) => atoms(term),
  };
}
