import 'dart:io';

import 'package:cyclecore_app/features/coaching/domain/evaluation/agreement.dart';
import 'package:cyclecore_app/features/coaching/domain/message/message_bank.dart';
import 'package:cyclecore_app/features/coaching/domain/replay/ride_recording.dart';
import 'package:cyclecore_app/features/coaching/domain/replay/ride_replay.dart';

/// Las metas de la fase de campo, tal como están en el plan.
const kComplianceGoal = 0.70;
const kAdvicesPer20MinGoal = (lo: 4.0, hi: 6.0);
const kKappaGoal = 0.6;

/// Una salida reproducida con su nombre de archivo.
typedef FieldRide = ({String file, ReplayResult result});

/// Reproduce todas las grabaciones de una carpeta.
///
/// Es lo que se corre al volver de un fin de semana de salidas: cada
/// archivo exportado del teléfono entra, y sale la tabla con la que se
/// decide si el coach está listo o hay que ajustarlo.
List<FieldRide> replayFolder(
  Directory folder, {
  MessageBank? bank,
  int composerSeed = 3,
}) {
  final files =
      folder
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final rides = <FieldRide>[];
  for (final file in files) {
    final RideRecording recording;
    try {
      recording = RideRecording.parse(file.readAsStringSync());
    } on FormatException catch (e) {
      stderr.writeln('  ${file.uri.pathSegments.last}: ${e.message}');
      continue;
    }
    if (!recording.hasPower) {
      stderr.writeln(
        '  ${file.uri.pathSegments.last}: sin potencia, no se reproduce',
      );
      continue;
    }
    rides.add((
      file: file.uri.pathSegments.last,
      result: replayRide(recording, bank: bank, composerSeed: composerSeed),
    ));
  }
  return rides;
}

/// Tabla de campo: una fila por salida y una final con el total.
String fieldCsv(List<FieldRide> rides) {
  final buffer = StringBuffer(
    'archivo,salida,minutos,metros,avisos,avisos_por_20min,'
    'objetivos,cumplidos,cumplimiento,micros_p50,micros_p95\n',
  );
  var seconds = 0, advices = 0, asked = 0, met = 0;
  for (final ride in rides) {
    final result = ride.result;
    final compliance = result.compliance();
    seconds += result.recording.seconds;
    advices += result.advices.length;
    asked += compliance.asked;
    met += compliance.met;
    buffer.writeln(
      [
        ride.file,
        '"${result.recording.name}"',
        (result.recording.seconds / 60).toStringAsFixed(1),
        result.recording.meters.round(),
        result.advices.length,
        result.advicesPer20Minutes.toStringAsFixed(2),
        compliance.asked,
        compliance.met,
        compliance.rate?.toStringAsFixed(3) ?? '',
        result.inferenceMicros(0.5) ?? '',
        result.inferenceMicros(0.95) ?? '',
      ].join(','),
    );
  }
  if (rides.isNotEmpty) {
    buffer.writeln(
      [
        'TOTAL',
        '"${rides.length} salidas"',
        (seconds / 60).toStringAsFixed(1),
        '',
        advices,
        seconds == 0 ? '' : (advices * 1200 / seconds).toStringAsFixed(2),
        asked,
        met,
        asked == 0 ? '' : (met / asked).toStringAsFixed(3),
        '',
        '',
      ].join(','),
    );
  }
  return buffer.toString();
}

/// Cómo va cada meta de la fase, en una línea por criterio.
String fieldGoals(List<FieldRide> rides, {AgreementReport? agreement}) {
  var seconds = 0, advices = 0, asked = 0, met = 0;
  for (final ride in rides) {
    final compliance = ride.result.compliance();
    seconds += ride.result.recording.seconds;
    advices += ride.result.advices.length;
    asked += compliance.asked;
    met += compliance.met;
  }
  final rate = asked == 0 ? null : met / asked;
  final per20 = seconds == 0 ? null : advices * 1200 / seconds;
  String mark(bool ok) => ok ? 'cumple' : 'todavía no';

  final buffer = StringBuffer()
    ..writeln('| Criterio | Meta | Medido | |')
    ..writeln('| --- | --- | --- | --- |')
    ..writeln(
      '| Cumplimiento | ≥ 70 % | '
      '${rate == null ? '--' : '${(rate * 100).toStringAsFixed(0)} % '
                '($met de $asked)'} | '
      '${rate == null ? '--' : mark(rate >= kComplianceGoal)} |',
    )
    ..writeln(
      '| Avisos por subida de 20 min | 4 a 6 | '
      '${per20?.toStringAsFixed(1) ?? '--'} | '
      '${per20 == null ? '--' : mark(per20 >= kAdvicesPer20MinGoal.lo && per20 <= kAdvicesPer20MinGoal.hi)} |',
    )
    ..writeln(
      '| Acuerdo con expertos (κ) | ≥ 0,6 | '
      '${agreement == null ? 'sin etiquetar' : '${agreement.kappa.toStringAsFixed(2)} '
                '(${agreement.reading})'} | '
      '${agreement == null ? '--' : mark(agreement.kappa >= kKappaGoal)} |',
    );
  return buffer.toString();
}
