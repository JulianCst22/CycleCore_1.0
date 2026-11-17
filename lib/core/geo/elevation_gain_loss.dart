import 'dart:collection';
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

/// [minChangePerPoint], si viene, es el umbral de cada punto (mismo
/// largo que [altitudes]) y reemplaza a [minChangeMeters].
///
/// [closeLastStretch]: contar también el regreso desde el último extremo
/// hasta el punto final, que no alcanzó a confirmarse porque la serie se
/// acabó. Sin esto, una vuelta corta que baja 6 m y vuelve a subir a la
/// casa daba +0 / -6: la subida del final se perdía entera. Con él el
/// balance siempre cierra (desnivel positivo menos negativo = altitud
/// final menos inicial). Mientras se graba no se cuenta: la salida no ha
/// terminado y esa subida todavía puede quedar en nada.
GainLoss computeGainLoss(
  List<double> altitudes, {
  double minChangeMeters = 3,
  List<double>? minChangePerPoint,
  bool closeLastStretch = true,
}) {
  if (altitudes.length < 2) return GainLoss.zero;
  assert(
    minChangePerPoint == null || minChangePerPoint.length == altitudes.length,
  );

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
    final threshold = minChangePerPoint?[i] ?? minChangeMeters;

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
    if (direction == 1 && (extreme - alt) >= threshold) {
      gain += extreme - pivot;
      pivot = extreme;
      extreme = alt;
      direction = -1;
    } else if (direction == -1 && (alt - extreme) >= threshold) {
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

  if (closeLastStretch) {
    final last = altitudes.last;
    if (direction == 1 && last < extreme) {
      loss += extreme - last;
    } else if (direction == -1 && last > extreme) {
      gain += last - extreme;
    }
  }

  return GainLoss(gain, loss);
}

/// Cada cuántos metros se remuestrea el recorrido antes de medir el
/// desnivel: así el resultado no depende de cada cuánto llegó un punto
/// GPS (más puntos = más ruido sumado).
const double routeGainStepMeters = 10;

/// Ventana del promedio móvil por distancia. 200 m son unas siete
/// celdas del modelo de 30 m: borra los edificios y árboles que el
/// modelo de superficie mete en una calle plana sin aplanar una rampa
/// de verdad.
const double routeGainWindowMeters = 200;

/// Umbral de la histéresis en terreno llano (ciudad, sabana). Medido en
/// la salida a La Calera del 28-oct-2026 contra un modelo de terreno sin
/// edificios ni árboles: con el perfil promediado a 200 m, el ruido de
/// Copernicus en la ciudad suma 0,09 m falsos por km con 5 m, lo mismo
/// que con 10 m; con 4 m ya suma 0,31 y con 3 m, 0,49.
const double routeGainFlatMinChangeMeters = 5;

/// Umbral en terreno quebrado (carretera de montaña). Ahí el error
/// lateral del GPS sobre una ladera mueve la altura del modelo: con 5 m
/// el ruido sumaba 1,24 m falsos por km y con 10 m, 0,47. Con 10 m en
/// toda la salida, La Calera daba 950 m contra 911 del Garmin.
const double routeGainRuggedMinChangeMeters = 10;

/// Relieve (lo que sube y baja el perfil limpio alrededor de un punto)
/// hasta el que el terreno es del todo llano, y desde el que es del todo
/// quebrado. En la salida a La Calera, la ciudad tenía de 3 a 8 m de
/// relieve y la montaña de 28 a 140 m.
const double routeGainFlatReliefMeters = 15;
const double routeGainRuggedReliefMeters = 40;

/// Media ventana (m) con que se mide el relieve alrededor de cada punto.
const double routeGainReliefHalfWindowMeters = 1000;

/// Escala vertical mínima (m) con que se dibuja un perfil: una salida
/// por la ciudad con 5 m de relieve no debe llenar el gráfico como si
/// fuera una montaña.
const double profileChartMinSpanMeters = 30;

/// Umbral de histéresis de cada punto de [smoothed] (perfil ya limpio,
/// remuestreado cada [stepMeters]) según el terreno que lo rodea.
///
/// Es un Sugeno de orden cero con dos reglas, como las capas del modelo
/// geoespacial: SI el terreno es llano ENTONCES umbral de
/// [routeGainFlatMinChangeMeters]; SI es quebrado ENTONCES
/// [routeGainRuggedMinChangeMeters]. "Llano" y "quebrado" son rampas
/// complementarias sobre el relieve local (de [routeGainFlatReliefMeters]
/// a [routeGainRuggedReliefMeters]), así que el umbral pasa de uno a
/// otro sin saltos. Cada tramo decide el suyo: en la misma salida la
/// ciudad cuenta con 5 m y la subida a Patios con 10.
List<double> routeGainThresholds(
  List<double> smoothed, {
  double stepMeters = routeGainStepMeters,
}) {
  final relief = _slidingRange(
    smoothed,
    (routeGainReliefHalfWindowMeters / stepMeters).round(),
  );
  const span = routeGainRuggedReliefMeters - routeGainFlatReliefMeters;
  return [
    for (final r in relief)
      () {
        final rugged =
            ((r - routeGainFlatReliefMeters) / span).clamp(0.0, 1.0);
        final flat = 1 - rugged;
        return (flat * routeGainFlatMinChangeMeters +
                rugged * routeGainRuggedMinChangeMeters) /
            (flat + rugged);
      }(),
  ];
}

/// Máximo menos mínimo de [values] en ±[radius] posiciones, con dos
/// colas monótonas: lineal, para poder correrlo en cada punto en vivo.
List<double> _slidingRange(List<double> values, int radius) {
  final n = values.length;
  final out = List<double>.filled(n, 0);
  final maxQ = ListQueue<int>();
  final minQ = ListQueue<int>();
  var right = -1;
  for (var i = 0; i < n; i++) {
    final hi = math.min(n - 1, i + radius);
    while (right < hi) {
      right++;
      while (maxQ.isNotEmpty && values[maxQ.last] <= values[right]) {
        maxQ.removeLast();
      }
      maxQ.addLast(right);
      while (minQ.isNotEmpty && values[minQ.last] >= values[right]) {
        minQ.removeLast();
      }
      minQ.addLast(right);
    }
    final lo = i - radius;
    while (maxQ.first < lo) {
      maxQ.removeFirst();
    }
    while (minQ.first < lo) {
      minQ.removeFirst();
    }
    out[i] = values[maxQ.first] - values[minQ.first];
  }
  return out;
}

/// Remuestreo cada [stepMeters] (interpolación lineal en la distancia) y
/// promedio móvil centrado de ±[windowMeters]/2. Es el perfil sobre el que
/// se mide el desnivel. `null` si el recorrido es muy corto para eso.
List<double>? _cleanGrid(
  List<double> altitudes,
  List<double> distances,
  double stepMeters,
  double windowMeters,
) {
  if (altitudes.length < 2) return null;
  final total = distances.last - distances.first;
  if (total < stepMeters * 2) return null;

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
  return smoothed;
}

/// Desnivel de un recorrido medido sobre la DISTANCIA y no punto a
/// punto: remuestreo cada [stepMeters], promedio móvil de
/// [windowMeters] y luego [computeGainLoss] con el umbral de cada tramo
/// según su terreno ([routeGainThresholds]), o con [minChangeMeters]
/// fijo si se pasa.
///
/// Sumada punto a punto, la salida Bogotá - La Calera - Bogotá del
/// 28-oct-2026 daba 1.700 m de desnivel con el modelo sano (el Garmin
/// barométrico marcó 911 m): cada cuadra de Bogotá sumaba «subiditas»
/// que eran techos y árboles del modelo. Con esta receta da 958 m, y en
/// la ciudad cuenta las lomitas de unos 7 m en adelante.
///
/// [distances] es la distancia acumulada de cada altitud (mismo largo).
/// [closeLastStretch]: ver [computeGainLoss].
GainLoss computeRouteGainLoss(
  List<double> altitudes,
  List<double> distances, {
  double stepMeters = routeGainStepMeters,
  double windowMeters = routeGainWindowMeters,
  double? minChangeMeters,
  bool closeLastStretch = true,
}) {
  assert(altitudes.length == distances.length);
  if (altitudes.length < 2) return GainLoss.zero;
  final smoothed = _cleanGrid(altitudes, distances, stepMeters, windowMeters);
  if (smoothed == null) {
    return computeGainLoss(
      altitudes,
      minChangeMeters: minChangeMeters ?? routeGainFlatMinChangeMeters,
      closeLastStretch: closeLastStretch,
    );
  }
  return computeGainLoss(
    smoothed,
    minChangeMeters: minChangeMeters ?? routeGainFlatMinChangeMeters,
    minChangePerPoint: minChangeMeters == null
        ? routeGainThresholds(smoothed, stepMeters: stepMeters)
        : null,
    closeLastStretch: closeLastStretch,
  );
}

/// El perfil limpio sobre el que [computeRouteGainLoss] mide el desnivel,
/// de vuelta en cada punto del recorrido. Es lo que dibujan los gráficos:
/// así cada subida que se ve más alta que el umbral de su tramo es una
/// subida que suma, y lo que no suma no aparece como una loma.
List<double> cleanRouteProfile(
  List<double> altitudes,
  List<double> distances, {
  double stepMeters = routeGainStepMeters,
  double windowMeters = routeGainWindowMeters,
}) {
  assert(altitudes.length == distances.length);
  final grid = _cleanGrid(altitudes, distances, stepMeters, windowMeters);
  if (grid == null) return List.of(altitudes);
  final start = distances.first;
  return [
    for (final d in distances)
      () {
        final x = ((d - start) / stepMeters).clamp(0.0, grid.length - 1.0);
        final i = x.floor();
        if (i >= grid.length - 1) return grid.last;
        return grid[i] + (grid[i + 1] - grid[i]) * (x - i);
      }(),
  ];
}

/// El desnivel positivo que se ve mientras se graba: la misma receta del
/// resumen ([computeRouteGainLoss], umbral por tramo) sobre lo grabado
/// hasta ahora. Así el número de la salida coincide con el que queda al
/// guardar.
///
/// Dos diferencias, a propósito: no cuenta la subida del final que
/// todavía no se confirma (puede quedar en nada), y nunca baja -- el
/// promedio cerca del último punto se mueve un poco con cada punto nuevo
/// y un contador de subida que retrocede se ve mal.
class LiveGainMeter {
  double _shown;

  /// [gainMeters] es lo ya mostrado (al reanudar una grabación).
  LiveGainMeter({double gainMeters = 0}) : _shown = gainMeters;

  double get gainMeters => _shown;

  /// Recalcula con todo lo grabado: altitudes y su distancia acumulada.
  double update(List<double> altitudes, List<double> distances) {
    if (altitudes.length < 2) return _shown;
    final gain = computeRouteGainLoss(
      altitudes,
      distances,
      closeLastStretch: false,
    ).gainMeters;
    if (gain > _shown) _shown = gain;
    return _shown;
  }
}
