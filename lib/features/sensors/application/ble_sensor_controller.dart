import 'dart:async';

import 'package:flutter/foundation.dart' show protected;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ble_permissions.dart';
import '../data/ble_sensor_service.dart';
import '../domain/discovered_device.dart';
import '../domain/sensor_kind.dart';
import 'sensor_connection_state.dart';

/// Controlador genérico de UN sensor BLE. Reemplaza a los cuatro
/// `StateNotifier` casi idénticos (FC / potencia / velocidad / cadencia,
/// ~200 líneas cada uno): todo el flujo escanear -> conectar -> perder
/// señal -> reconectar -> desconectar vive aquí una sola vez.
///
/// Cada tipo de sensor es una subclase mínima que sólo aporta:
/// - [handleReading]: qué hacer con cada lectura (escribir los providers
///   en vivo, y en Velocidad además el odómetro / talla de rueda).
/// - [clearLiveOutputs]: poner a `null` esos providers al caer la señal.
abstract class BleSensorController<R>
    extends StateNotifier<SensorConnectionState> {
  BleSensorController({
    required this.kind,
    required BleSensorService<R> service,
    required Ref ref,
    Future<bool> Function()? requestPermissions,
  }) : _service = service,
       _ref = ref,
       _requestPermissions = requestPermissions ?? BlePermissions.requestAll,
       super(const SensorConnectionState());

  final SensorKind kind;
  final BleSensorService<R> _service;
  final Ref _ref;
  final Future<bool> Function() _requestPermissions;

  @protected
  Ref get ref => _ref;

  static const _missingPermissionsMessage =
      'Se necesitan permisos de Bluetooth y ubicación para buscar sensores.';

  StreamSubscription<List<DiscoveredDevice>>? _scanSub;
  StreamSubscription<R>? _readingSub;
  StreamSubscription<SensorLinkState>? _linkSub;
  Timer? _reconnectAlertTimer;
  SensorLink<R>? _link;

  // --- Ganchos para las subclases -----------------------------------

  /// Procesa una lectura del sensor. Llamado en el hilo de la app.
  @protected
  void handleReading(R reading);

  /// Pone a `null` los providers en vivo de este sensor (al perder señal
  /// o desconectar).
  @protected
  void clearLiveOutputs();

  /// Se llama justo antes de intentar conectar -- para resetear
  /// calculadores/odómetros de la subclase.
  @protected
  void onBeforeConnect() {}

  /// Se llama al final de [disconnect], después de limpiar el estado.
  @protected
  void onAfterDisconnect() {}

  // --- Flujo compartido --------------------------------------------

  Future<void> startScan() async {
    final granted = await _requestPermissions();
    if (!granted) throw StateError(_missingPermissionsMessage);

    state = state.copyWith(
      status: SensorConnectionStatus.scanning,
      discoveredDevices: const [],
    );

    _scanSub = _service.scan().listen((devices) {
      state = state.copyWith(discoveredDevices: devices);
    });
  }

  Future<void> stopScan() async {
    await _service.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    if (state.status == SensorConnectionStatus.scanning) {
      state = state.copyWith(status: SensorConnectionStatus.disconnected);
    }
  }

  Future<void> connectTo(DiscoveredDevice device) async {
    await stopScan();
    state = state.copyWith(status: SensorConnectionStatus.connecting);
    onBeforeConnect();

    try {
      final link = await _service.connect(device.id);
      _link = link;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kind.lastDeviceIdPrefsKey, device.id);

      _readingSub = link.readings().listen(handleReading);
      _linkSub = link.connectionState().listen(_onLinkStateChanged);

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

  void _onLinkStateChanged(SensorLinkState link) {
    switch (link) {
      case SensorLinkState.disconnected:
        state = state.copyWith(status: SensorConnectionStatus.reconnecting);
        clearLiveOutputs();
        _startReconnectAlertTimer();
        _attemptReconnect();
      case SensorLinkState.connected:
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
        // Sólo avisamos si tras el tiempo configurado SIGUE sin señal.
        if (state.status == SensorConnectionStatus.reconnecting) {
          state = state.copyWith(showReconnectAlert: true);
        }
      },
    );
  }

  Future<void> _attemptReconnect() async {
    final link = _link;
    if (link == null) return;
    try {
      await link.reconnect();
      // Si funciona, connectionState() emitirá "connected" y
      // _onLinkStateChanged se encarga del resto.
    } catch (_) {
      // Reintento fallido; el usuario puede reintentar manualmente.
    }
  }

  /// Reintento manual desde la UI ("Reintentar ahora").
  Future<void> retryConnection() => _attemptReconnect();

  void setReconnectTimeoutSeconds(int seconds) {
    state = state.copyWith(reconnectTimeoutSeconds: seconds);
  }

  Future<void> disconnect() async {
    final link = _link;
    if (link != null) await link.disconnect();
    await _readingSub?.cancel();
    await _linkSub?.cancel();
    _reconnectAlertTimer?.cancel();
    _readingSub = null;
    _linkSub = null;
    _link = null;
    clearLiveOutputs();
    state = const SensorConnectionState();
    onAfterDisconnect();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _readingSub?.cancel();
    _linkSub?.cancel();
    _reconnectAlertTimer?.cancel();
    super.dispose();
  }
}
