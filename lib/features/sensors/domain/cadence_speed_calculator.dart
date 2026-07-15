/// Convierte contadores acumulados de revoluciones (lo único que manda
/// el protocolo BLE) en RPM de cadencia y km/h de velocidad -- para eso
/// SIEMPRE se necesitan DOS lecturas consecutivas (la diferencia entre
/// ellas), por eso esta clase tiene estado, a diferencia de los parsers
/// (que son funciones puras sin memoria).
///
/// Maneja el "rollover": los contadores de revoluciones (uint16 para
/// manivela, uint32 para rueda) y de tiempo de evento (uint16) se
/// reinician solos al llegar a su máximo. Sin este manejo, la primera
/// lectura después de un desborde daría una diferencia negativa absurda.
///
/// Una instancia de esta clase debe usarse para UNA sola fuente de datos
/// a la vez (ej. una instancia para el sensor de potencia, otra para el
/// sensor CSC) -- mezclar lecturas de dos sensores físicos distintos en
/// la misma instancia produciría deltas sin sentido.
class CadenceSpeedCalculator {
  static const int _crankCounterMax = 0x10000; // uint16
  static const int _wheelCounterMax = 0x100000000; // uint32
  static const int _eventTimeCounterMax = 0x10000; // uint16
  static const int _eventTimeResolutionHz = 1024; // 1/1024 s, por estándar

  int? _lastWheelRevolutions;
  int? _lastWheelEventTime;
  int? _lastCrankRevolutions;
  int? _lastCrankEventTime;

  /// Cadencia en RPM a partir de dos lecturas consecutivas de
  /// revoluciones de manivela. Devuelve null si es la primera lectura
  /// (todavía no hay con qué comparar) o si no hubo tiempo transcurrido
  /// real entre eventos (evita división por cero).
  double? updateCadenceRpm({
    required int cumulativeCrankRevolutions,
    required int lastCrankEventTime,
  }) {
    final delta = _delta(
      current: cumulativeCrankRevolutions,
      last: _lastCrankRevolutions,
      currentTime: lastCrankEventTime,
      lastTime: _lastCrankEventTime,
      counterMax: _crankCounterMax,
    );

    _lastCrankRevolutions = cumulativeCrankRevolutions;
    _lastCrankEventTime = lastCrankEventTime;

    if (delta == null) return null;
    final (revDelta, timeDeltaSeconds) = delta;
    if (timeDeltaSeconds <= 0) return null;

    return (revDelta / timeDeltaSeconds) * 60;
  }

  /// Velocidad en km/h a partir de dos lecturas consecutivas de
  /// revoluciones de rueda + la circunferencia real de la rueda (mm) --
  /// el protocolo BLE nunca manda velocidad calculada, solo revoluciones.
  double? updateSpeedKmh({
    required int cumulativeWheelRevolutions,
    required int lastWheelEventTime,
    required double wheelCircumferenceMm,
  }) {
    final delta = _delta(
      current: cumulativeWheelRevolutions,
      last: _lastWheelRevolutions,
      currentTime: lastWheelEventTime,
      lastTime: _lastWheelEventTime,
      counterMax: _wheelCounterMax,
    );

    _lastWheelRevolutions = cumulativeWheelRevolutions;
    _lastWheelEventTime = lastWheelEventTime;

    if (delta == null) return null;
    final (revDelta, timeDeltaSeconds) = delta;
    if (timeDeltaSeconds <= 0) return null;

    final distanceMeters = revDelta * (wheelCircumferenceMm / 1000);
    final speedMetersPerSecond = distanceMeters / timeDeltaSeconds;
    return speedMetersPerSecond * 3.6;
  }

  /// Calcula (delta de revoluciones, delta de tiempo en segundos) entre
  /// la lectura anterior y la actual, corrigiendo un único desborde de
  /// contador si ocurrió. Devuelve null en la primera lectura (sin
  /// referencia previa todavía).
  (int, double)? _delta({
    required int current,
    required int? last,
    required int currentTime,
    required int? lastTime,
    required int counterMax,
  }) {
    if (last == null || lastTime == null) return null;

    var revDelta = current - last;
    if (revDelta < 0) revDelta += counterMax;

    var timeDeltaRaw = currentTime - lastTime;
    if (timeDeltaRaw < 0) timeDeltaRaw += _eventTimeCounterMax;

    final timeDeltaSeconds = timeDeltaRaw / _eventTimeResolutionHz;
    return (revDelta, timeDeltaSeconds);
  }

  void reset() {
    _lastWheelRevolutions = null;
    _lastWheelEventTime = null;
    _lastCrankRevolutions = null;
    _lastCrankEventTime = null;
  }
}
