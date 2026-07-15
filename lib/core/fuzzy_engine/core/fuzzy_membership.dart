/// Funciones de pertenencia difusas reutilizables. Cada una devuelve un
/// grado de pertenencia entre 0.0 y 1.0 para un valor de entrada [x].
///
/// Son las mismas 4 formas estándar de cualquier sistema difuso Sugeno:
/// triangular, trapezoidal, rampa ascendente y rampa descendente. Todo
/// el motor difuso de CycleCore (fusión de altitud, plausibilidad de
/// pendiente, y en el futuro el motor de esfuerzo FC/potencia) se
/// construye combinando estas 4 funciones -- no hay nada específico de
/// geoespacial aquí a propósito, para que sea 100% reutilizable.
library;

/// Triangular: 0 en [a], sube linealmente a 1 en [b], baja linealmente
/// a 0 en [c].
double triangular(double x, double a, double b, double c) {
  if (x <= a || x >= c) return 0.0;
  if (x == b) return 1.0;
  if (x < b) return (x - a) / (b - a);
  return (c - x) / (c - b);
}

/// Trapezoidal: sube de [a] a [b], se mantiene en 1.0 entre [b] y [c],
/// baja de [c] a [d].
double trapezoidal(double x, double a, double b, double c, double d) {
  if (x <= a || x >= d) return 0.0;
  if (x >= b && x <= c) return 1.0;
  if (x < b) return (x - a) / (b - a);
  return (d - x) / (d - c);
}

/// Rampa ascendente: 0 antes de [a], sube linealmente a 1 en [b], se
/// mantiene en 1 después.
double rampUp(double x, double a, double b) {
  if (x <= a) return 0.0;
  if (x >= b) return 1.0;
  return (x - a) / (b - a);
}

/// Rampa descendente: 1 antes de [a], baja linealmente a 0 en [b], se
/// mantiene en 0 después.
double rampDown(double x, double a, double b) {
  if (x <= a) return 1.0;
  if (x >= b) return 0.0;
  return (b - x) / (b - a);
}
