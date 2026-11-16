import 'dart:math' as math;

import '../units.dart';

/// Balance de W′ en vivo, con el modelo diferencial de Skiba (2015):
///
///     P > CP:  W′bal ← W′bal − (P − CP)·Δt
///     P ≤ CP:  W′bal ← W′bal + (W′ − W′bal)·(CP − P)/W′·Δt
///
/// Sobre CP la reserva se vacía linealmente; bajo CP se recupera, más
/// rápido cuanto más vacía está y cuanto más suave se pedalea. El balance
/// puede quedar negativo: el modelo dice que el esfuerzo ya no era
/// sostenible, y ese dato también sirve.
///
/// Es una integral: hay que actualizarla con cada muestra, sin saltarse
/// ninguna.
final class WPrimeBalance {
  final Watts cp;
  final Joules wPrime;
  double _balance;

  WPrimeBalance({required this.cp, required this.wPrime})
    : assert(cp > 0 && wPrime > 0),
      _balance = wPrime;

  /// Reserva restante, en julios.
  Joules get balance => Joules(_balance);

  /// Reserva restante como fracción de W′ (1 = llena).
  double get fraction => _balance / wPrime;

  /// Aplica [seconds] segundos a potencia [power] y devuelve el balance.
  Joules update(Watts power, {double seconds = 1}) {
    if (seconds <= 0) {
      throw ArgumentError.value(seconds, 'seconds', 'debe ser positivo');
    }
    if (power > cp) {
      _balance -= (power - cp) * seconds;
    } else {
      final recovered = (wPrime - _balance) * (cp - power) / wPrime * seconds;
      _balance = math.min(wPrime.toDouble(), _balance + recovered);
    }
    return balance;
  }

  /// Aplica una serie de 1 Hz completa.
  Joules updateAll(Iterable<double> wattsPerSecond) {
    for (final p in wattsPerSecond) {
      update(Watts(p));
    }
    return balance;
  }

  void reset() => _balance = wPrime;
}

/// Qué fracción de la energía que hace falta para terminar a [power]
/// tiene el tanque:
///
///     S = W′bal / ((P − CP) · t_restante)
///
/// Bajo CP no se gasta reserva: devuelve [cap]. También se recorta a
/// [cap] por arriba y a 0 por abajo.
///
/// [keep] son los julios con los que hay que llegar al final: lo que
/// se puede gastar es `W′bal − keep`. Con 0 se cuenta todo el tanque
/// (llegar vacío); con un valor positivo se guarda esa reserva para la
/// cima, y con uno negativo se planea pedir un poco más de lo que el
/// tanque calibrado dice tener.
double sufficiency({
  required Joules balance,
  required Watts power,
  required Watts cp,
  required double remainingSeconds,
  double keep = 0,
  double cap = 2,
}) {
  assert(remainingSeconds >= 0);
  final excess = power - cp;
  if (excess <= 0 || remainingSeconds == 0) return cap;
  final s = (balance - keep) / (excess * remainingSeconds);
  return s.clamp(0, cap).toDouble();
}

/// Segundos hasta vaciar la reserva sosteniendo [power]; `null` si
/// [power] no supera CP (no se vacía).
double? timeToExhaustion({
  required Joules balance,
  required Watts power,
  required Watts cp,
}) {
  final excess = power - cp;
  if (excess <= 0) return null;
  return math.max(0, balance) / excess;
}

/// Potencia constante con la que se llega al final con [keep] julios
/// en el tanque: `CP + (W′bal − keep) / t_restante`. Con `keep = 0` se
/// llega justo vacío.
///
/// Si al tanque ya le queda menos que [keep], lo sostenible es la
/// potencia crítica: por encima se seguiría gastando lo que hay que
/// guardar.
Watts sustainablePower({
  required Joules balance,
  required Watts cp,
  required double remainingSeconds,
  double keep = 0,
}) {
  assert(remainingSeconds > 0);
  return Watts(cp + math.max(0, balance - keep) / remainingSeconds);
}
