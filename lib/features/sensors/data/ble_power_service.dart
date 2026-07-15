import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/cycling_power_parser.dart';
import '../domain/cycling_power_reading.dart';
import '../domain/discovered_device.dart';

/// Única puerta de entrada a flutter_blue_plus para sensores de
/// potencia. Mismo criterio que `BleHeartRateService`: ningún otro
/// archivo debería importar flutter_blue_plus directamente para esto.
///
/// Usa los UUID estándar de Bluetooth SIG (Cycling Power Service
/// 0x1818, Cycling Power Measurement 0x2A63), compatibles con
/// prácticamente cualquier medidor de potencia del mercado (Stages,
/// Quarq, Assioma, 4iiii, etc).
class BleCyclingPowerService {
  static final Guid _powerServiceUuid = Guid('1818');
  static final Guid _powerMeasurementCharUuid = Guid('2A63');

  Stream<List<DiscoveredDevice>> scanForPowerSensors({
    Duration timeout = const Duration(seconds: 12),
  }) {
    FlutterBluePlus.startScan(
      withServices: [_powerServiceUuid],
      timeout: timeout,
    );

    return FlutterBluePlus.scanResults.map(
      (results) => results
          .map(
            (r) => DiscoveredDevice(
              id: r.device.remoteId.str,
              name: r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : 'Medidor de potencia',
              rssi: r.rssi,
            ),
          )
          .toList(),
    );
  }

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  Future<BluetoothDevice> connect(String deviceId) async {
    final device = BluetoothDevice.fromId(deviceId);
    await device.connect(autoConnect: false);
    return device;
  }

  /// Se suscribe a las lecturas de potencia de un dispositivo ya
  /// conectado. Debe llamarse después de connect().
  Stream<CyclingPowerReading> watchPower(BluetoothDevice device) async* {
    final services = await device.discoverServices();

    final powerService = services.firstWhere(
      (s) => s.uuid == _powerServiceUuid,
      orElse: () => throw StateError(
        'Este dispositivo no expone el servicio estándar de potencia '
        '(0x1818).',
      ),
    );

    final measurementCharacteristic = powerService.characteristics
        .firstWhere((c) => c.uuid == _powerMeasurementCharUuid);

    await measurementCharacteristic.setNotifyValue(true);

    await for (final rawData in measurementCharacteristic.lastValueStream) {
      if (rawData.isEmpty) continue;
      yield parseCyclingPowerMeasurement(rawData);
    }
  }

  Stream<BluetoothConnectionState> watchConnectionState(
    BluetoothDevice device,
  ) {
    return device.connectionState;
  }

  Future<void> disconnect(BluetoothDevice device) => device.disconnect();
}
