import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ble_cadence_service.dart';
import '../data/ble_sensor_service.dart';
import '../data/cadence_source_repository.dart';
import '../domain/cadence_source.dart';
import '../domain/cadence_speed_calculator.dart';
import '../domain/cycling_speed_cadence_reading.dart';
import '../domain/revolution_stall_detector.dart';
import '../domain/sensor_kind.dart';
import 'ble_sensor_controller.dart';
import 'power_providers.dart' show powerSourcedCadenceRpmProvider;
import 'sensor_connection_state.dart';
import 'speed_providers.dart' show speedSourcedCadenceRpmProvider;

export '../domain/cadence_source.dart' show CadenceSource, CadenceSourceInfo;

/// Sin un evento de biela nuevo en este tiempo, se deja de pedalear. A
/// 30 rpm una vuelta tarda 2 s, así que 3 s no corta un pedaleo lento.
const crankStallAfter = Duration(seconds: 3);

/// Cadencia por encima de esto es un error de lectura, no una pedalada.
const maxPlausibleCadenceRpm = 220.0;

/// Sensor de cadencia dedicado (manivela). Si el dispositivo también
/// trae datos de rueda se ignoran aquí -- esa velocidad debe venir de la
/// tarjeta de Velocidad.
class CadenceSensorController
    extends BleSensorController<CyclingSpeedCadenceReading> {
  CadenceSensorController(
    BleSensorService<CyclingSpeedCadenceReading> service,
    Ref ref,
  ) : super(kind: SensorKind.cadence, service: service, ref: ref);

  final CadenceSpeedCalculator _calculator = CadenceSpeedCalculator();
  final RevolutionStallDetector _crank = RevolutionStallDetector(
    stallAfter: crankStallAfter,
  );

  void _resetCounters() {
    _calculator.reset();
    _crank.reset();
  }

  @override
  void onBeforeConnect() => _resetCounters();

  @override
  void onAfterDisconnect() => _resetCounters();

  @override
  void onLinkLost() => _resetCounters();

  @override
  void handleReading(CyclingSpeedCadenceReading reading) {
    if (!reading.hasCrankData) return;
    if (!_crank.observe(reading.lastCrankEventTime!, DateTime.now())) return;
    final rpm = _calculator.updateCadenceRpm(
      cumulativeCrankRevolutions: reading.cumulativeCrankRevolutions!,
      lastCrankEventTime: reading.lastCrankEventTime!,
    );
    if (rpm != null && rpm <= maxPlausibleCadenceRpm) {
      ref.read(dedicatedCadenceRpmProvider.notifier).state = rpm;
    }
  }

  @override
  void onTick(DateTime now) {
    if (_crank.checkStall(now)) {
      _calculator.resetCrank();
      ref.read(dedicatedCadenceRpmProvider.notifier).state = 0;
    }
  }

  @override
  void clearLiveOutputs() {
    ref.read(dedicatedCadenceRpmProvider.notifier).state = null;
  }
}

/// Cadencia del sensor de cadencia dedicado. NO pública -- ver
/// `cadenceRpmProvider`.
final dedicatedCadenceRpmProvider = StateProvider<double?>((ref) => null);

final cadenceSourceRepositoryProvider = Provider<CadenceSourceRepository>(
  (ref) => CadenceSourceRepository(),
);

/// De qué sensor quiere el ciclista la cadencia; `null` = automático.
class CadenceSourcePreference extends StateNotifier<CadenceSource?> {
  CadenceSourcePreference(this._repository) : super(null) {
    _load();
  }

  final CadenceSourceRepository _repository;
  bool _touched = false;

  Future<void> _load() async {
    final saved = await _repository.load();
    if (_touched || !mounted) return;
    state = saved;
  }

  Future<void> choose(CadenceSource? source) async {
    _touched = true;
    state = source;
    await _repository.save(source);
  }
}

final cadenceSourcePreferenceProvider =
    StateNotifierProvider<CadenceSourcePreference, CadenceSource?>(
      (ref) =>
          CadenceSourcePreference(ref.watch(cadenceSourceRepositoryProvider)),
    );

/// La fuente de cadencia que manda ahora mismo: la elegida si tiene
/// datos, y si no la primera que los tenga (ver `resolveCadenceSource`).
final activeCadenceSourceProvider = Provider<CadenceSource?>((ref) {
  return resolveCadenceSource(
    preferred: ref.watch(cadenceSourcePreferenceProvider),
    values: {
      CadenceSource.power: ref.watch(powerSourcedCadenceRpmProvider),
      CadenceSource.dedicated: ref.watch(dedicatedCadenceRpmProvider),
      CadenceSource.speedCombo: ref.watch(speedSourcedCadenceRpmProvider),
    },
  );
});

/// Cadencia "oficial" que lee el resto de la app (cockpit, grabación,
/// coach). Sale de la fuente activa (ver `activeCadenceSourceProvider`);
/// `0` significa que el ciclista no está pedaleando y `null` que no hay
/// ningún sensor que la mida.
final cadenceRpmProvider = Provider<double?>((ref) {
  return switch (ref.watch(activeCadenceSourceProvider)) {
    CadenceSource.power => ref.watch(powerSourcedCadenceRpmProvider),
    CadenceSource.dedicated => ref.watch(dedicatedCadenceRpmProvider),
    CadenceSource.speedCombo => ref.watch(speedSourcedCadenceRpmProvider),
    null => null,
  };
});

final bleCadenceServiceProvider = Provider<BleCadenceService>(
  (ref) => BleCadenceService(),
);

final cadenceSensorControllerProvider =
    StateNotifierProvider<CadenceSensorController, SensorConnectionState>(
      (ref) =>
          CadenceSensorController(ref.read(bleCadenceServiceProvider), ref),
    );
