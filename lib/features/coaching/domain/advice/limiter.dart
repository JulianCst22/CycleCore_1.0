import '../coaching_parameters.dart';
import '../extraction/ride_features.dart';

/// Qué es lo que de verdad está topando al ciclista en este momento.
///
/// El motor difuso dice *cuánto* corregir; la limitante dice *por qué*,
/// y eso es lo que el mensaje tiene que nombrar. Decirle a alguien
/// «afloja» sin decirle qué lo está frenando lo deja adivinando: no es
/// lo mismo aflojar porque el corazón está en el tope que aflojar
/// porque la reserva no alcanza para lo que falta.
enum Limiter {
  /// El tanque anaeróbico no da para lo que queda de subida.
  reserva('la reserva'),

  /// El corazón está arriba del techo cómodo: aflojar o respirar.
  pulso('el pulso'),

  /// Va atascado en el pedal: pedalea lento y con mucha fuerza.
  torque('la cadencia'),

  /// Lo que topa no es el cuerpo sino lo que viene: una rampa cerca.
  terreno('la rampa'),

  /// Va por detrás de su referencia y nada más lo está frenando.
  ritmo('el ritmo'),

  /// Nada está topando: el consejo es de afinación, no de rescate.
  ninguna('');

  /// Cómo se nombra en un mensaje hablado.
  final String subject;

  const Limiter(this.subject);

  bool get isNone => this == Limiter.ninguna;
}

/// La limitante con su grado: cuánto se ha pasado de su propio límite.
typedef LimiterReading = ({Limiter limiter, double degree});

const LimiterReading noLimiter = (limiter: Limiter.ninguna, degree: 0);

/// Decide la limitante comparando candidatas en la misma escala.
///
/// Cada candidata se mide con una rampa lineal entre «todavía no» y «ya
/// se pasó», de modo que los grados son comparables y gana el que más
/// se haya pasado. No es una prioridad fija a dedo: si el pulso está en
/// 0,92 de la reserva cardíaca y el tanque apenas va justo, manda el
/// pulso; si el tanque ya no alcanza, manda el tanque.
///
/// Por debajo de [CoachingParameters.limiterFloor] se considera que no
/// hay limitante y el mensaje habla solo del objetivo.
LimiterReading limiterOf(
  RideFeatures features, {
  CoachingParameters parameters = const CoachingParameters(),
}) {
  final candidates = <LimiterReading>[
    if (features.sufficiency case final s?)
      (limiter: Limiter.reserva, degree: _down(s.value, 1.0, 0.4)),
    if (features.heartRateReserve case final h?)
      (limiter: Limiter.pulso, degree: _up(h.value, 0.85, 0.95)),
    if (features.torque case final t?)
      (limiter: Limiter.torque, degree: _up(t.value, 1.25, 1.6)),
    (
      limiter: Limiter.terreno,
      degree:
          _up(features.maxRamp.value, 8, 12) *
          _down(features.terrain?.maxRampInMeters ?? 0, 400, 120),
    ),
    if (features.recordPace case final r?)
      (limiter: Limiter.ritmo, degree: _up(-r.value, 5, 25)),
  ];

  var best = noLimiter;
  for (final c in candidates) {
    if (c.degree > best.degree) best = c;
  }
  return best.degree >= parameters.limiterFloor ? best : noLimiter;
}

/// Rampa creciente: 0 en [start], 1 en [end].
double _up(double x, double start, double end) =>
    ((x - start) / (end - start)).clamp(0.0, 1.0);

/// Rampa decreciente: 0 en [start], 1 en [end] (con [end] < [start]).
double _down(double x, double start, double end) =>
    ((start - x) / (start - end)).clamp(0.0, 1.0);
