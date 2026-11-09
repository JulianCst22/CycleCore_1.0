import 'dart:math' as math;

/// Cuántos puntos tienen que traer presión para armar el perfil con el
/// barómetro. Por debajo (teléfono sin barómetro, sensor que se durmió)
/// se usa solo el modelo de elevación.
const double barometricMinCoverage = 0.8;

/// Ventana (m) con que se estima la diferencia entre el barómetro y el
/// modelo de elevación. Es el «filtro complementario» en distancia: lo
/// que cambia en menos de esto lo pone el barómetro, lo que cambia en
/// más lo pone el modelo.
///
/// Un kilómetro es largo para el ruido del modelo (edificios, árboles,
/// celdas de 30 m: decenas o pocos cientos de metros) y corto para lo
/// que deriva el barómetro, que es el clima: unos hPa en horas, es
/// decir, nada en los tres minutos que tarda un kilómetro de subida.
const double barometricLevelWindowMeters = 1000;

/// Altitud (m) de una presión (hPa) en la atmósfera estándar. El nivel
/// absoluto que da depende del clima del día; por eso aquí solo se usa
/// su forma, y el nivel lo pone el modelo de elevación.
double barometricAltitude(double pressureHpa) =>
    44330.0 * (1 - math.pow(pressureHpa / 1013.25, 1 / 5.255));

/// Perfil de una salida con la forma del barómetro y el nivel del
/// modelo de elevación: lo mismo que hace un ciclocomputador al
/// calibrar su barómetro contra el DEM, pero sobre la salida entera y
/// hacia los dos lados (al guardar ya se conoce lo que vino después).
///
/// - [pressures]: hPa de cada punto (`null` donde no hubo lectura).
/// - [distances]: distancia acumulada de cada punto.
/// - [reference]: altitud confiable de cada punto (HGT o GPX anclado),
///   `null` donde no hay.
/// - [fallback]: altitud en vivo de cada punto; solo se usa para poner
///   el nivel si la salida no tiene ningún punto con [reference].
///
/// Devuelve `null` si la presión no alcanza [barometricMinCoverage].
List<double>? barometricProfile({
  required List<double?> pressures,
  required List<double> distances,
  required List<double?> reference,
  required List<double> fallback,
  double levelWindowMeters = barometricLevelWindowMeters,
}) {
  final n = pressures.length;
  assert(distances.length == n && reference.length == n);
  if (n < 2) return null;
  final withPressure = pressures.where((p) => p != null).length;
  if (withPressure < n * barometricMinCoverage) return null;

  // 1. Forma: altitud del barómetro, con los huecos rellenados por
  //    interpolación en la distancia.
  final shape = _fillGaps([
    for (final p in pressures) p == null ? null : barometricAltitude(p),
  ], distances);

  // 2. Nivel: diferencia (modelo - barómetro) donde hay modelo.
  final residual = <double?>[
    for (var i = 0; i < n; i++)
      reference[i] == null ? null : reference[i]! - shape[i],
  ];
  if (residual.every((r) => r == null)) {
    // Sin modelo en toda la salida: el nivel lo pone la altitud en
    // vivo (GPS), con la mediana para que un mal arranque no pese.
    final offset = _median([
      for (var i = 0; i < n; i++) fallback[i] - shape[i],
    ]);
    return [for (final h in shape) h + offset];
  }

  // 3. La diferencia se suaviza en [levelWindowMeters]: primero una
  //    mediana (un puente o un edificio en el modelo no la mueven) y
  //    luego un promedio (para que no quede en escalones).
  final half = levelWindowMeters / 2;
  final median = _windowed(residual, distances, half, _median);
  final level = _fillGaps(_windowed(median, distances, half, _mean), distances);

  return [for (var i = 0; i < n; i++) shape[i] + level[i]];
}

/// Aplica [reduce] a los valores no nulos a ±[half] metros de cada
/// punto. `null` donde no hay ninguno.
List<double?> _windowed(
  List<double?> values,
  List<double> distances,
  double half,
  double Function(List<double>) reduce,
) {
  final out = List<double?>.filled(values.length, null);
  var from = 0;
  var to = 0;
  final window = <int>[];
  for (var i = 0; i < values.length; i++) {
    while (from < values.length && distances[from] < distances[i] - half) {
      from++;
    }
    while (to < values.length && distances[to] <= distances[i] + half) {
      to++;
    }
    window.clear();
    for (var k = from; k < to; k++) {
      if (values[k] != null) window.add(k);
    }
    if (window.isEmpty) continue;
    out[i] = reduce([for (final k in window) values[k]!]);
  }
  return out;
}

/// Rellena los `null` interpolando en la distancia entre los vecinos con
/// dato; antes del primero y después del último, el valor del extremo.
List<double> _fillGaps(List<double?> values, List<double> distances) {
  final known = [
    for (var i = 0; i < values.length; i++)
      if (values[i] != null) i,
  ];
  if (known.isEmpty) return List.filled(values.length, 0);
  final out = List<double>.filled(values.length, 0);
  var k = 0;
  for (var i = 0; i < values.length; i++) {
    if (values[i] != null) {
      out[i] = values[i]!;
      continue;
    }
    while (k < known.length - 1 && known[k + 1] < i) {
      k++;
    }
    final a = known[k];
    if (i < a) {
      out[i] = values[a]!;
      continue;
    }
    if (k == known.length - 1) {
      out[i] = values[a]!;
      continue;
    }
    final b = known[k + 1];
    final span = distances[b] - distances[a];
    final t = span > 0 ? (distances[i] - distances[a]) / span : 0.0;
    out[i] = values[a]! + (values[b]! - values[a]!) * t;
  }
  return out;
}

double _mean(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

double _median(List<double> values) {
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}
