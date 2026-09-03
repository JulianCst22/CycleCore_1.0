import 'package:drift/drift.dart' show Value;

import '../../../core/database/app_database.dart';
import '../../activities/domain/activity_json_helpers.dart';
import '../domain/segment_profile.dart';
import '../domain/segment_profile_builder.dart';
import '../domain/segment_source.dart';
import '../domain/segment_stats_calculator.dart';

/// Se lanza cuando el tramo que el usuario intentó recortar no sirve
/// para convertirse en segmento. `message` ya viene en español y
/// listo para mostrarse tal cual en la UI de creación (Fase 3) --
/// captúralo ahí en vez de dejarlo propagarse como un error genérico.
class SegmentCreationException implements Exception {
  final String message;
  const SegmentCreationException(this.message);

  @override
  String toString() => message;
}

/// Un segmento completado junto con el esfuerzo puntual de ESA
/// actividad -- es lo que necesita `ActivityDetailScreen` para la
/// sección "Segmentos en esta ruta": el nombre/stats del segmento
/// (`segment`) más el tiempo que se hizo ese día en particular
/// (`effort`), sin mezclarlo con el resto del historial del segmento.
class SegmentActivityEntry {
  final Segment segment;
  final SegmentEffort effort;

  const SegmentActivityEntry({required this.segment, required this.effort});
}

/// CRUD de segmentos + la lógica de crear uno nuevo desde sus dos
/// orígenes posibles:
///  - recortándolo de una actividad propia ya aplanada contra HGT
///    (`createSegmentFromActivity`);
///  - importando un GPX (`createSegmentFromGpx`), ya sea uno que subió
///    el usuario o uno del catálogo remoto de segmentos nativos.
class SegmentsRepository {
  final AppDatabase database;

  /// Alias público del umbral real (ver `kMinSegmentDistanceMeters`
  /// en `segment_stats_calculator.dart`) -- se deja expuesto acá
  /// también porque quien importa el repositorio no siempre necesita
  /// importar además la capa de dominio solo para leer una constante.
  static const double minSegmentDistanceMeters = kMinSegmentDistanceMeters;

  SegmentsRepository(this.database);

  Stream<List<Segment>> watchAllSegments() => database.watchAllSegments();

  Future<List<Segment>> getActiveSegments() => database.getActiveSegments();

  Future<Segment?> getSegmentById(int id) => database.getSegmentById(id);

  /// Prende/apaga la vigilancia de un segmento -- el toggle del menú
  /// de segmentos (Fase 4).
  Future<void> setActive(int id, bool isActive) =>
      database.setSegmentActive(id, isActive);

  Future<void> rename(int id, String name) => database.renameSegment(id, name);

  Future<void> delete(int id) => database.deleteSegment(id);

  Stream<List<SegmentEffort>> watchEfforts(int segmentId) =>
      database.watchEffortsForSegment(segmentId);

  /// Todos los esfuerzos de todos los segmentos, del más reciente al
  /// más antiguo -- para el resumen del menú de segmentos.
  Stream<List<SegmentEffort>> watchAllEfforts() => database.watchAllEfforts();

  /// Snapshot (no stream) de los esfuerzos de un segmento, del más
  /// rápido al más lento -- lo usa `SegmentDetectionController` al
  /// empezar a grabar para cargar la mejor marca de cada segmento
  /// vigilado (el "fantasma").
  Future<List<SegmentEffort>> getEfforts(int segmentId) =>
      database.getEffortsForSegment(segmentId);

  /// Borra un esfuerzo puntual del historial de un segmento.
  Future<void> deleteEffort(int effortId) =>
      database.deleteSegmentEffort(effortId);

  /// Borra todo el historial de esfuerzos de un segmento.
  Future<void> deleteAllEfforts(int segmentId) =>
      database.deleteAllEffortsForSegment(segmentId);

  /// Guarda un esfuerzo (una vez que se completó un segmento activo
  /// dentro de una actividad) -- lo usará `SegmentDetectionService`
  /// (Fase 5) al detectar que el ciclista pasó el punto final.
  Future<void> recordEffort(SegmentEffortsCompanion entry) =>
      database.insertSegmentEffort(entry);

  /// Qué segmentos se completaron DENTRO de una actividad puntual --
  /// para la sección "Segmentos en esta ruta" de
  /// `ActivityDetailScreen`. Cada esfuerzo de esa actividad se resuelve
  /// contra su segmento (nombre, distancia, etc.); si el segmento ya
  /// se borró mientras tanto, ese esfuerzo simplemente se omite -- no
  /// tiene nada que mostrar.
  Future<List<SegmentActivityEntry>> getSegmentsForActivity(
    int activityId,
  ) async {
    final efforts = await database.getEffortsForActivity(activityId);
    if (efforts.isEmpty) return const [];

    final entries = <SegmentActivityEntry>[];
    for (final effort in efforts) {
      final segment = await database.getSegmentById(effort.segmentId);
      if (segment != null) {
        entries.add(SegmentActivityEntry(segment: segment, effort: effort));
      }
    }
    return entries;
  }

  /// Recorta un segmento nuevo entre `startPointIndex` y
  /// `endPointIndex` (inclusive, índices sobre `activity.routePoints`
  /// -- YA aplanados por `ActivityAltitudeFlattener` al guardarse la
  /// actividad). La llama `SegmentCreationScreen` (Fase 3) cuando el
  /// usuario confirma la selección hecha arrastrando los marcadores
  /// A/B sobre el mapa.
  ///
  /// Lanza [SegmentCreationException] si la selección no sirve
  /// (índices inválidos, muy pocos puntos, o tramo más corto que
  /// [minSegmentDistanceMeters]) -- en la práctica, la UI ya debería
  /// haber bloqueado el botón "Guardar" antes de llegar aquí (ver
  /// `computeSegmentStats`/`SegmentStatsPreview.isTooShort`), así que
  /// esta excepción es más una red de seguridad que el camino
  /// esperado.
  Future<int> createSegmentFromActivity({
    required Activity activity,
    required int startPointIndex,
    required int endPointIndex,
    required String name,
  }) async {
    final points = activity.routePoints;

    if (startPointIndex < 0 ||
        endPointIndex >= points.length ||
        startPointIndex >= endPointIndex) {
      throw const SegmentCreationException(
        'La selección de puntos no es válida.',
      );
    }

    final slice = points.sublist(startPointIndex, endPointIndex + 1);
    if (slice.length < 3) {
      throw const SegmentCreationException(
        'El tramo es muy corto -- arrastra un poco más los marcadores.',
      );
    }

    // Perfil congelado re-basado a distancia 0 -- misma transformación
    // que usa la vista previa en vivo de `SegmentCreationScreen`, así
    // las stats coinciden exactamente (ver `segment_profile_builder.dart`).
    final profilePoints = profilePointsFromActivitySlice(slice);

    final stats = computeSegmentStats(profilePoints);
    if (stats.isTooShort) {
      throw SegmentCreationException(
        'El segmento debe medir al menos '
        '${minSegmentDistanceMeters.round()} metros.',
      );
    }

    return _insertSegment(
      name: name,
      profilePoints: profilePoints,
      stats: stats,
      source: SegmentSource.activity,
      sourceActivityId: activity.id,
    );
  }

  /// Crea un segmento a partir de un GPX ya parseado (ver
  /// `GpxSegmentImporter`). Lo usan tanto la importación de un archivo
  /// que subió el usuario como la descarga del catálogo remoto -- por
  /// eso recibe `source` y `remoteId` explícitos.
  ///
  /// A diferencia de `createSegmentFromActivity`, acá el perfil ya
  /// viene armado y validado por el importador, así que este método
  /// solo persiste.
  Future<int> createSegmentFromGpx({
    required String name,
    required List<SegmentProfilePoint> profilePoints,
    required SegmentStatsPreview stats,
    required double startBearingDegrees,
    SegmentSource source = SegmentSource.gpxImport,
    String? remoteId,
  }) {
    return _insertSegment(
      name: name,
      profilePoints: profilePoints,
      stats: stats,
      source: source,
      startBearingOverride: startBearingDegrees,
      remoteId: remoteId,
    );
  }

  Future<int> _insertSegment({
    required String name,
    required List<SegmentProfilePoint> profilePoints,
    required SegmentStatsPreview stats,
    required SegmentSource source,
    double? startBearingOverride,
    int? sourceActivityId,
    String? remoteId,
  }) {
    final startBearing =
        startBearingOverride ?? computeStartBearing(profilePoints);

    final companion = SegmentsCompanion.insert(
      name: name,
      startLat: profilePoints.first.latitude,
      startLng: profilePoints.first.longitude,
      endLat: profilePoints.last.latitude,
      endLng: profilePoints.last.longitude,
      startBearingDegrees: startBearing,
      distanceMeters: stats.distanceMeters,
      elevationGainMeters: stats.elevationGainMeters,
      avgSlopePercent: stats.avgSlopePercent,
      maxSlopePercent: stats.maxSlopePercent,
      profileJson: SegmentProfile.encode(profilePoints),
      createdAt: DateTime.now(),
      source: Value(source.wire),
      sourceActivityId: Value(sourceActivityId),
      remoteId: Value(remoteId),
    );

    return database.insertSegment(companion);
  }
}
