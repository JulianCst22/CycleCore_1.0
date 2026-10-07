/// Nota cuando una biela o una rueda dejó de girar.
///
/// Un sensor de cadencia o de velocidad no manda "0": manda contadores
/// acumulados de revoluciones con el instante del último evento. Parado
/// (o sin pedalear), sigue repitiendo el mismo contador -- o deja de
/// mandar -- y `CadenceSpeedCalculator` no tiene diferencia con qué
/// calcular, así que la app se quedaba mostrando la última cadencia
/// buena: 85 rpm bajando sin pedalear, y el coach creyéndolo.
///
/// La regla es la de cualquier ciclocomputador: si el instante del
/// evento no cambia en [stallAfter], la biela (o la rueda) está quieta.
///
/// Además resuelve el arranque después de la parada: el reloj de eventos
/// del protocolo da la vuelta cada 64 s, así que comparar contra la
/// última lectura de antes de parar daría un pico. Mientras el sensor
/// repita el evento viejo, [observe] dice que no se use; el primer
/// evento nuevo vuelve a tomar referencia.
class RevolutionStallDetector {
  RevolutionStallDetector({required this.stallAfter});

  /// Tiempo sin eventos nuevos para dar la biela o la rueda por quieta.
  final Duration stallAfter;

  int? _lastEventTime;
  DateTime? _lastChangeAt;
  bool _stalled = false;
  int? _stalledEventTime;

  bool get isStalled => _stalled;

  /// Registra el instante de evento de una lectura. Devuelve `false` si
  /// la lectura todavía repite el evento de antes de la parada y no hay
  /// que pasarla al calculador.
  bool observe(int eventTime, DateTime at) {
    if (_stalled) {
      if (eventTime == _stalledEventTime) return false;
      _stalled = false;
      _stalledEventTime = null;
    }
    if (eventTime != _lastEventTime) {
      _lastEventTime = eventTime;
      _lastChangeAt = at;
    }
    return true;
  }

  /// Revisión periódica. Devuelve `true` una sola vez, en el momento en
  /// que se da la biela (o la rueda) por detenida.
  bool checkStall(DateTime now) {
    final last = _lastChangeAt;
    if (_stalled || last == null) return false;
    if (now.difference(last) < stallAfter) return false;
    _stalled = true;
    _stalledEventTime = _lastEventTime;
    return true;
  }

  void reset() {
    _lastEventTime = null;
    _lastChangeAt = null;
    _stalled = false;
    _stalledEventTime = null;
  }
}
