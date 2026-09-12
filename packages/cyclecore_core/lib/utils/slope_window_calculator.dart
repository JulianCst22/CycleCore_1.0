/// Calcula la pendiente actual usando una regresión lineal sobre una
/// ventana móvil de los últimos [windowMeters] recorridos, en vez de la
/// diferencia entre solo dos puntos consecutivos.
///
/// Por qué: con solo dos puntos, un error de altitud de 1 metro sobre
/// apenas 5 metros de distancia horizontal produce ~20% de pendiente
/// aparente -- ruido que ahoga por completo una pendiente real del 2-3%
/// como la de un tramo real de Patios. Promediar la tendencia sobre una
/// ventana más larga reduce drásticamente ese ruido, a cambio de una
/// pequeña latencia en detectar cambios de pendiente reales.
///
/// Esta es una solución intermedia para el modo "ruta libre" (sin un
/// segmento pre-cargado). La solución definitiva, una vez exista el
/// módulo de segmentos, es precalcular el perfil de elevación completo
/// de la ruta de forma offline (con suavizado tipo Savitzky-Golay sobre
/// todo el recorrido) y solo hacer "lookup" de la pendiente según la
/// posición del ciclista sobre esa ruta ya conocida.
class SlopeWindowCalculator {
  final double windowMeters;
  final List<_Sample> _samples = [];

  SlopeWindowCalculator({this.windowMeters = 40});

  /// Agrega una nueva muestra (distancia acumulada, altitud fusionada) y
  /// devuelve la pendiente actual en porcentaje.
  double addSample({
    required double cumulativeDistanceMeters,
    required double altitude,
  }) {
    _samples.add(_Sample(cumulativeDistanceMeters, altitude));

    final cutoff = cumulativeDistanceMeters - windowMeters;
    _samples.removeWhere((s) => s.distanceMeters < cutoff);

    if (_samples.length < 3) return 0;

    final span = _samples.last.distanceMeters - _samples.first.distanceMeters;
    if (span < windowMeters * 0.5) return 0; // ventana aún muy corta

    final n = _samples.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (final s in _samples) {
      sumX += s.distanceMeters;
      sumY += s.altitude;
      sumXY += s.distanceMeters * s.altitude;
      sumXX += s.distanceMeters * s.distanceMeters;
    }

    final denominator = (n * sumXX) - (sumX * sumX);
    if (denominator == 0) return 0;

    final slope = ((n * sumXY) - (sumX * sumY)) / denominator;
    return slope * 100;
  }

  void reset() => _samples.clear();
}

class _Sample {
  final double distanceMeters;
  final double altitude;
  const _Sample(this.distanceMeters, this.altitude);
}
