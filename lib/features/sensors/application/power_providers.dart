import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ble_power_service.dart';
import '../data/ble_sensor_service.dart';
import '../domain/cadence_speed_calculator.dart';
import '../domain/cycling_power_reading.dart';
import '../domain/revolution_stall_detector.dart';
import '../domain/sensor_kind.dart';
import 'ble_sensor_controller.dart';
import 'sensor_connection_state.dart';

/// Sin lecturas del medidor en este tiempo, la potencia deja de
/// conocerse. Los medidores mandan entre 1 y 4 veces por segundo, y
/// pedaleando o no siguen mandando (0 W al dejar de pedalear); si se
/// callan es que se durmieron o se perdió el enlace, y ahí es mejor que
/// el coach estime con la velocidad a que crea en el último valor.
const powerSilenceAfter = Duration(seconds: 4);

/// Potencia instantánea por encima de esto es un error de lectura.
const _maxPlausibleWatts = 2500;

/// Mismo criterio que el sensor de cadencia dedicado (ver
/// `crankStallAfter` en `cadence_providers.dart`).
const _crankStallAfter = Duration(seconds: 3);
const _maxPlausibleCadenceRpm = 220.0;

/// Medidor de potencia. Además de los vatios, si el sensor trae datos de
/// manivela deriva cadencia (la fuente más "gratis": ya lo tienes
/// conectado). Esa cadencia NO es pública -- ver `cadenceRpmProvider`.
class PowerSensorController extends BleSensorController<CyclingPowerReading> {
  PowerSensorController(BleSensorService<CyclingPowerReading> service, Ref ref)
    : super(kind: SensorKind.power, service: service, ref: ref);

  final CadenceSpeedCalculator _cadence = CadenceSpeedCalculator();
  final RevolutionStallDetector _crank = RevolutionStallDetector(
    stallAfter: _crankStallAfter,
  );
  bool _silent = false;

  void _resetCounters() {
    _cadence.reset();
    _crank.reset();
    _silent = false;
  }

  @override
  void onBeforeConnect() => _resetCounters();

  @override
  void onAfterDisconnect() => _resetCounters();

  @override
  void onLinkLost() => _resetCounters();

  @override
  void handleReading(CyclingPowerReading reading) {
    _silent = false;
    final watts = reading.instantaneousPowerWatts;
    if (watts <= _maxPlausibleWatts) {
      ref.read(powerWattsProvider.notifier).state = watts < 0 ? 0 : watts;
    }

    if (!reading.hasCrankData) return;
    if (!_crank.observe(reading.lastCrankEventTime!, DateTime.now())) return;
    final rpm = _cadence.updateCadenceRpm(
      cumulativeCrankRevolutions: reading.cumulativeCrankRevolutions!,
      lastCrankEventTime: reading.lastCrankEventTime!,
    );
    if (rpm != null && rpm <= _maxPlausibleCadenceRpm) {
      ref.read(powerSourcedCadenceRpmProvider.notifier).state = rpm;
    }
  }

  @override
  void onTick(DateTime now) {
    if (_crank.checkStall(now)) {
      _cadence.resetCrank();
      ref.read(powerSourcedCadenceRpmProvider.notifier).state = 0;
    }
    final last = lastReadingAt;
    if (!_silent && last != null && now.difference(last) > powerSilenceAfter) {
      _silent = true;
      ref.read(powerWattsProvider.notifier).state = null;
    }
  }

  @override
  void clearLiveOutputs() {
    ref.read(powerWattsProvider.notifier).state = null;
    ref.read(powerSourcedCadenceRpmProvider.notifier).state = null;
  }
}

/// Potencia en vatios en tiempo real. El resto de la app la lee sin
/// saber que hay BLE detrás -- mismo patrón que `heartRateBpmProvider`.
final powerWattsProvider = StateProvider<int?>((ref) => null);

/// Cadencia derivada del medidor de potencia. NO pública -- la cadencia
/// "oficial" es `cadenceRpmProvider`, que fusiona esta fuente con las
/// demás.
final powerSourcedCadenceRpmProvider = StateProvider<double?>((ref) => null);

final bleCyclingPowerServiceProvider = Provider<BleCyclingPowerService>(
  (ref) => BleCyclingPowerService(),
);

final powerSensorControllerProvider =
    StateNotifierProvider<PowerSensorController, SensorConnectionState>(
      (ref) =>
          PowerSensorController(ref.read(bleCyclingPowerServiceProvider), ref),
    );
