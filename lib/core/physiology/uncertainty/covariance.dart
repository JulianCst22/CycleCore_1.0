import 'dart:math' as math;

/// Matriz de covarianza de un vector de entradas inciertas.
///
/// Se arma con las incertidumbres típicas de cada entrada y, si hace
/// falta, las correlaciones entre pares (por ejemplo, CP y W′ salen de la
/// misma regresión y están fuertemente correlacionadas).
final class Covariance {
  final List<List<double>> matrix;

  Covariance._(this.matrix);

  /// Entradas independientes con las incertidumbres típicas [sigmas].
  factory Covariance.diagonal(List<double> sigmas) {
    final n = sigmas.length;
    return Covariance._([
      for (var i = 0; i < n; i++)
        [for (var j = 0; j < n; j++) i == j ? sigmas[i] * sigmas[i] : 0.0],
    ]);
  }

  int get size => matrix.length;

  double sigma(int i) => math.sqrt(matrix[i][i]);

  /// Copia con la covarianza entre [i] y [j] fijada a [value].
  Covariance withCovariance(int i, int j, double value) {
    final m = [
      for (final row in matrix) [...row],
    ];
    m[i][j] = value;
    m[j][i] = value;
    return Covariance._(m);
  }

  /// Copia con la correlación entre [i] y [j] fijada a [rho] (−1 a 1).
  Covariance withCorrelation(int i, int j, double rho) {
    assert(rho >= -1 && rho <= 1);
    return withCovariance(i, j, rho * sigma(i) * sigma(j));
  }

  /// Factor de Cholesky `L` con `L·Lᵀ = Σ`, para generar muestras
  /// correlacionadas. Las entradas con varianza cero se toleran (su
  /// columna queda en cero).
  List<List<double>> cholesky() {
    final n = size;
    final l = [for (var i = 0; i < n; i++) List<double>.filled(n, 0)];
    for (var i = 0; i < n; i++) {
      for (var j = 0; j <= i; j++) {
        var sum = matrix[i][j];
        for (var k = 0; k < j; k++) {
          sum -= l[i][k] * l[j][k];
        }
        if (i == j) {
          if (sum < -1e-12) {
            throw StateError('La covarianza no es semidefinida positiva.');
          }
          l[i][i] = math.sqrt(math.max(0, sum));
        } else {
          l[i][j] = l[j][j] == 0 ? 0 : sum / l[j][j];
        }
      }
    }
    return l;
  }
}

/// Valor con su incertidumbre típica y la banda de ±1σ (68 %) que se usa
/// como intervalo de entrada del motor difuso.
final class UncertainValue {
  final double value;
  final double standardUncertainty;
  final double lo;
  final double hi;

  const UncertainValue({
    required this.value,
    required this.standardUncertainty,
    required this.lo,
    required this.hi,
  }) : assert(lo <= hi);

  /// Banda simétrica `value ± u`.
  factory UncertainValue.symmetric(double value, double u) => UncertainValue(
    value: value,
    standardUncertainty: u,
    lo: value - u,
    hi: value + u,
  );

  @override
  String toString() => '$value ± $standardUncertainty  [$lo, $hi]';
}
