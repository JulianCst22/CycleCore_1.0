import 'dart:math' as math;

import '../../../core/geo/geo.dart';

/// Cuándo vuelve a pensar el coach.
///
/// Cada [everySeconds] por reloj y, además, cuando el terreno cambia de
/// golpe: ahí es justo cuando el consejo anterior deja de servir. Entre
/// dos inferencias por evento se respeta [eventGapSeconds] para que una
/// pendiente nerviosa no dispare una inferencia por segundo.
///
/// Lo usan igual el controlador en vivo y la reproducción de una
/// actividad grabada: así una salida reproducida piensa en los mismos
/// instantes que pensó en la calle.
final class InferenceClock {
  /// Cada cuántos segundos se piensa por reloj.
  final int everySeconds;

  /// Mínimo entre dos inferencias disparadas por el terreno.
  final int eventGapSeconds;

  /// Cambio de pendiente (en puntos) que cuenta como evento.
  final double gradientJump;

  double _gradient;
  int _secondsSinceChange = 999;
  int _lastThoughtAt = -999;

  InferenceClock({
    required double gradient,
    this.everySeconds = 5,
    this.eventGapSeconds = 2,
    this.gradientJump = 1,
  }) : _gradient = gradient;

  /// Segundos desde que la pendiente cambió más de [gradientJump]: la
  /// credibilidad del pulso lo necesita (el pulso tarda en reaccionar a
  /// un cambio de carga).
  double get secondsSinceGradientChange => _secondsSinceChange.toDouble();

  /// Segundo en que se pensó por última vez.
  int get lastThoughtAt => _lastThoughtAt;

  /// Apunta el segundo [second] con la pendiente [gradient] y dice si
  /// toca pensar.
  bool tick({required int second, required double gradient}) {
    final changed = (gradient - _gradient).abs() > gradientJump;
    if (changed) {
      _gradient = gradient;
      _secondsSinceChange = 0;
    } else {
      _secondsSinceChange++;
    }
    final onSchedule = second % everySeconds == 0;
    final onEvent = changed && second - _lastThoughtAt >= eventGapSeconds;
    if (!onSchedule && !onEvent) return false;
    _lastThoughtAt = second;
    return true;
  }
}

/// Pendiente con la que el reloj decide si el terreno cambió: la cuerda
/// de ±[halfWindowMeters] alrededor de donde va el ciclista, no la
/// pendiente puntual del perfil.
///
/// La pendiente puntual de un GPX sale de una ventana de 40 m y baila
/// más de un punto de un tramo al siguiente aunque la carretera no
/// cambie. Con ella, cada bailoteo contaba como "cambio de pendiente" y
/// le quitaba credibilidad al pulso durante 20-40 s (ver
/// `SensorCredibility.from`): en una subida real el pulso quedaba casi
/// siempre descartado, justo lo que no puede pasar sin potenciómetro.
/// Sobre 100 m solo cuentan los cambios que de verdad cambian la carga.
double clockGradientAt(
  SegmentProfile profile,
  double alongMeters, {
  double halfWindowMeters = 50,
}) {
  final pointwise = profile.slopePercentAtDistance(alongMeters) ?? 0;
  final total = profile.totalDistanceMeters;
  final from = math.max(0.0, alongMeters - halfWindowMeters);
  final to = math.min(total, alongMeters + halfWindowMeters);
  if (to - from < halfWindowMeters) return pointwise;
  final a = profile.altitudeAtDistance(from);
  final b = profile.altitudeAtDistance(to);
  if (a == null || b == null) return pointwise;
  return 100 * (b - a) / (to - from);
}
