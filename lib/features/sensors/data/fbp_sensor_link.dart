import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/discovered_device.dart';
import 'ble_sensor_service.dart';

/// Utilidades compartidas de `flutter_blue_plus` para los cuatro
/// `Ble*Service`. Toda la dependencia real de `flutter_blue_plus` en el
/// feature `sensors` vive aquí y en los cuatro servicios concretos --
/// si mañana cambia el paquete BLE, solo se toca esta capa.

/// Escanea únicamente dispositivos que anuncian [serviceUuid]. Filtrar
/// en el escaneo (en vez de mostrar todo y filtrar después) evita
/// saturar al usuario con audífonos, parlantes y demás. [fallbackName]
/// se usa cuando el dispositivo no anuncia nombre.
Stream<List<DiscoveredDevice>> fbpScanForService(
  Guid serviceUuid,
  String fallbackName, {
  Duration timeout = const Duration(seconds: 12),
}) {
  FlutterBluePlus.startScan(withServices: [serviceUuid], timeout: timeout);
  return FlutterBluePlus.scanResults.map(
    (results) => results
        .map(
          (r) => DiscoveredDevice(
            id: r.device.remoteId.str,
            name: r.device.platformName.isNotEmpty
                ? r.device.platformName
                : fallbackName,
            rssi: r.rssi,
          ),
        )
        .toList(),
  );
}

Future<void> fbpStopScan() => FlutterBluePlus.stopScan();

/// Conecta con [deviceId] y devuelve un [SensorLink] que envuelve el
/// `BluetoothDevice`. [watch] produce el stream de lecturas ya parseadas
/// del dispositivo conectado (cada servicio pasa su propio parser).
Future<SensorLink<R>> fbpConnect<R>(
  String deviceId,
  Stream<R> Function(BluetoothDevice device) watch,
) async {
  final device = BluetoothDevice.fromId(deviceId);
  await device.connect(autoConnect: false);
  return _FbpSensorLink<R>(device, watch(device));
}

class _FbpSensorLink<R> implements SensorLink<R> {
  _FbpSensorLink(this._device, this._readings);

  final BluetoothDevice _device;
  final Stream<R> _readings;

  @override
  Stream<R> readings() => _readings;

  @override
  Stream<SensorLinkState> connectionState() => _device.connectionState.map(
    (s) => s == BluetoothConnectionState.connected
        ? SensorLinkState.connected
        : SensorLinkState.disconnected,
  );

  @override
  Future<void> reconnect() => _device.connect(autoConnect: false);

  @override
  Future<void> disconnect() => _device.disconnect();
}
