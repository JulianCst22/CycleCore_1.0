import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/cycling_power_parser.dart';
import '../domain/cycling_power_reading.dart';
import '../domain/discovered_device.dart';
import 'ble_sensor_service.dart';
import 'fbp_sensor_link.dart';

/// Acceso BLE a medidores de potencia.
///
/// Usa los UUID estándar de Bluetooth SIG (Cycling Power Service 0x1818,
/// Cycling Power Measurement 0x2A63), compatibles con prácticamente
/// cualquier medidor del mercado (Stages, Quarq, Assioma, 4iiii, etc).
class BleCyclingPowerService implements BleSensorService<CyclingPowerReading> {
  static final Guid _serviceUuid = Guid('1818');
  static final Guid _measurementCharUuid = Guid('2A63');

  @override
  Stream<List<DiscoveredDevice>> scan({
    Duration timeout = const Duration(seconds: 12),
  }) =>
      fbpScanForService(_serviceUuid, 'Medidor de potencia', timeout: timeout);

  @override
  Future<void> stopScan() => fbpStopScan();

  @override
  Future<SensorLink<CyclingPowerReading>> connect(String deviceId) =>
      fbpConnect(
        deviceId,
        serviceUuid: _serviceUuid,
        characteristicUuid: _measurementCharUuid,
        parse: parseCyclingPowerMeasurement,
        missingServiceMessage:
            'Este dispositivo no expone el servicio estándar de potencia '
            '(0x1818).',
      );
}
