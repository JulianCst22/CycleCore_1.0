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
/// - [onTick]: revisar una vez por segundo si el dato quedó viejo.
abstract class BleSensorController<R>
    extends StateNotifier<SensorConnectionState> {
  BleSensorController({
    required this.kind,
    required BleSensorService<R> service,
    required Ref ref,
    Future<bool> Function()? requestPermissions,
    this.retryDelay = const Duration(seconds: 3),
  }) : _service = service,
       _ref = ref,
       _requestPermissions = requestPermissions ?? BlePermissions.requestAll,
       super(const SensorConnectionState());

  final SensorKind kind;
  final BleSensorService<R> _service;
  final Ref _ref;
  final Future<bool> Function() _requestPermissions;

  /// Pausa entre dos intentos de reconexión.
  final Duration retryDelay;

  @protected
  Ref get ref => _ref;

  static const _missingPermissionsMessage =
      'Se necesitan permisos de Bluetooth y ubicación para buscar sensores.';

  StreamSubscription<List<DiscoveredDevice>>? _scanSub;
  StreamSubscription<R>? _readingSub;
  StreamSubscription<SensorLinkState>? _linkSub;
  Timer? _reconnectAlertTimer;
  Timer? _watchdog;
  SensorLink<R>? _link;
  bool _reconnecting = false;

  /// Instante de la última lectura que llegó del sensor. Sirve para
  /// notar un sensor que sigue "conectado" pero dejó de mandar datos.
  DateTime? _lastReadingAt;

  @protected
  DateTime? get lastReadingAt => _lastReadingAt;

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

  /// Se llama cuando el enlace se cae: los contadores de revoluciones
  /// tienen que volver a tomar referencia, o la primera lectura tras la
  /// reconexión daría un pico absurdo.
  @protected
  void onLinkLost() {}

  /// Revisión de cada segundo mientras el sensor está conectado. Las
  /// subclases deciden qué hacer si el dato quedó viejo: el pulso y la
  /// potencia se borran (no se sabe cuánto valen), la cadencia y la
  /// velocidad pasan a cero (la biela o la rueda se detuvieron).
  @protected
  void onTick(DateTime now) {}

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

      _readingSub = link.readings().listen(_onReading, onError: (_) {});
      _linkSub = link.connectionState().listen(_onLinkStateChanged);
      _startWatchdog();

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

  void _onReading(R reading) {
    _lastReadingAt = DateTime.now();
    if (!mounted) return;
    handleReading(reading);
  }

  void _onLinkStateChanged(SensorLinkState link) {
    if (_link == null || !mounted) return;
    switch (link) {
      case SensorLinkState.disconnected:
        if (state.status == SensorConnectionStatus.reconnecting) return;
        state = state.copyWith(status: SensorConnectionStatus.reconnecting);
        clearLiveOutputs();
        onLinkLost();
        _startReconnectAlertTimer();
        unawaited(_reconnectLoop());
      case SensorLinkState.connected:
        _reconnectAlertTimer?.cancel();
        if (state.status != SensorConnectionStatus.connected) {
          state = state.copyWith(
            status: SensorConnectionStatus.connected,
            showReconnectAlert: false,
          );
        }
    }
  }

  void _startReconnectAlertTimer() {
    _reconnectAlertTimer?.cancel();
    _reconnectAlertTimer = Timer(
      Duration(seconds: state.reconnectTimeoutSeconds),
      () {
        // Sólo avisamos si tras el tiempo configurado SIGUE sin señal.
        if (mounted && state.status == SensorConnectionStatus.reconnecting) {
          state = state.copyWith(showReconnectAlert: true);
        }
      },
    );
  }

  /// Reintenta hasta que el sensor vuelva o el usuario lo desconecte.
  /// Un solo intento no sirve en carretera: si la banda se alejó un
  /// momento (o el ciclista se bajó de la bici), el primer intento falla
  /// y el sensor quedaba perdido el resto de la salida.
  Future<void> _reconnectLoop() async {
    if (_reconnecting) return;
    _reconnecting = true;
    try {
      while (mounted &&
          _link != null &&
          state.status == SensorConnectionStatus.reconnecting) {
        final link = _link!;
        try {
          await link.reconnect();
          // El enlace avisa "connected" por su stream; por si el paquete
          // no emitiera el cambio, se da por recuperado acá también.
          if (mounted && identical(link, _link)) {
            _onLinkStateChanged(SensorLinkState.connected);
          }
          return;
        } catch (_) {
          await Future<void>.delayed(retryDelay);
        }
      }
    } finally {
      _reconnecting = false;
    }
  }

  /// Reintento manual desde la UI ("Reintentar ahora").
  Future<void> retryConnection() async {
    final link = _link;
    if (link == null) return;
    try {
      await link.reconnect();
      if (mounted && identical(link, _link)) {
        _onLinkStateChanged(SensorLinkState.connected);
      }
    } catch (_) {
      // El bucle de reconexión sigue intentando por su cuenta.
    }
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || state.status != SensorConnectionStatus.connected) return;
      onTick(DateTime.now());
    });
  }

  void setReconnectTimeoutSeconds(int seconds) {
    state = state.copyWith(reconnectTimeoutSeconds: seconds);
  }

  Future<void> disconnect() async {
    final link = _link;
    // Primero se olvida el enlace y se dejan de escuchar sus cambios: si
    // no, el "desconectado" que provoca el propio usuario arrancaría la
    // reconexión automática.
    _link = null;
    await _linkSub?.cancel();
    await _readingSub?.cancel();
    _reconnectAlertTimer?.cancel();
    _watchdog?.cancel();
    _readingSub = null;
    _linkSub = null;
    _watchdog = null;
    _lastReadingAt = null;
    if (link != null) {
      try {
        await link.disconnect();
      } catch (_) {
        // Ya estaba caído: no hay nada que cerrar.
      }
    }
    clearLiveOutputs();
    state = const SensorConnectionState();
    onAfterDisconnect();
  }

  @override
  void dispose() {
    _link = null;
    _scanSub?.cancel();
    _readingSub?.cancel();
    _linkSub?.cancel();
    _reconnectAlertTimer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }
}
