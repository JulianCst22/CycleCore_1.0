import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Tabla de actividades grabadas (carreras/entrenamientos).
///
/// `routePointsJson` guarda el trazado completo (lat/lng/altitud/
/// pendiente/velocidad/FC/potencia/cadencia por punto) serializado.
/// `photoPathsJson` guarda rutas absolutas a los archivos ya copiados al
/// almacenamiento permanente de la app (ver ActivitiesRepository).

class Activities extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();

  /// 'race' o 'training'.
  TextColumn get activityType => text()();

  TextColumn get bikeName => text()();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get durationSeconds => integer()();

  RealColumn get distanceMeters => real()();
  RealColumn get avgSpeedKmh => real()();
  RealColumn get maxSpeedKmh => real()();
  RealColumn get elevationGainMeters => real()();

  IntColumn get avgHeartRate => integer().nullable()();
  IntColumn get maxHeartRate => integer().nullable()();

  /// Null si no hubo medidor de potencia conectado durante la grabación.
  IntColumn get avgPower => integer().nullable()();
  IntColumn get maxPower => integer().nullable()();

  /// Cadencia redondeada a RPM entero para el resumen -- el detalle por
  /// punto (RoutePointSnapshot) sí guarda el valor sin redondear.
  IntColumn get avgCadence => integer().nullable()();
  IntColumn get maxCadence => integer().nullable()();

  TextColumn get notes => text().nullable()();
  TextColumn get routePointsJson => text().withDefault(const Constant('[]'))();
  TextColumn get photoPathsJson => text().withDefault(const Constant('[]'))();
}

/// Catálogo liviano de qué teselas de elevación (`.hgt`) ya se
/// descargaron a este dispositivo. El contenido binario de la tesela
/// vive en el sistema de archivos (`elevation_tiles/`), NO aquí -- esta
/// tabla solo guarda los metadatos, igual que decidimos para las fotos
/// de actividades.
class DownloadedElevationTiles extends Table {
  /// Nombre estándar de la tesela, ej. "N04W075.hgt".
  TextColumn get tileName => text()();
  TextColumn get filePath => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get downloadedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {tileName};
}

/// Catálogo liviano de qué regiones del grafo vial (`.roadgraph`) ya
/// se descargaron a este dispositivo -- mismo espíritu que
/// `DownloadedElevationTiles`: el contenido binario vive en el
/// sistema de archivos (`road_regions/`), esta tabla solo guarda los
/// metadatos. Ver `RoadRegionRepository` y `RoadRegionId`.
class DownloadedRoadRegions extends Table {
  /// Id de la región en el catálogo de `RoadRegionId`, ej.
  /// "norte_de_santander".
  TextColumn get regionId => text()();
  TextColumn get filePath => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get downloadedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {regionId};
}

/// Segmentos creados por el usuario arrastrando dos puntos sobre la
/// polilínea de una de sus propias actividades YA APLANADA contra HGT
/// (ver `ActivityAltitudeFlattener`). Nacen con la mayor confiabilidad
/// geográfica posible porque parten de datos ya limpios, no de un GPX
/// externo.
///
/// `profileJson` congela el perfil completo del tramo (distancia
/// acumulada, lat/lng, altitud y pendiente por punto). Es el que se
/// consulta por "lookup" mientras el segmento está activo en vivo, en
/// vez de recalcular pendiente con sensores -- ver
/// `SegmentDetectionService` (Fase 5).
class Segments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// De dónde nació el segmento:
  ///  - `activity`      : recortado de una actividad propia ya aplanada
  ///                      contra HGT (`SegmentCreationScreen`).
  ///  - `gpxImport`     : importado de un archivo GPX que subió el
  ///                      usuario (altitud barométrica de un
  ///                      ciclocomputador -- prioridad 1 sobre HGT).
  ///  - `nativeCatalog` : descargado del catálogo remoto de segmentos
  ///                      "nativos" de la app (mismo patrón que las
  ///                      teselas de elevación y el grafo vial).
  TextColumn get source => text().withDefault(const Constant('activity'))();

  /// Id del segmento en el catálogo remoto -- solo para `nativeCatalog`.
  /// Sirve para no volver a importar el mismo segmento oficial si el
  /// usuario toca "descargar" dos veces. `null` para segmentos locales.
  TextColumn get remoteId => text().nullable()();

  /// Reservado para cuando exista backend real (ver notas del
  /// proyecto: por ahora todo es local, así que esto siempre queda en
  /// `false`). El campo ya existe para no requerir otra migración
  /// cuando llegue la sincronización en la nube.
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();

  /// Si `SegmentDetectionService` debe vigilar este segmento mientras
  /// se pedalea. El usuario lo prende/apaga desde el menú de
  /// segmentos (Fase 4) -- si está activo, arranca solo al pasar por
  /// su inicio con el rumbo correcto; si no, se ignora por completo.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  RealColumn get startLat => real()();
  RealColumn get startLng => real()();
  RealColumn get endLat => real()();
  RealColumn get endLng => real()();

  /// Rumbo de referencia (grados, 0-360) en el arranque del segmento,
  /// calculado sobre los primeros metros del tramo al crearlo. Se usa
  /// para exigir que el ciclista vaya en el sentido correcto y no
  /// disparar el segmento si pasa en contravía o por una calle
  /// paralela.
  RealColumn get startBearingDegrees => real()();

  RealColumn get distanceMeters => real()();
  RealColumn get elevationGainMeters => real()();
  RealColumn get avgSlopePercent => real()();
  RealColumn get maxSlopePercent => real()();

  /// Perfil congelado del tramo, serializado en JSON: lista de
  /// `{dist, lat, lng, alt, slope}` en orden desde el inicio hasta el
  /// fin del segmento.
  TextColumn get profileJson => text()();

  DateTimeColumn get createdAt => dateTime()();

  /// De qué actividad salió este segmento -- trazabilidad, y permite
  /// regenerar el perfil más adelante si cambia el método de
  /// aplanado sin perder el segmento.
  IntColumn get sourceActivityId => integer().nullable()();
}

/// Un "esfuerzo": cada vez que el usuario completa un segmento activo
/// dentro de una actividad. Permite comparar contra la mejor marca
/// propia (equivalente a los "segment efforts" de Strava) y alimentar
/// después el motor difuso de frases de voz ("vas mejor que tu mejor
/// marca", etc.).
class SegmentEfforts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get segmentId => integer()();
  IntColumn get activityId => integer()();
  IntColumn get durationSeconds => integer()();
  RealColumn get avgSpeedKmh => real()();
  IntColumn get avgHeartRate => integer().nullable()();
  IntColumn get avgPower => integer().nullable()();
  DateTimeColumn get completedAt => dateTime()();

  /// Curva tiempo-vs-distancia REAL de este esfuerzo, serializada como
  /// JSON: `[{d: <metros desde el inicio>, t: <segundos>}]`. Es lo que
  /// alimenta el "fantasma" de la mejor marca en la pantalla de
  /// segmento en vivo (Fase D) -- el fantasma se mueve a la velocidad
  /// real que llevaba el ciclista en cada punto, no a un ritmo
  /// promedio constante. `'[]'` para esfuerzos grabados antes de la
  /// Fase C.
  TextColumn get splitsJson => text().withDefault(const Constant('[]'))();
}

/// Lugares que el usuario guardó para navegar rápido (Casa, un alto que
/// hace seguido, un punto de encuentro). Aparecen primero en el buscador
/// de "Navegar" y con estrella sobre el mapa. Ver `SavedPlacesRepository`.
class SavedPlaces extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  /// 'home' | 'peak' | 'generic' -- decide el ícono. 'peak' se sugiere
  /// solo cuando el nombre parece un alto (ver `climb_detection.dart`).
  TextColumn get kind => text().withDefault(const Constant('generic'))();

  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(
  tables: [
    Activities,
    DownloadedElevationTiles,
    Segments,
    SegmentEfforts,
    DownloadedRoadRegions,
    SavedPlaces,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Quien venía de la versión 1 (antes de las teselas de
      // elevación) solo necesita la tabla nueva; Activities no cambió.
      if (from < 2) {
        await m.createTable(downloadedElevationTiles);
      }
      // Quien venía de antes del módulo de potencia/cadencia (v3)
      // necesita estas 4 columnas nuevas, todas nullable -- las
      // actividades ya guardadas simplemente quedan con estos campos
      // en null (equivalente a "sin sensor conectado ese día").
      if (from < 3) {
        await m.addColumn(activities, activities.avgPower);
        await m.addColumn(activities, activities.maxPower);
        await m.addColumn(activities, activities.avgCadence);
        await m.addColumn(activities, activities.maxCadence);
      }
      // Módulo de segmentos (Fase 1): quien venía de antes de v4
      // simplemente no tenía estas dos tablas -- se crean vacías,
      // no hay datos previos que migrar.
      if (from < 4) {
        await m.createTable(segments);
        await m.createTable(segmentEfforts);
      }
      // Módulo de navegación (Fase 1): igual que segmentos, tabla
      // nueva vacía -- nadie tenía regiones descargadas antes de
      // que existiera el concepto.
      if (from < 5) {
        await m.createTable(downloadedRoadRegions);
      }
      // Segmentos en vivo (Fases B/C): origen del segmento
      // (actividad / GPX importado / catálogo remoto), id remoto
      // para dedup del catálogo, y la curva tiempo-distancia del
      // esfuerzo para el fantasma. Todas con default, así las filas
      // ya existentes quedan como `source='activity'`,
      // `remoteId=null`, `splitsJson='[]'`.
      if (from < 6) {
        await m.addColumn(segments, segments.source);
        await m.addColumn(segments, segments.remoteId);
        await m.addColumn(segmentEfforts, segmentEfforts.splitsJson);
      }
      // Ubicaciones guardadas para navegar (Casa, altos frecuentes...).
      // Tabla nueva vacía -- nadie tenía lugares guardados antes.
      if (from < 7) {
        await m.createTable(savedPlaces);
      }
    },
  );

  // ---------------------------------------------------------------
  // Ubicaciones guardadas
  // ---------------------------------------------------------------

  Stream<List<SavedPlace>> watchSavedPlaces() {
    return (select(
      savedPlaces,
    )..orderBy([(p) => OrderingTerm.asc(p.name)])).watch();
  }

  Future<int> insertSavedPlace(SavedPlacesCompanion entry) {
    return into(savedPlaces).insert(entry);
  }

  Future<void> updateSavedPlace(SavedPlacesCompanion entry) {
    return update(savedPlaces).replace(entry);
  }

  Future<void> deleteSavedPlace(int id) {
    return (delete(savedPlaces)..where((p) => p.id.equals(id))).go();
  }

  // ---------------------------------------------------------------
  // Actividades
  // ---------------------------------------------------------------

  /// Stream reactivo: cualquier pantalla que lo escuche (ej. el futuro
  /// Home con el historial) se actualiza sola cuando se guarda o borra
  /// una actividad, sin necesidad de refrescar manualmente.
  Stream<List<Activity>> watchAllActivities() {
    return (select(
      activities,
    )..orderBy([(a) => OrderingTerm.desc(a.startedAt)])).watch();
  }

  Future<Activity?> getActivityById(int id) {
    return (select(
      activities,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertActivity(ActivitiesCompanion entry) {
    return into(activities).insert(entry);
  }

  Future<void> deleteActivity(int id) {
    return (delete(activities)..where((a) => a.id.equals(id))).go();
  }

  // ---------------------------------------------------------------
  // Catálogo de teselas de elevación
  // ---------------------------------------------------------------

  Stream<List<DownloadedElevationTile>> watchDownloadedTiles() {
    return select(downloadedElevationTiles).watch();
  }

  Future<List<DownloadedElevationTile>> getAllDownloadedTiles() {
    return select(downloadedElevationTiles).get();
  }

  Future<DownloadedElevationTile?> getTile(String tileName) {
    return (select(
      downloadedElevationTiles,
    )..where((t) => t.tileName.equals(tileName))).getSingleOrNull();
  }

  Future<void> upsertTile(DownloadedElevationTilesCompanion entry) {
    return into(downloadedElevationTiles).insertOnConflictUpdate(entry);
  }

  Future<void> deleteTile(String tileName) {
    return (delete(
      downloadedElevationTiles,
    )..where((t) => t.tileName.equals(tileName))).go();
  }

  // ---------------------------------------------------------------
  // Catálogo de regiones del grafo vial (Navegación)
  // ---------------------------------------------------------------
  //
  // Mismo patrón que el catálogo de teselas de elevación de arriba --
  // esto es lo que consulta `RoadRegionRepository`.

  Stream<List<DownloadedRoadRegion>> watchDownloadedRoadRegions() {
    return select(downloadedRoadRegions).watch();
  }

  Future<List<DownloadedRoadRegion>> getAllDownloadedRoadRegions() {
    return select(downloadedRoadRegions).get();
  }

  Future<DownloadedRoadRegion?> getRoadRegion(String regionId) {
    return (select(
      downloadedRoadRegions,
    )..where((r) => r.regionId.equals(regionId))).getSingleOrNull();
  }

  Future<void> upsertRoadRegion(DownloadedRoadRegionsCompanion entry) {
    return into(downloadedRoadRegions).insertOnConflictUpdate(entry);
  }

  Future<void> deleteRoadRegion(String regionId) {
    return (delete(
      downloadedRoadRegions,
    )..where((r) => r.regionId.equals(regionId))).go();
  }

  // ---------------------------------------------------------------
  // Segmentos
  // ---------------------------------------------------------------
  //
  // CRUD mínimo necesario para que la Fase 1 quede completa y
  // probable por sí sola (se puede insertar/leer un segmento antes de
  // que exista cualquier pantalla). La Fase 2 construye el
  // `SegmentsRepository` de dominio sobre estos métodos.

  /// Stream reactivo de todos los segmentos del usuario -- lo usará el
  /// menú de segmentos (Fase 4) para la lista con el toggle de
  /// activo/inactivo.
  Stream<List<Segment>> watchAllSegments() {
    return (select(
      segments,
    )..orderBy([(s) => OrderingTerm.asc(s.name)])).watch();
  }

  /// Solo los segmentos activos -- es la lista que consulta
  /// `SegmentDetectionService` en cada punto GPS nuevo mientras NO se
  /// está dentro de un segmento, así que conviene tenerla ya filtrada
  /// en la base de datos y no traer todos para filtrar en Dart.
  Future<List<Segment>> getActiveSegments() {
    return (select(segments)..where((s) => s.isActive.equals(true))).get();
  }

  /// Segmentos que nacieron de un GPX (importado o del catálogo) --
  /// sus perfiles son la fuente de elevación de PRIORIDAD 1 para el
  /// aplanado de actividades (ver `GpxTrackRepository` /
  /// `ElevationResolver`). Un segmento recortado de una actividad
  /// (`source = 'activity'`) NO cuenta: su altitud ya salió de HGT, no
  /// aportaría nada nuevo como fuente.
  Future<List<Segment>> getGpxOriginSegments() {
    return (select(
      segments,
    )..where((s) => s.source.equals('activity').not())).get();
  }

  Future<Segment?> getSegmentById(int id) {
    return (select(segments)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Segmento descargado del catálogo remoto por su id remoto -- para
  /// que `SegmentCatalogRepository` no re-importe el mismo segmento
  /// oficial si el usuario toca "descargar" dos veces.
  Future<Segment?> getSegmentByRemoteId(String remoteId) {
    return (select(
      segments,
    )..where((s) => s.remoteId.equals(remoteId))).getSingleOrNull();
  }

  Future<int> insertSegment(SegmentsCompanion entry) {
    return into(segments).insert(entry);
  }

  /// Prende/apaga la vigilancia de un segmento -- lo que dispara el
  /// toggle del menú de segmentos.
  Future<void> setSegmentActive(int id, bool isActive) {
    return (update(segments)..where((s) => s.id.equals(id))).write(
      SegmentsCompanion(isActive: Value(isActive)),
    );
  }

  Future<void> renameSegment(int id, String name) {
    return (update(segments)..where((s) => s.id.equals(id))).write(
      SegmentsCompanion(name: Value(name)),
    );
  }

  Future<void> deleteSegment(int id) {
    return (delete(segments)..where((s) => s.id.equals(id))).go();
  }

  // ---------------------------------------------------------------
  // Esfuerzos sobre segmentos
  // ---------------------------------------------------------------

  Future<int> insertSegmentEffort(SegmentEffortsCompanion entry) {
    return into(segmentEfforts).insert(entry);
  }

  /// Borra un esfuerzo puntual -- para poder limpiar tiempos sueltos
  /// desde el detalle del segmento (útil sobre todo con tiempos de
  /// prueba incoherentes).
  Future<void> deleteSegmentEffort(int id) {
    return (delete(segmentEfforts)..where((e) => e.id.equals(id))).go();
  }

  /// Borra TODOS los esfuerzos de un segmento -- "empezar de cero" el
  /// historial de ese segmento.
  Future<void> deleteAllEffortsForSegment(int segmentId) {
    return (delete(
      segmentEfforts,
    )..where((e) => e.segmentId.equals(segmentId))).go();
  }

  /// Todos los esfuerzos de un segmento, del más rápido al más lento --
  /// pensado para poder sacar la mejor marca directamente con
  /// `.first` sin ordenar de nuevo en Dart.
  Future<List<SegmentEffort>> getEffortsForSegment(int segmentId) {
    return (select(segmentEfforts)
          ..where((e) => e.segmentId.equals(segmentId))
          ..orderBy([(e) => OrderingTerm.asc(e.durationSeconds)]))
        .get();
  }

  Stream<List<SegmentEffort>> watchEffortsForSegment(int segmentId) {
    return (select(segmentEfforts)
          ..where((e) => e.segmentId.equals(segmentId))
          ..orderBy([(e) => OrderingTerm.asc(e.durationSeconds)]))
        .watch();
  }

  /// Todos los esfuerzos de todos los segmentos, del más reciente al
  /// más antiguo -- alimenta el resumen y el feed de "esfuerzos
  /// recientes" del menú de segmentos.
  Stream<List<SegmentEffort>> watchAllEfforts() {
    return (select(
      segmentEfforts,
    )..orderBy([(e) => OrderingTerm.desc(e.completedAt)])).watch();
  }

  /// Todos los esfuerzos registrados dentro de UNA actividad puntual --
  /// a diferencia de `getEffortsForSegment`/`watchEffortsForSegment`
  /// (que miran "todos los intentos de este segmento, sin importar en
  /// qué actividad"), esto es "qué segmentos se completaron DURANTE
  /// esta actividad". Lo usa `ActivityDetailScreen` para la sección
  /// "Segmentos en esta ruta".
  Future<List<SegmentEffort>> getEffortsForActivity(int activityId) {
    return (select(
      segmentEfforts,
    )..where((e) => e.activityId.equals(activityId))).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cyclecore.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
