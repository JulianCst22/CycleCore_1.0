import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../domain/activity_summary.dart';

class ActivitiesRepository {
  final AppDatabase database;

  ActivitiesRepository(this.database);

  Stream<List<Activity>> watchActivities() => database.watchAllActivities();

  Future<void> deleteActivity(int id) => database.deleteActivity(id);

  /// Guarda la actividad: copia las fotos elegidas (rutas temporales de la
  /// galería) a una carpeta permanente dentro del almacenamiento de la
  /// app, y persiste todo en SQLite vía Drift.
  Future<int> saveActivity({
    required ActivitySummary summary,
    required String title,
    required String activityType,
    required String bikeName,
    String? notes,
    List<String> temporaryPhotoPaths = const [],
  }) async {
    final persistedPhotoPaths = await _persistPhotos(temporaryPhotoPaths);

    final companion = ActivitiesCompanion.insert(
      title: title,
      activityType: activityType,
      bikeName: bikeName,
      startedAt: summary.startedAt,
      endedAt: summary.endedAt,
      durationSeconds: summary.duration.inSeconds,
      distanceMeters: summary.distanceMeters,
      avgSpeedKmh: summary.avgSpeedKmh,
      maxSpeedKmh: summary.maxSpeedKmh,
      elevationGainMeters: summary.elevationGainMeters,
      avgHeartRate: Value(summary.avgHeartRate),
      maxHeartRate: Value(summary.maxHeartRate),
      notes: Value(notes),
      routePointsJson: Value(
        jsonEncode(summary.routePoints.map((r) => r.toJson()).toList()),
      ),
      photoPathsJson: Value(jsonEncode(persistedPhotoPaths)),
    );

    return database.insertActivity(companion);
  }

  /// Copia cada foto elegida a `<documentos_app>/activity_photos/`, para
  /// que la actividad no dependa de que la foto siga existiendo en la
  /// galería del usuario (si la borra ahí, no se pierde en la app).
  Future<List<String>> _persistPhotos(List<String> temporaryPaths) async {
    if (temporaryPaths.isEmpty) return [];

    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'activity_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final persisted = <String>[];
    for (final tempPath in temporaryPaths) {
      final ext = p.extension(tempPath);
      final newName =
          '${DateTime.now().microsecondsSinceEpoch}_${persisted.length}$ext';
      final newPath = p.join(photosDir.path, newName);
      await File(tempPath).copy(newPath);
      persisted.add(newPath);
    }
    return persisted;
  }
}
