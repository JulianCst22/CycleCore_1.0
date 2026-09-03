import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/heart_rate_provider.dart';
import '../data/ble_heart_rate_service.dart';
import '../data/ble_sensor_service.dart';
import '../domain/heart_rate_reading.dart';
import '../domain/sensor_kind.dart';
import 'ble_sensor_controller.dart';
import 'cadence_providers.dart';
import 'power_providers.dart';
import 'sensor_connection_state.dart';
import 'speed_providers.dart';

export 'sensor_connection_state.dart';

/// Sensor de frecuencia cardíaca. La única fuente de verdad del `bpm`
/// real: el resto de la app (panel del mapa, motor difuso a futuro) sólo
/// lee `heartRateBpmProvider` sin saber que hay BLE detrás.
class HeartRateSensorController extends BleSensorController<HeartRateReading> {
  HeartRateSensorController(BleSensorService<HeartRateReading> service, Ref ref)
    : super(kind: SensorKind.heartRate, service: service, ref: ref);

  @override
  void handleReading(HeartRateReading reading) {
    ref.read(heartRateBpmProvider.notifier).state = reading.bpm;
  }

  @override
  void clearLiveOutputs() {
    ref.read(heartRateBpmProvider.notifier).state = null;
  }
}

final bleHeartRateServiceProvider = Provider<BleHeartRateService>(
  (ref) => BleHeartRateService(),
);

final heartRateSensorControllerProvider =
    StateNotifierProvider<HeartRateSensorController, SensorConnectionState>(
      (ref) =>
          HeartRateSensorController(ref.read(bleHeartRateServiceProvider), ref),
    );

/// Vista de los cuatro sensores a la vez -- para el resumen "N de 4
/// conectados" y para que el cockpit / el onboarding sepan si el equipo
/// está listo sin cablear cuatro providers.
class SensorsHubSnapshot {
  final Map<SensorKind, SensorConnectionState> byKind;

  const SensorsHubSnapshot(this.byKind);

  SensorConnectionState of(SensorKind kind) =>
      byKind[kind] ?? const SensorConnectionState();

  int get total => SensorKind.values.length;

  int get connectedCount => byKind.values.where((s) => s.isConnected).length;

  bool get anyConnected => connectedCount > 0;

  bool get anyReconnecting => byKind.values.any((s) => s.isReconnecting);
}

final sensorsHubProvider = Provider<SensorsHubSnapshot>((ref) {
  return SensorsHubSnapshot({
    SensorKind.heartRate: ref.watch(heartRateSensorControllerProvider),
    SensorKind.power: ref.watch(powerSensorControllerProvider),
    SensorKind.speed: ref.watch(speedSensorControllerProvider),
    SensorKind.cadence: ref.watch(cadenceSensorControllerProvider),
  });
});
