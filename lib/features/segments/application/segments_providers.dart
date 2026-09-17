import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_database/core_database.dart';
import '../data/segment_catalog_repository.dart';
import '../data/segments_repository.dart';
import '../domain/segment_catalog_entry.dart';
import '../domain/segments_overview.dart';

// Re-exportado para que quien importe este archivo (ej.
// `ActivityDetailScreen`) tenga también `SegmentActivityEntry` y
// `SegmentCreationException` sin necesitar un segundo import directo
// a la capa de datos.
export '../data/segments_repository.dart' show SegmentActivityEntry;

final segmentsRepositoryProvider = Provider<SegmentsRepository>((ref) {
  final database = ref.read(appDatabaseProvider);
  return SegmentsRepository(database);
});

final segmentCatalogRepositoryProvider = Provider<SegmentCatalogRepository>((
  ref,
) {
  return SegmentCatalogRepository(ref.read(segmentsRepositoryProvider));
});

/// Lista de segmentos "nativos" disponibles en el catálogo remoto.
/// `FutureProvider` (snapshot): se re-pide con pull-to-refresh o al
/// reentrar a la pantalla, no necesita ser un stream.
final segmentCatalogProvider = FutureProvider<List<SegmentCatalogEntry>>((ref) {
  return ref.read(segmentCatalogRepositoryProvider).fetchCatalog();
});

/// Ids remotos de segmentos ya descargados -- derivado del mismo stream
/// que alimenta la lista, así el botón "descargar" pasa a "descargado"
/// solo apenas termina la importación.
final downloadedRemoteIdsProvider = Provider<Set<String>>((ref) {
  final segmentsAsync = ref.watch(segmentsListProvider);
  return segmentsAsync.maybeWhen(
    data: (segments) =>
        segments.map((s) => s.remoteId).whereType<String>().toSet(),
    orElse: () => <String>{},
  );
});

/// Todos los segmentos del usuario, activos e inactivos -- la lista
/// completa que va a alimentar el menú de segmentos (Fase 4), con su
/// toggle de activar/desactivar. Es un `Stream` (no un snapshot único)
/// para que crear/renombrar/borrar un segmento se refleje solo, sin
/// tener que refrescar manualmente -- mismo patrón que ya usa
/// `activitiesListProvider`.
final segmentsListProvider = StreamProvider<List<Segment>>((ref) {
  return ref.watch(segmentsRepositoryProvider).watchAllSegments();
});

/// Solo los segmentos activos -- lo que consulta
/// `SegmentDetectionService` (Fase 5) para saber a cuáles vigilar
/// mientras se pedalea. Se vuelve a pedir cada vez que arranca una
/// grabación nueva, así que un snapshot puntual (`FutureProvider`) es
/// suficiente -- no hace falta reactividad en vivo mientras se graba.
final activeSegmentsProvider = FutureProvider<List<Segment>>((ref) async {
  return ref.watch(segmentsRepositoryProvider).getActiveSegments();
});

/// Un segmento puntual, para la pantalla de detalle. En vez de pedir
/// una fila nueva a la base de datos, se deriva del mismo stream que
/// ya mantiene vivo `segmentsListProvider` -- así el detalle se
/// refresca solo si el nombre o el toggle de activo cambian desde
/// otra pantalla (ej. el usuario abre el detalle, vuelve a la lista y
/// lo renombra), sin pagar el costo de una consulta aparte.
///
/// `null` significa "todavía no llega el primer valor del stream" (ver
/// `.when` en la UI) o "el segmento ya no existe" (se borró) -- ambos
/// casos se tratan igual en pantalla: no hay nada que mostrar.
final segmentByIdProvider = Provider.family<AsyncValue<Segment?>, int>((
  ref,
  id,
) {
  final segmentsAsync = ref.watch(segmentsListProvider);
  return segmentsAsync.whenData((segments) {
    for (final segment in segments) {
      if (segment.id == id) return segment;
    }
    return null;
  });
});

/// Esfuerzos guardados para un segmento puntual, del más rápido al
/// más lento -- el primero de la lista es siempre la mejor marca (ver
/// `AppDatabase.watchEffortsForSegment`, que ya viene ordenado por
/// `durationSeconds` ascendente).
final segmentEffortsProvider = StreamProvider.family<List<SegmentEffort>, int>((
  ref,
  segmentId,
) {
  return ref.watch(segmentsRepositoryProvider).watchEfforts(segmentId);
});

/// Todos los esfuerzos de todos los segmentos, del más reciente al más
/// antiguo -- fuente del resumen y el feed del menú de segmentos.
final allSegmentEffortsProvider = StreamProvider<List<SegmentEffort>>((ref) {
  return ref.watch(segmentsRepositoryProvider).watchAllEfforts();
});

/// Resumen del menú de segmentos: cifras del panel, feed de esfuerzos
/// recientes y una `SegmentSummary` por segmento (con su mejor marca y
/// su actividad reciente). Combina tres streams y se recalcula solo
/// cuando cambia cualquiera de ellos.
final segmentsOverviewProvider = Provider<AsyncValue<SegmentsOverview>>((ref) {
  final segments = ref.watch(segmentsListProvider);
  final efforts = ref.watch(allSegmentEffortsProvider);
  final activities = ref.watch(allActivitiesProvider);

  if (segments.isLoading || efforts.isLoading) {
    return const AsyncValue.loading();
  }
  final error = segments.error ?? efforts.error;
  if (error != null) {
    return AsyncValue.error(error, StackTrace.current);
  }

  return AsyncValue.data(
    computeSegmentsOverview(
      segments: segments.requireValue,
      efforts: efforts.requireValue,
      activities: activities.valueOrNull ?? const [],
    ),
  );
});

/// Cómo se dibuja la franja "Progreso" del detalle de segmento: puntos
/// sueltos (dispersión) o línea de tendencia. Vive en memoria -- se
/// recuerda mientras la app está abierta, se resetea al reiniciar.
enum SegmentProgressMode { dots, line }

final segmentProgressModeProvider = StateProvider<SegmentProgressMode>(
  (ref) => SegmentProgressMode.dots,
);

/// Qué segmentos se completaron dentro de una actividad puntual -- lo
/// consume la sección "Segmentos en esta ruta" de
/// `ActivityDetailScreen`. Snapshot único (no stream): la lista de
/// esfuerzos de una actividad ya cerrada no cambia sola, solo si el
/// usuario borra un segmento (en cuyo caso ese esfuerzo deja de
/// resolverse y desaparece de la lista la próxima vez que se entre a
/// la pantalla).
final segmentsForActivityProvider =
    FutureProvider.family<List<SegmentActivityEntry>, int>((ref, activityId) {
      return ref
          .watch(segmentsRepositoryProvider)
          .getSegmentsForActivity(activityId);
    });
