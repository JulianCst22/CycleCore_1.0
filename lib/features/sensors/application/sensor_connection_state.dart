import '../domain/discovered_device.dart';

enum SensorConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
}

/// Estado de conexión de UN sensor. Antes había cuatro clases idénticas
/// (`SensorsState`, `PowerConnectionState`, ...); ahora es una sola. Los
/// dos últimos campos sólo los usa Velocidad -- para el resto quedan en
/// su valor por defecto.
class SensorConnectionState {
  final SensorConnectionStatus status;
  final List<DiscoveredDevice> discoveredDevices;
  final String? connectedDeviceName;

  /// Segundos sin señal antes de avisar al usuario que no se ha podido
  /// reconectar. Configurable desde la UI.
  final int reconnectTimeoutSeconds;
  final bool showReconnectAlert;

  /// (Velocidad) el sensor ya reporta datos de rueda pero no hay
  /// circunferencia configurada -- la UI debe pedir la talla de llanta.
  final bool needsWheelSizeSetup;

  /// (Velocidad) el usuario marcó que este sensor es un combo que
  /// también da cadencia (rueda + manivela en un solo aparato).
  final bool alsoProvidesCadence;

  const SensorConnectionState({
    this.status = SensorConnectionStatus.disconnected,
    this.discoveredDevices = const [],
    this.connectedDeviceName,
    this.reconnectTimeoutSeconds = 60,
    this.showReconnectAlert = false,
    this.needsWheelSizeSetup = false,
    this.alsoProvidesCadence = false,
  });

  bool get isConnected => status == SensorConnectionStatus.connected;
  bool get isScanning => status == SensorConnectionStatus.scanning;
  bool get isReconnecting => status == SensorConnectionStatus.reconnecting;

  SensorConnectionState copyWith({
    SensorConnectionStatus? status,
    List<DiscoveredDevice>? discoveredDevices,
    String? connectedDeviceName,
    int? reconnectTimeoutSeconds,
    bool? showReconnectAlert,
    bool? needsWheelSizeSetup,
    bool? alsoProvidesCadence,
  }) {
    return SensorConnectionState(
      status: status ?? this.status,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      reconnectTimeoutSeconds:
          reconnectTimeoutSeconds ?? this.reconnectTimeoutSeconds,
      showReconnectAlert: showReconnectAlert ?? this.showReconnectAlert,
      needsWheelSizeSetup: needsWheelSizeSetup ?? this.needsWheelSizeSetup,
      alsoProvidesCadence: alsoProvidesCadence ?? this.alsoProvidesCadence,
    );
  }
}
