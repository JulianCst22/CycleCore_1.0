  import 'dart:async';

  import 'package:flutter_blue_plus/flutter_blue_plus.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  import '../data/ble_permissions.dart';
  import '../data/ble_power_service.dart';
  import '../domain/cadence_speed_calculator.dart';
  import '../domain/discovered_device.dart';
  import 'sensors_providers.dart' show SensorConnectionStatus;

  class PowerConnectionState {
    final SensorConnectionStatus status;
    final List<DiscoveredDevice> discoveredDevices;
    final String? connectedDeviceName;
    final int reconnectTimeoutSeconds;
    final bool showReconnectAlert;

    const PowerConnectionState({
      this.status = SensorConnectionStatus.disconnected,
      this.discoveredDevices = const [],
      this.connectedDeviceName,
      this.reconnectTimeoutSeconds = 60,
      this.showReconnectAlert = false,
    });

    PowerConnectionState copyWith({
      SensorConnectionStatus? status,
      List<DiscoveredDevice>? discoveredDevices,
      String? connectedDeviceName,
      int? reconnectTimeoutSeconds,
      bool? showReconnectAlert,
    }) {
      return PowerConnectionState(
        status: status ?? this.status,
        discoveredDevices: discoveredDevices ?? this.discoveredDevices,
        connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
        reconnectTimeoutSeconds:
            reconnectTimeoutSeconds ?? this.reconnectTimeoutSeconds,
        showReconnectAlert: showReconnectAlert ?? this.showReconnectAlert,
      );
    }
  }

  const _prefsLastDeviceIdKey = 'last_power_device_id';

  class PowerSensorController extends StateNotifier<PowerConnectionState> {
    final BleCyclingPowerService _bleService;
    final Ref _ref;
    final CadenceSpeedCalculator _cadenceCalculator = CadenceSpeedCalculator();

    StreamSubscription<List<DiscoveredDevice>>? _scanSubscription;
    StreamSubscription? _powerSubscription;
    StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
    Timer? _reconnectAlertTimer;
    BluetoothDevice? _connectedDevice;

    PowerSensorController(this._bleService, this._ref)
      : super(const PowerConnectionState());

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

      _scanSubscription = _bleService.scanForPowerSensors().listen((devices) {
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
      _cadenceCalculator.reset();

      try {
        final bleDevice = await _bleService.connect(device.id);
        _connectedDevice = bleDevice;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsLastDeviceIdKey, device.id);

        _powerSubscription = _bleService.watchPower(bleDevice).listen((
          reading,
        ) {
          // Único lugar de toda la app donde se escribe la potencia real
          // -- el resto de la app solo lee powerWattsProvider, igual que
          // ya pasa con heartRateBpmProvider.
          _ref.read(powerWattsProvider.notifier).state =
              reading.instantaneousPowerWatts;

          if (reading.hasCrankData) {
            final rpm = _cadenceCalculator.updateCadenceRpm(
              cumulativeCrankRevolutions: reading.cumulativeCrankRevolutions!,
              lastCrankEventTime: reading.lastCrankEventTime!,
            );
            if (rpm != null) {
              _ref.read(powerSourcedCadenceRpmProvider.notifier).state = rpm;
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

    void _onConnectionStateChanged(BluetoothConnectionState connectionState) {
      if (connectionState == BluetoothConnectionState.disconnected) {
        state = state.copyWith(status: SensorConnectionStatus.reconnecting);
        _ref.read(powerWattsProvider.notifier).state = null;
        _ref.read(powerSourcedCadenceRpmProvider.notifier).state = null;
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
      await _powerSubscription?.cancel();
      await _connectionSubscription?.cancel();
      _reconnectAlertTimer?.cancel();
      _connectedDevice = null;
      _cadenceCalculator.reset();
      _ref.read(powerWattsProvider.notifier).state = null;
      _ref.read(powerSourcedCadenceRpmProvider.notifier).state = null;
      state = const PowerConnectionState();
    }

    @override
    void dispose() {
      _scanSubscription?.cancel();
      _powerSubscription?.cancel();
      _connectionSubscription?.cancel();
      _reconnectAlertTimer?.cancel();
      super.dispose();
    }
  }

  /// Potencia en vatios en tiempo real. El resto de la app (cockpit,
  /// grabación de actividad, futuro motor de esfuerzo) lee esto sin saber
  /// que existe BLE detrás -- mismo patrón que heartRateBpmProvider.
  final powerWattsProvider = StateProvider<int?>((ref) => null);

  /// Cadencia derivada del medidor de potencia (si trae datos de
  /// manivela). NO es pública -- la cadencia "oficial" que lee el resto de
  /// la app es `cadenceRpmProvider` (en cadence_speed_providers.dart), que
  /// fusiona esta fuente con la del sensor CSC dedicado.
  final powerSourcedCadenceRpmProvider = StateProvider<double?>((ref) => null);

  final bleCyclingPowerServiceProvider = Provider<BleCyclingPowerService>((
    ref,
  ) {
    return BleCyclingPowerService();
  });

  final powerSensorControllerProvider =
      StateNotifierProvider<PowerSensorController, PowerConnectionState>((ref) {
        final service = ref.read(bleCyclingPowerServiceProvider);
        return PowerSensorController(service, ref);
      });
