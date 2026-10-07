import 'dart:convert';

import '../../../core/database/database.dart';
import '../domain/athlete.dart';
import '../domain/replay/ride_recording.dart';

/// Saca una salida guardada en el formato que el motor sabe reproducir.
///
/// Es el puente entre el teléfono y las herramientas de la tesis: se
/// exporta el archivo, se pasa al computador y
/// `dart run tool/thesis.dart --grabacion <archivo>` saca la tabla de
/// avisos y las figuras de esa subida.
class RideExportRepository {
  final AppDatabase database;

  RideExportRepository(this.database);

  /// Las salidas que se pueden reproducir, de la más reciente a la más
  /// vieja: cualquiera con trazado, con o sin potenciómetro. Sin él el
  /// motor estima la potencia con la velocidad y la pendiente de cada
  /// punto, igual que en vivo, así que la salida sin potenciómetro
  /// también sirve para la tesis.
  Future<List<Activity>> recentRides({int limit = 15}) async {
    final activities = await database.watchAllActivities().first;
    return [
      for (final activity in activities)
        if (activity.routePointsJson.length > 2) activity,
    ].take(limit).toList();
  }

  /// Arma la grabación de [activityId] con el ciclista [athlete].
  ///
  /// Los puntos del trazado ya vienen con las llaves que lee
  /// [RideRecording]; lo único que hay que poner es quién pedaleaba.
  Future<RideRecording?> recordingOf(
    int activityId, {
    required CoachAthlete athlete,
  }) async {
    final activity = await database.getActivityById(activityId);
    if (activity == null) return null;
    final points = jsonDecode(activity.routePointsJson);
    if (points is! List || points.length < 2) return null;

    return RideRecording.fromJson({
      'name': activity.title,
      'athlete': {
        'cp': athlete.power.cp.toDouble(),
        'wPrime': athlete.power.wPrime.toDouble(),
        'seCp': athlete.power.seCp,
        'seWPrime': athlete.power.seWPrime,
        'covariance': athlete.power.covariance,
        'maxHeartRate': athlete.maxHeartRate.toDouble(),
        'restingHeartRate': athlete.restingHeartRate.toDouble(),
        'preferredCadence': athlete.preferredCadence.toDouble(),
      },
      'terrainSource': 'ownActivity',
      'points': points,
    });
  }

  /// La misma grabación como texto JSON, lista para guardar o compartir.
  Future<String?> exportJson(
    int activityId, {
    required CoachAthlete athlete,
  }) async {
    final recording = await recordingOf(activityId, athlete: athlete);
    if (recording == null) return null;
    return const JsonEncoder.withIndent('  ').convert(recording.toJson());
  }

  /// Nombre de archivo sugerido: la fecha de la salida.
  static String fileNameOf(Activity activity) {
    final date = activity.startedAt;
    String two(int value) => value.toString().padLeft(2, '0');
    return 'cyclecore_${date.year}${two(date.month)}${two(date.day)}'
        '_${two(date.hour)}${two(date.minute)}.json';
  }
}
