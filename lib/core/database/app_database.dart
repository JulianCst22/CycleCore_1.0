import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Tabla de actividades grabadas (carreras/entrenamientos).
///
/// `routePointsJson` guarda el trazado completo (lat/lng/altitud/
/// pendiente/velocidad/FC por punto) serializado. `photoPathsJson` guarda
/// rutas absolutas a los archivos ya copiados al almacenamiento
/// permanente de la app (ver ActivitiesRepository).
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

  TextColumn get notes => text().nullable()();
  TextColumn get routePointsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get photoPathsJson =>
      text().withDefault(const Constant('[]'))();
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

@DriftDatabase(tables: [Activities, DownloadedElevationTiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
        },
      );

  // ---------------------------------------------------------------
  // Actividades
  // ---------------------------------------------------------------

  /// Stream reactivo: cualquier pantalla que lo escuche (ej. el futuro
  /// Home con el historial) se actualiza sola cuando se guarda o borra
  /// una actividad, sin necesidad de refrescar manualmente.
  Stream<List<Activity>> watchAllActivities() {
    return (select(activities)
          ..orderBy([(a) => OrderingTerm.desc(a.startedAt)]))
        .watch();
  }

  Future<Activity?> getActivityById(int id) {
    return (select(activities)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
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
    return (select(downloadedElevationTiles)
          ..where((t) => t.tileName.equals(tileName)))
        .getSingleOrNull();
  }

  Future<void> upsertTile(DownloadedElevationTilesCompanion entry) {
    return into(
      downloadedElevationTiles,
    ).insertOnConflictUpdate(entry);
  }

  Future<void> deleteTile(String tileName) {
    return (delete(
      downloadedElevationTiles,
    )..where((t) => t.tileName.equals(tileName))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cyclecore.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
