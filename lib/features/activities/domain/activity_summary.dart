/// Snapshot de una actividad recién grabada en el mapa, antes de que el
/// usuario le ponga título, tipo y bicicleta y decida guardarla.
///
/// Esto NO es el modelo persistido (ese es `Activity`, generado por Drift
/// a partir de la tabla `Activities`). Este objeto es solo el puente
/// entre "lo que grabó el GPS/sensores" y la pantalla de guardado.
class ActivitySummary {
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final double distanceMeters;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final double elevationGainMeters;

  /// Null si no hubo sensor de FC conectado durante la grabación.
  final int? avgHeartRate;
  final int? maxHeartRate;

  /// Null si no hubo medidor de potencia conectado durante la grabación.
  final int? avgPower;
  final int? maxPower;

  /// Null si no hubo sensor de cadencia (propio o vía medidor de
  /// potencia) conectado durante la grabación. Redondeados a RPM entero
  /// para el resumen -- el detalle por punto sí guarda el valor exacto.
  final int? avgCadence;
  final int? maxCadence;

  final List<RoutePointSnapshot> routePoints;

  const ActivitySummary({
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.distanceMeters,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.elevationGainMeters,
    required this.routePoints,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgPower,
    this.maxPower,
    this.avgCadence,
    this.maxCadence,
  });
}

/// Punto de ruta enriquecido: no solo la posición, sino todo lo necesario
/// para dibujar los gráficos de altimetría/FC/velocidad/potencia/cadencia
/// con scrubbing en el detalle de la actividad. Se guarda serializado
/// dentro de `Activities.routePointsJson`, así que cualquier campo nuevo
/// que se agregue aquí debe tener un valor de respaldo en `fromJson` para
/// no romper actividades ya guardadas con una versión anterior del
/// modelo.
class RoutePointSnapshot {
  final double latitude;
  final double longitude;
  final double altitude;

  /// Distancia acumulada (metros) desde el inicio de la actividad hasta
  /// este punto. Es el eje X de los gráficos.
  final double distanceFromStartMeters;

  final double slopePercent;
  final double speedKmh;

  /// Segundos transcurridos desde el inicio (tiempo activo, sin pausas).
  final int secondsFromStart;

  /// Última lectura de FC conocida en este instante ("carry forward": si
  /// el sensor no mandó una muestra justo en este punto, se usa la
  /// última que sí llegó). Null si aún no había ninguna lectura de FC.
  final int? heartRateBpm;

  /// Última lectura de potencia conocida en este instante (mismo
  /// criterio de "carry forward" que heartRateBpm). Null si no había
  /// medidor de potencia conectado todavía en este punto.
  final int? powerWatts;

  /// Última lectura de cadencia conocida en este instante (mismo
  /// criterio de "carry forward"). Viene de `cadenceRpmProvider`, así
  /// que ya trae la fusión con prioridad (potencia primero, CSC como
  /// respaldo) resuelta -- este campo no sabe ni le importa de qué
  /// sensor físico vino.
  final double? cadenceRpm;

  const RoutePointSnapshot({
    required this.latitude,
    required this.longitude,
    this.altitude = 0,
    this.distanceFromStartMeters = 0,
    this.slopePercent = 0,
    this.speedKmh = 0,
    this.secondsFromStart = 0,
    this.heartRateBpm,
    this.powerWatts,
    this.cadenceRpm,
  });

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
        'alt': altitude,
        'dist': distanceFromStartMeters,
        'slope': slopePercent,
        'speed': speedKmh,
        't': secondsFromStart,
        'hr': heartRateBpm,
        'pw': powerWatts,
        'cad': cadenceRpm,
      };

  factory RoutePointSnapshot.fromJson(Map<String, dynamic> json) {
    return RoutePointSnapshot(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      // Los campos nuevos usan `??` con un valor de respaldo para poder
      // seguir leyendo actividades grabadas antes de agregar estos datos
      // (esas solo tenían lat/lng, o luego lat/lng/.../hr) sin que la
      // app truene al abrirlas.
      altitude: (json['alt'] as num?)?.toDouble() ?? 0,
      distanceFromStartMeters: (json['dist'] as num?)?.toDouble() ?? 0,
      slopePercent: (json['slope'] as num?)?.toDouble() ?? 0,
      speedKmh: (json['speed'] as num?)?.toDouble() ?? 0,
      secondsFromStart: (json['t'] as num?)?.toInt() ?? 0,
      heartRateBpm: (json['hr'] as num?)?.toInt(),
      powerWatts: (json['pw'] as num?)?.toInt(),
      cadenceRpm: (json['cad'] as num?)?.toDouble(),
    );
  }
}

/// Una lectura puntual de FC con su momento exacto, capturada mientras se
/// graba. Se usa solo de forma transitoria para "casar" cada lectura de
/// FC con el punto GPS más cercano en el tiempo (ver
/// `RouteRecordingController.finishRecording`); no se persiste tal cual.
class HeartRateSample {
  final DateTime timestamp;
  final int bpm;

  const HeartRateSample({required this.timestamp, required this.bpm});
}

/// Igual que `HeartRateSample`, pero para potencia -- una lectura de
/// `powerWattsProvider` con su momento exacto.
class PowerSample {
  final DateTime timestamp;
  final int watts;

  const PowerSample({required this.timestamp, required this.watts});
}

/// Igual que `HeartRateSample`, pero para cadencia -- una lectura de
/// `cadenceRpmProvider` (ya fusionada) con su momento exacto.
class CadenceSample {
  final DateTime timestamp;
  final double rpm;

  const CadenceSample({required this.timestamp, required this.rpm});
}
