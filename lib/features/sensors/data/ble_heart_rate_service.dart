import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/discovered_device.dart';
import '../domain/heart_rate_parser.dart';
import '../domain/heart_rate_reading.dart';
import 'ble_sensor_service.dart';
import 'fbp_sensor_link.dart';

/// Acceso BLE a sensores de frecuencia cardíaca.
///
/// Usa los UUID estándar de Bluetooth SIG (Heart Rate Service 0x180D,
/// Heart Rate Measurement 0x2A37), compatibles con Polar, Garmin,
/// Wahoo, Magene y la gran mayoría de bandas del mercado.
class BleHeartRateService implements BleSensorService<HeartRateReading> {
  static final Guid _serviceUuid = Guid('180D');
  static final Guid _measurementCharUuid = Guid('2A37');

  @override
  Stream<List<DiscoveredDevice>> scan({
    Duration timeout = const Duration(seconds: 12),
  }) => fbpScanForService(_serviceUuid, 'Sensor de FC', timeout: timeout);

  @override
  Future<void> stopScan() => fbpStopScan();

  @override
  Future<SensorLink<HeartRateReading>> connect(String deviceId) =>
      fbpConnect(deviceId, _watch);

  Stream<HeartRateReading> _watch(BluetoothDevice device) async* {
    final services = await device.discoverServices();

    final heartRateService = services.firstWhere(
      (s) => s.uuid == _serviceUuid,
      orElse: () => throw StateError(
        'Este dispositivo no expone el servicio estándar de frecuencia '
        'cardíaca (0x180D).',
      ),
    );

    final measurementCharacteristic = heartRateService.characteristics
        .firstWhere((c) => c.uuid == _measurementCharUuid);

    await measurementCharacteristic.setNotifyValue(true);

    await for (final rawData in measurementCharacteristic.lastValueStream) {
      if (rawData.isEmpty) continue;
      yield parseHeartRateMeasurement(rawData);
    }
  }
}
