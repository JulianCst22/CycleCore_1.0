import 'dart:math' as math;

import 'package:cyclecore_app/core/fuzzy_type2/fuzzy_type2.dart'
    show Implication, TNorm;
import 'package:cyclecore_app/features/coaching/domain/coaching_parameters.dart';
import 'package:cyclecore_app/features/coaching/domain/replay/ride_recording.dart';
import 'package:cyclecore_app/features/coaching/domain/replay/ride_replay.dart';

/// Una variante del motor que se quiere comparar con la del anexo.
typedef SensitivityCase = ({
  String name,
  String group,
  InferenceMode mode,
  CoachingParameters parameters,
});

/// Lo que cambió esa variante frente a la base, en la misma grabación.
typedef SensitivityRow = ({
  SensitivityCase variant,
  int advices,
  double advicesPer20Minutes,
  double? complianceRate,
  double meanAdjustment,
  double meanTargetWatts,
  double meanTargetShiftWatts,
  double maxTargetShiftWatts,
  double differentActionShare,
  double meanUrgency,
  double meanRelativeWidth,
  int inferenceMicrosP95,
});

/// El barrido de la tesis: los quiebres ±10 %, las t-normas de cada
/// motor, la implicación y tipo-1 contra tipo-2.
///
/// Todo sale de [CoachingParameters], así que una variante es un dato,
/// no una rama de código.
List<SensitivityCase> defaultSensitivityCases() => [
  (
    name: 'base (anexo)',
    group: 'base',
    mode: InferenceMode.type2,
    parameters: const CoachingParameters(),
  ),
  for (final scale in const [0.90, 0.95, 1.05, 1.10])
    (
      name:
          'quiebres ${scale > 1 ? '+' : '−'}'
          '${((scale - 1).abs() * 100).round()} %',
      group: 'quiebres',
      mode: InferenceMode.type2,
      parameters: CoachingParameters(breakpointScale: scale),
    ),
  (
    name: 'Y de C: mínimo',
    group: 't-norma',
    mode: InferenceMode.type2,
    parameters: const CoachingParameters(decisionAnd: TNorm.minimum),
  ),
  (
    name: 'Y de C: Łukasiewicz',
    group: 't-norma',
    mode: InferenceMode.type2,
    parameters: const CoachingParameters(decisionAnd: TNorm.lukasiewicz),
  ),
  (
    name: 'Y de A y B: producto',
    group: 't-norma',
    mode: InferenceMode.type2,
    parameters: const CoachingParameters(
      effortAnd: TNorm.product,
      terrainAnd: TNorm.product,
    ),
  ),
  (
    name: 'implicación de Larsen',
    group: 'implicación',
    mode: InferenceMode.type2,
    parameters: const CoachingParameters(implication: Implication.scale),
  ),
  (
    name: 'tipo-1',
    group: 'tipo',
    mode: InferenceMode.type1,
    parameters: const CoachingParameters(),
  ),
];

/// Corre cada variante sobre la misma grabación y la compara con la
/// primera (la base).
///
/// La comparación es instante a instante: el reloj de inferencia depende
/// del terreno, no de los parámetros, así que las dos corridas piensan
/// en los mismos segundos y los objetivos se pueden restar.
List<SensitivityRow> runSensitivity(
  RideRecording recording, {
  List<SensitivityCase>? cases,
}) {
  final variants = cases ?? defaultSensitivityCases();
  final results = [
    for (final variant in variants)
      replayRide(recording, mode: variant.mode, parameters: variant.parameters),
  ];
  final base = results.first;
  final baseTargets = {
    for (final row in base.rows) row.second: row.advice.power?.spoken,
  };
  final baseActions = {
    for (final row in base.rows)
      row.second: row.advice.decision.advisedAdjustment,
  };

  final rows = <SensitivityRow>[];
  for (var i = 0; i < variants.length; i++) {
    final result = results[i];
    var adjustment = 0.0, target = 0.0, urgency = 0.0, width = 0.0;
    var shift = 0.0, maxShift = 0.0;
    var compared = 0, different = 0, targets = 0, counted = 0;
    for (final row in result.rows) {
      final decision = row.advice.decision;
      final value = decision.adjustment.value;
      if (value == null) continue;
      counted++;
      adjustment += value;
      urgency += decision.urgency.value ?? 0;
      width += decision.adjustment.relativeUncertainty ?? 0;

      final watts = row.advice.power?.spoken;
      if (watts != null) {
        targets++;
        target += watts;
        final reference = baseTargets[row.second];
        if (reference != null) {
          final delta = (watts - reference).abs();
          shift += delta;
          maxShift = math.max(maxShift, delta);
        }
      }
      final action = decision.advisedAdjustment;
      final baseAction = baseActions[row.second];
      if (baseAction != null) {
        compared++;
        if (action != baseAction) different++;
      }
    }
    rows.add((
      variant: variants[i],
      advices: result.advices.length,
      advicesPer20Minutes: result.advicesPer20Minutes,
      complianceRate: result.compliance().rate,
      meanAdjustment: counted == 0 ? 0 : adjustment / counted,
      meanTargetWatts: targets == 0 ? 0 : target / targets,
      meanTargetShiftWatts: targets == 0 ? 0 : shift / targets,
      maxTargetShiftWatts: maxShift,
      differentActionShare: compared == 0 ? 0 : different / compared,
      meanUrgency: counted == 0 ? 0 : urgency / counted,
      meanRelativeWidth: counted == 0 ? 0 : width / counted,
      inferenceMicrosP95: result.inferenceMicros(0.95) ?? 0,
    ));
  }
  return rows;
}

/// La tabla de sensibilidad como CSV.
String sensitivityCsv(List<SensitivityRow> rows) {
  final buffer = StringBuffer(
    'variante,grupo,modo,avisos,avisos_por_20min,cumplimiento,'
    'ajuste_medio,objetivo_medio_w,dif_objetivo_media_w,'
    'dif_objetivo_max_w,accion_distinta_pct,urgencia_media,'
    'ancho_relativo_medio,micros_p95\n',
  );
  for (final row in rows) {
    buffer.writeln(
      [
        '"${row.variant.name}"',
        row.variant.group,
        row.variant.mode.name,
        row.advices,
        row.advicesPer20Minutes.toStringAsFixed(2),
        row.complianceRate?.toStringAsFixed(3) ?? '',
        row.meanAdjustment.toStringAsFixed(2),
        row.meanTargetWatts.toStringAsFixed(1),
        row.meanTargetShiftWatts.toStringAsFixed(2),
        row.maxTargetShiftWatts.toStringAsFixed(1),
        (100 * row.differentActionShare).toStringAsFixed(1),
        row.meanUrgency.toStringAsFixed(3),
        row.meanRelativeWidth.toStringAsFixed(4),
        row.inferenceMicrosP95,
      ].join(','),
    );
  }
  return buffer.toString();
}
