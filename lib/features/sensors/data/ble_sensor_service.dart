import '../domain/discovered_device.dart';

/// Contrato común de acceso BLE para los cuatro tipos de sensor. Cada
/// `Ble*Service` concreto (frecuencia cardíaca, potencia, velocidad,
/// cadencia) lo implementa parametrizado por su tipo de lectura `R`
/// (`HeartRateReading`, `CyclingPowerReading`, `CyclingSpeedCadenceReading`).
///
/// `BleSensorController` habla SOLO con esta interfaz -- nunca importa
/// `flutter_blue_plus` -- así que la lógica de conexión/reconexión se
/// prueba con un doble de test sin tocar Bluetooth real.
abstract interface class BleSensorService<R> {
  /// Escanea sensores de este tipo cerca. El stream emite la lista
  /// completa de descubiertos cada vez que cambia.
  Stream<List<DiscoveredDevice>> scan({Duration timeout});

  /// Detiene cualquier escaneo en curso.
  Future<void> stopScan();

  /// Conecta con un dispositivo por id y devuelve el enlace activo por
  /// el que fluyen las lecturas y los cambios de conexión.
  Future<SensorLink<R>> connect(String deviceId);
}

/// Un enlace BLE ya establecido con un sensor concreto.
abstract interface class SensorLink<R> {
  /// Lecturas del sensor ya interpretadas (aún sin convertir a km/h /
  /// rpm cuando aplica -- eso lo hace el controlador).
  Stream<R> readings();

  /// Cambios de conexión del enlace.
  Stream<SensorLinkState> connectionState();

  /// Intenta re-establecer el enlace tras una caída.
  Future<void> reconnect();

  /// Cierra el enlace.
  Future<void> disconnect();
}

enum SensorLinkState { connected, disconnected }
