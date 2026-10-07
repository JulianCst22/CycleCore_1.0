import '../reduction/karnik_mendel.dart';
import '../rules/linguistic_variable.dart';
import '../rules/rule.dart';
import '../sets/interval.dart';
import '../sets/polyline.dart';
import '../shape/shape_descriptors.dart';

/// Cómo votó una regla en una inferencia.
final class FiredRule {
  final Rule rule;

  /// Valor de verdad de la condición.
  final Interval truth;

  /// Credibilidad aplicada: la de la fuente menos creíble que usa.
  final double credibility;

  /// `truth × certeza × credibilidad`.
  final Interval strength;

  const FiredRule({
    required this.rule,
    required this.truth,
    required this.credibility,
    required this.strength,
  });

  @override
  String toString() => '${rule.id} $strength';
}

/// Resultado de una variable de salida.
final class OutputInference {
  final LinguisticVariable<Enum> variable;

  /// Activación de cada etiqueta: es el puerto que recibe un motor de
  /// nivel superior.
  final Map<Enum, Interval> activations;

  /// Figura superior (disparos máximos, etiquetas ensanchadas).
  final Polyline upper;

  /// Figura inferior (disparos mínimos, etiquetas estrechadas).
  final Polyline lower;

  /// Reducción de tipo; `null` si ninguna regla aportó evidencia.
  final TypeReduction? reduction;

  late final ShapeDescriptors upperShape = ShapeDescriptors.of(upper);
  late final ShapeDescriptors lowerShape = ShapeDescriptors.of(lower);

  OutputInference({
    required this.variable,
    required Map<Enum, Interval> activations,
    required this.upper,
    required this.lower,
    required this.reduction,
  }) : activations = Map.unmodifiable(activations);

  bool get hasEvidence => reduction != null;

  /// Centroide de intervalo `[y_l, y_r]`.
  Interval? get centroid {
    final r = reduction;
    return r == null ? null : Interval(r.left, r.right);
  }

  /// Valor recomendado: punto medio del centroide de intervalo.
  double? get value => centroid?.mid;

  /// Ancho del centroide: la incertidumbre del resultado.
  double? get uncertainty => centroid?.width;

  /// [uncertainty] relativa al tamaño del universo.
  double? get relativeUncertainty {
    final u = uncertainty;
    return u == null ? null : u / (variable.max - variable.min);
  }

  Interval activationOf(Enum label) => activations[label] ?? Interval.zero;
}

/// Resultado completo de una inferencia: una salida por variable y la
/// traza de todas las reglas, de la más fuerte a la más débil.
final class InferenceResult {
  final Map<LinguisticVariable<Enum>, OutputInference> _outputs;
  final List<FiredRule> trace;

  InferenceResult(
    Map<LinguisticVariable<Enum>, OutputInference> outputs,
    List<FiredRule> trace,
  ) : _outputs = Map.unmodifiable(outputs),
      trace = List.unmodifiable(_sortedByStrength(trace));

  /// De la regla más fuerte a la más débil; en empate se conserva el
  /// orden de la base (el ordenamiento de Dart no es estable).
  static List<FiredRule> _sortedByStrength(List<FiredRule> trace) {
    final indexed = [for (var i = 0; i < trace.length; i++) (i, trace[i])];
    indexed.sort((x, y) {
      final byHi = y.$2.strength.hi.compareTo(x.$2.strength.hi);
      if (byHi != 0) return byHi;
      final byLo = y.$2.strength.lo.compareTo(x.$2.strength.lo);
      return byLo != 0 ? byLo : x.$1.compareTo(y.$1);
    });
    return [for (final e in indexed) e.$2];
  }

  Iterable<OutputInference> get outputs => _outputs.values;

  OutputInference operator [](LinguisticVariable<Enum> variable) {
    final out = _outputs[variable];
    if (out == null) {
      throw ArgumentError('${variable.name} no es salida de este motor.');
    }
    return out;
  }

  /// Reglas que aportaron algo a [variable], de la más fuerte a la más
  /// débil.
  List<FiredRule> firedFor(LinguisticVariable<Enum> variable) => [
    for (final f in trace)
      if (identical(f.rule.then.variable, variable) && f.strength.hi > 0) f,
  ];
}
