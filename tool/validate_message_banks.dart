// Revisa los bancos de frases del coach:
//
//     dart run tool/validate_message_banks.dart
//
// Sale con código 1 si alguno tiene un defecto, así sirve igual en la
// terminal y en integración continua.
import 'dart:io';

import 'package:cyclecore_app/features/coaching/domain/message/message_bank.dart';

void main(List<String> args) {
  final directory = Directory(
    args.isNotEmpty ? args.first : 'assets/coaching/messages',
  );
  if (!directory.existsSync()) {
    stderr.writeln('No existe ${directory.path}');
    exit(1);
  }

  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    stderr.writeln('No hay bancos en ${directory.path}');
    exit(1);
  }

  var problems = 0;
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    MessageBank bank;
    try {
      bank = MessageBank.parse(file.readAsStringSync());
    } on FormatException catch (e) {
      stdout.writeln('$name: no se pudo leer -- ${e.message}');
      problems++;
      continue;
    }
    final issues = MessageBankValidator.check(bank);
    if (issues.isEmpty) {
      stdout.writeln(
        '$name: ${bank.pieces.length} piezas, '
        '${bank.covers.length} situaciones cubiertas. Sin defectos.',
      );
      continue;
    }
    problems += issues.length;
    stdout.writeln('$name: ${issues.length} defectos');
    for (final issue in issues) {
      stdout.writeln('  - ${issue.piece}: ${issue.problem}');
    }
  }
  exit(problems == 0 ? 0 : 1);
}
