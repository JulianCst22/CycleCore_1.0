import '../../../../core/fuzzy_type2/fuzzy_type2.dart';
import '../engine/coaching_engine.dart';
import '../variables/labels.dart';

/// Una celda del tensor de mensajes: estado × demanda × fase.
typedef SituationKey = ({EffortState state, Demand demand, PhaseLevel phase});

/// Qué tan bien describe cada celda del tensor el instante actual.
///
/// La activación de una celda es el producto de los grados de sus tres
/// etiquetas (en tipo-2, extremo a extremo). Sirve para elegir la celda y
/// para la histéresis; la decisión de hablar la toma la urgencia.
final class SituationTable {
  final Map<SituationKey, Interval> activations;

  SituationTable._(this.activations);

  factory SituationTable.of(CoachingDecision decision) {
    Interval degree(Map<Enum, Interval> m, Enum label) =>
        m[label] ?? Interval.zero;
    final out = <SituationKey, Interval>{};
    for (final state in EffortState.values) {
      final s = degree(decision.effort.activations, state);
      if (s.hi == 0) continue;
      for (final demand in Demand.values) {
        final d = degree(decision.demand.activations, demand);
        if (d.hi == 0) continue;
        for (final phase in PhaseLevel.values) {
          final f = degree(decision.phase, phase);
          if (f.hi == 0) continue;
          out[(state: state, demand: demand, phase: phase)] = Interval(
            s.lo * d.lo * f.lo,
            s.hi * d.hi * f.hi,
          );
        }
      }
    }
    return SituationTable._(Map.unmodifiable(out));
  }

  /// Activación de [key] (cero si ninguna de sus etiquetas está activa).
  Interval of(SituationKey key) => activations[key] ?? Interval.zero;

  /// La celda más activa (por el punto medio de su intervalo); `null` si
  /// no hay ninguna.
  ({SituationKey key, Interval activation})? get best {
    MapEntry<SituationKey, Interval>? top;
    for (final e in activations.entries) {
      if (top == null || e.value.mid > top.value.mid) top = e;
    }
    return top == null ? null : (key: top.key, activation: top.value);
  }
}
