import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ble_power_service.dart';
import '../data/ble_sensor_service.dart';
import '../domain/cadence_speed_calculator.dart';
import '../domain/cycling_power_reading.dart';
import '../domain/sensor_kind.dart';
import 'ble_sensor_controller.dart';
import 'sensor_connection_state.dart';

/// Medidor de potencia. Además de los vatios, si el sensor trae datos de
/// manivela deriva cadencia (la fuente más "gratis": ya lo tienes
/// conectado). Esa cadencia NO es pública -- ver `cadenceRpmProvider`.
class PowerSensorController extends BleSensorController<CyclingPowerReading> {
  PowerSensorController(BleSensorService<CyclingPowerReading> service, Ref ref)
    : super(kind: SensorKind.power, service: service, ref: ref);

  final CadenceSpeedCalculator _cadence = CadenceSpeedCalculator();

  @override
  void onBeforeConnect() => _cadence.reset();

  @override
  void onAfterDisconnect() => _cadence.reset();

  @override
  void handleReading(CyclingPowerReading reading) {
    ref.read(powerWattsProvider.notifier).state =
        reading.instantaneousPowerWatts;

    if (reading.hasCrankData) {
      final rpm = _cadence.updateCadenceRpm(
        cumulativeCrankRevolutions: reading.cumulativeCrankRevolutions!,
        lastCrankEventTime: reading.lastCrankEventTime!,
      );
      if (rpm != null) {
        ref.read(powerSourcedCadenceRpmProvider.notifier).state = rpm;
      }
    }
  }

  @override
  void clearLiveOutputs() {
    ref.read(powerWattsProvider.notifier).state = null;
    ref.read(powerSourcedCadenceRpmProvider.notifier).state = null;
  }
}

/// Potencia en vatios en tiempo real. El resto de la app la lee sin
/// saber que hay BLE detrás -- mismo patrón que `heartRateBpmProvider`.
final powerWattsProvider = StateProvider<int?>((ref) => null);

/// Cadencia derivada del medidor de potencia. NO pública -- la cadencia
/// "oficial" es `cadenceRpmProvider`, que fusiona esta fuente con las
/// demás.
final powerSourcedCadenceRpmProvider = StateProvider<double?>((ref) => null);

final bleCyclingPowerServiceProvider = Provider<BleCyclingPowerService>(
  (ref) => BleCyclingPowerService(),
);

final powerSensorControllerProvider =
    StateNotifierProvider<PowerSensorController, SensorConnectionState>(
      (ref) =>
          PowerSensorController(ref.read(bleCyclingPowerServiceProvider), ref),
    );
