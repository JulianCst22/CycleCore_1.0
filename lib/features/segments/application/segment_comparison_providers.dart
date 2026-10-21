import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../domain/segment_comparison.dart';
import 'segments_providers.dart';

/// Lo básico de cada actividad (fechas y título), sin cargar
/// trazados.
final activityRefsProvider = StreamProvider<List<ActivityRef>>((ref) {
  return ref.watch(appDatabaseProvider).watchActivityRefs();
});

/// Salidas y segmentos en los que habló el coach.
final coachedRidesProvider = StreamProvider<Set<(DateTime, int)>>((ref) {
  return ref.watch(appDatabaseProvider).watchCoachedSegmentRides();
});

/// Marcas de antes de la app (de los GPX), de todos los segmentos.
final allBaselineEffortsProvider = StreamProvider<List<BaselineEffort>>((ref) {
  return ref.watch(segmentsRepositoryProvider).watchAllBaselineEfforts();
});

/// Antes y con la app, y con y sin coach, en un segmento.
final segmentComparisonProvider =
    Provider.family<AsyncValue<SegmentComparison>, int>((ref, segmentId) {
      final efforts = ref.watch(segmentEffortsProvider(segmentId));
      final baseline = ref.watch(allBaselineEffortsProvider);
      final activities = ref.watch(activityRefsProvider);
      final coached = ref.watch(coachedRidesProvider);

      final pending = [efforts, baseline, activities, coached];
      if (pending.any((a) => a.isLoading)) return const AsyncValue.loading();
      for (final a in pending) {
        if (a.hasError) return AsyncValue.error(a.error!, StackTrace.current);
      }

      return AsyncValue.data(
        compareSegment(
          efforts: efforts.requireValue,
          baseline: [
            for (final b in baseline.requireValue)
              if (b.segmentId == segmentId) b,
          ],
          activitiesById: {for (final a in activities.requireValue) a.id: a},
          coachedRides: coached.requireValue,
        ),
      );
    });

/// La comparativa de todos los segmentos.
final comparisonOverviewProvider = Provider<AsyncValue<ComparisonOverview>>((
  ref,
) {
  final segments = ref.watch(segmentsListProvider);
  final efforts = ref.watch(allSegmentEffortsProvider);
  final baseline = ref.watch(allBaselineEffortsProvider);
  final activities = ref.watch(activityRefsProvider);
  final coached = ref.watch(coachedRidesProvider);

  final pending = [segments, efforts, baseline, activities, coached];
  if (pending.any((a) => a.isLoading)) return const AsyncValue.loading();
  for (final a in pending) {
    if (a.hasError) return AsyncValue.error(a.error!, StackTrace.current);
  }

  final activitiesById = {for (final a in activities.requireValue) a.id: a};
  final effortsBySegment = <int, List<SegmentEffort>>{};
  for (final e in efforts.requireValue) {
    (effortsBySegment[e.segmentId] ??= []).add(e);
  }
  final baselineBySegment = <int, List<BaselineEffort>>{};
  for (final b in baseline.requireValue) {
    (baselineBySegment[b.segmentId] ??= []).add(b);
  }

  return AsyncValue.data(
    ComparisonOverview([
      for (final s in segments.requireValue)
        SegmentComparisonRow(
          s,
          compareSegment(
            efforts: effortsBySegment[s.id] ?? const [],
            baseline: baselineBySegment[s.id] ?? const [],
            activitiesById: activitiesById,
            coachedRides: coached.requireValue,
          ),
        ),
    ]),
  );
});
