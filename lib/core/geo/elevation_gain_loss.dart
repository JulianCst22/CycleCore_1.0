import 'dart:math' as math;

/// Desnivel positivo y negativo de una serie de altitudes, con
/// **histéresis**: solo se "cuenta" un cambio de dirección cuando la
/// altitud se aleja más de [minChangeMeters] del último pivote. Es el
/// método que usan Garmin/Strava y evita que el ruido de la serie
/// (jitter de GPS, costuras de HGT, barómetro indoor durante un test)
/// infle el desnivel -- el problema clásico de "hice solo una subida
/// pero me marca desnivel negativo".
///
/// Sumar cada delta > un piso fijo (lo que hacía antes el aplanador y
/// `_DerivedStats`) falla justo en ese caso: una serie que oscila
/// ±1 m mil veces acumula cientos de metros falsos en ambos sentidos.
class GainLoss {
  final double gainMeters;
  final double lossMeters;

  const GainLoss(this.gainMeters, this.lossMeters);

  static const zero = GainLoss(0, 0);
}

GainLoss computeGainLoss(
  List<double> altitudes, {
  double minChangeMeters = 3,
}) {
  if (altitudes.length < 2) return GainLoss.zero;

  double gain = 0;
  double loss = 0;

  // Pivote: última altitud "confirmada". `direction` = hacia dónde
  // veníamos (1 subiendo, -1 bajando, 0 sin definir).
  double pivot = altitudes.first;
  double extreme = altitudes.first; // el punto más lejos del pivote en
  // la dirección actual (candidato a nuevo pivote)
  int direction = 0;

  for (int i = 1; i < altitudes.length; i++) {
    final alt = altitudes[i];

    if (direction >= 0 && alt > extreme) {
      // Seguimos (o empezamos) a subir -- el extremo sube con nosotros.
      extreme = alt;
      if (direction == 0) direction = 1;
    } else if (direction <= 0 && alt < extreme) {
      extreme = alt;
      if (direction == 0) direction = -1;
    }

    // ¿Retrocedimos lo suficiente respecto al extremo como para
    // confirmar un cambio de dirección?
    if (direction == 1 && (extreme - alt) >= minChangeMeters) {
      gain += extreme - pivot;
      pivot = extreme;
      extreme = alt;
      direction = -1;
    } else if (direction == -1 && (alt - extreme) >= minChangeMeters) {
      loss += pivot - extreme;
      pivot = extreme;
      extreme = alt;
      direction = 1;
    }
  }

  // Cerrar el tramo abierto al final.
  if (direction == 1 && extreme > pivot) {
    gain += extreme - pivot;
  } else if (direction == -1 && extreme < pivot) {
    loss += pivot - extreme;
  }

  return GainLoss(gain, loss);
}

/// Cada cuántos metros se remuestrea el recorrido antes de medir el
/// desnivel: así el resultado no depende de cada cuánto llegó un punto
/// GPS (más puntos = más ruido sumado).
const double routeGainStepMeters = 10;

/// Ventana del promedio móvil por distancia. 200 m son unas siete
/// celdas del SRTM de 30 m: borra los edificios y árboles que el
/// modelo de superficie mete en una calle plana sin aplanar una rampa
/// de verdad.
const double routeGainWindowMeters = 200;

/// Solo cuenta una subida (o bajada) sostenida de al menos esto. Es el
/// umbral que Strava usa para la altitud de mapa (archivos sin
/// barómetro); con barómetro usa 2 m.
const double routeGainMinChangeMeters = 10;

/// Desnivel de un recorrido medido sobre la DISTANCIA y no punto a
/// punto: remuestreo cada [stepMeters], promedio móvil de
/// [windowMeters] y luego [computeGainLoss] con [minChangeMeters].
///
/// Es la receta de las plataformas de entrenamiento para altitud de
/// modelo de elevación. Sumada punto a punto, la salida Bogotá - La
/// Calera - Bogotá del 28-oct-2026 daba 1.700 m de desnivel con el DEM
/// sano (el Garmin barométrico marcó 911 m): cada cuadra de Bogotá
/// sumaba «subiditas» que eran techos y árboles del SRTM. Con esta
/// receta da unos 990 m y la subida a Patios queda en sus 422 m.
///
/// [distances] es la distancia acumulada de cada altitud (mismo largo).
GainLoss computeRouteGainLoss(
  List<double> altitudes,
  List<double> distances, {
  double stepMeters = routeGainStepMeters,
  double windowMeters = routeGainWindowMeters,
  double minChangeMeters = routeGainMinChangeMeters,
}) {
  assert(altitudes.length == distances.length);
  if (altitudes.length < 2) return GainLoss.zero;
  final total = distances.last - distances.first;
  if (total < stepMeters * 2) {
    return computeGainLoss(altitudes, minChangeMeters: minChangeMeters);
  }

  // 1. Remuestreo a paso fijo (interpolación lineal en la distancia).
  final resampled = <double>[];
  var j = 0;
  for (var d = distances.first; d <= distances.last; d += stepMeters) {
    while (j < distances.length - 2 && distances[j + 1] < d) {
      j++;
    }
    final d0 = distances[j];
    final d1 = distances[j + 1];
    final t = d1 > d0 ? ((d - d0) / (d1 - d0)).clamp(0.0, 1.0) : 0.0;
    resampled.add(altitudes[j] + (altitudes[j + 1] - altitudes[j]) * t);
  }

  // 2. Promedio móvil centrado de ±windowMeters/2 (sumas acumuladas).
  final radius = (windowMeters / 2 / stepMeters).round();
  final prefix = List<double>.filled(resampled.length + 1, 0);
  for (var i = 0; i < resampled.length; i++) {
    prefix[i + 1] = prefix[i] + resampled[i];
  }
  final smoothed = List<double>.filled(resampled.length, 0);
  for (var i = 0; i < resampled.length; i++) {
    final a = math.max(0, i - radius);
    final b = math.min(resampled.length - 1, i + radius);
    smoothed[i] = (prefix[b + 1] - prefix[a]) / (b - a + 1);
  }

  // 3. Histéresis.
  return computeGainLoss(smoothed, minChangeMeters: minChangeMeters);
}

/// La histéresis de [computeGainLoss] pero punto a punto: el desnivel
/// que se ve mientras se graba. Antes el cockpit sumaba cada subida
/// entre dos puntos seguidos, así que en la salida marcaba otra cifra
/// (más alta) que la del resumen al guardar.
class GainCounter {
  final double minChangeMeters;
  double _gain;
  double? _pivot;
  double? _extreme;
  int _direction = 0;

  /// [gainMeters] es lo ya contado (al reanudar una grabación).
  GainCounter({
    this.minChangeMeters = routeGainMinChangeMeters,
    double gainMeters = 0,
  }) : _gain = gainMeters;

  /// Lo confirmado más la subida que va en curso: así el número crece
  /// mientras se sube, sin esperar a que el camino baje.
  double get gainMeters {
    final pivot = _pivot;
    final extreme = _extreme;
    if (_direction == 1 && pivot != null && extreme != null) {
      return _gain + (extreme - pivot);
    }
    return _gain;
  }

  void add(double altitude) {
    final pivot = _pivot;
    final extreme = _extreme;
    if (pivot == null || extreme == null) {
      _pivot = altitude;
      _extreme = altitude;
      return;
    }
    if (_direction >= 0 && altitude > extreme) {
      _extreme = altitude;
      if (_direction == 0) _direction = 1;
    } else if (_direction <= 0 && altitude < extreme) {
      _extreme = altitude;
      if (_direction == 0) _direction = -1;
    }
    final top = _extreme!;
    if (_direction == 1 && top - altitude >= minChangeMeters) {
      _gain += top - pivot;
      _pivot = top;
      _extreme = altitude;
      _direction = -1;
    } else if (_direction == -1 && altitude - top >= minChangeMeters) {
      _pivot = top;
      _extreme = altitude;
      _direction = 1;
    }
  }
}
