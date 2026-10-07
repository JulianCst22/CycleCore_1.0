import '../replay/ride_replay.dart';
import '../variables/labels.dart';
import 'agreement.dart';

/// La hoja que llena el experto y su lectura de vuelta.
///
/// El protocolo es a ciegas: la hoja describe el instante con números
/// (lo que el ciclista vería en la pantalla) pero **no** dice qué
/// recomendó el coach. El experto escribe qué haría él y solo después se
/// compara. Si la hoja mostrara el consejo, el acuerdo mediría
/// obediencia, no criterio.

/// Un instante para etiquetar.
typedef LabelRow = ({
  String id,
  int second,
  double alongMeters,
  ReplayRow source,
});

/// Los instantes de una reproducción que se van a etiquetar: los mismos
/// en los que el coach habló.
List<LabelRow> labelRowsOf(ReplayResult result, {String prefix = 'a'}) => [
  for (var i = 0; i < result.advices.length; i++)
    (
      id: '$prefix${i + 1}',
      second: result.advices[i].second,
      alongMeters: result.advices[i].alongMeters,
      source: result.advices[i],
    ),
];

/// Hoja de etiquetado en CSV.
///
/// Con [withAdvice] en `true` se agrega lo que dijo el coach: sirve para
/// revisar después, nunca para etiquetar.
String labelSheetCsv(
  ReplayResult result, {
  String prefix = 'a',
  bool withAdvice = false,
}) {
  final buffer = StringBuffer(
    'id,segundo,minuto,metros,avance_pct,pendiente_pct,rampa_pct,'
    'desnivel_restante_m,potencia_w,pulso_ppm,cadencia_rpm,'
    'reserva_wprime_pct,ventaja_s'
    '${withAdvice ? ',accion_del_coach,frase_del_coach' : ''}'
    ',accion_experto,comentario\n',
  );
  for (final row in labelRowsOf(result, prefix: prefix)) {
    final advice = row.source.advice;
    final f = advice.features;
    String? number(num? value, int digits) =>
        value?.toDouble().toStringAsFixed(digits);
    final cells = <Object?>[
      row.id,
      row.second,
      '${(row.second ~/ 60)}:${(row.second % 60).toString().padLeft(2, '0')}',
      number(row.alongMeters, 0),
      number(f.progress.value, 0),
      number(f.gradientAhead.value, 1),
      number(f.maxRamp.value, 1),
      number(f.climbLeft.value, 0),
      number(f.basePower, 0),
      number(f.heartRate, 0),
      number(f.cadence, 0),
      number(f.reserve?.value, 0),
      number(f.recordPace?.value, 0),
      if (withAdvice) ...[
        advice.decision.advisedAdjustment?.name,
        '"${row.source.message?.text ?? ''}"',
      ],
      '', // accion_experto: lo llena el experto
      '', // comentario
    ];
    buffer.writeln(cells.map((c) => c ?? '').join(','));
  }
  return buffer.toString();
}

/// Instrucciones que acompañan la hoja: van en el archivo para que el
/// experto no tenga que preguntar nada.
const labelSheetInstructions = '''
Cómo llenar la hoja
===================

Cada fila es un momento de una subida. Con los números de esa fila,
escriba en «accion_experto» lo que usted le diría al ciclista, usando
una sola de estas cinco palabras:

  soltarMucho   bajar bastante el ritmo, se está pasando
  soltar        bajar un poco
  mantener      así está bien
  apretar       puede ir un poco más fuerte
  apretarMucho  está sobrado, hay que subir el ritmo

En «comentario» puede escribir lo que quiera (opcional).

No hace falta llenar todas las filas: las vacías simplemente no cuentan.
Las columnas de la izquierda son: minuto de la subida, metros recorridos,
avance en el segmento, pendiente del tramo que viene y de la rampa más
dura, desnivel que falta, potencia media de los últimos 30 s, pulso,
cadencia, reserva anaeróbica que le queda (% de W') y ventaja o atraso
contra su mejor marca (negativo = va atrasado).
''';

/// Lee una hoja llena. Devuelve la acción de cada id etiquetado; las
/// filas en blanco o con una palabra que no existe se ignoran.
Map<String, Adjustment> parseLabelSheet(String csv) {
  final lines = csv.split(RegExp(r'\r?\n'));
  if (lines.isEmpty) return const {};
  final header = _cells(lines.first);
  final idColumn = header.indexOf('id');
  final actionColumn = header.indexOf('accion_experto');
  if (idColumn < 0 || actionColumn < 0) {
    throw const FormatException(
      'La hoja debe tener las columnas «id» y «accion_experto».',
    );
  }

  final labels = <String, Adjustment>{};
  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final cells = _cells(line);
    if (cells.length <= actionColumn) continue;
    final name = cells[actionColumn].trim();
    if (name.isEmpty) continue;
    for (final adjustment in Adjustment.values) {
      if (adjustment.name.toLowerCase() == name.toLowerCase()) {
        labels[cells[idColumn].trim()] = adjustment;
        break;
      }
    }
  }
  return labels;
}

/// Compara lo que decidió el motor con lo que escribió el experto.
AgreementReport agreementOf(
  ReplayResult result,
  Map<String, Adjustment> labels, {
  String prefix = 'a',
}) {
  final engine = <Adjustment>[];
  final expert = <Adjustment>[];
  for (final row in labelRowsOf(result, prefix: prefix)) {
    final label = labels[row.id];
    final action = row.source.advice.decision.advisedAdjustment;
    if (label == null || action == null) continue;
    engine.add(action);
    expert.add(label);
  }
  return AgreementReport.of(engine, expert);
}

List<String> _cells(String line) {
  final cells = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      quoted = !quoted;
    } else if (char == ',' && !quoted) {
      cells.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  cells.add(buffer.toString());
  return cells;
}
