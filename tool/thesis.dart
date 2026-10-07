// Herramientas de la tesis: reproduce una salida con el motor de
// coaching y regenera todas las tablas y figuras del documento.
//
//     dart run tool/thesis.dart                     (todo, con la subida simulada)
//     dart run tool/thesis.dart --grabacion mi.json (una salida de verdad)
//     dart run tool/thesis.dart --solo figuras      (solo una parte)
//
// Escribe en `build/tesis/`: las tablas en CSV y las figuras en SVG. Con
// la misma grabación y la misma semilla el resultado es idéntico, así
// que las figuras del documento se pueden rehacer cuando el motor
// cambie y se nota enseguida si algo se movió.
import 'dart:convert';
import 'dart:io';

import 'package:cyclecore_app/features/coaching/domain/coaching_parameters.dart';
import 'package:cyclecore_app/features/coaching/domain/evaluation/agreement.dart';
import 'package:cyclecore_app/features/coaching/domain/evaluation/label_sheet.dart';
import 'package:cyclecore_app/features/coaching/domain/engine/coaching_engine.dart';
import 'package:cyclecore_app/features/coaching/domain/message/message_bank.dart';
import 'package:cyclecore_app/features/coaching/domain/replay/replay_csv.dart';
import 'package:cyclecore_app/features/coaching/domain/replay/ride_recording.dart';
import 'package:cyclecore_app/features/coaching/domain/replay/ride_replay.dart';
import 'package:cyclecore_app/features/coaching/domain/variables/labels.dart';

import 'thesis/control_surface.dart';
import 'thesis/field_report.dart';
import 'thesis/sensitivity.dart';
import 'thesis/simulated_ride.dart';
import 'thesis/svg_chart.dart';
import 'thesis/tuning.dart';

const _parts = {'avisos', 'sensibilidad', 'superficies', 'figuras', 'campo'};

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  if (options.help) {
    stdout.write(_usage);
    return;
  }

  final recording = options.recordingPath == null
      ? simulatedPatiosRide()
      : RideRecording.parse(File(options.recordingPath!).readAsStringSync());
  if (!recording.hasPower) {
    stderr.writeln(
      'La grabación no trae potencia: sin potenciómetro el coach no habla.',
    );
    exitCode = 1;
    return;
  }
  final bank = MessageBank.parse(
    File('assets/coaching/messages/${options.persona}.json').readAsStringSync(),
  );

  final out = Directory(options.outputPath)..createSync(recursive: true);
  void write(String name, String contents) {
    final file = File('${out.path}/$name')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(contents);
    stdout.writeln('  ${file.path}');
  }

  stdout.writeln(
    'Grabación: ${recording.name} · ${recording.seconds} s · '
    '${recording.meters.round()} m'
    '${options.recordingPath == null ? ' (simulada)' : ''}',
  );

  final type2 = replayRide(recording, bank: bank, composerSeed: options.seed);
  final type1 = replayRide(
    recording,
    mode: InferenceMode.type1,
    bank: bank,
    composerSeed: options.seed,
  );

  // La misma subida sin potenciómetro: el motor estima la potencia con
  // la velocidad y la pendiente.
  final blind = replayRide(
    withoutPowerMeter(recording),
    bank: bank,
    composerSeed: options.seed,
  );

  if (options.wants('avisos')) {
    stdout.writeln('\nReproducción');
    write(
      'recorrido.json',
      const JsonEncoder.withIndent('  ').convert(recording.toJson()),
    );
    write('avisos.csv', replayAdvicesCsv(type2));
    write('inferencias.csv', replayTraceCsv(type2));
    write('inferencias_tipo1.csv', replayTraceCsv(type1));
    write('avisos_sin_potenciometro.csv', replayAdvicesCsv(blind));
    write('resumen.csv', replaySummaryCsv([type2, type1, blind]));
  }

  List<SensitivityRow>? sensitivity;
  if (options.wants('sensibilidad')) {
    stdout.writeln('\nSensibilidad');
    sensitivity = runSensitivity(recording);
    write('sensibilidad.csv', sensitivityCsv(sensitivity));
  }

  final surfaces = defaultSurfaces();
  if (options.wants('superficies')) {
    stdout.writeln('\nSuperficies de control');
    for (final surface in surfaces) {
      write('superficies/${_slug(surface.name)}.csv', surface.toCsv());
    }
  }

  if (options.wants('figuras')) {
    stdout.writeln('\nFiguras');
    for (final surface in surfaces) {
      write(
        'figuras/superficie_${_slug(surface.name)}.svg',
        surfaceSvg(surface),
      );
    }
    for (final variable in CoachingEngine().variables.all) {
      write(
        'figuras/particion_${_slug(variable.name)}.svg',
        membershipSvg(variable),
      );
    }
    write('figuras/recorrido_potencia.svg', _powerFigure(type2));
    write('figuras/recorrido_urgencia.svg', _urgencyFigure(type2));
    write('figuras/tipo1_vs_tipo2.svg', _typeFigure(type1, type2));
    write('figuras/sensibilidad_quiebres.svg', _breakpointFigure(recording));
    final footprint = _strongest(type2);
    if (footprint != null) {
      write(
        'figuras/huella_ajuste.svg',
        footprintSvg(
          footprint.advice.decision.adjustment,
          title:
              'Huella del ajuste · segundo ${footprint.second} '
              '(${footprint.alongMeters.round()} m)',
          note:
              'Regla ${footprint.advice.diagnosis?.rule.id ?? '--'} · tono '
              '${footprint.advice.register.name} · objetivo '
              '${footprint.advice.power?.spoken.round()} W',
        ),
      );
    }
  }

  // --- Campo: varias salidas y el acuerdo con los expertos ---
  var rides = <FieldRide>[
    (file: options.recordingPath ?? 'simulada', result: type2),
  ];
  if (options.wants('campo')) {
    stdout.writeln('\nCampo');
    final folder = options.ridesPath;
    if (folder != null) {
      rides = replayFolder(
        Directory(folder),
        bank: bank,
        composerSeed: options.seed,
      );
      if (rides.isEmpty) {
        stderr.writeln('No había salidas reproducibles en $folder');
      }
    }
    write('campo/campo.csv', fieldCsv(rides));
    write('campo/instrucciones.txt', labelSheetInstructions);
    for (var i = 0; i < rides.length; i++) {
      final prefix = 'r${i + 1}-';
      write(
        'campo/${_slug(rides[i].file)}_etiquetar.csv',
        labelSheetCsv(rides[i].result, prefix: prefix),
      );
      write(
        'campo/${_slug(rides[i].file)}_avisos.csv',
        labelSheetCsv(rides[i].result, prefix: prefix, withAdvice: true),
      );
    }
  }

  final experts = _agreements(rides, options.labelSheets);
  var tuning = const <TuningRow>[];
  if (experts.isNotEmpty) {
    stdout.writeln('\nAcuerdo con expertos');
    for (final entry in experts.entries) {
      write('campo/acuerdo_${_slug(entry.key)}.csv', entry.value.toCsv());
      write(
        'figuras/acuerdo_${_slug(entry.key)}.svg',
        confusionSvg(
          entry.value.matrix,
          [for (final a in Adjustment.values) a.name],
          title: 'Acuerdo con ${entry.key}',
          note:
              'κ = ${entry.value.kappa.toStringAsFixed(2)} '
              '(${entry.value.reading}) · '
              'a una casilla o menos: '
              '${(entry.value.withinOneStep * 100).toStringAsFixed(0)} % · '
              'n = ${entry.value.count}',
        ),
      );
    }
  }

  if (experts.isNotEmpty) {
    // Con las etiquetas en la mano se puede preguntar qué variante del
    // motor se habría parecido más al experto.
    final labels = <String, Adjustment>{};
    for (final path in options.labelSheets.values) {
      final file = File(path);
      if (file.existsSync()) {
        labels.addAll(parseLabelSheet(file.readAsStringSync()));
      }
    }
    tuning = tuneAgainstLabels(rides, labels);
    if (tuning.isNotEmpty) write('campo/ajuste.csv', tuningCsv(tuning));
  }

  write(
    'indice.md',
    _index(
      recording,
      type2,
      type1,
      sensitivity,
      surfaces,
      rides,
      experts,
      tuning,
      blind,
      simulated: options.recordingPath == null && options.ridesPath == null,
    ),
  );
  stdout.writeln('\nListo: ${out.path}');
}

/// Lee las hojas que llenaron los expertos y las compara con lo que
/// decidió el motor, juntando todas las salidas.
Map<String, AgreementReport> _agreements(
  List<FieldRide> rides,
  Map<String, String> sheets,
) {
  final reports = <String, AgreementReport>{};
  for (final entry in sheets.entries) {
    final file = File(entry.value);
    if (!file.existsSync()) {
      stderr.writeln('No existe la hoja ${entry.value}');
      continue;
    }
    final Map<String, Adjustment> labels;
    try {
      labels = parseLabelSheet(file.readAsStringSync());
    } on FormatException catch (e) {
      stderr.writeln('${entry.value}: ${e.message}');
      continue;
    }
    final engine = <Adjustment>[];
    final expert = <Adjustment>[];
    for (var i = 0; i < rides.length; i++) {
      for (final row in labelRowsOf(rides[i].result, prefix: 'r${i + 1}-')) {
        final label = labels[row.id];
        final action = row.source.advice.decision.advisedAdjustment;
        if (label == null || action == null) continue;
        engine.add(action);
        expert.add(label);
      }
    }
    if (engine.isEmpty) {
      stderr.writeln('${entry.value}: ninguna fila coincide con los avisos');
      continue;
    }
    reports[entry.key] = AgreementReport.of(engine, expert);
  }
  return reports;
}

/// Potencia, objetivo y piso a lo largo de la subida, con una marca en
/// cada aviso.
String _powerFigure(ReplayResult result) {
  final power = <ChartPoint>[];
  final target = <ChartPoint>[];
  final floor = <ChartPoint>[];
  for (final row in result.rows) {
    final base = row.advice.features.basePower;
    if (base != null) power.add((x: row.second.toDouble(), y: base));
    final watts = row.advice.power;
    if (watts != null) {
      target.add((x: row.second.toDouble(), y: watts.spoken));
      final low = watts.floor;
      if (low != null) floor.add((x: row.second.toDouble(), y: low));
    }
  }
  return lineChartSvg(
    title: 'Potencia y objetivo · ${result.recording.name}',
    xLabel: 'segundos de subida',
    yLabel: 'vatios',
    series: [
      ChartSeries(name: 'potencia (30 s)', color: kBlue, points: power),
      ChartSeries(name: 'objetivo del coach', color: kOrange, points: target),
      ChartSeries(
        name: 'piso sostenible',
        color: kGray,
        points: floor,
        dashed: true,
      ),
    ],
    marks: [
      for (final row in result.advices)
        (x: row.second.toDouble(), label: row.advice.diagnosis?.rule.id ?? ''),
    ],
    note:
        'Las líneas punteadas verticales son los avisos hablados '
        '(${result.advices.length} en total).',
  );
}

/// La urgencia como intervalo, con la compuerta del gobernador.
String _urgencyFigure(ReplayResult result) {
  final band = <({double x, double lo, double hi})>[];
  final middle = <ChartPoint>[];
  for (final row in result.rows) {
    final urgency = row.advice.urgency;
    if (urgency == null) continue;
    band.add((x: row.second.toDouble(), lo: urgency.lo, hi: urgency.hi));
    middle.add((x: row.second.toDouble(), y: urgency.mid));
  }
  final threshold = result.parameters.urgencyThreshold;
  return lineChartSvg(
    title: 'Urgencia y compuerta del gobernador',
    xLabel: 'segundos de subida',
    yLabel: 'urgencia',
    yMin: 0,
    yMax: 1,
    bands: [
      ChartBand(name: 'intervalo [u_l, u_r]', color: kOrange, points: band),
    ],
    series: [
      ChartSeries(name: 'urgencia', color: kOrange, points: middle),
      ChartSeries(
        name: 'umbral ${threshold.toStringAsFixed(2)}',
        color: kGreen,
        dashed: true,
        points: [
          if (middle.isNotEmpty) (x: middle.first.x, y: threshold),
          if (middle.isNotEmpty) (x: middle.last.x, y: threshold),
        ],
      ),
    ],
    marks: [
      for (final row in result.advices) (x: row.second.toDouble(), label: ''),
    ],
    note:
        'El coach solo habla si el extremo inferior del intervalo supera '
        'el umbral.',
  );
}

/// Tipo-1 contra tipo-2 sobre la misma subida.
String _typeFigure(ReplayResult type1, ReplayResult type2) => lineChartSvg(
  title: 'Ajuste recomendado · tipo-1 contra tipo-2',
  xLabel: 'segundos de subida',
  yLabel: 'ajuste (%)',
  bands: [
    ChartBand(
      name: 'intervalo del tipo-2',
      color: kOrange,
      points: [
        for (final row in type2.rows)
          if (row.advice.decision.adjustment.centroid case final c?)
            (x: row.second.toDouble(), lo: c.lo, hi: c.hi),
      ],
    ),
  ],
  series: [
    ChartSeries(
      name: 'tipo-2 (y*)',
      color: kOrange,
      points: [
        for (final row in type2.rows)
          if (row.advice.decision.adjustment.value case final y?)
            (x: row.second.toDouble(), y: y),
      ],
    ),
    ChartSeries(
      name: 'tipo-1',
      color: kBlue,
      dashed: true,
      points: [
        for (final row in type1.rows)
          if (row.advice.decision.adjustment.value case final y?)
            (x: row.second.toDouble(), y: y),
      ],
    ),
  ],
  note: 'El tipo-1 es el caso particular de banda cero: siempre cae dentro.',
);

/// Qué le pasa al objetivo si los quiebres se mueven un 10 %.
String _breakpointFigure(RideRecording recording) {
  final colors = {0.90: kBlue, 1.00: kOrange, 1.10: kGreen};
  final series = <ChartSeries>[];
  for (final scale in colors.keys) {
    final result = replayRide(
      recording,
      parameters: CoachingParameters(breakpointScale: scale),
    );
    series.add(
      ChartSeries(
        name: scale == 1
            ? 'quiebres del anexo'
            : 'quiebres ${scale > 1 ? '+' : '−'}'
                  '${((scale - 1).abs() * 100).round()} %',
        color: colors[scale]!,
        dashed: scale != 1,
        points: [
          for (final row in result.rows)
            if (row.advice.power?.spoken case final watts?)
              (x: row.second.toDouble(), y: watts),
        ],
      ),
    );
  }
  return lineChartSvg(
    title: 'Sensibilidad del objetivo a los quiebres',
    xLabel: 'segundos de subida',
    yLabel: 'objetivo (W)',
    series: series,
    note:
        'Mover todos los quiebres de las variables medidas un 10 % arriba '
        'o abajo.',
  );
}

/// El aviso más urgente: es el que mejor ilustra la huella.
ReplayRow? _strongest(ReplayResult result) {
  ReplayRow? best;
  for (final row in result.advices) {
    final urgency = row.advice.urgency?.lo ?? 0;
    if (best == null || urgency > (best.advice.urgency?.lo ?? 0)) best = row;
  }
  return best ?? (result.rows.isEmpty ? null : result.rows.last);
}

String _index(
  RideRecording recording,
  ReplayResult type2,
  ReplayResult type1,
  List<SensitivityRow>? sensitivity,
  List<ControlSurface> surfaces,
  List<FieldRide> rides,
  Map<String, AgreementReport> experts,
  List<TuningRow> tuning,
  ReplayResult blind, {
  required bool simulated,
}) {
  final compliance = type2.compliance();
  final buffer = StringBuffer()
    ..writeln('# Resultados del motor de coaching')
    ..writeln()
    ..writeln(
      'Generado por `dart run tool/thesis.dart`. Todo lo de esta carpeta '
      'se rehace con ese comando.',
    )
    ..writeln()
    ..writeln('## La subida reproducida')
    ..writeln()
    ..writeln(
      simulated
          ? '> Subida **simulada** con un modelo físico de ciclismo '
                '(`tool/thesis/simulated_ride.dart`): sirve para que las '
                'figuras se puedan rehacer siempre iguales. Los datos '
                'reales llegan en la fase de campo.\n'
          : '',
    )
    ..writeln('- Nombre: ${recording.name}')
    ..writeln(
      '- Duración: ${recording.seconds} s · ${recording.meters.round()} m',
    )
    ..writeln('- Inferencias: ${type2.rows.length} (una cada 5 s y por evento)')
    ..writeln(
      '- Avisos hablados: ${type2.advices.length} '
      '(${type2.advicesPer20Minutes.toStringAsFixed(1)} por cada 20 min; '
      'la meta de la tesis es 4–6)',
    )
    ..writeln(
      '- Cumplimiento: ${compliance.met}/${compliance.asked}'
      '${compliance.rate == null ? '' : ' (${(compliance.rate! * 100).toStringAsFixed(0)} %)'}'
      ' llegaron al objetivo en menos de 30 s'
      '${simulated ? ' -- en una subida simulada el ciclista no oye al coach, '
                'así que esta cifra solo tiene sentido con datos de campo' : ''}',
    )
    ..writeln(
      '- Inferencia: mediana ${_ms(type2.inferenceMicros(0.5))} ms · '
      'p95 ${_ms(type2.inferenceMicros(0.95))} ms '
      '(criterio: menos de 5 ms en el teléfono)',
    )
    ..writeln('- Tonos: ${type2.registers}')
    ..writeln()
    ..writeln('## Tablas')
    ..writeln()
    ..writeln('| Archivo | Qué tiene |')
    ..writeln('| --- | --- |')
    ..writeln('| `recorrido.json` | La grabación tal como entró al motor. |')
    ..writeln(
      '| `avisos.csv` | Un renglón por aviso: situación, regla, tono, objetivo y frase. |',
    )
    ..writeln(
      '| `inferencias.csv` | La traza completa: entradas, salidas y tiempo de cómputo. |',
    )
    ..writeln(
      '| `inferencias_tipo1.csv` | Lo mismo en tipo-1, para comparar. |',
    )
    ..writeln('| `resumen.csv` | Una fila por corrida. |');
  if (sensitivity != null) {
    buffer.writeln(
      '| `sensibilidad.csv` | Cada variante del motor contra la del anexo. |',
    );
  }
  buffer
    ..writeln(
      '| `superficies/*.csv` | Las superficies de control como malla. |',
    )
    ..writeln()
    ..writeln('## Figuras')
    ..writeln()
    ..writeln(
      '- `figuras/recorrido_potencia.svg` — potencia, objetivo y piso, con los avisos marcados.',
    )
    ..writeln(
      '- `figuras/recorrido_urgencia.svg` — la urgencia como intervalo y la compuerta.',
    )
    ..writeln(
      '- `figuras/tipo1_vs_tipo2.svg` — el tipo-1 dentro del intervalo del tipo-2.',
    )
    ..writeln(
      '- `figuras/sensibilidad_quiebres.svg` — el objetivo con los quiebres ±10 %.',
    )
    ..writeln(
      '- `figuras/huella_ajuste.svg` — la huella del ajuste en el aviso más urgente.',
    )
    ..writeln(
      '- `figuras/superficie_*.svg` — una por salida (${surfaces.map((s) => s.name).join(', ')}).',
    )
    ..writeln('- `figuras/particion_*.svg` — las etiquetas de cada variable.')
    ..writeln()
    ..writeln('## Cobertura de las superficies')
    ..writeln()
    ..writeln(
      'Celdas donde alguna regla aporta evidencia. Donde no la hay, el '
      'coach se queda callado: es el hueco de la base de reglas dibujado.',
    )
    ..writeln();
  for (final surface in surfaces) {
    buffer.writeln(
      '- ${surface.name}: '
      '${(surface.covered * 100).toStringAsFixed(1)} %',
    );
  }
  if (sensitivity != null) {
    buffer
      ..writeln()
      ..writeln('## Sensibilidad')
      ..writeln()
      ..writeln(
        '| Variante | Avisos | Objetivo medio (W) | Δ medio (W) | Δ máx (W) | Acción distinta |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- |');
    for (final row in sensitivity) {
      buffer.writeln(
        '| ${row.variant.name} | ${row.advices} | '
        '${row.meanTargetWatts.toStringAsFixed(1)} | '
        '${row.meanTargetShiftWatts.toStringAsFixed(1)} | '
        '${row.maxTargetShiftWatts.toStringAsFixed(1)} | '
        '${(100 * row.differentActionShare).toStringAsFixed(1)} % |',
      );
    }
  }
  buffer
    ..writeln()
    ..writeln(
      '> El tipo-1 recomendó en promedio '
      '${_meanTarget(type1).toStringAsFixed(1)} W y el tipo-2, '
      '${_meanTarget(type2).toStringAsFixed(1)} W.',
    )
    ..writeln()
    ..writeln('## Sin potenciómetro')
    ..writeln()
    ..writeln(
      'La misma subida, quitándole la potencia: el motor la estima con '
      'la velocidad y la pendiente, y la credibilidad de esa estimación '
      'sube con la pendiente (cero en llano, 0,8 desde el 6 %).',
    )
    ..writeln()
    ..writeln(
      '- Avisos: ${blind.advices.length} contra ${type2.advices.length} '
      'con potenciómetro.',
    )
    ..writeln(
      '- Ningún aviso dice vatios: serían un número estimado, y toda '
      'cifra hablada tiene que venir del motor y ser de fiar (ADR-8). '
      'La pantalla sí lo muestra, marcado con «≈».',
    )
    ..writeln('- La tabla está en `avisos_sin_potenciometro.csv`.')
    ..writeln()
    ..writeln('## Campo')
    ..writeln()
    ..writeln(
      'Salidas reproducidas: ${rides.length}'
      '${simulated ? ' (la simulada: los números de campo solo valen con '
                'salidas reales)' : ''}.',
    )
    ..writeln()
    ..write(fieldGoals(rides, agreement: _bestEffort(experts)));

  if (experts.isEmpty) {
    buffer
      ..writeln()
      ..writeln(
        'Para medir el acuerdo: pásele a cada experto la hoja '
        '`campo/*_etiquetar.csv` junto con `campo/instrucciones.txt` (la '
        'hoja no dice qué recomendó el coach, a propósito) y después '
        'corra `dart run tool/thesis.dart --etiquetas nombre=hoja.csv`.',
      );
  } else {
    buffer
      ..writeln()
      ..writeln('| Experto | n | κ | κ ponderado | A una casilla | Lectura |')
      ..writeln('| --- | --- | --- | --- | --- | --- |');
    for (final entry in experts.entries) {
      final report = entry.value;
      buffer.writeln(
        '| ${entry.key} | ${report.count} | '
        '${report.kappa.toStringAsFixed(2)} | '
        '${report.weightedKappa().toStringAsFixed(2)} | '
        '${(report.withinOneStep * 100).toStringAsFixed(0)} % | '
        '${report.reading} |',
      );
    }
    final panel = panelAgreement(experts);
    buffer
      ..writeln()
      ..writeln(
        '> κ promedio del panel: ${panel.meanKappa.toStringAsFixed(2)} '
        '(${panel.meetsGoal ? 'cumple' : 'todavía no cumple'} la meta de 0,6). '
        'La matriz de confusión de cada uno está en `campo/acuerdo_*.csv` y '
        'dibujada en `figuras/acuerdo_*.svg`.',
      );
  }

  if (tuning.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('### Qué variante se habría parecido más')
      ..writeln()
      ..writeln('| Variante | κ | κ ponderado | Acierto | A una casilla |')
      ..writeln('| --- | --- | --- | --- | --- |');
    for (final row in tuning.take(6)) {
      final agreement = row.agreement;
      buffer.writeln(
        '| ${row.variant.name} | ${agreement.kappa.toStringAsFixed(2)} | '
        '${agreement.weightedKappa().toStringAsFixed(2)} | '
        '${(agreement.observed * 100).toStringAsFixed(0)} % | '
        '${(agreement.withinOneStep * 100).toStringAsFixed(0)} % |',
      );
    }
    buffer
      ..writeln()
      ..writeln(
        '> La tabla completa está en `campo/ajuste.csv`. Es una '
        'propuesta, no un cambio: mover un quiebre o una certeza se '
        'decide y se escribe con su razón.',
      );
  }
  return buffer.toString();
}

/// Un solo κ para la tabla de metas: si hay varios expertos, el
/// promedio del panel expresado como el reporte del más parecido a ese
/// promedio (la tabla completa va aparte).
AgreementReport? _bestEffort(Map<String, AgreementReport> experts) {
  if (experts.isEmpty) return null;
  final mean = panelAgreement(experts).meanKappa;
  AgreementReport? closest;
  for (final report in experts.values) {
    if (closest == null ||
        (report.kappa - mean).abs() < (closest.kappa - mean).abs()) {
      closest = report;
    }
  }
  return closest;
}

double _meanTarget(ReplayResult result) {
  var sum = 0.0, count = 0;
  for (final row in result.rows) {
    final watts = row.advice.power?.spoken;
    if (watts == null) continue;
    sum += watts;
    count++;
  }
  return count == 0 ? 0 : sum / count;
}

String _ms(int? micros) =>
    micros == null ? '--' : (micros / 1000).toStringAsFixed(2);

String _slug(String text) {
  const from = 'áéíóúüñÁÉÍÓÚÜÑ′()%';
  const to = 'aeiouunAEIOUUN    ';
  var result = text;
  for (var i = 0; i < from.length; i++) {
    result = result.replaceAll(from[i], to[i]);
  }
  return result
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

const _usage = '''
Herramientas de la tesis del motor de coaching.

  dart run tool/thesis.dart [opciones]

  --grabacion <archivo>  Salida a reproducir (JSON). Sin esto usa la
                         subida simulada de Patios.
  --salida <carpeta>     Dónde escribir. Por defecto build/tesis.
  --voz <persona>        Banco de frases (pro, chill, coach, hype, zen).
  --semilla <n>          Semilla del compositor. Por defecto 3.
  --grabaciones <carpeta> Reproduce todas las salidas de la carpeta y
                         saca la tabla de campo y las hojas para etiquetar.
  --etiquetas <archivo>  Hoja ya llena por un experto. Se puede repetir,
                         y con «nombre=archivo.csv» se le pone nombre.
  --solo <parte>         avisos | sensibilidad | superficies | figuras | campo.
  --ayuda                Esto.
''';

final class _Options {
  final String? recordingPath;
  final String? ridesPath;
  final Map<String, String> labelSheets;
  final String outputPath;
  final String persona;
  final int seed;
  final Set<String> only;
  final bool help;

  const _Options({
    required this.recordingPath,
    required this.ridesPath,
    required this.labelSheets,
    required this.outputPath,
    required this.persona,
    required this.seed,
    required this.only,
    required this.help,
  });

  bool wants(String part) => only.isEmpty || only.contains(part);

  factory _Options.parse(List<String> args) {
    String? recording;
    String? rides;
    final labels = <String, String>{};
    var output = 'build/tesis';
    var persona = 'pro';
    var seed = 3;
    final only = <String>{};
    var help = false;
    for (var i = 0; i < args.length; i++) {
      final value = i + 1 < args.length ? args[i + 1] : null;
      switch (args[i]) {
        case '--grabacion' || '--recording':
          recording = value;
          i++;
        case '--grabaciones' || '--rides':
          rides = value;
          i++;
        case '--etiquetas' || '--labels':
          if (value != null) {
            final parts = value.split('=');
            final name = parts.length > 1
                ? parts.first
                : Uri.file(value).pathSegments.last.split('.').first;
            labels[name] = parts.length > 1
                ? parts.sublist(1).join('=')
                : value;
          }
          i++;
        case '--salida' || '--out':
          if (value != null) output = value;
          i++;
        case '--voz' || '--persona':
          if (value != null) persona = value;
          i++;
        case '--semilla' || '--seed':
          seed = int.tryParse(value ?? '') ?? seed;
          i++;
        case '--solo' || '--only':
          if (value != null && _parts.contains(value)) only.add(value);
          i++;
        case '--ayuda' || '--help' || '-h':
          help = true;
      }
    }
    return _Options(
      recordingPath: recording,
      ridesPath: rides,
      labelSheets: labels,
      outputPath: output,
      persona: persona,
      seed: seed,
      only: only,
      help: help,
    );
  }
}
