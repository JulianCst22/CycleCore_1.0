import '../../../core/database/database.dart';

/// Un tiempo en un segmento, listo para comparar.
class ComparableEffort {
  final DateTime at;
  final int seconds;

  /// Hecho con la app (grabado en vivo). `false` = una marca de antes de
  /// la app, sacada de un GPX del ciclista.
  final bool withApp;

  /// Con la app y con el coach hablando en ese segmento.
  final bool coached;

  const ComparableEffort({
    required this.at,
    required this.seconds,
    required this.withApp,
    required this.coached,
  });
}

/// Cuál de las dos cifras se compara.
enum ComparisonMetric { best, median }

/// Resumen de un grupo de tiempos.
class EffortGroupStats {
  final int count;
  final int? bestSeconds;
  final DateTime? bestAt;
  final double? medianSeconds;

  const EffortGroupStats({
    required this.count,
    this.bestSeconds,
    this.bestAt,
    this.medianSeconds,
  });

  static const empty = EffortGroupStats(count: 0);

  factory EffortGroupStats.of(Iterable<ComparableEffort> efforts) {
    final list = efforts.toList();
    if (list.isEmpty) return empty;
    var best = list.first;
    for (final e in list) {
      if (e.seconds < best.seconds) best = e;
    }
    final sorted = list.map((e) => e.seconds).toList()..sort();
    final mid = sorted.length ~/ 2;
    final median = sorted.length.isOdd
        ? sorted[mid].toDouble()
        : (sorted[mid - 1] + sorted[mid]) / 2;
    return EffortGroupStats(
      count: list.length,
      bestSeconds: best.seconds,
      bestAt: best.at,
      medianSeconds: median,
    );
  }

  bool get isEmpty => count == 0;

  double? value(ComparisonMetric metric) => switch (metric) {
    ComparisonMetric.best => bestSeconds?.toDouble(),
    ComparisonMetric.median => medianSeconds,
  };
}

/// Qué dos grupos se comparan.
enum ComparisonPair {
  /// Tus tiempos con la app contra los de antes (de tus GPX).
  appVsBefore,

  /// Con la app: con coach contra sin coach.
  coachVsNoCoach,
}

/// Un segmento visto de dos maneras, siempre con datos del ciclista:
/// antes y con la app, y con y sin coach.
class SegmentComparison {
  /// Todos los tiempos, por fecha.
  final List<ComparableEffort> efforts;

  /// Marcas de antes de la app (de los GPX).
  final EffortGroupStats before;
  final EffortGroupStats withApp;
  final EffortGroupStats coached;
  final EffortGroupStats withoutCoach;

  const SegmentComparison({
    required this.efforts,
    required this.before,
    required this.withApp,
    required this.coached,
    required this.withoutCoach,
  });

  static const empty = SegmentComparison(
    efforts: [],
    before: EffortGroupStats.empty,
    withApp: EffortGroupStats.empty,
    coached: EffortGroupStats.empty,
    withoutCoach: EffortGroupStats.empty,
  );

  (EffortGroupStats, EffortGroupStats) _groups(ComparisonPair pair) =>
      switch (pair) {
        ComparisonPair.appVsBefore => (withApp, before),
        ComparisonPair.coachVsNoCoach => (coached, withoutCoach),
      };

  /// Hay tiempos de los dos lados de [pair].
  bool comparable(ComparisonPair pair) {
    final (a, b) = _groups(pair);
    return !a.isEmpty && !b.isEmpty;
  }

  /// Diferencia en segundos del primer grupo contra el segundo
  /// (negativo = más rápido con la app / con el coach).
  double? deltaSeconds(ComparisonPair pair, ComparisonMetric metric) {
    final (a, b) = _groups(pair);
    final va = a.value(metric);
    final vb = b.value(metric);
    if (va == null || vb == null) return null;
    return va - vb;
  }

  /// La misma diferencia en porcentaje del segundo grupo.
  double? deltaPercent(ComparisonPair pair, ComparisonMetric metric) {
    final delta = deltaSeconds(pair, metric);
    final (_, b) = _groups(pair);
    final vb = b.value(metric);
    if (delta == null || vb == null || vb <= 0) return null;
    return delta / vb * 100;
  }
}

/// Arma la comparación de un segmento con sus esfuerzos grabados con la
/// app ([efforts]) y sus marcas de antes ([baseline]).
///
/// [activitiesById] y [coachedRides] dicen en qué salidas habló el coach
/// dentro de ese segmento.
SegmentComparison compareSegment({
  required List<SegmentEffort> efforts,
  required List<BaselineEffort> baseline,
  required Map<int, ActivityRef> activitiesById,
  required Set<(DateTime, int)> coachedRides,
}) {
  final list = <ComparableEffort>[
    for (final b in baseline)
      ComparableEffort(
        at: b.completedAt,
        seconds: b.durationSeconds,
        withApp: false,
        coached: false,
      ),
    for (final e in efforts)
      ComparableEffort(
        at: e.completedAt,
        seconds: e.durationSeconds,
        withApp: true,
        coached: switch (activitiesById[e.activityId]) {
          final a? => coachedRides.contains((a.startedAt, e.segmentId)),
          null => false,
        },
      ),
  ]..sort((a, b) => a.at.compareTo(b.at));

  final app = list.where((e) => e.withApp);
  return SegmentComparison(
    efforts: list,
    before: EffortGroupStats.of(list.where((e) => !e.withApp)),
    withApp: EffortGroupStats.of(app),
    coached: EffortGroupStats.of(app.where((e) => e.coached)),
    withoutCoach: EffortGroupStats.of(app.where((e) => !e.coached)),
  );
}

/// Una fila de la comparativa global.
class SegmentComparisonRow {
  final Segment segment;
  final SegmentComparison comparison;

  const SegmentComparisonRow(this.segment, this.comparison);
}

/// La comparativa de todos los segmentos.
class ComparisonOverview {
  final List<SegmentComparisonRow> rows;

  const ComparisonOverview(this.rows);

  /// Segmentos con tiempos de los dos lados de [pair], del que más
  /// mejoró al que menos.
  List<SegmentComparisonRow> comparable(
    ComparisonPair pair,
    ComparisonMetric metric,
  ) {
    final list = [
      for (final r in rows)
        if (r.comparison.deltaPercent(pair, metric) != null) r,
    ];
    list.sort(
      (a, b) => a.comparison
          .deltaPercent(pair, metric)!
          .compareTo(b.comparison.deltaPercent(pair, metric)!),
    );
    return list;
  }

  /// En cuántos de esos segmentos se va más rápido.
  int fasterCount(ComparisonPair pair, ComparisonMetric metric) => comparable(
    pair,
    metric,
  ).where((r) => r.comparison.deltaPercent(pair, metric)! < 0).length;

  /// Mediana de las diferencias en porcentaje: una sola cifra que no se
  /// deja arrastrar por un segmento raro.
  double? medianDeltaPercent(ComparisonPair pair, ComparisonMetric metric) {
    final values = [
      for (final r in comparable(pair, metric))
        r.comparison.deltaPercent(pair, metric)!,
    ]..sort();
    if (values.isEmpty) return null;
    final mid = values.length ~/ 2;
    return values.length.isOdd
        ? values[mid]
        : (values[mid - 1] + values[mid]) / 2;
  }
}
