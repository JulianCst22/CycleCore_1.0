import 'dart:math' as math;

import '../variables/labels.dart';

/// Cuánto coincide el coach con un experto humano.
///
/// La escala es ordinal (soltar mucho → apretar mucho), así que además
/// del κ de Cohen clásico se calcula el κ ponderado: equivocarse por una
/// casilla no es lo mismo que recomendar lo contrario. La meta de la
/// tesis (κ ≥ 0,6) se mide con el κ sin ponderar, que es el más
/// exigente.
final class AgreementReport {
  /// Filas comparadas (consejos que el experto etiquetó).
  final int count;

  /// `matrix[motor][experto]`, en el orden de [Adjustment.values].
  final List<List<int>> matrix;

  AgreementReport._(this.count, List<List<int>> matrix)
    : matrix = List<List<int>>.unmodifiable([
        for (final row in matrix) List<int>.unmodifiable(row),
      ]);

  /// Compara las decisiones del motor con las del experto, en orden.
  factory AgreementReport.of(List<Adjustment> engine, List<Adjustment> expert) {
    if (engine.length != expert.length) {
      throw ArgumentError('Las dos listas deben tener el mismo largo.');
    }
    final size = Adjustment.values.length;
    final matrix = [for (var i = 0; i < size; i++) List.filled(size, 0)];
    for (var i = 0; i < engine.length; i++) {
      matrix[engine[i].index][expert[i].index]++;
    }
    return AgreementReport._(engine.length, matrix);
  }

  /// Acuerdo observado: la proporción de veces que coincidieron.
  double get observed => count == 0 ? 0 : _diagonal() / count;

  /// Acuerdo que saldría solo por azar, con las mismas preferencias de
  /// cada uno.
  double get expected {
    if (count == 0) return 0;
    var sum = 0.0;
    for (var i = 0; i < matrix.length; i++) {
      sum += _rowTotal(i) * _columnTotal(i) / count;
    }
    return sum / count;
  }

  /// κ de Cohen: el acuerdo que hay por encima del azar.
  double get kappa {
    final pe = expected;
    return (1 - pe).abs() < 1e-12 ? 1 : (observed - pe) / (1 - pe);
  }

  /// κ ponderado: un desacuerdo de una casilla pesa menos que uno de
  /// cuatro. Con [quadratic] el castigo crece con el cuadrado de la
  /// distancia (Fleiss–Cohen); si no, es lineal.
  double weightedKappa({bool quadratic = false}) {
    if (count == 0) return 0;
    final size = matrix.length;
    final maxDistance = (size - 1).toDouble();
    double weight(int i, int j) {
      final distance = (i - j).abs() / maxDistance;
      return 1 - (quadratic ? distance * distance : distance);
    }

    var observedSum = 0.0, expectedSum = 0.0;
    for (var i = 0; i < size; i++) {
      for (var j = 0; j < size; j++) {
        final chance = _rowTotal(i) * _columnTotal(j) / count;
        observedSum += weight(i, j) * matrix[i][j];
        expectedSum += weight(i, j) * chance;
      }
    }
    final pe = expectedSum / count;
    return (1 - pe).abs() < 1e-12 ? 1 : (observedSum / count - pe) / (1 - pe);
  }

  /// Acuerdo «de vecindad»: coincidieron o se separaron por una sola
  /// casilla. Es la cifra que suele importar en la calle: nadie nota la
  /// diferencia entre «soltar» y «soltar mucho», pero sí entre soltar y
  /// apretar.
  double get withinOneStep {
    if (count == 0) return 0;
    var near = 0;
    for (var i = 0; i < matrix.length; i++) {
      for (var j = 0; j < matrix.length; j++) {
        if ((i - j).abs() <= 1) near += matrix[i][j];
      }
    }
    return near / count;
  }

  /// Error típico del κ (aproximación de Fleiss) y su intervalo del
  /// 95 %. Sin datos suficientes el intervalo no dice nada, pero con
  /// treinta consejos ya orienta.
  double get standardError {
    if (count < 2) return double.nan;
    final po = observed, pe = expected;
    final denominator = count * (1 - pe) * (1 - pe);
    if (denominator.abs() < 1e-12) return double.nan;
    return math.sqrt(po * (1 - po) / denominator);
  }

  ({double lo, double hi}) get confidence95 {
    final se = standardError;
    if (se.isNaN) return (lo: double.nan, hi: double.nan);
    return (lo: kappa - 1.96 * se, hi: kappa + 1.96 * se);
  }

  /// Lectura habitual del κ (escala de Landis y Koch).
  String get reading => switch (kappa) {
    < 0 => 'peor que el azar',
    < 0.20 => 'leve',
    < 0.40 => 'aceptable',
    < 0.60 => 'moderado',
    < 0.80 => 'sustancial',
    _ => 'casi perfecto',
  };

  /// La meta de la fase: κ ≥ 0,6.
  bool get meetsGoal => kappa >= 0.6;

  int _diagonal() {
    var sum = 0;
    for (var i = 0; i < matrix.length; i++) {
      sum += matrix[i][i];
    }
    return sum;
  }

  int _rowTotal(int i) => matrix[i].fold(0, (a, b) => a + b);

  int _columnTotal(int j) {
    var sum = 0;
    for (final row in matrix) {
      sum += row[j];
    }
    return sum;
  }

  /// La matriz de confusión como CSV, con el motor en las filas.
  String toCsv() {
    final labels = Adjustment.values.map((a) => a.name);
    final buffer = StringBuffer('motor\\experto,${labels.join(',')},total\n');
    for (var i = 0; i < matrix.length; i++) {
      buffer.writeln(
        '${Adjustment.values[i].name},${matrix[i].join(',')},${_rowTotal(i)}',
      );
    }
    buffer.writeln(
      'total,'
      '${[for (var j = 0; j < matrix.length; j++) _columnTotal(j)].join(',')},'
      '$count',
    );
    return buffer.toString();
  }
}

/// Acuerdo con varios expertos: el κ de Cohen de cada uno contra el
/// motor, más el promedio.
///
/// Se usa Cohen por experto (y no Fleiss) porque el motor no es «un
/// juez más»: es el sistema que se está evaluando, y lo que interesa es
/// cuánto coincide cada humano con él.
typedef PanelAgreement = ({
  Map<String, AgreementReport> byExpert,
  double meanKappa,
  bool meetsGoal,
});

PanelAgreement panelAgreement(Map<String, AgreementReport> byExpert) {
  if (byExpert.isEmpty) {
    return (byExpert: const {}, meanKappa: 0, meetsGoal: false);
  }
  final mean =
      byExpert.values.map((r) => r.kappa).reduce((a, b) => a + b) /
      byExpert.length;
  return (
    byExpert: Map.unmodifiable(byExpert),
    meanKappa: mean,
    meetsGoal: mean >= 0.6,
  );
}
