import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ble_sensor_service.dart';
import '../data/ble_speed_service.dart';
import '../data/wheel_size_repository.dart';
import '../domain/cadence_speed_calculator.dart';
import '../domain/cycling_speed_cadence_reading.dart';
import '../domain/sensor_kind.dart';
import 'ble_sensor_controller.dart';
import 'sensor_connection_state.dart';

/// Máximo del contador de revoluciones de rueda (uint32). El odómetro
/// lleva su PROPIO tracking de "última lectura", separado del que usa
/// `CadenceSpeedCalculator` para la velocidad instantánea, para que uno
/// no interfiera con el otro.
const _wheelCounterMax = 0x100000000;

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
  double? _wheelCircumferenceMm;

  double _odometerMeters = 0;
  int? _lastOdometerWheelRevs;

  Future<void> _loadWheelCircumference() async {
    _wheelCircumferenceMm = await _wheelSizeRepository.loadCircumferenceMm();
  }

  @override
  void onBeforeConnect() {
    _calculator.reset();
    _odometerMeters = 0;
    _lastOdometerWheelRevs = null;
  }

  @override
  void onAfterDisconnect() {
    _calculator.reset();
    _odometerMeters = 0;
    _lastOdometerWheelRevs = null;
    // alsoProvidesCadence vuelve a false a propósito -- es una propiedad
    // del dispositivo conectado, no una preferencia general. `disconnect`
    // ya restauró `SensorConnectionState()` por defecto.
  }

  @override
  void handleReading(CyclingSpeedCadenceReading reading) {
    // Sólo se procesa cadencia si el usuario marcó que este sensor es un
    // combo -- si no, aunque el dispositivo traiga manivela, esta tarjeta
    // la ignora (esa cadencia debe venir de la tarjeta de Cadencia).
    if (state.alsoProvidesCadence && reading.hasCrankData) {
      final rpm = _calculator.updateCadenceRpm(
        cumulativeCrankRevolutions: reading.cumulativeCrankRevolutions!,
        lastCrankEventTime: reading.lastCrankEventTime!,
      );
      if (rpm != null) {
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
    if (_lastOdometerWheelRevs != null) {
      var revDelta = currentRevs - _lastOdometerWheelRevs!;
      if (revDelta < 0) revDelta += _wheelCounterMax;
      _odometerMeters += revDelta * (_wheelCircumferenceMm! / 1000);
      ref.read(speedDistanceMetersProvider.notifier).state = _odometerMeters;
    }
    _lastOdometerWheelRevs = currentRevs;

    final kmh = _calculator.updateSpeedKmh(
      cumulativeWheelRevolutions: currentRevs,
      lastWheelEventTime: reading.lastWheelEventTime!,
      wheelCircumferenceMm: _wheelCircumferenceMm!,
    );
    if (kmh != null) {
      ref.read(speedKmhProvider.notifier).state = kmh;
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
