import 'package:cyclecore_app/features/coaching/domain/evaluation/agreement.dart';
import 'package:cyclecore_app/features/coaching/domain/evaluation/label_sheet.dart';
import 'package:cyclecore_app/features/coaching/domain/replay/ride_replay.dart';
import 'package:cyclecore_app/features/coaching/domain/variables/labels.dart';

import 'field_report.dart';
import 'sensitivity.dart';

/// Qué tan de acuerdo queda cada variante del motor con los expertos.
typedef TuningRow = ({
  SensitivityCase variant,
  AgreementReport agreement,
  int advices,
});

/// Busca, entre las variantes del barrido, la que más coincide con lo
/// que dijeron los expertos.
///
/// La comparación es **en los mismos instantes**: el experto etiquetó
/// los segundos que eligió el motor del anexo, así que cada variante se
/// evalúa en esos segundos y no en los suyos. Si no, se compararían
/// momentos distintos y el κ no querría decir nada.
///
/// Esto no cambia el motor: propone. Cambiar un quiebre o una certeza
/// sigue siendo una decisión escrita, con su razón.
List<TuningRow> tuneAgainstLabels(
  List<FieldRide> rides,
  Map<String, Adjustment> labels, {
  List<SensitivityCase>? cases,
}) {
  final variants = cases ?? defaultSensitivityCases();

  // id de la hoja → (salida, segundo) del aviso que se etiquetó.
  final labelled = <({int ride, int second, Adjustment expert})>[];
  for (var i = 0; i < rides.length; i++) {
    for (final row in labelRowsOf(rides[i].result, prefix: 'r${i + 1}-')) {
      final expert = labels[row.id];
      if (expert != null) {
        labelled.add((ride: i, second: row.second, expert: expert));
      }
    }
  }
  if (labelled.isEmpty) return const [];

  final rows = <TuningRow>[];
  for (final variant in variants) {
    final byRide = [
      for (final ride in rides)
        replayRide(
          ride.result.recording,
          mode: variant.mode,
          parameters: variant.parameters,
        ),
    ];
    final actionAt = <String, Adjustment>{};
    var advices = 0;
    for (var i = 0; i < byRide.length; i++) {
      advices += byRide[i].advices.length;
      for (final row in byRide[i].rows) {
        final action = row.advice.decision.advisedAdjustment;
        if (action != null) actionAt['$i/${row.second}'] = action;
      }
    }

    final engine = <Adjustment>[];
    final expert = <Adjustment>[];
    for (final entry in labelled) {
      final action = actionAt['${entry.ride}/${entry.second}'];
      if (action == null) continue;
      engine.add(action);
      expert.add(entry.expert);
    }
    if (engine.isEmpty) continue;
    rows.add((
      variant: variant,
      agreement: AgreementReport.of(engine, expert),
      advices: advices,
    ));
  }
  rows.sort((a, b) => b.agreement.kappa.compareTo(a.agreement.kappa));
  return rows;
}

/// La tabla de ajuste en CSV, de la variante más parecida al experto a
/// la que menos.
String tuningCsv(List<TuningRow> rows) {
  final buffer = StringBuffer(
    'variante,grupo,modo,n,kappa,kappa_ponderado,acuerdo_observado,'
    'a_una_casilla,avisos\n',
  );
  for (final row in rows) {
    final agreement = row.agreement;
    buffer.writeln(
      [
        '"${row.variant.name}"',
        row.variant.group,
        row.variant.mode.name,
        agreement.count,
        agreement.kappa.toStringAsFixed(3),
        agreement.weightedKappa().toStringAsFixed(3),
        agreement.observed.toStringAsFixed(3),
        agreement.withinOneStep.toStringAsFixed(3),
        row.advices,
      ].join(','),
    );
  }
  return buffer.toString();
}
