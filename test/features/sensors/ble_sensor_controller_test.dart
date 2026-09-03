import 'dart:async';

import 'package:cyclecore_app/features/sensors/data/ble_sensor_service.dart';
import 'package:cyclecore_app/features/sensors/domain/discovered_device.dart';
import 'package:cyclecore_app/features/sensors/domain/sensor_kind.dart';
import 'package:cyclecore_app/features/sensors/presentation/ble_sensor_controller.dart';
import 'package:cyclecore_app/features/sensors/presentation/sensor_connection_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLink implements SensorLink<int> {
  final _readings = StreamController<int>.broadcast();
  final _link = StreamController<SensorLinkState>.broadcast();
  int reconnectCalls = 0;
  int disconnectCalls = 0;

  @override
  Stream<int> readings() => _readings.stream;
  @override
  Stream<SensorLinkState> connectionState() => _link.stream;
  @override
  Future<void> reconnect() async => reconnectCalls++;
  @override
  Future<void> disconnect() async => disconnectCalls++;

  void pushReading(int v) => _readings.add(v);
  void pushLink(SensorLinkState s) => _link.add(s);
  Future<void> close() async {
    await _readings.close();
    await _link.close();
  }
}

class _FakeService implements BleSensorService<int> {
  _FakeService(this.link);
  final _FakeLink link;
  bool connectThrows = false;
  int stopScanCalls = 0;
  final _scan = StreamController<List<DiscoveredDevice>>.broadcast();

  @override
  Stream<List<DiscoveredDevice>> scan({
    Duration timeout = const Duration(seconds: 1),
  }) => _scan.stream;

  @override
  Future<void> stopScan() async => stopScanCalls++;

  @override
  Future<SensorLink<int>> connect(String deviceId) async {
    if (connectThrows) throw StateError('no se pudo conectar');
    return link;
  }

  void pushScan(List<DiscoveredDevice> d) => _scan.add(d);
  Future<void> close() => _scan.close();
}

class _TestController extends BleSensorController<int> {
  _TestController(BleSensorService<int> service, Ref ref, {bool grant = true})
    : super(
        kind: SensorKind.heartRate,
        service: service,
        ref: ref,
        requestPermissions: () async => grant,
      );

  final readings = <int>[];
  int clearCalls = 0;
  int beforeConnect = 0;
  int afterDisconnect = 0;

  @override
  void handleReading(int reading) => readings.add(reading);
  @override
  void clearLiveOutputs() => clearCalls++;
  @override
  void onBeforeConnect() => beforeConnect++;
  @override
  void onAfterDisconnect() => afterDisconnect++;
}

const _device = DiscoveredDevice(id: 'aa:bb', name: 'Wahoo TICKR', rssi: -55);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late _FakeLink link;
  late _FakeService service;
  late ProviderContainer container;
  late StateNotifierProvider<_TestController, SensorConnectionState> provider;

  void build({bool grant = true}) {
    link = _FakeLink();
    service = _FakeService(link);
    provider = StateNotifierProvider(
      (ref) => _TestController(service, ref, grant: grant),
    );
    container = ProviderContainer();
  }

  tearDown(() async {
    container.dispose();
    await link.close();
    await service.close();
  });

  _TestController ctrl() => container.read(provider.notifier);
  SensorConnectionState st() => container.read(provider);

  test(
    'startScan pasa a "scanning" y publica los dispositivos hallados',
    () async {
      build();
      await ctrl().startScan();
      expect(st().status, SensorConnectionStatus.scanning);

      service.pushScan([_device]);
      await Future<void>.delayed(Duration.zero);
      expect(st().discoveredDevices, [_device]);
    },
  );

  test('sin permisos, startScan lanza y no queda escaneando', () async {
    build(grant: false);
    await expectLater(ctrl().startScan(), throwsStateError);
    expect(st().status, SensorConnectionStatus.disconnected);
  });

  test('stopScan detiene el escaneo y vuelve a "disconnected"', () async {
    build();
    await ctrl().startScan();
    await ctrl().stopScan();
    expect(service.stopScanCalls, 1);
    expect(st().status, SensorConnectionStatus.disconnected);
  });

  test('connectTo conecta, guarda el nombre y enruta las lecturas', () async {
    build();
    await ctrl().connectTo(_device);

    expect(st().status, SensorConnectionStatus.connected);
    expect(st().connectedDeviceName, 'Wahoo TICKR');
    expect(ctrl().beforeConnect, 1);
    expect(service.stopScanCalls, 1); // connectTo detiene el escaneo antes

    link.pushReading(148);
    link.pushReading(151);
    await Future<void>.delayed(Duration.zero);
    expect(ctrl().readings, [148, 151]);
  });

  test('si connect falla, vuelve a "disconnected" y propaga', () async {
    build();
    service.connectThrows = true;
    await expectLater(ctrl().connectTo(_device), throwsStateError);
    expect(st().status, SensorConnectionStatus.disconnected);
  });

  test(
    'perder señal → reconnecting + limpia salidas + reintenta solo',
    () async {
      build();
      await ctrl().connectTo(_device);

      link.pushLink(SensorLinkState.disconnected);
      await Future<void>.delayed(Duration.zero);

      expect(st().status, SensorConnectionStatus.reconnecting);
      expect(ctrl().clearCalls, 1);
      expect(link.reconnectCalls, 1);
      expect(st().showReconnectAlert, isFalse); // aún no salta la alerta
    },
  );

  test('recuperar la señal vuelve a "connected"', () async {
    build();
    await ctrl().connectTo(_device);
    link.pushLink(SensorLinkState.disconnected);
    await Future<void>.delayed(Duration.zero);
    link.pushLink(SensorLinkState.connected);
    await Future<void>.delayed(Duration.zero);

    expect(st().status, SensorConnectionStatus.connected);
    expect(st().showReconnectAlert, isFalse);
  });

  test('la alerta de reconexión salta tras el timeout configurado', () {
    fakeAsync((async) {
      build();
      ctrl().setReconnectTimeoutSeconds(3);
      unawaited(ctrl().connectTo(_device));
      async.flushMicrotasks();

      link.pushLink(SensorLinkState.disconnected);
      async.flushMicrotasks();
      expect(st().showReconnectAlert, isFalse);

      async.elapse(const Duration(seconds: 4));
      expect(st().showReconnectAlert, isTrue);
    });
  });

  test('disconnect limpia todo y restaura el estado por defecto', () async {
    build();
    await ctrl().connectTo(_device);
    await ctrl().disconnect();

    expect(link.disconnectCalls, 1);
    expect(ctrl().afterDisconnect, 1);
    expect(st().status, SensorConnectionStatus.disconnected);
    expect(st().connectedDeviceName, isNull);
    // Las lecturas posteriores al enlace cerrado ya no llegan.
    ctrl().readings.clear();
    link.pushReading(200);
    await Future<void>.delayed(Duration.zero);
    expect(ctrl().readings, isEmpty);
  });
}
