import '../rules/linguistic_variable.dart';
import '../sets/interval.dart';

/// Entradas de una inferencia: los grados de pertenencia de cada
/// variable, ya calculados.
///
/// Una variable se puede cargar de dos maneras: con su valor (exacto o
/// como intervalo de incertidumbre), que se fuzzifica aquí, o con sus
/// grados directamente, que es como un motor recibe la salida de otro
/// motor en una jerarquía sin defuzzificar en el medio.
final class FuzzyInputs {
  final Map<LinguisticVariable<Enum>, Map<Enum, Interval>> _degrees =
      Map.identity();

  /// Valor exacto (tipo-1).
  void crisp<L extends Enum>(LinguisticVariable<L> variable, double value) =>
      uncertain(variable, Interval.point(value));

  /// Valor que puede estar en cualquier punto de [value].
  void uncertain<L extends Enum>(
    LinguisticVariable<L> variable,
    Interval value,
  ) => _degrees[variable] = variable.fuzzify(value);

  /// Grados ya calculados, por ejemplo el puerto de salida de otro motor.
  /// Las etiquetas que falten valen 0.
  void degrees<L extends Enum>(
    LinguisticVariable<L> variable,
    Map<L, Interval> degrees,
  ) => _degrees[variable] = Map<Enum, Interval>.of(degrees);

  bool has(LinguisticVariable<Enum> variable) => _degrees.containsKey(variable);

  /// Grado de [label] en [variable]. Falla si la variable no se cargó:
  /// una regla que la usa no puede evaluarse.
  Interval degreeOf(LinguisticVariable<Enum> variable, Enum label) {
    final byLabel = _degrees[variable];
    if (byLabel == null) {
      throw StateError('Falta la entrada ${variable.name}.');
    }
    return byLabel[label] ?? Interval.zero;
  }

  Map<Enum, Interval> degreesOf(LinguisticVariable<Enum> variable) =>
      Map.unmodifiable(_degrees[variable] ?? const {});
}
