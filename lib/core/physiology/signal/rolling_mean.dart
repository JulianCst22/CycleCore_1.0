/// Media móvil simple de las últimas [window] muestras, en O(1) por
/// muestra: suaviza el rizado de cada pedalada sin retrasar demasiado la
/// señal (3 s para potencia, 5 s para cadencia, 10 s para pulso).
final class RollingMean {
  final int window;
  final List<double> _buffer;
  var _next = 0;
  var _count = 0;
  var _sum = 0.0;

  RollingMean(this.window)
    : assert(window > 0),
      _buffer = List.filled(window, 0);

  /// Agrega una muestra y devuelve la media actual.
  double add(double sample) {
    if (_count == window) {
      _sum -= _buffer[_next];
    } else {
      _count++;
    }
    _buffer[_next] = sample;
    _sum += sample;
    _next = (_next + 1) % window;
    return value!;
  }

  /// Media de las muestras disponibles; `null` si todavía no hay ninguna.
  double? get value => _count == 0 ? null : _sum / _count;

  /// Ya hay [window] muestras.
  bool get isFull => _count == window;

  void reset() {
    _next = 0;
    _count = 0;
    _sum = 0;
  }
}

/// Media móvil de una serie completa. Los primeros valores promedian las
/// muestras que haya (ventana creciente).
List<double> movingAverage(List<double> series, int window) {
  final mean = RollingMean(window);
  return [for (final x in series) mean.add(x)];
}
