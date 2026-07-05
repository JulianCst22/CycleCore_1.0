import 'dart:math';

/// Fusiona la altitud reportada por GPS con la calculada a partir de
/// presión barométrica, usando un filtro complementario.
///
/// Por qué un filtro complementario y no un filtro de Kalman completo:
/// un Kalman requiere modelar matrices de covarianza y ruido de proceso,
/// lo cual es una complejidad matemática innecesaria para el alcance de
/// este prototipo. El filtro complementario logra un resultado muy
/// similar en la práctica con una fracción del esfuerzo de
/// implementación, y es mucho más fácil de explicar y sustentar.
///
/// Lógica: el barómetro es muy preciso para *cambios* de altitud a
/// corto plazo (sube/baja el terreno), pero tiene deriva a largo plazo.
/// El GPS es ruidoso momento a momento, pero no tiene deriva. Se usa el
/// delta del barómetro para seguir los cambios rápidos, y se corrige
/// lentamente hacia el GPS para no acumular error.
class AltitudeFusionService {
  /// Presión estándar a nivel del mar. No es necesario calibrarla con
  /// la presión real del día -- como solo nos interesan los *cambios*
  /// de altitud (para pendiente y desnivel), un offset constante en la
  /// referencia no afecta las diferencias entre lecturas consecutivas.
  static const double _seaLevelPressureHpa = 1013.25;

  /// Peso que le damos al barómetro frente al GPS. Cerca de 1.0 = casi
  /// todo el peso al barómetro (respuesta rápida y suave), con una
  /// corrección lenta hacia el GPS para evitar deriva acumulada.
  static const double _complementaryAlpha = 0.98;

  double? _fusedAltitude;
  double? _lastBarometricAltitude;

  double _pressureToAltitude(double pressureHpa) {
    return 44330.0 *
        (1.0 - pow(pressureHpa / _seaLevelPressureHpa, 1 / 5.255));
  }

  /// Calcula la altitud fusionada para una nueva lectura.
  ///
  /// Si [pressureHpa] es null (dispositivo sin barómetro, o aún no ha
  /// llegado ninguna lectura), se hace fallback transparente a GPS puro.
  double fuse({required double gpsAltitude, double? pressureHpa}) {
    if (pressureHpa == null) {
      _fusedAltitude = gpsAltitude;
      return gpsAltitude;
    }

    final barometricAltitude = _pressureToAltitude(pressureHpa);

    // Primera lectura: no hay historial todavía para calcular un delta,
    // así que arrancamos confiando en el GPS.
    if (_fusedAltitude == null || _lastBarometricAltitude == null) {
      _fusedAltitude = gpsAltitude;
      _lastBarometricAltitude = barometricAltitude;
      return _fusedAltitude!;
    }

    final barometricDelta = barometricAltitude - _lastBarometricAltitude!;
    final predicted = _fusedAltitude! + barometricDelta;

    _fusedAltitude =
        (_complementaryAlpha * predicted) +
        ((1 - _complementaryAlpha) * gpsAltitude);
    _lastBarometricAltitude = barometricAltitude;

    return _fusedAltitude!;
  }

  /// Reinicia el estado interno. Se debe llamar al empezar una nueva
  /// grabación, para que la fusión no arrastre datos de una sesión
  /// anterior.
  void reset() {
    _fusedAltitude = null;
    _lastBarometricAltitude = null;
  }
}
