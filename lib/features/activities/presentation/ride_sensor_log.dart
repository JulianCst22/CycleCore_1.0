import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/providers/heart_rate_provider.dart';
import '../../geospatial/presentation/map_providers.dart'
    show routeRecordingProvider, RouteRecordingState;
import '../../sensors/presentation/cadence_providers.dart';
import '../../sensors/presentation/power_providers.dart';
import '../domain/activity_summary.dart';

/// Bitácora de muestras de sensores (FC / potencia / cadencia) con su
/// timestamp, acumuladas SOLO mientras se está grabando y sin pausa.
///
/// Antes esto vivía como 3 listas mutables en el `State` de `MapScreen`
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
  RideSensorLogController() : super(const RideSensorLog());

  void addHeartRate(int bpm) {
    state = state.copyWith(
      heartRate: [
        ...state.heartRate,
        HeartRateSample(timestamp: DateTime.now(), bpm: bpm),
      ],
    );
  }

  void addPower(int watts) {
    state = state.copyWith(
      power: [
        ...state.power,
        PowerSample(timestamp: DateTime.now(), watts: watts),
      ],
    );
  }

  void addCadence(double rpm) {
    state = state.copyWith(
      cadence: [
        ...state.cadence,
        CadenceSample(timestamp: DateTime.now(), rpm: rpm),
      ],
    );
  }

  void clear() => state = const RideSensorLog();
}

/// Bitácora de sensores de la sesión de grabación en curso. Se limpia
/// sola cuando arranca una grabación nueva y solo acumula mientras
/// `isRecording && !isPaused`.
final rideSensorLogProvider =
    StateNotifierProvider<RideSensorLogController, RideSensorLog>((ref) {
  final controller = RideSensorLogController();

  bool recordingActive() {
    final rec = ref.read(routeRecordingProvider);
    return rec.isRecording && !rec.isPaused;
  }

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
  ref.listen<RouteRecordingState>(routeRecordingProvider, (prev, next) {
    final justStarted = (prev == null || !prev.isRecording) && next.isRecording;
    if (justStarted) controller.clear();
  });

  return controller;
});
