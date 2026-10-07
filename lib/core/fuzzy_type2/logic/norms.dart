import 'dart:math' as math;

import '../sets/interval.dart';

/// Norma triangular: el «Y» difuso.
///
/// Todas son monótonas, así que sobre intervalos basta con aplicarlas a
/// los extremos inferiores y a los superiores por separado.
enum TNorm {
  /// Zadeh: la regla vale lo que su condición más débil.
  minimum,

  /// Producto: acumular condiciones parciales se nota.
  product,

  /// Łukasiewicz: `max(0, a + b − 1)`.
  lukasiewicz;

  double call(double a, double b) => switch (this) {
    TNorm.minimum => math.min(a, b),
    TNorm.product => a * b,
    TNorm.lukasiewicz => math.max(0.0, a + b - 1),
  };

  Interval onIntervals(Interval x, Interval y) =>
      Interval(call(x.lo, y.lo), call(x.hi, y.hi));
}

/// Conorma triangular: el «O» difuso.
enum SNorm {
  /// Dual del mínimo.
  maximum,

  /// Dual del producto: `a + b − ab`.
  probabilisticSum;

  double call(double a, double b) => switch (this) {
    SNorm.maximum => math.max(a, b),
    SNorm.probabilisticSum => a + b - a * b,
  };

  Interval onIntervals(Interval x, Interval y) =>
      Interval(call(x.lo, y.lo), call(x.hi, y.hi));
}

/// Modificador lingüístico de Zadeh aplicado a una pertenencia.
enum Hedge {
  none,

  /// «muy»: concentra, `μ²`.
  very,

  /// «algo»: dilata, `√μ`.
  somewhat;

  double call(double mu) => switch (this) {
    Hedge.none => mu,
    Hedge.very => mu * mu,
    Hedge.somewhat => math.sqrt(mu),
  };

  Interval onInterval(Interval x) => Interval(call(x.lo), call(x.hi));
}

/// Cómo una regla da forma a su consecuente según su fuerza de disparo.
///
/// Las dos dejan el consecuente lineal a trozos, así que la figura
/// agregada se sigue integrando en forma exacta.
enum Implication {
  /// Mamdani: corta el consecuente a la altura de la fuerza.
  clip,

  /// Larsen: encoge el consecuente conservando su forma.
  scale;

  double call(double strength, double mu) => switch (this) {
    Implication.clip => math.min(strength, mu),
    Implication.scale => strength * mu,
  };
}

/// Negación estándar sobre un intervalo: invierte y cambia el orden de
/// los extremos.
Interval negate(Interval x) => Interval(1 - x.hi, 1 - x.lo);
