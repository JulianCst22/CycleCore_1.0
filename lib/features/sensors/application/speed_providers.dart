import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ble_sensor_service.dart';
import '../data/ble_speed_service.dart';
import '../data/wheel_size_repository.dart';
import '../domain/cadence_speed_calculator.dart';
import '../domain/cycling_speed_cadence_reading.dart';
import '../domain/revolution_stall_detector.dart';
import '../domain/sensor_kind.dart';
import 'ble_sensor_controller.dart';
import 'sensor_connection_state.dart';

/// Máximo del contador de revoluciones de rueda (uint32). El odómetro
/// lleva su PROPIO tracking de "última lectura", separado del que usa
/// `CadenceSpeedCalculator` para la velocidad instantánea, para que uno
/// no interfiera con el otro.
const _wheelCounterMax = 0x100000000;

/// Sin un evento de rueda nuevo en este tiempo, la bici está quieta. Una
/// rueda de 2,1 m a 3 km/h tarda 2,5 s por vuelta.
const _wheelStallAfter = Duration(milliseconds: 3500);
const _crankStallAfter = Duration(seconds: 3);

/// Más rápido que esto (m/s, ~110 km/h) es un error de lectura o un
/// sensor que se reinició, no la bicicleta.
const _maxPlausibleMetersPerSecond = 30.0;
const _maxPlausibleCadenceRpm = 220.0;

/// Sensor de velocidad (rueda). El más complejo: además de km/h lleva un
/// odómetro (metros desde que se conectó, fuente de distancia con
/// prioridad sobre el GPS), pide la talla de rueda la primera vez, y
/// puede aportar cadencia si el usuario lo marca como combo.
class SpeedSensorController
    extends BleSensorController<CyclingSpeedCadenceReading> {
  SpeedSensorController(
    BleSensorService<CyclingSpeedCadenceReading> service,
    this._wheelSizeRepository,
    Ref ref,
  ) : super(kind: SensorKind.speed, service: service, ref: ref) {
    _loadWheelCircumference();
  }

  final WheelSizeRepository _wheelSizeRepository;
  final CadenceSpeedCalculator _calculator = CadenceSpeedCalculator();
  final RevolutionStallDetector _wheel = RevolutionStallDetector(
    stallAfter: _wheelStallAfter,
  );
  final RevolutionStallDetector _crank = RevolutionStallDetector(
    stallAfter: _crankStallAfter,
  );
  double? _wheelCircumferenceMm;

  double _odometerMeters = 0;
  int? _lastOdometerWheelRevs;
  DateTime? _lastOdometerAt;

  Future<void> _loadWheelCircumference() async {
    _wheelCircumferenceMm = await _wheelSizeRepository.loadCircumferenceMm();
  }

  @override
  void onBeforeConnect() {
    _resetCounters();
    _odometerMeters = 0;
    _lastOdometerWheelRevs = null;
    _lastOdometerAt = null;
  }

  /// Tras una caída del enlace la velocidad y la cadencia vuelven a tomar
  /// referencia, pero el odómetro NO se reinicia: el sensor siguió
  /// contando vueltas mientras tanto y esa distancia es real.
  @override
  void onLinkLost() => _resetCounters();

  void _resetCounters() {
    _calculator.reset();
    _wheel.reset();
    _crank.reset();
  }

  @override
  void onAfterDisconnect() {
    _resetCounters();
    _odometerMeters = 0;
    _lastOdometerWheelRevs = null;
    _lastOdometerAt = null;
    // alsoProvidesCadence vuelve a false a propósito -- es una propiedad
    // del dispositivo conectado, no una preferencia general. `disconnect`
    // ya restauró `SensorConnectionState()` por defecto.
  }

  @override
  void handleReading(CyclingSpeedCadenceReading reading) {
    // Sólo se procesa cadencia si el usuario marcó que este sensor es un
    // combo -- si no, aunque el dispositivo traiga manivela, esta tarjeta
    // la ignora (esa cadencia debe venir de la tarjeta de Cadencia).
    final now = DateTime.now();
    if (state.alsoProvidesCadence &&
        reading.hasCrankData &&
        _crank.observe(reading.lastCrankEventTime!, now)) {
      final rpm = _calculator.updateCadenceRpm(
        cumulativeCrankRevolutions: reading.cumulativeCrankRevolutions!,
        lastCrankEventTime: reading.lastCrankEventTime!,
      );
      if (rpm != null && rpm <= _maxPlausibleCadenceRpm) {
        ref.read(speedSourcedCadenceRpmProvider.notifier).state = rpm;
      }
    }

    if (!reading.hasWheelData) return;

    if (_wheelCircumferenceMm == null) {
      // Ya llegan datos de rueda pero no sabemos la circunferencia -- la
      // UI debe pedirla antes de poder calcular velocidad.
      if (!state.needsWheelSizeSetup) {
        state = state.copyWith(needsWheelSizeSetup: true);
      }
      return;
    }

    // Odómetro: metros totales desde la conexión, con su propio rollover
    // independiente del cálculo de velocidad instantánea (el calculador
    // necesita DOS lecturas para dar km/h; la distancia acumulada sólo
    // necesita el delta de revoluciones).
    final currentRevs = reading.cumulativeWheelRevolutions!;
    final lastRevs = _lastOdometerWheelRevs;
    final lastAt = _lastOdometerAt;
    if (lastRevs != null && lastAt != null) {
      var revDelta = currentRevs - lastRevs;
      if (revDelta < 0) revDelta += _wheelCounterMax;
      final meters = revDelta * (_wheelCircumferenceMm! / 1000);
      // Un salto imposible para el tiempo transcurrido es un sensor que
      // se reinició (pila, golpe): se toma la nueva referencia sin sumar.
      final seconds = now.difference(lastAt).inMilliseconds / 1000;
      if (meters <= _maxPlausibleMetersPerSecond * seconds + 20) {
        _odometerMeters += meters;
      }
      ref.read(speedDistanceMetersProvider.notifier).state = _odometerMeters;
    }
    _lastOdometerWheelRevs = currentRevs;
    _lastOdometerAt = now;

    if (!_wheel.observe(reading.lastWheelEventTime!, now)) return;
    final kmh = _calculator.updateSpeedKmh(
      cumulativeWheelRevolutions: currentRevs,
      lastWheelEventTime: reading.lastWheelEventTime!,
      wheelCircumferenceMm: _wheelCircumferenceMm!,
    );
    if (kmh != null && kmh <= _maxPlausibleMetersPerSecond * 3.6) {
      ref.read(speedKmhProvider.notifier).state = kmh;
    }
  }

  @override
  void onTick(DateTime now) {
    if (_wheel.checkStall(now)) {
      _calculator.resetWheel();
      if (ref.read(speedKmhProvider) != null) {
        ref.read(speedKmhProvider.notifier).state = 0;
      }
    }
    if (_crank.checkStall(now)) {
      _calculator.resetCrank();
      if (state.alsoProvidesCadence) {
        ref.read(speedSourcedCadenceRpmProvider.notifier).state = 0;
      }
    }
  }

  @override
  void clearLiveOutputs() {
    ref.read(speedKmhProvider.notifier).state = null;
    ref.read(speedDistanceMetersProvider.notifier).state = null;
    ref.read(speedSourcedCadenceRpmProvider.notifier).state = null;
  }

  /// Llamado desde la configuración de talla de rueda. Se persiste para
  /// no volver a preguntar; desde ese momento las lecturas de rueda ya
  /// calculan velocidad con normalidad.
  Future<void> setWheelCircumferenceMm(double mm) async {
    _wheelCircumferenceMm = mm;
    await _wheelSizeRepository.saveCircumferenceMm(mm);
    state = state.copyWith(needsWheelSizeSetup: false);
  }

  /// Activa/desactiva el modo "sensor combo". Al desactivarlo se limpia
  /// cualquier cadencia que este sensor hubiera aportado.
  void setAlsoProvidesCadence(bool value) {
    state = state.copyWith(alsoProvidesCadence: value);
    if (!value) {
      ref.read(speedSourcedCadenceRpmProvider.notifier).state = null;
    }
  }
}

/// Velocidad en km/h en tiempo real. El resto de la app la lee sin saber
/// que hay BLE detrás.
final speedKmhProvider = StateProvider<double?>((ref) => null);

/// Metros totales acumulados por el sensor de velocidad desde que se
/// conectó (no desde que arrancó la grabación). Null si no hay sensor.
final speedDistanceMetersProvider = StateProvider<double?>((ref) => null);

/// Cadencia derivada del sensor de VELOCIDAD cuando el usuario lo marcó
/// como combo. NO pública -- ver `cadenceRpmProvider`.
final speedSourcedCadenceRpmProvider = StateProvider<double?>((ref) => null);

final bleSpeedServiceProvider = Provider<BleSpeedService>(
  (ref) => BleSpeedService(),
);

final wheelSizeRepositoryProvider = Provider<WheelSizeRepository>(
  (ref) => WheelSizeRepository(),
);

final speedSensorControllerProvider =
    StateNotifierProvider<SpeedSensorController, SensorConnectionState>(
      (ref) => SpeedSensorController(
        ref.read(bleSpeedServiceProvider),
        ref.read(wheelSizeRepositoryProvider),
        ref,
      ),
    );
