import '../../../core/database/app_database.dart';

/// Un segmento con su marca y su actividad reciente resumidas -- lo que
/// necesita cada tarjeta de la lista de segmentos.
class SegmentSummary {
  final Segment segment;

  /// El esfuerzo más rápido registrado, o `null` si nunca se completó.
  final SegmentEffort? best;
  final int effortCount;
  final DateTime? lastEffortAt;

  const SegmentSummary({
    required this.segment,
    this.best,
    this.effortCount = 0,
    this.lastEffortAt,
  });

  bool get hasEfforts => best != null;
}

/// Un esfuerzo del feed "esfuerzos recientes", ya resuelto contra su
/// segmento (nombre, mejor marca) y su actividad (título).
class RecentEffort {
  final SegmentEffort effort;
  final int segmentId;
  final String segmentName;
  final String? activityTitle;

  /// Para un esfuerzo normal: segundos por encima de la mejor marca del
  /// segmento (positivo). Para el esfuerzo que ES la mejor marca:
  /// segundos por debajo de la marca anterior (negativo), o `0` si es
  /// el primer tiempo del segmento.
  final int deltaSeconds;
  final bool isPersonalBest;

  /// El esfuerzo que marca el récord es además el primer tiempo del
  /// segmento (no batió nada porque no había nada).
  final bool isFirstEffort;

  const RecentEffort({
    required this.effort,
    required this.segmentId,
    required this.segmentName,
    required this.activityTitle,
    required this.deltaSeconds,
    required this.isPersonalBest,
    required this.isFirstEffort,
  });
}

/// Todo lo que muestra el menú de segmentos de un vistazo.
class SegmentsOverview {
  final int total;
  final int active;

  /// Segmentos cuya mejor marca actual se logró este mes.
  final int personalBestsThisMonth;
  final int totalEfforts;

  final List<SegmentSummary> summaries;
  final List<RecentEffort> recent;

  const SegmentsOverview({
    required this.total,
    required this.active,
    required this.personalBestsThisMonth,
    required this.totalEfforts,
    required this.summaries,
    required this.recent,
  });

  bool get isEmpty => total == 0;
}

/// Máximo de filas en el feed de "esfuerzos recientes".
const int _kRecentFeedLimit = 8;

/// Cruza segmentos + esfuerzos + actividades en un [SegmentsOverview].
/// Función pura (sin Riverpod ni base de datos) para poder probarla.
/// [now] es inyectable en pruebas.
SegmentsOverview computeSegmentsOverview({
  required List<Segment> segments,
  required List<SegmentEffort> efforts,
  List<Activity> activities = const [],
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final titleByActivityId = {for (final a in activities) a.id: a.title};

  final effortsBySegment = <int, List<SegmentEffort>>{};
  for (final e in efforts) {
    effortsBySegment.putIfAbsent(e.segmentId, () => []).add(e);
  }

  // Mejor y segunda mejor marca por segmento -- la segunda sirve para
  // decir "cuánto batiste tu marca anterior" en el feed.
  final bestSecondsBySegment = <int, int>{};
  final secondBestSecondsBySegment = <int, int>{};
  for (final entry in effortsBySegment.entries) {
    final durations = entry.value.map((e) => e.durationSeconds).toList()
      ..sort();
    bestSecondsBySegment[entry.key] = durations.first;
    if (durations.length >= 2) {
      secondBestSecondsBySegment[entry.key] = durations[1];
    }
  }

  // --- Resumen por segmento (tarjetas) ---
  var personalBestsThisMonth = 0;
  final summaries = <SegmentSummary>[];
  for (final segment in segments) {
    final list = effortsBySegment[segment.id] ?? const <SegmentEffort>[];
    SegmentEffort? best;
    DateTime? last;
    for (final e in list) {
      if (best == null || e.durationSeconds < best.durationSeconds) best = e;
      if (last == null || e.completedAt.isAfter(last)) last = e.completedAt;
    }
    if (best != null &&
        best.completedAt.year == reference.year &&
        best.completedAt.month == reference.month) {
      personalBestsThisMonth++;
    }
    summaries.add(
      SegmentSummary(
        segment: segment,
        best: best,
        effortCount: list.length,
        lastEffortAt: last,
      ),
    );
  }

  int rank(SegmentSummary s) {
    if (s.segment.isActive && s.hasEfforts) return 0;
    if (s.segment.isActive) return 1;
    if (s.hasEfforts) return 2;
    return 3;
  }

  summaries.sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    if (a.hasEfforts && b.hasEfforts) {
      return b.lastEffortAt!.compareTo(a.lastEffortAt!);
    }
    return a.segment.name.toLowerCase().compareTo(b.segment.name.toLowerCase());
  });

  // --- Feed de esfuerzos recientes ---
  final segmentNameById = {for (final s in segments) s.id: s.name};
  final byDateDesc = [...efforts]
    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  final recent = <RecentEffort>[];
  for (final e in byDateDesc) {
    final name = segmentNameById[e.segmentId];
    if (name == null) continue; // el segmento se borró
    final bestSeconds = bestSecondsBySegment[e.segmentId] ?? e.durationSeconds;
    final isBest = e.durationSeconds == bestSeconds;
    final secondBest = secondBestSecondsBySegment[e.segmentId];
    final delta = isBest
        ? (secondBest == null ? 0 : e.durationSeconds - secondBest)
        : e.durationSeconds - bestSeconds;
    recent.add(
      RecentEffort(
        effort: e,
        segmentId: e.segmentId,
        segmentName: name,
        activityTitle: titleByActivityId[e.activityId],
        deltaSeconds: delta,
        isPersonalBest: isBest,
        isFirstEffort: isBest && secondBest == null,
      ),
    );
    if (recent.length >= _kRecentFeedLimit) break;
  }

  return SegmentsOverview(
    total: segments.length,
    active: segments.where((s) => s.isActive).length,
    personalBestsThisMonth: personalBestsThisMonth,
    totalEfforts: efforts.length,
    summaries: summaries,
    recent: recent,
  );
}
