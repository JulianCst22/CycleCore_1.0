import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/cycling_speed_cadence_parser.dart';
import '../domain/cycling_speed_cadence_reading.dart';
import '../domain/discovered_device.dart';
import 'ble_sensor_service.dart';
import 'fbp_sensor_link.dart';

/// Acceso BLE al sensor de VELOCIDAD (rueda). Usa el servicio estándar
/// CSC (Cycling Speed and Cadence, 0x1816 / característica 0x2A5B), el
/// mismo que el sensor de cadencia dedicado ([BleCadenceService]): muchos
/// fabricantes venden el sensor de rueda y el de manivela por separado,
/// cada uno como su propio dispositivo BLE, pero ambos hablan este
/// servicio. Son dos servicios independientes a propósito, para poder
/// tener rueda Y manivela conectadas a la vez.
class BleSpeedService implements BleSensorService<CyclingSpeedCadenceReading> {
  static final Guid _serviceUuid = Guid('1816');
  static final Guid _measurementCharUuid = Guid('2A5B');

  @override
  Stream<List<DiscoveredDevice>> scan({
    Duration timeout = const Duration(seconds: 12),
  }) =>
      fbpScanForService(_serviceUuid, 'Sensor de velocidad', timeout: timeout);

  @override
  Future<void> stopScan() => fbpStopScan();

  @override
  Future<SensorLink<CyclingSpeedCadenceReading>> connect(String deviceId) =>
      fbpConnect(
        deviceId,
        serviceUuid: _serviceUuid,
        characteristicUuid: _measurementCharUuid,
        parse: parseCyclingSpeedCadenceMeasurement,
        missingServiceMessage:
            'Este dispositivo no expone el servicio estándar de velocidad/'
            'cadencia (0x1816).',
      );
}
