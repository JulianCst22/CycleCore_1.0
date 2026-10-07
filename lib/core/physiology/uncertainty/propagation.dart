import 'dart:math' as math;

import 'covariance.dart';

/// Función de un vector de entradas: el cálculo cuya incertidumbre se
/// quiere conocer.
typedef VectorFunction = double Function(List<double> x);

/// Propagación de primer orden (GUM, JCGM 100):
///
///     u²(f) = Σᵢ Σⱼ ∂f/∂xᵢ · ∂f/∂xⱼ · cov(xᵢ, xⱼ) = J·Σ·Jᵀ
///
/// Las derivadas se calculan por diferencias centrales. Sirve para
/// funciones casi lineales en el rango de la incertidumbre (intensidad,
/// reserva cardíaca, torque); para las que no lo son, usar
/// [propagateMonteCarlo].
UncertainValue propagateLinear(
  VectorFunction f,
  List<double> mean,
  Covariance covariance,
) {
  assert(mean.length == covariance.size);
  final n = mean.length;
  final jacobian = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    final h = math.max(mean[i].abs(), 1.0) * 1e-6;
    final plus = [...mean]..[i] += h;
    final minus = [...mean]..[i] -= h;
    jacobian[i] = (f(plus) - f(minus)) / (2 * h);
  }
  var variance = 0.0;
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < n; j++) {
      variance += jacobian[i] * jacobian[j] * covariance.matrix[i][j];
    }
  }
  return UncertainValue.symmetric(f(mean), math.sqrt(math.max(0, variance)));
}

/// Propagación por Monte Carlo (GUM Suplemento 1, JCGM 101).
///
/// Genera [samples] vectores normales con la [covariance] dada, evalúa
/// [f] en cada uno y devuelve la mediana como valor y los percentiles
/// 15,87 y 84,13 como banda de ±1σ. No asume linealidad: es la opción
/// correcta para la suficiencia de W′, que divide por `P − CP`.
///
/// Con la misma [seed] el resultado es reproducible.
UncertainValue propagateMonteCarlo(
  VectorFunction f,
  List<double> mean,
  Covariance covariance, {
  int samples = 2000,
  int seed = 1,
}) {
  assert(samples > 1);
  final results = List<double>.filled(samples, 0);
  var sum = 0.0, sumSq = 0.0, s = 0;
  _sample(mean, covariance, samples, seed, (x) {
    final y = f(x);
    results[s++] = y;
    sum += y;
    sumSq += y * y;
  });
  results.sort();
  final m = sum / samples;
  return UncertainValue(
    value: _percentile(results, 0.5),
    standardUncertainty: math.sqrt(math.max(0, sumSq / samples - m * m)),
    lo: _percentile(results, 0.158655),
    hi: _percentile(results, 0.841345),
  );
}

/// Probabilidad de que [condition] se cumpla bajo la incertidumbre de las
/// entradas (fracción de muestras de Monte Carlo en que se cumple).
double probabilityMonteCarlo(
  bool Function(List<double> x) condition,
  List<double> mean,
  Covariance covariance, {
  int samples = 2000,
  int seed = 1,
}) {
  var hits = 0;
  _sample(mean, covariance, samples, seed, (x) {
    if (condition(x)) hits++;
  });
  return hits / samples;
}

/// Muestras de una normal multivariada con la [covariance] dada: cada
/// una es un conjunto de entradas posibles (por ejemplo, un atleta
/// compatible con la calibración). Con la misma [seed] el resultado es
/// reproducible.
List<List<double>> sampleMultivariateNormal(
  List<double> mean,
  Covariance covariance, {
  int samples = 2000,
  int seed = 1,
}) {
  final out = <List<double>>[];
  _sample(mean, covariance, samples, seed, (x) => out.add(List.of(x)));
  return out;
}

/// Percentil [p] (0–1) de una lista ya ordenada.
double percentileOfSorted(List<double> sorted, double p) =>
    _percentile(sorted, p);

/// Percentil [p] (0–1) sin ordenar toda la lista: solo deja el elemento
/// buscado en su sitio (selección rápida, lineal en promedio). Reordena
/// [values] parcialmente, así que si el orden original importa hay que
/// pasarle una copia.
///
/// Con miles de muestras y unos pocos percentiles sale mucho más barato
/// que ordenar: es lo que permite recalcular las bandas del conjunto de
/// atletas posibles en cada inferencia.
double percentileInPlace(List<double> values, double p) {
  if (values.isEmpty) return 0;
  final target = (p * (values.length - 1)).round().clamp(0, values.length - 1);
  var low = 0, high = values.length - 1;
  while (low < high) {
    final pivot = values[(low + high) >> 1];
    var i = low, j = high;
    while (i <= j) {
      while (values[i] < pivot) {
        i++;
      }
      while (values[j] > pivot) {
        j--;
      }
      if (i <= j) {
        final swap = values[i];
        values[i] = values[j];
        values[j] = swap;
        i++;
        j--;
      }
    }
    if (target <= j) {
      high = j;
    } else if (target >= i) {
      low = i;
    } else {
      return values[target];
    }
  }
  return values[target];
}

/// Genera [samples] vectores `mean + L·z`, con `L` el factor de Cholesky
/// de la covarianza y `z` normal estándar, y se los pasa a [visit]. El
/// vector se reutiliza entre muestras: [visit] no debe guardarlo.
void _sample(
  List<double> mean,
  Covariance covariance,
  int samples,
  int seed,
  void Function(List<double> x) visit,
) {
  assert(mean.length == covariance.size);
  final n = mean.length;
  final l = covariance.cholesky();
  final rnd = math.Random(seed);
  final z = List<double>.filled(n, 0);
  final x = List<double>.filled(n, 0);
  for (var s = 0; s < samples; s++) {
    for (var i = 0; i < n; i++) {
      z[i] = _standardNormal(rnd);
    }
    for (var i = 0; i < n; i++) {
      var v = mean[i];
      for (var k = 0; k <= i; k++) {
        v += l[i][k] * z[k];
      }
      x[i] = v;
    }
    visit(x);
  }
}

/// Normal estándar por Box–Muller.
double _standardNormal(math.Random rnd) {
  var u = 0.0;
  while (u == 0) {
    u = rnd.nextDouble();
  }
  final v = rnd.nextDouble();
  return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
}

double _percentile(List<double> sorted, double p) {
  final index = (p * (sorted.length - 1)).round();
  return sorted[index.clamp(0, sorted.length - 1)];
}
