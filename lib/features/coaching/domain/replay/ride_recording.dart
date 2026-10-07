import 'dart:convert';
import 'dart:math' as math;

import '../../../../core/geo/geo.dart';
import '../../../../core/physiology/physiology.dart';
import '../athlete.dart';
import '../extraction/effort_tracker.dart';
import '../extraction/sensor_credibility.dart';
import '../extraction/terrain_reader.dart';
import '../variables/labels.dart';
import 'ride_replay.dart' show replayRide;

/// Una subida grabada, con todo lo que el motor necesita para volver a
/// vivirla: el ciclista, el perfil del terreno, el récord y las lecturas
/// segundo a segundo.
///
/// Es la entrada de [replayRide] y de las herramientas de la tesis. El
/// formato es el JSON que ya guarda la app, así que una actividad
/// exportada del teléfono se reproduce tal cual: los puntos traen
/// `secondsFromStart`, `distanceFromStartMeters`, `powerWatts`,
/// `heartRateBpm` y `cadenceRpm`, y de ahí sale también el perfil si el
/// archivo no trae uno aparte.
final class RideRecording {
  final String name;
  final CoachAthlete athlete;
  final SegmentProfile profile;
  final ReferenceEffort? reference;

  /// Lecturas a 1 Hz de tiempo en movimiento, con los segundos ya
  /// seguidos (las pausas no cuentan).
  final List<RideTick> ticks;

  final TerrainSource terrainSource;
  final Goal goal;

  RideRecording({
    required this.name,
    required this.athlete,
    required this.profile,
    required List<RideTick> ticks,
    this.reference,
    this.terrainSource = TerrainSource.ownActivity,
    this.goal = Goal.pr,
  }) : ticks = List.unmodifiable(ticks);

  int get seconds => ticks.length;

  double get meters => ticks.isEmpty ? 0 : ticks.last.alongMeters;

  /// Si el archivo traía potencia en algún momento: sin ella el coach no
  /// tiene de qué hablar.
  bool get hasPower => ticks.any((t) => t.power != null);

  bool get hasHeartRate => ticks.any((t) => t.heartRate != null);

  /// Estado de las fuentes en el segundo [index]. Se asume que lo que
  /// está en el archivo llegó en ese instante: lo que falta es porque el
  /// sensor no estaba.
  SensorStatus statusAt(int index, {required double secondsSinceChange}) {
    final tick = ticks[index];
    return SensorStatus(
      powerAgeSeconds: tick.power == null ? null : 0,
      heartRateAgeSeconds: tick.heartRate == null ? null : 0,
      cadenceAgeSeconds: tick.cadence == null ? null : 0,
      secondsSinceGradientChange: secondsSinceChange,
      currentGradient: profile.slopePercentAtDistance(tick.alongMeters) ?? 0,
      terrainSource: terrainSource,
      hasReference: reference != null,
    );
  }

  static RideRecording parse(String json) =>
      RideRecording.fromJson(jsonDecode(json) as Map<String, dynamic>);

  /// Lee el formato de reproducción. Solo `athlete` y los puntos son
  /// obligatorios; el resto tiene un valor razonable por defecto.
  factory RideRecording.fromJson(Map<String, dynamic> json) {
    final points = _listOf(json, const ['points', 'puntos', 'ticks']);
    if (points.isEmpty) {
      throw const FormatException('La grabación no trae puntos.');
    }
    final athlete = json['athlete'] ?? json['atleta'];
    if (athlete is! Map<String, dynamic>) {
      throw const FormatException('Falta el ciclista («athlete»).');
    }
    final ticks = _ticksOf(points);
    final profileJson = json['profile'] ?? json['perfil'];
    return RideRecording(
      name: (json['name'] ?? json['nombre'] ?? 'grabación') as String,
      athlete: _athleteOf(athlete),
      profile: profileJson is List
          ? _profileOf(profileJson)
          : _profileFromPoints(points, ticks),
      ticks: ticks,
      reference: _referenceOf(json['reference'] ?? json['referencia']),
      terrainSource: _sourceOf(json['terrainSource'] as String?),
      goal: Goal.values.firstWhere(
        (g) => g.name == json['goal'],
        orElse: () => Goal.pr,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
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
    'terrainSource': terrainSource.name,
    'goal': goal.name,
    'profile': [
      for (final p in profile.points)
        {
          'dist': p.distanceFromStartMeters,
          'alt': p.altitude,
          'slope': p.slopePercent,
          'lat': p.latitude,
          'lng': p.longitude,
        },
    ],
    if (reference != null)
      'reference': [
        for (final s in reference!.splits)
          {'meters': s.meters, 'seconds': s.seconds},
      ],
    'points': [
      for (final t in ticks)
        {
          'second': t.second,
          'alongMeters': t.alongMeters,
          if (t.power != null) 'power': t.power,
          if (t.heartRate != null) 'heartRate': t.heartRate,
          if (t.cadence != null) 'cadence': t.cadence,
          if (t.speed != null) 'speed': t.speed,
        },
    ],
  };

  static List<dynamic> _listOf(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) return value;
    }
    return const [];
  }

  static CoachAthlete _athleteOf(Map<String, dynamic> json) {
    double? number(String a, [String? b]) {
      final value = json[a] ?? (b == null ? null : json[b]);
      return value is num ? value.toDouble() : null;
    }

    final cp = number('cp', 'potenciaCritica');
    if (cp == null || cp <= 0) {
      throw const FormatException('El ciclista necesita su «cp» en vatios.');
    }
    return CoachAthlete(
      power: CriticalPowerModel.manual(
        cp: Watts(cp),
        wPrime: Joules(number('wPrime') ?? 20000),
        seCp: number('seCp'),
        seWPrime: number('seWPrime'),
        covariance: number('covariance') ?? 0,
      ),
      maxHeartRate: Bpm(number('maxHeartRate', 'fcMaxima') ?? 190),
      restingHeartRate: Bpm(number('restingHeartRate', 'fcReposo') ?? 60),
      preferredCadence: Rpm(number('preferredCadence') ?? 85),
    );
  }

  static SegmentProfile _profileOf(List<dynamic> points) => SegmentProfile([
    for (final e in points.cast<Map<String, dynamic>>())
      SegmentProfilePoint(
        distanceFromStartMeters: _num(e, const [
          'dist',
          'distance',
          'distanceFromStartMeters',
        ]),
        altitude: _num(e, const ['alt', 'altitude']),
        slopePercent: _num(e, const ['slope', 'slopePercent']),
        latitude: _num(e, const ['lat', 'latitude']),
        longitude: _num(e, const ['lng', 'lon', 'longitude']),
      ),
  ]);

  /// Perfil sacado de la propia grabación: se reproduce la salida como
  /// si toda ella fuera el segmento. La pendiente se toma del archivo si
  /// viene; si no, del desnivel entre puntos.
  static SegmentProfile _profileFromPoints(
    List<dynamic> points,
    List<RideTick> ticks,
  ) {
    final raw = points.cast<Map<String, dynamic>>();
    final profile = <SegmentProfilePoint>[];
    var previousDistance = double.negativeInfinity;
    for (var i = 0; i < raw.length; i++) {
      final e = raw[i];
      final distance = _num(e, const [
        'distanceFromStartMeters',
        'alongMeters',
        'dist',
        'distance',
      ]);
      if (distance <= previousDistance) continue; // sin avance no hay perfil
      final altitude = _num(e, const ['altitude', 'alt']);
      var slope = _numOrNull(e, const ['slopePercent', 'slope']);
      if (slope == null && profile.isNotEmpty) {
        final previous = profile.last;
        final run = distance - previous.distanceFromStartMeters;
        slope = run > 0 ? 100 * (altitude - previous.altitude) / run : 0;
      }
      profile.add(
        SegmentProfilePoint(
          distanceFromStartMeters: distance,
          altitude: altitude,
          slopePercent: slope ?? 0,
          latitude: _num(e, const ['latitude', 'lat']),
          longitude: _num(e, const ['longitude', 'lng', 'lon']),
        ),
      );
      previousDistance = distance;
    }
    if (profile.length >= 2) return SegmentProfile(profile);
    // Sin distancias utilizables: un llano del largo que recorrió.
    return SegmentProfile([
      const SegmentProfilePoint(
        distanceFromStartMeters: 0,
        altitude: 0,
        slopePercent: 0,
        latitude: 0,
        longitude: 0,
      ),
      SegmentProfilePoint(
        distanceFromStartMeters: math.max(1, ticks.last.alongMeters),
        altitude: 0,
        slopePercent: 0,
        latitude: 0,
        longitude: 0,
      ),
    ]);
  }

  static ReferenceEffort? _referenceOf(Object? value) {
    if (value is! List || value.length < 2) return null;
    return ReferenceEffort([
      for (final e in value.cast<Map<String, dynamic>>())
        (
          meters: _num(e, const ['meters', 'metros', 'distanceMeters']),
          seconds: _num(e, const ['seconds', 'segundos', 'secondsFromStart']),
        ),
    ]);
  }

  static TerrainSource _sourceOf(String? name) =>
      TerrainSource.values.firstWhere(
        (s) => s.name == name,
        orElse: () => TerrainSource.ownActivity,
      );

  /// Pasa los puntos del archivo a un tren de segundos seguidos.
  ///
  /// El reloj de una actividad incluye las pausas (durante una pausa no
  /// se graban puntos), así que un salto largo entre dos puntos es una
  /// pausa y no se rellena: el motor mide tiempo en movimiento. Los
  /// huecos cortos sí se rellenan con la última lectura, que es lo mismo
  /// que hace el registro en vivo.
  static List<RideTick> _ticksOf(
    List<dynamic> points, {
    int pauseGapSeconds = 10,
  }) {
    final raw = [
      for (final e in points.cast<Map<String, dynamic>>())
        (
          second: _numOrNull(e, const [
            'second',
            'secondsFromStart',
            'segundo',
          ]),
          meters: _num(e, const [
            'alongMeters',
            'distanceFromStartMeters',
            'dist',
            'distance',
          ]),
          power: _numOrNull(e, const ['power', 'powerWatts']),
          heartRate: _numOrNull(e, const ['heartRate', 'heartRateBpm']),
          cadence: _numOrNull(e, const ['cadence', 'cadenceRpm']),
          speed: _speedOf(e),
        ),
    ]..sort((a, b) => (a.second ?? 0).compareTo(b.second ?? 0));

    final ticks = <RideTick>[];
    double? previousClock;
    for (final point in raw) {
      final clock = point.second ?? (previousClock ?? -1) + 1;
      // Hueco corto: se repite la última lectura hasta llegar al punto.
      final gap = previousClock == null ? 1 : (clock - previousClock).round();
      if (previousClock != null && gap > 1 && gap <= pauseGapSeconds) {
        final last = ticks.last;
        for (var i = 1; i < gap; i++) {
          ticks.add(
            RideTick(
              second: ticks.length,
              alongMeters:
                  last.alongMeters +
                  (point.meters - last.alongMeters) * i / gap,
              power: last.power,
              heartRate: last.heartRate,
              cadence: last.cadence,
              speed: last.speed,
            ),
          );
        }
      }
      ticks.add(
        RideTick(
          second: ticks.length,
          alongMeters: point.meters,
          power: point.power,
          heartRate: point.heartRate,
          cadence: point.cadence,
          speed: point.speed,
        ),
      );
      previousClock = clock;
    }
    return ticks;
  }

  /// Velocidad en m/s: el archivo puede traerla en km/h (como la guarda
  /// la app) o ya en metros por segundo.
  static double? _speedOf(Map<String, dynamic> json) {
    final kmh = _numOrNull(json, const ['speedKmh', 'velocidadKmh']);
    if (kmh != null) return kmh / 3.6;
    return _numOrNull(json, const ['speed', 'speedMetersPerSecond']);
  }

  static double _num(Map<String, dynamic> json, List<String> keys) =>
      _numOrNull(json, keys) ?? 0;

  static double? _numOrNull(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
    }
    return null;
  }
}
