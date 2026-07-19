import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ble_permissions.dart';
import '../data/ble_speed_service.dart';
import '../data/wheel_size_repository.dart';
import '../domain/cadence_speed_calculator.dart';
import '../domain/discovered_device.dart';
import 'sensors_providers.dart' show SensorConnectionStatus;

class SpeedConnectionState {
  final SensorConnectionStatus status;
  final List<DiscoveredDevice> discoveredDevices;
  final String? connectedDeviceName;
  final int reconnectTimeoutSeconds;
  final bool showReconnectAlert;

  /// true cuando el sensor ya está conectado y reporta datos de rueda,
  /// pero todavía no hay una circunferencia configurada -- la UI debe
  /// mostrar el popup de talla de llanta cuando esto se activa.
  final bool needsWheelSizeSetup;

  /// El usuario marca esto cuando sabe que su sensor de velocidad es en
  /// realidad un combo de un solo aparato que también reporta cadencia
  /// (manivela) -- así no necesita conectar el mismo dispositivo por
  /// segunda vez en la tarjeta de Cadencia. Si el dispositivo conectado
  /// no trae datos de manivela, esto simplemente no produce nada (no es
  /// perjudicial dejarlo marcado por error).
  final bool alsoProvidesCadence;

  const SpeedConnectionState({
    this.status = SensorConnectionStatus.disconnected,
    this.discoveredDevices = const [],
    this.connectedDeviceName,
    this.reconnectTimeoutSeconds = 60,
    this.showReconnectAlert = false,
    this.needsWheelSizeSetup = false,
    this.alsoProvidesCadence = false,
  });

  SpeedConnectionState copyWith({
    SensorConnectionStatus? status,
    List<DiscoveredDevice>? discoveredDevices,
    String? connectedDeviceName,
    int? reconnectTimeoutSeconds,
    bool? showReconnectAlert,
    bool? needsWheelSizeSetup,
    bool? alsoProvidesCadence,
  }) {
    return SpeedConnectionState(
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

const _prefsLastDeviceIdKey = 'last_speed_device_id';

class SpeedSensorController extends StateNotifier<SpeedConnectionState> {
  final BleSpeedService _bleService;
  final WheelSizeRepository _wheelSizeRepository;
  final Ref _ref;
  final CadenceSpeedCalculator _calculator = CadenceSpeedCalculator();

  StreamSubscription<List<DiscoveredDevice>>? _scanSubscription;
  StreamSubscription? _cscSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  Timer? _reconnectAlertTimer;
  BluetoothDevice? _connectedDevice;
  double? _wheelCircumferenceMm;

  SpeedSensorController(
    this._bleService,
    this._wheelSizeRepository,
    this._ref,
  ) : super(const SpeedConnectionState()) {
    _loadWheelCircumference();
  }

  Future<void> _loadWheelCircumference() async {
    _wheelCircumferenceMm = await _wheelSizeRepository.loadCircumferenceMm();
  }

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

    _scanSubscription = _bleService.scanForSpeedSensors().listen((devices) {
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

      _cscSubscription = _bleService.watchSpeed(bleDevice).listen((reading) {
        // Solo se procesa cadencia si el usuario marcó explícitamente
        // que este sensor es un combo -- de lo contrario, aunque el
        // dispositivo traiga datos de manivela, esta tarjeta los ignora
        // (esa cadencia debe venir de la tarjeta de Cadencia dedicada).
        if (state.alsoProvidesCadence && reading.hasCrankData) {
          final rpm = _calculator.updateCadenceRpm(
            cumulativeCrankRevolutions: reading.cumulativeCrankRevolutions!,
            lastCrankEventTime: reading.lastCrankEventTime!,
          );
          if (rpm != null) {
            _ref.read(speedSourcedCadenceRpmProvider.notifier).state = rpm;
          }
        }

        if (reading.hasWheelData) {
          if (_wheelCircumferenceMm == null) {
            // Ya llegan datos de rueda pero no sabemos la circunferencia
            // -- la UI debe pedirla antes de poder calcular velocidad.
            if (!state.needsWheelSizeSetup) {
              state = state.copyWith(needsWheelSizeSetup: true);
            }
            return;
          }

          final kmh = _calculator.updateSpeedKmh(
            cumulativeWheelRevolutions: reading.cumulativeWheelRevolutions!,
            lastWheelEventTime: reading.lastWheelEventTime!,
            wheelCircumferenceMm: _wheelCircumferenceMm!,
          );
          if (kmh != null) {
            _ref.read(speedKmhProvider.notifier).state = kmh;
          }
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

  /// Llamado desde el popup de configuración cuando el usuario elige o
  /// ingresa la circunferencia de su rueda. Se persiste para no volver
  /// a preguntar; desde ese momento las siguientes lecturas de rueda ya
  /// calculan velocidad con normalidad.
  Future<void> setWheelCircumferenceMm(double mm) async {
    _wheelCircumferenceMm = mm;
    await _wheelSizeRepository.saveCircumferenceMm(mm);
    state = state.copyWith(needsWheelSizeSetup: false);
  }

  /// Activa/desactiva el modo "sensor combo" (ver comentario del campo
  /// en `SpeedConnectionState`). Si se desactiva, se limpia cualquier
  /// cadencia que este sensor hubiera aportado, para no dejar un valor
  /// "fantasma" en `speedSourcedCadenceRpmProvider`.
  void setAlsoProvidesCadence(bool value) {
    state = state.copyWith(alsoProvidesCadence: value);
    if (!value) {
      _ref.read(speedSourcedCadenceRpmProvider.notifier).state = null;
    }
  }

  void _onConnectionStateChanged(BluetoothConnectionState connectionState) {
    if (connectionState == BluetoothConnectionState.disconnected) {
      state = state.copyWith(status: SensorConnectionStatus.reconnecting);
      _ref.read(speedKmhProvider.notifier).state = null;
      _ref.read(speedSourcedCadenceRpmProvider.notifier).state = null;
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
    _ref.read(speedKmhProvider.notifier).state = null;
    _ref.read(speedSourcedCadenceRpmProvider.notifier).state = null;
    // alsoProvidesCadence se reinicia a false a propósito: es una
    // propiedad de ESTE dispositivo conectado, no una preferencia
    // general -- si luego conectas un sensor distinto, no debería
    // heredar el flag del anterior.
    state = const SpeedConnectionState();
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

/// Velocidad en km/h en tiempo real. El resto de la app la lee sin
/// saber que existe BLE detrás.
final speedKmhProvider = StateProvider<double?>((ref) => null);

/// Cadencia derivada del sensor de VELOCIDAD cuando el usuario marcó que
/// es un combo (`alsoProvidesCadence`). NO es pública -- ver
/// `cadenceRpmProvider` en cadence_providers.dart para la fusión real
/// (potencia > cadencia dedicada > este combo).
final speedSourcedCadenceRpmProvider = StateProvider<double?>((ref) => null);

final bleSpeedServiceProvider = Provider<BleSpeedService>((ref) {
  return BleSpeedService();
});

final wheelSizeRepositoryProvider = Provider<WheelSizeRepository>((ref) {
  return WheelSizeRepository();
});

final speedSensorControllerProvider =
    StateNotifierProvider<SpeedSensorController, SpeedConnectionState>((ref) {
      final service = ref.read(bleSpeedServiceProvider);
      final wheelSizeRepository = ref.read(wheelSizeRepositoryProvider);
      return SpeedSensorController(service, wheelSizeRepository, ref);
    });
