import 'antecedent.dart';
import 'linguistic_variable.dart';

/// Conclusión de una regla: «[variable] ES [label]».
final class Consequent<L extends Enum> {
  final LinguisticVariable<L> variable;
  final L label;

  const Consequent(this.variable, this.label);

  @override
  bool operator ==(Object other) =>
      other is Consequent &&
      identical(other.variable, variable) &&
      other.label == label;

  @override
  int get hashCode => Object.hash(identityHashCode(variable), label);

  @override
  String toString() => '${variable.name} ES ${label.name}';
}

/// Regla difusa: «SI [when] ENTONCES [then]».
///
/// [certainty] es la confianza del experto en la regla (0–1) y
/// [rationale] explica en lenguaje natural por qué existe; se usa para
/// documentarla y para explicar un consejo.
final class Rule {
  final String id;
  final Antecedent when;
  final Consequent<Enum> then;
  final double certainty;
  final String rationale;

  const Rule({
    required this.id,
    required this.when,
    required this.then,
    this.certainty = 1,
    this.rationale = '',
  }) : assert(certainty >= 0 && certainty <= 1);

  @override
  String toString() => '$id: SI $when ENTONCES $then';
}
