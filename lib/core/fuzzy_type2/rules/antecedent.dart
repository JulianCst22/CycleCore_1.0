import '../logic/norms.dart';
import 'linguistic_variable.dart';

/// Condición de una regla, representada como árbol de datos.
///
/// Que sea un árbol y no una función permite inspeccionarla: saber qué
/// variables toca (y con eso aplicar la credibilidad de sus fuentes),
/// compararla con otras para detectar contradicciones y explicarla.
sealed class Antecedent {
  const Antecedent();

  /// Variables que aparecen en la condición.
  Set<LinguisticVariable<Enum>> get variables;
}

/// Hecho atómico: «[variable] ES [label]», con un modificador opcional.
final class Is<L extends Enum> extends Antecedent {
  final LinguisticVariable<L> variable;
  final L label;
  final Hedge hedge;

  const Is(this.variable, this.label, {this.hedge = Hedge.none});

  @override
  Set<LinguisticVariable<Enum>> get variables => {variable};

  @override
  bool operator ==(Object other) =>
      other is Is &&
      identical(other.variable, variable) &&
      other.label == label &&
      other.hedge == hedge;

  @override
  int get hashCode => Object.hash(identityHashCode(variable), label, hedge);

  @override
  String toString() =>
      '${variable.name} ES ${hedge == Hedge.none ? '' : '${hedge.name} '}${label.name}';
}

/// Conjunción: todas las condiciones (norma triangular del motor).
final class All extends Antecedent {
  final List<Antecedent> terms;

  const All(this.terms);

  @override
  Set<LinguisticVariable<Enum>> get variables => {
    for (final t in terms) ...t.variables,
  };

  /// La conjunción es conmutativa: el orden de las condiciones no cambia
  /// su significado.
  @override
  bool operator ==(Object other) =>
      other is All && _sameTerms(other.terms, terms);

  @override
  int get hashCode => Object.hash(All, Object.hashAllUnordered(terms.toSet()));

  @override
  String toString() => terms.join(' Y ');
}

/// Disyunción: alguna de las condiciones (conorma del motor).
final class Any extends Antecedent {
  final List<Antecedent> terms;

  const Any(this.terms);

  @override
  Set<LinguisticVariable<Enum>> get variables => {
    for (final t in terms) ...t.variables,
  };

  @override
  bool operator ==(Object other) =>
      other is Any && _sameTerms(other.terms, terms);

  @override
  int get hashCode => Object.hash(Any, Object.hashAllUnordered(terms.toSet()));

  @override
  String toString() => '(${terms.join(' O ')})';
}

/// Negación de una condición.
final class Not extends Antecedent {
  final Antecedent term;

  const Not(this.term);

  @override
  Set<LinguisticVariable<Enum>> get variables => term.variables;

  @override
  bool operator ==(Object other) => other is Not && other.term == term;

  @override
  int get hashCode => Object.hash(Not, term);

  @override
  String toString() => 'NO ($term)';
}

/// Mismas condiciones sin importar orden ni repeticiones: `A ∧ A` es `A`.
bool _sameTerms(List<Object> a, List<Object> b) {
  final sa = a.toSet(), sb = b.toSet();
  return sa.length == sb.length && sa.containsAll(sb);
}
