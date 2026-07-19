import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/cycling_speed_cadence_parser.dart';
import '../domain/cycling_speed_cadence_reading.dart';
import '../domain/discovered_device.dart';

/// Puerta de entrada a flutter_blue_plus para el sensor de VELOCIDAD
/// (rueda). Usa el mismo servicio estándar CSC (Cycling Speed and
/// Cadence, 0x1816 / característica 0x2A5B) que el sensor de cadencia
/// dedicado -- muchos fabricantes venden sensores de rueda y de
/// manivela por separado, cada uno como su propio dispositivo BLE, pero
/// ambos hablan este mismo servicio. Este archivo y
/// `ble_cadence_service.dart` son clones estructurales a propósito: cada
/// uno es su propia conexión física independiente, para poder tener un
/// sensor de rueda Y uno de manivela conectados al mismo tiempo.
class BleSpeedService {
  static final Guid _cscServiceUuid = Guid('1816');
  static final Guid _cscMeasurementCharUuid = Guid('2A5B');

  Stream<List<DiscoveredDevice>> scanForSpeedSensors({
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
                  : 'Sensor de velocidad',
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

  /// Se suscribe a las lecturas CSC de un dispositivo ya conectado. El
  /// controlador de velocidad usa `reading.hasWheelData` (y, si el
  /// usuario marcó que este sensor también da cadencia, además
  /// `reading.hasCrankData`) -- este servicio entrega el payload
  /// completo tal cual, sin filtrar nada.
  Stream<CyclingSpeedCadenceReading> watchSpeed(BluetoothDevice device) async* {
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
