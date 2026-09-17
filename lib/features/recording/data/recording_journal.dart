import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import 'package:core_database/core_database.dart';
import '../domain/recording_snapshot.dart';
import '../domain/route_point.dart';

/// Tipo de muestra de sensor en `RecordingSensorSamples.kind`.
enum RecordingSampleKind {
  heartRate('hr'),
  power('power'),
  cadence('cadence');

  final String wire;
  const RecordingSampleKind(this.wire);

  static RecordingSampleKind? fromWire(String wire) {
    for (final kind in values) {
      if (kind.wire == wire) return kind;
    }
    return null;
  }
}

/// Diario de la grabación en curso: la "caja negra" que evita perder el
/// recorrido si la app se cierra a mitad de la salida.
///
/// Mientras se graba, los puntos GPS y las muestras de sensores se
/// acumulan en memoria y se escriben por lotes a SQLite con [flush]
/// (cada pocos segundos, al pausar y cuando la app pasa a segundo plano
/// -- ver `RouteRecordingController`). Así lo más que se pierde ante un
/// cierre inesperado es lo del último lote.
///
/// Ciclo de vida de una sesión:
///  1. [open] al empezar a grabar (borra cualquier resto anterior).
///  2. [addPoint]/[addHeartRate]/... + [flush] mientras se graba.
///  3. [flush] con `endedAt` al tocar "Terminar" -- la sesión queda
///     marcada como terminada, pero sigue en el diario.
///  4. [clear] recién cuando la actividad ya está en el historial, o
///     cuando el usuario la descarta.
///
/// Si la app se abre y [loadRecoverable] devuelve algo, esa grabación no
/// llegó al paso 4.
///
/// Un fallo de escritura NUNCA interrumpe la grabación: se registra, las
/// filas vuelven al buffer y se reintentan en el siguiente [flush].
class RecordingJournal {
  final AppDatabase _database;

  RecordingJournal(this._database);

  int? _sessionId;
  final List<RecordingPointsCompanion> _pendingPoints = [];
  final List<RecordingSensorSamplesCompanion> _pendingSamples = [];

  /// Cola de escrituras -- cada operación espera a la anterior, para que
  /// un [clear] no se cruce con un [flush] todavía en vuelo.
  Future<void> _writes = Future.value();

  /// true mientras hay una sesión abierta en la que escribir.
  bool get isOpen => _sessionId != null;

  /// Abre una sesión nueva para una grabación que empieza en
  /// [startedAt].
  Future<void> open(DateTime startedAt) {
    _discardBuffers();
    return _enqueue(() async {
      try {
        _sessionId = await _database.startRecordingSession(startedAt);
      } catch (e) {
        // Sin diario la grabación sigue funcionando igual, solo sin
        // recuperación ante un cierre.
        _sessionId = null;
        debugPrint('RecordingJournal: no se pudo abrir la sesión: $e');
      }
    });
  }

  /// Retoma una sesión que ya existe en el diario (la recuperada) para
  /// seguir escribiendo en ella.
  void resume(RecordingSnapshot snapshot) {
    _discardBuffers();
    _sessionId = snapshot.sessionId;
  }

  void addPoint(JournalPoint entry) {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final p = entry.point;
    _pendingPoints.add(
      RecordingPointsCompanion.insert(
        sessionId: sessionId,
        latitude: p.latitude,
        longitude: p.longitude,
        altitude: p.altitude,
        speedMetersPerSecond: p.speedMetersPerSecond,
        bearingDegrees: p.bearingDegrees,
        accuracyMeters: p.accuracyMeters,
        timestampMillis: p.timestamp.millisecondsSinceEpoch,
        distanceMeters: entry.distanceMeters,
        speedKmh: entry.speedKmh,
      ),
    );
  }

  void addHeartRate(HeartRateSample sample) => _addSample(
    RecordingSampleKind.heartRate,
    sample.timestamp,
    sample.bpm.toDouble(),
  );

  void addPower(PowerSample sample) => _addSample(
    RecordingSampleKind.power,
    sample.timestamp,
    sample.watts.toDouble(),
  );

  void addCadence(CadenceSample sample) =>
      _addSample(RecordingSampleKind.cadence, sample.timestamp, sample.rpm);

  void _addSample(RecordingSampleKind kind, DateTime at, double value) {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    _pendingSamples.add(
      RecordingSensorSamplesCompanion.insert(
        sessionId: sessionId,
        kind: kind.wire,
        timestampMillis: at.millisecondsSinceEpoch,
        value: value,
      ),
    );
  }

  /// Escribe lo acumulado en memoria junto con el progreso de la sesión.
  /// Con [endedAt] la sesión además queda marcada como terminada.
  Future<void> flush({
    required Duration movingTime,
    required bool isPaused,
    DateTime? endedAt,
  }) {
    final sessionId = _sessionId;
    if (sessionId == null) return _writes;

    final points = List.of(_pendingPoints);
    final samples = List.of(_pendingSamples);
    _pendingPoints.clear();
    _pendingSamples.clear();

    return _enqueue(() async {
      // La sesión pudo cerrarse ([clear]) mientras este lote esperaba.
      if (_sessionId != sessionId) return;
      try {
        await _database.appendToRecordingJournal(
          sessionId: sessionId,
          progress: RecordingSessionsCompanion(
            movingMillis: Value(movingTime.inMilliseconds),
            isPaused: Value(isPaused),
            endedAt: endedAt == null ? const Value.absent() : Value(endedAt),
            updatedAt: Value(DateTime.now()),
          ),
          points: points,
          samples: samples,
        );
      } catch (e) {
        _pendingPoints.insertAll(0, points);
        _pendingSamples.insertAll(0, samples);
        debugPrint('RecordingJournal: no se pudo escribir el lote: $e');
      }
    });
  }

  /// Vacía el diario -- la grabación ya está en el historial o se
  /// descartó.
  Future<void> clear() {
    _sessionId = null;
    _discardBuffers();
    return _enqueue(() async {
      try {
        await _database.clearRecordingJournal();
      } catch (e) {
        debugPrint('RecordingJournal: no se pudo vaciar el diario: $e');
      }
    });
  }

  /// La grabación que quedó sin guardar en el historial, o `null` si no
  /// hay nada que recuperar.
  ///
  /// Limpia de paso lo que no vale la pena ofrecer: una sesión sin un
  /// solo punto GPS, o una que alcanzó a guardarse en el historial justo
  /// antes de que la app se cerrara (antes de vaciar el diario).
  Future<RecordingSnapshot?> loadRecoverable() async {
    await _writes;
    final session = await _database.getRecordingSession();
    if (session == null) return null;

    final points = await _database.getRecordingPoints(session.id);
    if (points.isEmpty ||
        await _database.hasActivityStartedAt(session.startedAt)) {
      await clear();
      return null;
    }

    final samples = await _database.getRecordingSensorSamples(session.id);
    return _toSnapshot(session, points, samples);
  }

  void _discardBuffers() {
    _pendingPoints.clear();
    _pendingSamples.clear();
  }

  Future<void> _enqueue(Future<void> Function() write) {
    final next = _writes.then((_) => write());
    _writes = next;
    return next;
  }

  static RecordingSnapshot _toSnapshot(
    RecordingSession session,
    List<RecordingPoint> points,
    List<RecordingSensorSample> samples,
  ) {
    final heartRate = <HeartRateSample>[];
    final power = <PowerSample>[];
    final cadence = <CadenceSample>[];

    for (final s in samples) {
      final at = DateTime.fromMillisecondsSinceEpoch(s.timestampMillis);
      switch (RecordingSampleKind.fromWire(s.kind)) {
        case RecordingSampleKind.heartRate:
          heartRate.add(HeartRateSample(timestamp: at, bpm: s.value.round()));
        case RecordingSampleKind.power:
          power.add(PowerSample(timestamp: at, watts: s.value.round()));
        case RecordingSampleKind.cadence:
          cadence.add(CadenceSample(timestamp: at, rpm: s.value));
        case null:
          break;
      }
    }

    return RecordingSnapshot(
      sessionId: session.id,
      startedAt: session.startedAt,
      movingTime: Duration(milliseconds: session.movingMillis),
      isPaused: session.isPaused,
      endedAt: session.endedAt,
      points: [
        for (final p in points)
          JournalPoint(
            point: RoutePoint(
              latitude: p.latitude,
              longitude: p.longitude,
              altitude: p.altitude,
              speedMetersPerSecond: p.speedMetersPerSecond,
              bearingDegrees: p.bearingDegrees,
              accuracyMeters: p.accuracyMeters,
              timestamp: DateTime.fromMillisecondsSinceEpoch(p.timestampMillis),
            ),
            distanceMeters: p.distanceMeters,
            speedKmh: p.speedKmh,
          ),
      ],
      heartRate: heartRate,
      power: power,
      cadence: cadence,
    );
  }
}
