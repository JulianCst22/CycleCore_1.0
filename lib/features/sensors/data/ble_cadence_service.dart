import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/cycling_speed_cadence_parser.dart';
import '../domain/cycling_speed_cadence_reading.dart';
import '../domain/discovered_device.dart';

/// Puerta de entrada a flutter_blue_plus para el sensor de CADENCIA
/// (manivela) dedicado. Usa el mismo servicio estándar CSC que
/// `ble_speed_service.dart` -- ver el comentario de ese archivo para el
/// razonamiento completo de por qué son dos clases independientes en
/// vez de una sola compartida.
class BleCadenceService {
  static final Guid _cscServiceUuid = Guid('1816');
  static final Guid _cscMeasurementCharUuid = Guid('2A5B');

  Stream<List<DiscoveredDevice>> scanForCadenceSensors({
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
                  : 'Sensor de cadencia',
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
  /// controlador de cadencia solo usa `reading.hasCrankData` -- si el
  /// dispositivo también trae datos de rueda, simplemente se ignoran
  /// aquí (esta tarjeta no es dueña de la velocidad).
  Stream<CyclingSpeedCadenceReading> watchCadence(
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
