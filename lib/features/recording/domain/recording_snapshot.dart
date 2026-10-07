import '../../../core/database/database.dart';

import 'route_point.dart';

/// Un punto del diario de grabación: el [RoutePoint] tal como se grabó
/// más la distancia y la velocidad ya priorizadas (sensor BLE o GPS) en
/// ese instante -- el mismo par que `RouteRecordingController` lleva en
/// `_liveDistanceHistory`/`_liveSpeedHistory`.
class JournalPoint {
  final RoutePoint point;

  /// Distancia acumulada desde el inicio (m).
  final double distanceMeters;

  final double speedKmh;

  const JournalPoint({
    required this.point,
    required this.distanceMeters,
    required this.speedKmh,
  });
}

/// Todo lo que el diario alcanzó a guardar de una grabación que no
/// terminó bien (la app se cerró antes de guardarla en el historial).
/// Con esto se puede reanudar la grabación o terminarla y guardarla
/// como si nunca se hubiera cerrado. Ver `RecordingJournal`.
class RecordingSnapshot {
  /// Id de la sesión en el diario -- para seguir escribiendo en ella al
  /// reanudar.
  final int sessionId;

  final DateTime startedAt;

  /// Tiempo en movimiento (sin pausas) hasta la última escritura.
  final Duration movingTime;

  final bool isPaused;

  /// Cuándo se tocó "Terminar", o `null` si todavía se estaba grabando
  /// cuando la app se cerró.
  final DateTime? endedAt;

  /// Última escritura al diario: hasta aquí se sabe que la app seguía
  /// grabando, aunque estuviera quieta (en pausa automática no se graban
  /// puntos, pero el diario se sigue escribiendo).
  final DateTime? updatedAt;

  final List<JournalPoint> points;
  final List<HeartRateSample> heartRate;
  final List<PowerSample> power;
  final List<CadenceSample> cadence;

  const RecordingSnapshot({
    required this.sessionId,
    required this.startedAt,
    required this.movingTime,
    required this.isPaused,
    required this.points,
    this.endedAt,
    this.updatedAt,
    this.heartRate = const [],
    this.power = const [],
    this.cadence = const [],
  });

  /// La app se cerró ya en la pantalla de guardar: la grabación estaba
  /// terminada, solo faltaba guardarla.
  bool get isFinished => endedAt != null;

  double get distanceMeters => points.isEmpty ? 0 : points.last.distanceMeters;

  /// Momento del último dato conocido -- el fin de la actividad cuando se
  /// termina una sesión que nunca llegó a "Terminar".
  DateTime get lastDataAt {
    final ended = endedAt;
    if (ended != null) return ended;
    var last = updatedAt ?? startedAt;
    if (points.isNotEmpty && points.last.point.timestamp.isAfter(last)) {
      last = points.last.point.timestamp;
    }
    return last;
  }

  double get maxSpeedKmh =>
      points.fold(0, (max, p) => p.speedKmh > max ? p.speedKmh : max);

  /// Desnivel positivo tal como se venía acumulando en vivo (suma de
  /// subidas entre puntos consecutivos). Solo para el cockpit al
  /// reanudar -- el resumen final lo recalcula el aplanado.
  double get liveElevationGainMeters {
    var gain = 0.0;
    for (var i = 1; i < points.length; i++) {
      final delta = points[i].point.altitude - points[i - 1].point.altitude;
      if (delta > 0) gain += delta;
    }
    return gain;
  }

  List<RoutePoint> get routePoints => [for (final p in points) p.point];
}
