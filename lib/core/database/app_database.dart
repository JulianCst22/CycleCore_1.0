import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Tabla de actividades grabadas (carreras/entrenamientos).
///
/// `routePointsJson` guarda el trazado completo (lat/lng) serializado,
/// para poder redibujar la ruta en el historial más adelante sin
/// necesidad de una tabla aparte todavía.
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

  TextColumn get notes => text().nullable()();
  TextColumn get routePointsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get photoPathsJson =>
      text().withDefault(const Constant('[]'))();
}

@DriftDatabase(tables: [Activities])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cyclecore.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
