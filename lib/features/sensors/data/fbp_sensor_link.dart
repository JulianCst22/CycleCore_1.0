import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/discovered_device.dart';
import 'ble_sensor_service.dart';

/// Utilidades compartidas de `flutter_blue_plus` para los cuatro
/// `Ble*Service`. Toda la dependencia real de `flutter_blue_plus` en el
/// feature `sensors` vive aquí y en los cuatro servicios concretos --
/// si mañana cambia el paquete BLE, solo se toca esta capa.

/// Cuánto se espera a que un sensor conteste antes de dar el intento de
/// conexión por fallido. El valor por defecto del paquete (35 s) es
/// demasiado para un sensor que se cayó a mitad de una subida: mejor
/// reintentar seguido.
const _connectTimeout = Duration(seconds: 15);

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

/// Conecta con [deviceId], se suscribe a la característica
/// [characteristicUuid] del servicio [serviceUuid] y devuelve un
/// [SensorLink] cuyas lecturas ya vienen interpretadas con [parse].
///
/// Si el dispositivo no expone ese servicio se desconecta y se lanza un
/// [StateError] con [missingServiceMessage], para que la pantalla de
/// sensores lo muestre.
Future<SensorLink<R>> fbpConnect<R>(
  String deviceId, {
  required Guid serviceUuid,
  required Guid characteristicUuid,
  required R Function(List<int> data) parse,
  required String missingServiceMessage,
}) async {
  final device = BluetoothDevice.fromId(deviceId);
  await device.connect(autoConnect: false, mtu: null, timeout: _connectTimeout);
  final link = _FbpSensorLink<R>(
    device,
    serviceUuid: serviceUuid,
    characteristicUuid: characteristicUuid,
    parse: parse,
    missingServiceMessage: missingServiceMessage,
  );
  try {
    await link.subscribe();
  } catch (_) {
    await link.disconnect();
    rethrow;
  }
  link.watchConnection();
  return link;
}

/// Enlace con un sensor ya conectado.
///
/// Lo delicado es la reconexión: cuando un sensor se cae, Android olvida
/// sus servicios y la suscripción a las notificaciones. Volver a
/// conectar no basta -- hay que descubrir los servicios y pedir las
/// notificaciones otra vez, o el sensor queda "conectado" pero mudo.
/// Por eso cada vez que el enlace vuelve a quedar conectado se repite
/// [subscribe], y las lecturas salen siempre por el mismo stream.
class _FbpSensorLink<R> implements SensorLink<R> {
  _FbpSensorLink(
    this._device, {
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.parse,
    required this.missingServiceMessage,
  });

  final BluetoothDevice _device;
  final Guid serviceUuid;
  final Guid characteristicUuid;
  final R Function(List<int> data) parse;
  final String missingServiceMessage;

  final StreamController<R> _readings = StreamController<R>.broadcast();
  StreamSubscription<List<int>>? _valueSub;
  StreamSubscription<BluetoothConnectionState>? _stateSub;
  bool _closed = false;
  bool _subscribing = false;

  @override
  Stream<R> readings() => _readings.stream;

  @override
  Stream<SensorLinkState> connectionState() => _device.connectionState.map(
    (s) => s == BluetoothConnectionState.connected
        ? SensorLinkState.connected
        : SensorLinkState.disconnected,
  );

  /// Descubre los servicios y pide las notificaciones de la
  /// característica de medida.
  Future<void> subscribe() async {
    if (_closed || _subscribing) return;
    _subscribing = true;
    try {
      await _valueSub?.cancel();
      _valueSub = null;

      final services = await _device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid == serviceUuid,
        orElse: () => throw StateError(missingServiceMessage),
      );
      final characteristic = service.characteristics.firstWhere(
        (c) => c.uuid == characteristicUuid,
        orElse: () => throw StateError(missingServiceMessage),
      );

      // `onValueReceived` y no `lastValueStream`: este último repite el
      // último valor al suscribirse, y tras una reconexión ese valor ya
      // es viejo.
      _valueSub = characteristic.onValueReceived.listen(_onRaw);
      await characteristic.setNotifyValue(true);
    } finally {
      _subscribing = false;
    }
  }

  void _onRaw(List<int> raw) {
    if (raw.isEmpty || _readings.isClosed) return;
    try {
      _readings.add(parse(raw));
    } on Object {
      // Un paquete malformado se descarta; si se dejara pasar el error,
      // cortaría el stream y el sensor quedaría mudo hasta reconectarlo.
    }
  }

  /// Vuelve a suscribirse sola cada vez que el enlace se recupera.
  void watchConnection() {
    _stateSub = _device.connectionState.skip(1).listen((s) async {
      if (_closed) return;
      if (s == BluetoothConnectionState.connected) {
        try {
          await subscribe();
        } on Object {
          // Si falla, el siguiente intento de reconexión lo repite.
        }
      } else {
        await _valueSub?.cancel();
        _valueSub = null;
      }
    });
  }

  @override
  Future<void> reconnect() async {
    if (_closed) return;
    await _device.connect(
      autoConnect: false,
      mtu: null,
      timeout: _connectTimeout,
    );
    // Si el paquete ya estaba conectado no emite un cambio de estado:
    // se suscribe acá también (es idempotente).
    await subscribe();
  }

  @override
  Future<void> disconnect() async {
    _closed = true;
    await _stateSub?.cancel();
    await _valueSub?.cancel();
    _stateSub = null;
    _valueSub = null;
    try {
      await _device.disconnect();
    } finally {
      await _readings.close();
    }
  }
}
