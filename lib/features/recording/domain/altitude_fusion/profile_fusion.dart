import 'dart:math' as math;

import '../../../../core/fuzzy_logic/fuzzy_logic.dart';

/// Cuántos puntos tienen que traer presión para usar el barómetro como
/// fuente. Por debajo (teléfono sin barómetro, sensor que se durmió) la
/// salida se arma con las demás.
const double barometricMinCoverage = 0.8;

/// Ventana (m) con que se corrige el NIVEL del perfil contra el modelo de
/// elevación. Lo que cambia en menos de esto lo deciden las fuentes
/// pesadas por la lógica difusa; lo que cambia en más, el modelo.
///
/// Un kilómetro es largo para el ruido del modelo (edificios, árboles,
/// celdas de 30 m) y corto para lo que deriva el barómetro, que es el
/// clima: unos hPa en horas, nada en los minutos que tarda un kilómetro.
const double profileLevelWindowMeters = 1000;

/// Media ventana (m) con que se mide la pendiente de cada fuente y la
/// rugosidad del modelo, para comparar las fuentes entre sí.
const double profileCompareHalfWindowMeters = 50;

/// Altitud (m) de una presión (hPa) en la atmósfera estándar. El nivel
/// absoluto depende del clima del día; por eso del barómetro solo se usan
/// los cambios.
double barometricAltitude(double pressureHpa) =>
    44330.0 * (1 - math.pow(pressureHpa / 1013.25, 1 / 5.255));

/// Fuentes de altura de una salida, alineadas punto a punto. `null`
/// donde la fuente no tiene dato.
class ProfileSources {
  final List<double> distances;

  /// Copernicus GLO-30 (teselas descargadas).
  final List<double?> model;

  /// GPX importado, ya anclado al modelo (`GpxTrackRepository`).
  final List<double?> gpx;

  /// Presión del barómetro (hPa).
  final List<double?> pressures;

  /// Altitud que se calculó en vivo (capas 1 y 2): solo pesa cuando no
  /// hay barómetro, en salidas grabadas antes de guardar la presión.
  final List<double> live;

  /// Velocidad (m/s): a alta velocidad el viento mueve la presión.
  final List<double> speeds;

  const ProfileSources({
    required this.distances,
    required this.model,
    required this.gpx,
    required this.pressures,
    required this.live,
    required this.speeds,
  });

  int get length => distances.length;
}

/// Cuánto pesó cada fuente en el perfil final (fracciones que suman 1).
class ProfileSourceShares {
  final double barometer;
  final double model;
  final double gpx;
  final double live;

  const ProfileSourceShares({
    this.barometer = 0,
    this.model = 0,
    this.gpx = 0,
    this.live = 0,
  });
}

class ProfileFusionResult {
  final List<double> altitudes;
  final ProfileSourceShares shares;

  /// Se usó el barómetro (había presión en suficientes puntos).
  final bool barometric;

  const ProfileFusionResult({
    required this.altitudes,
    required this.shares,
    required this.barometric,
  });
}

/// CAPA 3 del modelo geoespacial: arma el perfil de una salida guardada
/// pesando, tramo por tramo y con lógica difusa (Sugeno de orden cero,
/// como las capas 1 y 2), cuánto creerle a cada fuente:
///
///   - el **barómetro**: mide muy bien los cambios de altura, pero el
///     viento lo mueve a alta velocidad;
///   - **Copernicus**: sabe la altura real, pero en la ciudad mide techos
///     y árboles (se ve "rugoso") y bajo un puente marca el valle;
///   - el **GPX** importado: su forma vale si coincide con las demás;
///   - la **altitud en vivo**: respaldo para salidas sin presión guardada.
///
/// Las fuentes se combinan en sus CAMBIOS de altura (cada una tiene su
/// propio nivel: el barómetro depende del clima); el perfil resultante se
/// corrige después al nivel del modelo en ventanas de
/// [profileLevelWindowMeters]. Así ninguna fuente "gana" por prioridad
/// fija: la que mejor describe cada tramo es la que más pesa.
class ProfileFusionFilter {
  /// Cuánto se le cree al modelo (Copernicus) en un tramo.
  late final FuzzyInferenceEngine _modelTrust = FuzzyInferenceEngine(
    fallbackOutput: 0.6,
    rules: [
      // Sin barómetro, un modelo liso es la mejor forma que hay.
      FuzzyRule(
        name: 'modelo_liso_sin_barometro',
        firingStrength: (d) =>
            FuzzyRule.and([d['modeloLiso']!, d['sinBarometro']!]),
        outputValue: 0.9,
      ),
      // Con el barómetro en calma (rodando lento), su forma es mejor que
      // la de cualquier modelo de 30 m: el modelo casi solo da el nivel.
      // En la prueba con un barómetro simulado, repartir 50/50 en las
      // subidas daba más error que dejarle la forma al barómetro.
      FuzzyRule(
        name: 'barometro_en_calma',
        firingStrength: (d) => FuzzyRule.and([d['hayBarometro']!, d['lento']!]),
        outputValue: 0.2,
      ),
      // Modelo rugoso: techos y árboles de la ciudad, no la vía.
      FuzzyRule(
        name: 'modelo_rugoso_desconfia',
        firingStrength: (d) => d['modeloRugoso']!,
        outputValue: 0.25,
      ),
      // A alta velocidad el barómetro sufre con el viento: el modelo
      // pone la forma.
      FuzzyRule(
        name: 'rapido_confia_modelo',
        firingStrength: (d) => d['rapido']!,
        outputValue: 0.95,
      ),
      // Rodando lento, el modelo contradice al barómetro de forma
      // sostenida: puente, túnel o artefacto del modelo.
      FuzzyRule(
        name: 'modelo_contradice_barometro',
        firingStrength: (d) =>
            FuzzyRule.and([d['discrepanciaBarometro']!, d['lento']!]),
        outputValue: 0.15,
      ),
    ],
  );

  /// Cuánto se le cree al barómetro en un tramo.
  late final FuzzyInferenceEngine _barometerTrust = FuzzyInferenceEngine(
    fallbackOutput: 0.7,
    rules: [
      FuzzyRule(
        name: 'barometro_lento_confia',
        firingStrength: (d) => d['lento']!,
        outputValue: 0.9,
      ),
      FuzzyRule(
        name: 'barometro_con_viento',
        firingStrength: (d) => d['rapido']!,
        outputValue: 0.25,
      ),
      // Donde el modelo es rugoso, la forma buena es la del barómetro.
      FuzzyRule(
        name: 'barometro_en_ciudad',
        firingStrength: (d) => d['modeloRugoso']!,
        outputValue: 0.95,
      ),
    ],
  );

  /// Cuánto se le cree al GPX en un tramo.
  late final FuzzyInferenceEngine _gpxTrust = FuzzyInferenceEngine(
    fallbackOutput: 0.7,
    rules: [
      FuzzyRule(
        name: 'gpx_coincide',
        firingStrength: (d) => d['gpxCoincide']!,
        outputValue: 0.95,
      ),
      FuzzyRule(
        name: 'gpx_discrepa',
        firingStrength: (d) => d['gpxDiscrepa']!,
        outputValue: 0.2,
      ),
    ],
  );

  /// Cuánto se le cree a la altitud en vivo (solo sin barómetro).
  late final FuzzyInferenceEngine _liveTrust = FuzzyInferenceEngine(
    fallbackOutput: 0.2,
    rules: [
      FuzzyRule(
        name: 'vivo_coincide',
        firingStrength: (d) => d['vivoCoincide']!,
        outputValue: 0.5,
      ),
      // En la salida a La Calera del 28-oct-2026, la altitud en vivo de
      // un tramo sin modelo salió exagerada 3-4 veces: si contradice a
      // las demás, casi no pesa.
      FuzzyRule(
        name: 'vivo_discrepa',
        firingStrength: (d) => d['vivoDiscrepa']!,
        outputValue: 0.05,
      ),
    ],
  );

  ProfileFusionResult fuse(ProfileSources s) {
    final n = s.length;
    if (n == 0) {
      return const ProfileFusionResult(
        altitudes: [],
        shares: ProfileSourceShares(),
        barometric: false,
      );
    }
    final d = s.distances;
    final withPressure = s.pressures.where((p) => p != null).length;
    final barometric = withPressure >= n * barometricMinCoverage;
    // Los huecos del barómetro (lecturas que no llegaron) se rellenan
    // interpolando: si no, en un tramo sin modelo se colaba la altitud en
    // vivo justo en esos pasos.
    final List<double?> baro = barometric
        ? _fillGaps([
            for (final p in s.pressures)
              p == null ? null : barometricAltitude(p),
          ], d)
        : List<double?>.filled(n, null);
    final live = <double?>[for (final h in s.live) barometric ? null : h];

    const half = profileCompareHalfWindowMeters;
    final roughness = _roughness(s.model, d, half);
    final modelSlope = _chordSlopes(s.model, d, half);
    final baroSlope = _chordSlopes(baro, d, half);
    final gpxSlope = _chordSlopes(s.gpx, d, half);
    final liveSlope = _chordSlopes(live, d, half);

    // --- Pesos de cada fuente en cada punto (lógica difusa). ---
    final weights = List.generate(n, (_) => List<double>.filled(4, 0));
    for (var i = 0; i < n; i++) {
      final kmh = s.speeds[i] * 3.6;
      final reference = baroSlope[i] ?? modelSlope[i];
      final degrees = <String, double>{
        'hayBarometro': baro[i] == null ? 0 : 1,
        'sinBarometro': baro[i] == null ? 1 : 0,
        'modeloLiso': roughness[i] == null
            ? 0
            : rampDown(roughness[i]!, 0.6, 1.6),
        'modeloRugoso': roughness[i] == null
            ? 0
            : rampUp(roughness[i]!, 1.0, 2.5),
        'rapido': rampUp(kmh, 35, 55),
        'lento': rampDown(kmh, 30, 45),
        'discrepanciaBarometro': baroSlope[i] == null || modelSlope[i] == null
            ? 0
            : rampUp((baroSlope[i]! - modelSlope[i]!).abs(), 2, 6),
        'gpxCoincide': gpxSlope[i] == null || reference == null
            ? 0
            : rampDown((gpxSlope[i]! - reference).abs(), 1, 3),
        'gpxDiscrepa': gpxSlope[i] == null || reference == null
            ? 0
            : rampUp((gpxSlope[i]! - reference).abs(), 2, 6),
        'vivoCoincide': liveSlope[i] == null || modelSlope[i] == null
            ? 0
            : rampDown((liveSlope[i]! - modelSlope[i]!).abs(), 1, 3),
        'vivoDiscrepa': liveSlope[i] == null || modelSlope[i] == null
            ? 0
            : rampUp((liveSlope[i]! - modelSlope[i]!).abs(), 2, 5),
      };
      weights[i][0] = baro[i] == null ? 0 : _barometerTrust.infer(degrees);
      weights[i][1] = s.model[i] == null ? 0 : _modelTrust.infer(degrees);
      weights[i][2] = s.gpx[i] == null ? 0 : _gpxTrust.infer(degrees);
      weights[i][3] = live[i] == null ? 0 : _liveTrust.infer(degrees);
    }

    // --- Forma: cambios de altura de cada fuente, pesados. ---
    final sources = [baro, s.model, s.gpx, live];
    final used = List<double>.filled(4, 0);
    final shape = List<double>.filled(n, 0);
    for (var i = 1; i < n; i++) {
      var sum = 0.0;
      var total = 0.0;
      final stepWeights = List<double>.filled(4, 0);
      for (var k = 0; k < 4; k++) {
        final a = sources[k][i - 1];
        final b = sources[k][i];
        if (a == null || b == null) continue;
        final w = weights[i][k];
        if (w <= 0) continue;
        sum += w * (b - a);
        total += w;
        stepWeights[k] = w;
      }
      if (total <= 0) {
        // Ninguna fuente cubre este paso: la altitud en vivo, aunque no
        // se le crea, es mejor que un escalón plano.
        shape[i] = shape[i - 1] + (s.live[i] - s.live[i - 1]);
        used[3] += 1;
        continue;
      }
      shape[i] = shape[i - 1] + sum / total;
      for (var k = 0; k < 4; k++) {
        used[k] += stepWeights[k] / total;
      }
    }

    // --- Nivel: el del modelo (o del GPX donde no hay modelo). ---
    final residual = <double?>[
      for (var i = 0; i < n; i++)
        (s.model[i] ?? s.gpx[i]) == null
            ? null
            : (s.model[i] ?? s.gpx[i])! - shape[i],
    ];
    List<double> altitudes;
    if (residual.every((r) => r == null)) {
      // Sin modelo ni GPX en toda la salida: el nivel lo pone la altitud
      // en vivo, con la mediana para que un mal arranque no pese.
      final offset = _median([
        for (var i = 0; i < n; i++) s.live[i] - shape[i],
      ]);
      altitudes = [for (final h in shape) h + offset];
    } else {
      // Primero una mediana (un puente o un edificio en el modelo no la
      // mueven) y luego un promedio (para que no quede en escalones).
      const levelHalf = profileLevelWindowMeters / 2;
      final median = _windowed(residual, d, levelHalf, _median);
      final level = _fillGaps(_windowed(median, d, levelHalf, _mean), d);
      altitudes = [for (var i = 0; i < n; i++) shape[i] + level[i]];
    }

    final steps = math.max(1, n - 1);
    return ProfileFusionResult(
      altitudes: altitudes,
      barometric: barometric,
      shares: ProfileSourceShares(
        barometer: used[0] / steps,
        model: used[1] / steps,
        gpx: used[2] / steps,
        live: used[3] / steps,
      ),
    );
  }

  /// Pendiente (%) de [values] entre los puntos con dato más alejados
  /// dentro de ±[half] metros; `null` si no abarcan al menos [half].
  static List<double?> _chordSlopes(
    List<double?> values,
    List<double> d,
    double half,
  ) {
    final out = List<double?>.filled(values.length, null);
    var from = 0;
    var to = 0;
    for (var i = 0; i < values.length; i++) {
      while (from < values.length && d[from] < d[i] - half) {
        from++;
      }
      while (to < values.length && d[to] <= d[i] + half) {
        to++;
      }
      var a = from;
      while (a < to && values[a] == null) {
        a++;
      }
      var b = to - 1;
      while (b > a && values[b] == null) {
        b--;
      }
      if (b <= a || values[a] == null || values[b] == null) continue;
      final run = d[b] - d[a];
      if (run < half) continue;
      out[i] = 100 * (values[b]! - values[a]!) / run;
    }
    return out;
  }

  /// Rugosidad del modelo: desviación (m) respecto de su propio promedio
  /// en ±[half] metros. Una vía lisa da décimas; una calle con edificios
  /// y árboles en el modelo, uno o dos metros.
  static List<double?> _roughness(
    List<double?> model,
    List<double> d,
    double half,
  ) {
    final smooth = _windowed(model, d, half, _mean);
    final squared = <double?>[
      for (var i = 0; i < model.length; i++)
        model[i] == null || smooth[i] == null
            ? null
            : math.pow(model[i]! - smooth[i]!, 2).toDouble(),
    ];
    return [
      for (final v in _windowed(squared, d, half, _mean))
        v == null ? null : math.sqrt(v),
    ];
  }
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
  final window = <double>[];
  for (var i = 0; i < values.length; i++) {
    while (from < values.length && distances[from] < distances[i] - half) {
      from++;
    }
    while (to < values.length && distances[to] <= distances[i] + half) {
      to++;
    }
    window.clear();
    for (var k = from; k < to; k++) {
      if (values[k] != null) window.add(values[k]!);
    }
    if (window.isEmpty) continue;
    out[i] = reduce(window);
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
    if (i < a || k == known.length - 1) {
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
