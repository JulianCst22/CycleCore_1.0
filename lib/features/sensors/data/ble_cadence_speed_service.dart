import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/cycling_speed_cadence_parser.dart';
import '../domain/cycling_speed_cadence_reading.dart';
import '../domain/discovered_device.dart';

/// Única puerta de entrada a flutter_blue_plus para sensores de
/// velocidad/cadencia (CSC). Mismo criterio que los demás servicios BLE
/// del proyecto.
///
/// Usa los UUID estándar de Bluetooth SIG (Cycling Speed and Cadence
/// Service 0x1816, CSC Measurement 0x2A5B).
class BleCadenceSpeedService {
  static final Guid _cscServiceUuid = Guid('1816');
  static final Guid _cscMeasurementCharUuid = Guid('2A5B');

  Stream<List<DiscoveredDevice>> scanForCadenceSpeedSensors({
    Duration timeout = const Duration(seconds: 12),
  }) {
    FlutterBluePlus.startScan(
      withServices: [_cscServiceUuid],
      timeout: timeout,
    );

    return FlutterBluePlus.scanResults.map(
      (results) => results
          .map(
            (r) => DiscoveredDevice(
              id: r.device.remoteId.str,
              name: r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : 'Sensor de velocidad/cadencia',
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

  /// Se suscribe a las lecturas CSC de un dispositivo ya conectado.
  /// Debe llamarse después de connect().
  Stream<CyclingSpeedCadenceReading> watchCadenceSpeed(
    BluetoothDevice device,
  ) async* {
    final services = await device.discoverServices();

    final cscService = services.firstWhere(
      (s) => s.uuid == _cscServiceUuid,
      orElse: () => throw StateError(
        'Este dispositivo no expone el servicio estándar de velocidad/'
        'cadencia (0x1816).',
      ),
    );

    final measurementCharacteristic = cscService.characteristics.firstWhere(
      (c) => c.uuid == _cscMeasurementCharUuid,
    );

    await measurementCharacteristic.setNotifyValue(true);

    await for (final rawData in measurementCharacteristic.lastValueStream) {
      if (rawData.isEmpty) continue;
      yield parseCyclingSpeedCadenceMeasurement(rawData);
    }
  }

  Stream<BluetoothConnectionState> watchConnectionState(
    BluetoothDevice device,
  ) {
    return device.connectionState;
  }

  Future<void> disconnect(BluetoothDevice device) => device.disconnect();
}
