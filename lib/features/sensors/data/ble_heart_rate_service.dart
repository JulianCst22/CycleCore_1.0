import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/discovered_device.dart';
import '../domain/heart_rate_parser.dart';
import '../domain/heart_rate_reading.dart';

/// Única puerta de entrada a flutter_blue_plus para sensores de
/// frecuencia cardíaca. Ningún otro archivo del feature `sensors` (y
/// mucho menos de otros features) debería importar flutter_blue_plus
/// directamente -- si mañana cambiamos de paquete BLE, solo se toca
/// este archivo.
///
/// Usa los UUID estándar de Bluetooth SIG (Heart Rate Service 0x180D,
/// Heart Rate Measurement 0x2A37), compatibles con Polar, Garmin,
/// Wahoo, Magene y la gran mayoría de bandas del mercado -- tal como
/// se definió en la arquitectura del proyecto.
class BleHeartRateService {
  static final Guid _heartRateServiceUuid = Guid('180D');
  static final Guid _heartRateMeasurementCharUuid = Guid('2A37');

  /// Escanea ÚNICAMENTE dispositivos que anuncian el servicio estándar
  /// de frecuencia cardíaca. Filtrar en el escaneo mismo (en vez de
  /// mostrar todo lo que hay alrededor y filtrar después) evita
  /// saturar al usuario con audífonos, parlantes u otros dispositivos
  /// BLE irrelevantes.
  Stream<List<DiscoveredDevice>> scanForHeartRateSensors({
    Duration timeout = const Duration(seconds: 12),
  }) {
    FlutterBluePlus.startScan(
      withServices: [_heartRateServiceUuid],
      timeout: timeout,
    );

    return FlutterBluePlus.scanResults.map(
      (results) => results
          .map(
            (r) => DiscoveredDevice(
              id: r.device.remoteId.str,
              name: r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : 'Sensor de FC',
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

  /// Se suscribe a las lecturas de frecuencia cardíaca de un dispositivo
  /// ya conectado. Debe llamarse después de connect().
  Stream<HeartRateReading> watchHeartRate(BluetoothDevice device) async* {
    final services = await device.discoverServices();

    final heartRateService = services.firstWhere(
      (s) => s.uuid == _heartRateServiceUuid,
      orElse: () => throw StateError(
        'Este dispositivo no expone el servicio estándar de frecuencia '
        'cardíaca (0x180D).',
      ),
    );

    final measurementCharacteristic = heartRateService.characteristics
        .firstWhere((c) => c.uuid == _heartRateMeasurementCharUuid);

    await measurementCharacteristic.setNotifyValue(true);

    await for (final rawData in measurementCharacteristic.lastValueStream) {
      if (rawData.isEmpty) continue;
      yield parseHeartRateMeasurement(rawData);
    }
  }

  Stream<BluetoothConnectionState> watchConnectionState(
    BluetoothDevice device,
  ) {
    return device.connectionState;
  }

  Future<void> disconnect(BluetoothDevice device) => device.disconnect();
}
