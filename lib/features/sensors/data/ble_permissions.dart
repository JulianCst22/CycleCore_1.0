import 'package:permission_handler/permission_handler.dart';

/// Solicita los permisos runtime necesarios para escanear BLE en Android.
///
/// Separado en su propio archivo (en vez de mezclarlo con la lógica de
/// escaneo en BleHeartRateService) porque es una responsabilidad
/// distinta: pedir permisos es un problema de plataforma/UX, no de
/// protocolo Bluetooth.
class BlePermissions {
  /// Devuelve true si todos los permisos requeridos quedaron concedidos.
  static Future<bool> requestAll() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }
}
