import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:core_database/core_database.dart';
import '../../elevation/elevation.dart';
import '../../recording/recording.dart';

/// Resumen de una re-corrida del aplanado de altimetría -- para
/// mostrarle al usuario en "Ajustar altimetría" qué tan buena quedó la
/// cobertura de fuentes.
class AltitudeReadjustResult {
  final double gainMeters;
  final double lossMeters;
  final int gpxPoints;
  final int hgtPoints;
  final int approxPoints;
  final int totalPoints;

  const AltitudeReadjustResult({
    required this.gainMeters,
    required this.lossMeters,
    required this.gpxPoints,
    required this.hgtPoints,
    required this.approxPoints,
    required this.totalPoints,
  });

  /// Fracción de puntos con una fuente confiable (GPX o HGT).
  double get reliableFraction => totalPoints == 0
      ? 0
      : (gpxPoints + hgtPoints) / totalPoints;
}

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
      avgPower: Value(summary.avgPower),
      maxPower: Value(summary.maxPower),
      avgCadence: Value(summary.avgCadence),
      maxCadence: Value(summary.maxCadence),
      notes: Value(notes),
      routePointsJson: Value(
        jsonEncode(summary.routePoints.map((r) => r.toJson()).toList()),
      ),
      photoPathsJson: Value(jsonEncode(persistedPhotoPaths)),
    );

    return database.insertActivity(companion);
  }

  /// Actualiza los datos editables de una actividad ya guardada (título,
  /// tipo, bicicleta, notas y fotos). No toca `routePointsJson` ni las
  /// estadísticas (distancia, duración, etc.) -- esas se calcularon al
  /// grabar y no cambian al editar.
  ///
  /// [photoPaths] es la lista final completa que debe quedar guardada
  /// (fotos que ya eran permanentes + fotos nuevas). [newTemporaryPhotoPaths]
  /// es el subconjunto de esa lista que todavía son rutas temporales del
  /// selector de imágenes -- esas son las que hay que copiar a
  /// almacenamiento permanente, igual que hace `saveActivity`.
  Future<void> updateActivity({
    required int id,
    required String title,
    required String activityType,
    required String bikeName,
    String? notes,
    required List<String> photoPaths,
    List<String> newTemporaryPhotoPaths = const [],
  }) async {
    final persistedNewPaths = await _persistPhotos(newTemporaryPhotoPaths);

    // Las rutas que ya eran permanentes (no estaban en la lista de
    // temporales) se dejan tal cual; las nuevas se reemplazan por su
    // ruta permanente ya copiada.
    final finalPhotoPaths = [
      ...photoPaths.where((path) => !newTemporaryPhotoPaths.contains(path)),
      ...persistedNewPaths,
    ];

    await (database.update(database.activities)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      ActivitiesCompanion(
        title: Value(title),
        activityType: Value(activityType),
        bikeName: Value(bikeName),
        notes: Value(notes),
        photoPathsJson: Value(jsonEncode(finalPhotoPaths)),
      ),
    );
  }

  /// Vuelve a correr el aplanado de altimetría sobre una actividad ya
  /// guardada, usando la cadena de prioridades actual (GPX > HGT >
  /// fusión). Útil cuando en la primera pasada faltaban teselas HGT o
  /// no habías importado el GPX del recorrido -- descargás/importás y
  /// tocás "Ajustar altimetría" hasta que quede bien.
  ///
  /// Trabaja sobre `rawAltitude` (la altitud fusionada en vivo, antes
  /// de aplanar) para no re-procesar un dato ya procesado. Actividades
  /// viejas sin `rawAltitude` caen a `altitude` -- menos ideal, pero
  /// igual mejora si ahora hay más cobertura de fuentes.
  Future<AltitudeReadjustResult> readjustAltitude({
    required int activityId,
    required ElevationResolver resolver,
  }) async {
    final activity = await database.getActivityById(activityId);
    if (activity == null) {
      throw StateError('La actividad ya no existe.');
    }
    final points = activity.routePoints;
    if (points.length < 2) {
      throw StateError('La actividad no tiene trazado para ajustar.');
    }

    await resolver.preload();

    final routePoints = <RoutePoint>[
      for (final pt in points)
        RoutePoint(
          latitude: pt.latitude,
          longitude: pt.longitude,
          altitude: pt.rawAltitude ?? pt.altitude,
          speedMetersPerSecond: 0,
          bearingDegrees: 0,
          accuracyMeters: 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        ),
    ];
    final cumulative = [
      for (final pt in points) pt.distanceFromStartMeters,
    ];

    final flattener = ActivityAltitudeFlattener(resolver);
    final result = flattener.flatten(
      points: routePoints,
      cumulativeDistanceMeters: cumulative,
    );

    final newPoints = <RoutePointSnapshot>[
      for (int i = 0; i < points.length; i++)
        points[i].copyWith(
          altitude: result.altitudes[i],
          slopePercent: result.slopePercents[i],
          isElevationApproximate: result.isApproximate[i],
        ),
    ];

    await (database.update(database.activities)
          ..where((a) => a.id.equals(activityId)))
        .write(
      ActivitiesCompanion(
        routePointsJson: Value(
          jsonEncode(newPoints.map((pt) => pt.toJson()).toList()),
        ),
        elevationGainMeters: Value(result.elevationGainMeters),
      ),
    );

    return AltitudeReadjustResult(
      gainMeters: result.elevationGainMeters,
      lossMeters: result.elevationLossMeters,
      gpxPoints: result.countFrom(ElevationSource.gpx),
      hgtPoints: result.countFrom(ElevationSource.hgt),
      approxPoints: result.approximatePointCount,
      totalPoints: points.length,
    );
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
