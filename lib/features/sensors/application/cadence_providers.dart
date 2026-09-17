import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ble_cadence_service.dart';
import '../data/ble_sensor_service.dart';
import '../domain/cadence_speed_calculator.dart';
import '../domain/cycling_speed_cadence_reading.dart';
import '../domain/sensor_kind.dart';
import 'ble_sensor_controller.dart';
import 'power_providers.dart' show powerSourcedCadenceRpmProvider;
import 'sensor_connection_state.dart';
import 'speed_providers.dart' show speedSourcedCadenceRpmProvider;

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

  @override
  void onBeforeConnect() => _calculator.reset();

  @override
  void onAfterDisconnect() => _calculator.reset();

  @override
  void handleReading(CyclingSpeedCadenceReading reading) {
    if (!reading.hasCrankData) return;
    final rpm = _calculator.updateCadenceRpm(
      cumulativeCrankRevolutions: reading.cumulativeCrankRevolutions!,
      lastCrankEventTime: reading.lastCrankEventTime!,
    );
    if (rpm != null) {
      ref.read(dedicatedCadenceRpmProvider.notifier).state = rpm;
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

/// Cadencia "oficial" que lee el resto de la app (cockpit, grabación,
/// etc). Prioridad:
///   1. Medidor de potencia (si trae manivela) -- la fuente más "gratis".
///   2. Sensor de cadencia dedicado.
///   3. Sensor de velocidad marcado como combo -- respaldo.
final cadenceRpmProvider = Provider<double?>((ref) {
  final fromPower = ref.watch(powerSourcedCadenceRpmProvider);
  if (fromPower != null) return fromPower;

  final fromDedicated = ref.watch(dedicatedCadenceRpmProvider);
  if (fromDedicated != null) return fromDedicated;

  return ref.watch(speedSourcedCadenceRpmProvider);
});

final bleCadenceServiceProvider = Provider<BleCadenceService>(
  (ref) => BleCadenceService(),
);

final cadenceSensorControllerProvider =
    StateNotifierProvider<CadenceSensorController, SensorConnectionState>(
      (ref) =>
          CadenceSensorController(ref.read(bleCadenceServiceProvider), ref),
    );
