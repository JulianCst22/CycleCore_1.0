import 'dart:math' as math;

import '../units.dart';

/// Potencia normalizada de una serie de 1 Hz:
///
///     NP = ( media( (media móvil de [window] s)⁴ ) )^¼
///
/// Es la potencia constante que habría costado lo mismo fisiológicamente
/// que la potencia variable real: la cuarta potencia castiga los picos.
/// `null` si la serie es más corta que la ventana.
Watts? normalizedPower(List<double> watts, {int window = 30}) {
  assert(window > 0);
  if (watts.length < window) return null;
  var sum = 0.0;
  for (var i = 0; i < window; i++) {
    sum += watts[i];
  }
  var acc = math.pow(sum / window, 4).toDouble();
  var count = 1;
  for (var i = window; i < watts.length; i++) {
    sum += watts[i] - watts[i - window];
    acc += math.pow(sum / window, 4).toDouble();
    count++;
  }
  return Watts(math.pow(acc / count, 0.25).toDouble());
}

/// Media aritmética; `null` si la serie está vacía.
Watts? meanPower(List<double> watts) =>
    watts.isEmpty ? null : Watts(watts.reduce((a, b) => a + b) / watts.length);
