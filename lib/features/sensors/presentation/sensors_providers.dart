import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/heart_rate_provider.dart';
import '../data/ble_heart_rate_service.dart';
import '../data/ble_permissions.dart';
import '../domain/discovered_device.dart';

enum SensorConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
}

class SensorsState {
  final SensorConnectionStatus status;
  final List<DiscoveredDevice> discoveredDevices;
  final String? connectedDeviceName;

  /// Tiempo de espera, en segundos, antes de mostrar una alerta al
  /// usuario si el sensor no logra reconectarse tras una desconexión.
  /// Configurable desde la UI, tal como se definió en el discovery.
  final int reconnectTimeoutSeconds;
  final bool showReconnectAlert;

  const SensorsState({
    this.status = SensorConnectionStatus.disconnected,
    this.discoveredDevices = const [],
    this.connectedDeviceName,
    this.reconnectTimeoutSeconds = 60,
    this.showReconnectAlert = false,
  });

  SensorsState copyWith({
    SensorConnectionStatus? status,
    List<DiscoveredDevice>? discoveredDevices,
    String? connectedDeviceName,
    int? reconnectTimeoutSeconds,
    bool? showReconnectAlert,
  }) {
    return SensorsState(
      status: status ?? this.status,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      reconnectTimeoutSeconds:
          reconnectTimeoutSeconds ?? this.reconnectTimeoutSeconds,
      showReconnectAlert: showReconnectAlert ?? this.showReconnectAlert,
    );
  }
}

const _prefsLastDeviceIdKey = 'last_heart_rate_device_id';

class SensorsController extends StateNotifier<SensorsState> {
  final BleHeartRateService _bleService;
  final Ref _ref;

  StreamSubscription<List<DiscoveredDevice>>? _scanSubscription;
  StreamSubscription? _heartRateSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  Timer? _reconnectAlertTimer;
  BluetoothDevice? _connectedDevice;

  SensorsController(this._bleService, this._ref)
    : super(const SensorsState());

  Future<void> startScan() async {
    final permissionsGranted = await BlePermissions.requestAll();
    if (!permissionsGranted) {
      throw StateError(
        'Se necesitan permisos de Bluetooth y ubicación para buscar sensores.',
      );
    }

    state = state.copyWith(
      status: SensorConnectionStatus.scanning,
      discoveredDevices: [],
    );

    _scanSubscription = _bleService.scanForHeartRateSensors().listen((
      devices,
    ) {
      state = state.copyWith(discoveredDevices: devices);
    });
  }

  Future<void> stopScan() async {
    await _bleService.stopScan();
    await _scanSubscription?.cancel();
    if (state.status == SensorConnectionStatus.scanning) {
      state = state.copyWith(status: SensorConnectionStatus.disconnected);
    }
  }

  Future<void> connectTo(DiscoveredDevice device) async {
    await stopScan();
    state = state.copyWith(status: SensorConnectionStatus.connecting);

    try {
      final bleDevice = await _bleService.connect(device.id);
      _connectedDevice = bleDevice;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsLastDeviceIdKey, device.id);

      _heartRateSubscription = _bleService.watchHeartRate(bleDevice).listen((
        reading,
      ) {
        // Este es el único lugar de toda la app donde se escribe el bpm
        // real -- el resto de la app (panel del mapa, futuro motor
        // difuso) solo lee heartRateBpmProvider sin saber que existe BLE.
        _ref.read(heartRateBpmProvider.notifier).state = reading.bpm;
      });

      _connectionSubscription = _bleService
          .watchConnectionState(bleDevice)
          .listen(_onConnectionStateChanged);

      state = state.copyWith(
        status: SensorConnectionStatus.connected,
        connectedDeviceName: device.name,
        showReconnectAlert: false,
      );
    } catch (e) {
      state = state.copyWith(status: SensorConnectionStatus.disconnected);
      rethrow;
    }
  }

  void _onConnectionStateChanged(BluetoothConnectionState connectionState) {
    if (connectionState == BluetoothConnectionState.disconnected) {
      state = state.copyWith(status: SensorConnectionStatus.reconnecting);
      _ref.read(heartRateBpmProvider.notifier).state = null;
      _startReconnectAlertTimer();
      _attemptAutoReconnect();
    } else if (connectionState == BluetoothConnectionState.connected) {
      _reconnectAlertTimer?.cancel();
      state = state.copyWith(
        status: SensorConnectionStatus.connected,
        showReconnectAlert: false,
      );
    }
  }

  void _startReconnectAlertTimer() {
    _reconnectAlertTimer?.cancel();
    _reconnectAlertTimer = Timer(
      Duration(seconds: state.reconnectTimeoutSeconds),
      () {
        // Solo mostramos la alerta si, tras el tiempo configurado, el
        // sensor SIGUE sin reconectar.
        if (state.status == SensorConnectionStatus.reconnecting) {
          state = state.copyWith(showReconnectAlert: true);
        }
      },
    );
  }

  Future<void> _attemptAutoReconnect() async {
    if (_connectedDevice == null) return;
    try {
      await _connectedDevice!.connect(autoConnect: false);
      // Si funciona, watchConnectionState() ya va a emitir "connected"
      // y _onConnectionStateChanged se encarga del resto.
    } catch (_) {
      // El reintento falló; el usuario puede reintentar manualmente
      // desde la pantalla, o esperará al próximo intento si el sistema
      // operativo dispara otro evento de conexión.
    }
  }

  void setReconnectTimeoutSeconds(int seconds) {
    state = state.copyWith(reconnectTimeoutSeconds: seconds);
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _bleService.disconnect(_connectedDevice!);
    }
    await _heartRateSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _reconnectAlertTimer?.cancel();
    _connectedDevice = null;
    _ref.read(heartRateBpmProvider.notifier).state = null;
    state = const SensorsState();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _heartRateSubscription?.cancel();
    _connectionSubscription?.cancel();
    _reconnectAlertTimer?.cancel();
    super.dispose();
  }
}

final bleHeartRateServiceProvider = Provider<BleHeartRateService>((ref) {
  return BleHeartRateService();
});

final sensorsControllerProvider =
    StateNotifierProvider<SensorsController, SensorsState>((ref) {
      final service = ref.read(bleHeartRateServiceProvider);
      return SensorsController(service, ref);
    });
