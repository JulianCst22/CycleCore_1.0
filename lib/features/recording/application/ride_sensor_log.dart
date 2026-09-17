import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sensors/sensors.dart';
import 'route_recording_providers.dart'
    show recordingJournalProvider, routeRecordingProvider, RouteRecordingState;
import 'package:core_database/core_database.dart';
import '../data/recording_journal.dart';
import '../domain/recording_snapshot.dart';

/// Bitácora de muestras de sensores (FC / potencia / cadencia) con su
/// timestamp, acumuladas SOLO mientras se está grabando y sin pausa.
///
/// Antes esto vivía como 3 listas mutables en el `State` de `RideScreen`
/// más 3 bloques `ref.listen`. Se sacó de la UI porque:
///  1. La detección de segmentos en vivo (Fase C) necesita el promedio
///     de FC/potencia DENTRO de la ventana de un segmento para
///     registrar el esfuerzo -- sin depender de que la pantalla del
///     mapa esté montada.
///  2. `finishRecording` ya recibía estas listas como parámetro; ahora
///     la fuente única es este provider.
class RideSensorLog {
  final List<HeartRateSample> heartRate;
  final List<PowerSample> power;
  final List<CadenceSample> cadence;

  const RideSensorLog({
    this.heartRate = const [],
    this.power = const [],
    this.cadence = const [],
  });

  /// La bitácora tal como la guardó el diario de una grabación recuperada.
  RideSensorLog.fromSnapshot(RecordingSnapshot snapshot)
    : heartRate = snapshot.heartRate,
      power = snapshot.power,
      cadence = snapshot.cadence;

  RideSensorLog copyWith({
    List<HeartRateSample>? heartRate,
    List<PowerSample>? power,
    List<CadenceSample>? cadence,
  }) {
    return RideSensorLog(
      heartRate: heartRate ?? this.heartRate,
      power: power ?? this.power,
      cadence: cadence ?? this.cadence,
    );
  }

  int? get maxPowerSoFar => _maxOrNull(power.map((s) => s.watts));
  double? get maxCadenceSoFar => _maxOrNull(cadence.map((s) => s.rpm));

  /// Promedio de FC entre [from] y [to] (inclusive), o null si no hubo
  /// ninguna muestra en esa ventana -- lo usa el registro de esfuerzos
  /// de segmento.
  int? avgHeartRateBetween(DateTime from, DateTime to) {
    final values = heartRate
        .where((s) => !s.timestamp.isBefore(from) && !s.timestamp.isAfter(to))
        .map((s) => s.bpm)
        .toList();
    if (values.isEmpty) return null;
    return (values.reduce((a, b) => a + b) / values.length).round();
  }

  int? avgPowerBetween(DateTime from, DateTime to) {
    final values = power
        .where((s) => !s.timestamp.isBefore(from) && !s.timestamp.isAfter(to))
        .map((s) => s.watts)
        .toList();
    if (values.isEmpty) return null;
    return (values.reduce((a, b) => a + b) / values.length).round();
  }

  static T? _maxOrNull<T extends num>(Iterable<T> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a > b ? a : b);
  }
}

class RideSensorLogController extends StateNotifier<RideSensorLog> {
  /// Cada muestra también va al diario de la grabación, para no perderla
  /// si la app se cierra -- ver `RecordingJournal`.
  final RecordingJournal _journal;

  RideSensorLogController(this._journal) : super(const RideSensorLog());

  void addHeartRate(int bpm) {
    final sample = HeartRateSample(timestamp: DateTime.now(), bpm: bpm);
    _journal.addHeartRate(sample);
    state = state.copyWith(heartRate: [...state.heartRate, sample]);
  }

  void addPower(int watts) {
    final sample = PowerSample(timestamp: DateTime.now(), watts: watts);
    _journal.addPower(sample);
    state = state.copyWith(power: [...state.power, sample]);
  }

  void addCadence(double rpm) {
    final sample = CadenceSample(timestamp: DateTime.now(), rpm: rpm);
    _journal.addCadence(sample);
    state = state.copyWith(cadence: [...state.cadence, sample]);
  }

  /// Vuelve a cargar la bitácora de una grabación recuperada del diario.
  /// Se llama ANTES de `RouteRecordingController.resumeFrom`, para que la
  /// detección de segmentos ya la encuentre al ponerse al día.
  void restore(RecordingSnapshot snapshot) {
    state = RideSensorLog.fromSnapshot(snapshot);
  }

  void clear() => state = const RideSensorLog();
}

/// Bitácora de sensores de la sesión de grabación en curso. Se limpia
/// sola cuando arranca una grabación nueva y solo acumula mientras
/// `isCapturing` -- ni en pausa manual ni detenido en pausa automática,
/// para que los promedios no se arrastren con cada semáforo.
final rideSensorLogProvider =
    StateNotifierProvider<RideSensorLogController, RideSensorLog>((ref) {
  final controller = RideSensorLogController(
    ref.read(recordingJournalProvider),
  );

  bool recordingActive() => ref.read(routeRecordingProvider).isCapturing;

  ref.listen<int?>(heartRateBpmProvider, (_, next) {
    if (next != null && recordingActive()) controller.addHeartRate(next);
  });
  ref.listen<int?>(powerWattsProvider, (_, next) {
    if (next != null && recordingActive()) controller.addPower(next);
  });
  ref.listen<double?>(cadenceRpmProvider, (_, next) {
    if (next != null && recordingActive()) controller.addCadence(next);
  });

  // Limpia al arrancar una grabación nueva (isRecording: false -> true).
  // Una grabación nueva arranca sin puntos; una reanudada tras un cierre
  // inesperado ya los trae, y su bitácora se acaba de restaurar (ver
  // `restore`) -- esa no se toca.
  ref.listen<RouteRecordingState>(routeRecordingProvider, (prev, next) {
    final justStarted = (prev == null || !prev.isRecording) && next.isRecording;
    if (justStarted && next.points.isEmpty) controller.clear();
  });

  return controller;
});
