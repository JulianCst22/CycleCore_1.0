import 'package:core_database/core_database.dart';
import 'package:cyclecore_app/features/recording/data/recording_journal.dart';
import 'package:cyclecore_app/features/recording/domain/recording_snapshot.dart';
import 'package:cyclecore_app/features/recording/domain/route_point.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// Drift guarda las fechas con precisión de segundos -- el inicio de la
// sesión se elige ya redondeado para poder compararlo tal cual.
final _start = DateTime(2026, 9, 12, 7, 0);

JournalPoint _point(int second, double distance) => JournalPoint(
  point: RoutePoint(
    latitude: 4.7 + second / 10000,
    longitude: -74.0,
    altitude: 2500.5 + second,
    speedMetersPerSecond: 6.2,
    bearingDegrees: 90,
    accuracyMeters: 3.5,
    timestamp: _start.add(Duration(seconds: second, milliseconds: 250)),
  ),
  distanceMeters: distance,
  speedKmh: 22.3,
);

void main() {
  late AppDatabase db;
  late RecordingJournal journal;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    journal = RecordingJournal(db);
  });

  tearDown(() => db.close());

  Future<void> saveActivityStartedAt(DateTime startedAt) {
    return db.insertActivity(
      ActivitiesCompanion.insert(
        title: 'Salida',
        activityType: 'training',
        bikeName: 'Ruta',
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(hours: 1)),
        durationSeconds: 3600,
        distanceMeters: 30000,
        avgSpeedKmh: 30,
        maxSpeedKmh: 55,
        elevationGainMeters: 400,
      ),
    );
  }

  test('sin sesión no hay nada que recuperar', () async {
    expect(await journal.loadRecoverable(), isNull);
  });

  test(
    'recupera puntos, sensores y progreso tal como se escribieron',
    () async {
      await journal.open(_start);
      journal
        ..addPoint(_point(0, 0))
        ..addPoint(_point(2, 12.5))
        ..addHeartRate(
          HeartRateSample(
            timestamp: _start.add(const Duration(seconds: 1)),
            bpm: 131,
          ),
        )
        ..addPower(PowerSample(timestamp: _start, watts: 245))
        ..addCadence(
          CadenceSample(
            timestamp: _start.add(const Duration(seconds: 2)),
            rpm: 87.5,
          ),
        );
      await journal.flush(
        movingTime: const Duration(seconds: 2, milliseconds: 400),
        isPaused: true,
      );

      // Otra instancia -- como si la app se hubiera vuelto a abrir.
      final snapshot = await RecordingJournal(db).loadRecoverable();

      expect(snapshot, isNotNull);
      expect(snapshot!.startedAt, _start);
      expect(
        snapshot.movingTime,
        const Duration(seconds: 2, milliseconds: 400),
      );
      expect(snapshot.isPaused, isTrue);
      expect(snapshot.isFinished, isFalse);

      expect(snapshot.points, hasLength(2));
      final p = snapshot.points.last;
      expect(p.distanceMeters, 12.5);
      expect(p.speedKmh, 22.3);
      expect(p.point.altitude, 2502.5);
      expect(p.point.accuracyMeters, 3.5);
      // Los instantes de los puntos conservan los milisegundos.
      expect(
        p.point.timestamp,
        _start.add(const Duration(seconds: 2, milliseconds: 250)),
      );

      expect(snapshot.heartRate.single.bpm, 131);
      expect(snapshot.power.single.watts, 245);
      expect(snapshot.cadence.single.rpm, 87.5);
    },
  );

  test('lo que no se alcanzó a escribir con flush no se recupera', () async {
    await journal.open(_start);
    journal.addPoint(_point(0, 0));
    await journal.flush(movingTime: Duration.zero, isPaused: false);
    journal.addPoint(_point(2, 10)); // la app "muere" antes del flush

    final snapshot = await RecordingJournal(db).loadRecoverable();
    expect(snapshot!.points, hasLength(1));
  });

  test('flush con endedAt deja la sesión marcada como terminada', () async {
    final endedAt = _start.add(const Duration(hours: 1));
    await journal.open(_start);
    journal.addPoint(_point(0, 0));
    await journal.flush(
      movingTime: const Duration(minutes: 55),
      isPaused: false,
      endedAt: endedAt,
    );

    final snapshot = await journal.loadRecoverable();
    expect(snapshot!.isFinished, isTrue);
    expect(snapshot.lastDataAt, endedAt);
  });

  test('clear vacía el diario', () async {
    await journal.open(_start);
    journal.addPoint(_point(0, 0));
    await journal.flush(movingTime: Duration.zero, isPaused: false);

    await journal.clear();

    expect(await journal.loadRecoverable(), isNull);
    expect(journal.isOpen, isFalse);
  });

  test('abrir una sesión nueva borra la anterior', () async {
    await journal.open(_start);
    journal.addPoint(_point(0, 0));
    await journal.flush(movingTime: Duration.zero, isPaused: false);

    final secondStart = _start.add(const Duration(hours: 3));
    await journal.open(secondStart);
    journal.addPoint(_point(0, 0));
    await journal.flush(movingTime: Duration.zero, isPaused: false);

    final snapshot = await journal.loadRecoverable();
    expect(snapshot!.startedAt, secondStart);
    expect(snapshot.points, hasLength(1));
  });

  test('una sesión sin puntos no se ofrece y se limpia', () async {
    await journal.open(_start);
    await journal.flush(movingTime: Duration.zero, isPaused: false);

    expect(await journal.loadRecoverable(), isNull);
    expect(await db.getRecordingSession(), isNull);
  });

  test(
    'si la actividad ya llegó al historial solo se limpia el diario',
    () async {
      await journal.open(_start);
      journal.addPoint(_point(0, 0));
      await journal.flush(movingTime: Duration.zero, isPaused: false);
      await saveActivityStartedAt(_start);

      expect(await journal.loadRecoverable(), isNull);
      expect(await db.getRecordingSession(), isNull);
    },
  );

  test('al reanudar se sigue escribiendo en la misma sesión', () async {
    await journal.open(_start);
    journal.addPoint(_point(0, 0));
    await journal.flush(
      movingTime: const Duration(seconds: 30),
      isPaused: false,
    );

    final reopened = RecordingJournal(db);
    final snapshot = await reopened.loadRecoverable();
    reopened
      ..resume(snapshot!)
      ..addPoint(_point(600, 3000));
    await reopened.flush(
      movingTime: const Duration(seconds: 45),
      isPaused: false,
    );

    final after = await RecordingJournal(db).loadRecoverable();
    expect(after!.sessionId, snapshot.sessionId);
    expect(after.points.map((p) => p.distanceMeters), [0, 3000]);
    expect(after.movingTime, const Duration(seconds: 45));
  });
}
