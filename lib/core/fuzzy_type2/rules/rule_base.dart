import 'antecedent.dart';
import 'linguistic_variable.dart';
import 'rule.dart';

/// Conjunto de reglas de un motor. Valida al construirse que los ids no
/// se repitan y que ninguna condición esté vacía.
final class RuleBase {
  final List<Rule> rules;

  /// Variables de salida, en el orden en que aparecen por primera vez.
  final List<LinguisticVariable<Enum>> outputs;

  /// Variables de entrada que usa alguna regla.
  final Set<LinguisticVariable<Enum>> inputs;

  RuleBase(List<Rule> rules)
    : rules = List.unmodifiable(rules),
      outputs = List.unmodifiable(_outputsOf(rules)),
      inputs = Set.unmodifiable({for (final r in rules) ...r.when.variables}) {
    final ids = <String>{};
    for (final r in rules) {
      if (!ids.add(r.id)) {
        throw ArgumentError('Id de regla repetido: ${r.id}');
      }
      _checkNotEmpty(r.when, r.id);
    }
  }

  static List<LinguisticVariable<Enum>> _outputsOf(List<Rule> rules) {
    final seen = <LinguisticVariable<Enum>>[];
    for (final r in rules) {
      if (!seen.any((v) => identical(v, r.then.variable))) {
        seen.add(r.then.variable);
      }
    }
    return seen;
  }

  Rule byId(String id) => rules.firstWhere(
    (r) => r.id == id,
    orElse: () => throw ArgumentError('No existe la regla $id'),
  );

  static void _checkNotEmpty(Antecedent a, String id) {
    switch (a) {
      case Is():
        return;
      case All(:final terms) || Any(:final terms):
        if (terms.isEmpty) {
          throw ArgumentError('La regla $id tiene una condición vacía.');
        }
        for (final t in terms) {
          _checkNotEmpty(t, id);
        }
      case Not(:final term):
        _checkNotEmpty(term, id);
    }
  }
}
