import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ble_cadence_service.dart';
import '../data/ble_permissions.dart';
import '../domain/cadence_speed_calculator.dart';
import '../domain/discovered_device.dart';
import 'power_providers.dart' show powerSourcedCadenceRpmProvider;
import 'sensors_providers.dart' show SensorConnectionStatus;
import 'speed_providers.dart' show speedSourcedCadenceRpmProvider;

class CadenceConnectionState {
  final SensorConnectionStatus status;
  final List<DiscoveredDevice> discoveredDevices;
  final String? connectedDeviceName;
  final int reconnectTimeoutSeconds;
  final bool showReconnectAlert;

  const CadenceConnectionState({
    this.status = SensorConnectionStatus.disconnected,
    this.discoveredDevices = const [],
    this.connectedDeviceName,
    this.reconnectTimeoutSeconds = 60,
    this.showReconnectAlert = false,
  });

  CadenceConnectionState copyWith({
    SensorConnectionStatus? status,
    List<DiscoveredDevice>? discoveredDevices,
    String? connectedDeviceName,
    int? reconnectTimeoutSeconds,
    bool? showReconnectAlert,
  }) {
    return CadenceConnectionState(
      status: status ?? this.status,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      reconnectTimeoutSeconds:
          reconnectTimeoutSeconds ?? this.reconnectTimeoutSeconds,
      showReconnectAlert: showReconnectAlert ?? this.showReconnectAlert,
    );
  }
}

const _prefsLastDeviceIdKey = 'last_cadence_device_id';

class CadenceSensorController extends StateNotifier<CadenceConnectionState> {
  final BleCadenceService _bleService;
  final Ref _ref;
  final CadenceSpeedCalculator _calculator = CadenceSpeedCalculator();

  StreamSubscription<List<DiscoveredDevice>>? _scanSubscription;
  StreamSubscription? _cscSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  Timer? _reconnectAlertTimer;
  BluetoothDevice? _connectedDevice;

  CadenceSensorController(this._bleService, this._ref)
    : super(const CadenceConnectionState());

  Future<void> startScan() async {
    final permissionsGranted = await BlePermissions.requestAll();
    if (!permissionsGranted) {
      throw StateError(
        'Se necesitan permisos de Bluetooth y ubicación para buscar '
        'sensores.',
      );
    }

    state = state.copyWith(
      status: SensorConnectionStatus.scanning,
      discoveredDevices: [],
    );

    _scanSubscription = _bleService.scanForCadenceSensors().listen((
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
    _calculator.reset();

    try {
      final bleDevice = await _bleService.connect(device.id);
      _connectedDevice = bleDevice;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsLastDeviceIdKey, device.id);

      _cscSubscription = _bleService.watchCadence(bleDevice).listen((
        reading,
      ) {
        // Esta tarjeta solo es dueña de la cadencia -- si el
        // dispositivo también trae datos de rueda, se ignoran (esa
        // velocidad debe venir de la tarjeta de Velocidad, si el
        // usuario decide conectar el mismo aparato ahí también).
        if (!reading.hasCrankData) return;

        final rpm = _calculator.updateCadenceRpm(
          cumulativeCrankRevolutions: reading.cumulativeCrankRevolutions!,
          lastCrankEventTime: reading.lastCrankEventTime!,
        );
        if (rpm != null) {
          _ref.read(dedicatedCadenceRpmProvider.notifier).state = rpm;
        }
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
      _ref.read(dedicatedCadenceRpmProvider.notifier).state = null;
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
    } catch (_) {
      // Reintento fallido; el usuario puede reintentar manualmente.
    }
  }

  void setReconnectTimeoutSeconds(int seconds) {
    state = state.copyWith(reconnectTimeoutSeconds: seconds);
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _bleService.disconnect(_connectedDevice!);
    }
    await _cscSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _reconnectAlertTimer?.cancel();
    _connectedDevice = null;
    _calculator.reset();
    _ref.read(dedicatedCadenceRpmProvider.notifier).state = null;
    state = const CadenceConnectionState();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _cscSubscription?.cancel();
    _connectionSubscription?.cancel();
    _reconnectAlertTimer?.cancel();
    super.dispose();
  }
}

/// Cadencia derivada del sensor de CADENCIA dedicado. NO es pública --
/// ver `cadenceRpmProvider` más abajo para la fusión real.
final dedicatedCadenceRpmProvider = StateProvider<double?>((ref) => null);

/// Cadencia "oficial" que debe leer el resto de la app (cockpit,
/// grabación de actividad, etc). Prioridad:
///   1. Medidor de potencia (si trae datos de manivela) -- ya lo tenías
///      conectado para potencia, es la fuente más "gratis".
///   2. Sensor de cadencia dedicado -- un aparato hecho específicamente
///      para esto.
///   3. Sensor de velocidad marcado como "combo" -- respaldo para
///      cuando el mismo aparato que da velocidad también da cadencia y
///      el usuario no tiene (o no quiere usar) un sensor dedicado.
final cadenceRpmProvider = Provider<double?>((ref) {
  final fromPower = ref.watch(powerSourcedCadenceRpmProvider);
  if (fromPower != null) return fromPower;

  final fromDedicated = ref.watch(dedicatedCadenceRpmProvider);
  if (fromDedicated != null) return fromDedicated;

  return ref.watch(speedSourcedCadenceRpmProvider);
});

final bleCadenceServiceProvider = Provider<BleCadenceService>((ref) {
  return BleCadenceService();
});

final cadenceSensorControllerProvider =
    StateNotifierProvider<CadenceSensorController, CadenceConnectionState>((
      ref,
    ) {
      final service = ref.read(bleCadenceServiceProvider);
      return CadenceSensorController(service, ref);
    });
