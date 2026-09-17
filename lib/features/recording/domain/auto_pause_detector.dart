/// Cambio de estado que decidió [AutoPauseDetector].
enum AutoPauseTransition { paused, resumed }

/// Pausa automática estilo Garmin: decide cuándo el ciclista se detuvo y
/// cuándo volvió a rodar. Puro: no lee sensores ni el reloj, recibe cada
/// evidencia con su instante.
///
/// No basta con esperar "velocidad 0", porque parado casi nunca llega
/// ese dato:
///  - el GPS se pide con `distanceFilter` (ver `LocationService`), así
///    que sin moverse simplemente deja de mandar posiciones;
///  - el sensor de rueda BLE, con la rueda quieta, repite el mismo
///    contador y `CadenceSpeedCalculator` no emite una velocidad nueva
///    -- se queda la última.
///
/// Por eso se razona al revés: lo que se registra es la EVIDENCIA de
/// movimiento ([onSpeed] del GPS, [onMovement] de la rueda), y si pasan
/// [stopDelay] sin ninguna, se considera detenido ([onTick]).
class AutoPauseDetector {
  /// Por debajo de esto una lectura GPS no cuenta como movimiento: parado,
  /// la velocidad GPS "baila" en 1-3 km/h.
  final double movingSpeedKmh;

  /// Tiempo sin evidencia de movimiento para dar la parada por hecha.
  /// Tiene que superar lo que tarda en llegar un punto GPS rodando muy
  /// despacio (a 4 km/h, los 5 m del `distanceFilter` toman ~4.5 s).
  final Duration stopDelay;

  AutoPauseDetector({
    this.movingSpeedKmh = 4,
    this.stopDelay = const Duration(seconds: 6),
  });

  DateTime? _lastMovementAt;
  bool _isPaused = false;

  bool get isPaused => _isPaused;

  /// Último instante con evidencia de movimiento -- donde de verdad se
  /// detuvo el ciclista (la pausa se confirma [stopDelay] después).
  DateTime? get lastMovementAt => _lastMovementAt;

  /// Empieza a vigilar desde [now] como si se viniera rodando -- al
  /// arrancar la grabación o al volver de una pausa manual.
  void reset(DateTime now) {
    _lastMovementAt = now;
    _isPaused = false;
  }

  /// Una lectura de velocidad (GPS). Solo cuenta si supera
  /// [movingSpeedKmh].
  AutoPauseTransition? onSpeed(double speedKmh, DateTime at) {
    if (speedKmh < movingSpeedKmh) return null;
    return onMovement(at);
  }

  /// Evidencia directa de movimiento -- la rueda sumó distancia.
  AutoPauseTransition? onMovement(DateTime at) {
    _lastMovementAt = at;
    if (!_isPaused) return null;
    _isPaused = false;
    return AutoPauseTransition.resumed;
  }

  /// Revisión periódica: si ya pasó [stopDelay] desde la última evidencia
  /// de movimiento, se pausa.
  AutoPauseTransition? onTick(DateTime now) {
    final last = _lastMovementAt;
    if (_isPaused || last == null) return null;
    if (now.difference(last) < stopDelay) return null;
    _isPaused = true;
    return AutoPauseTransition.paused;
  }
}
