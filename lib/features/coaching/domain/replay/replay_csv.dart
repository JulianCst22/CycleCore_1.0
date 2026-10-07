import '../../../../core/physiology/physiology.dart';
import 'ride_replay.dart';

/// Tablas de una reproducción, en CSV separado por comas y con punto
/// decimal (lo que leen igual Excel, R y pandas).
///
/// Dos tablas con propósitos distintos: [replayAdvicesCsv] es la que se
/// lee a ojo —qué dijo el coach y por qué— y [replayTraceCsv] es la
/// traza completa, para las gráficas y para comparar dos corridas.

/// Tabla de avisos: una fila por cada vez que el coach habló.
String replayAdvicesCsv(ReplayResult result) {
  final rows = <List<Object?>>[
    const [
      'segundo',
      'metros',
      'avance_pct',
      'estado',
      'demanda',
      'fase',
      'tono',
      'regla',
      'accion',
      'ajuste',
      'ajuste_lo',
      'ajuste_hi',
      'potencia_base_w',
      'objetivo_w',
      'objetivo_lo_w',
      'objetivo_hi_w',
      'piso_w',
      'pedido_w',
      'sostenible_w',
      'brecha_fisica_pct',
      'cadencia_rpm',
      'urgencia_lo',
      'urgencia_hi',
      'palabras',
      'frase',
    ],
  ];
  for (final row in result.advices) {
    final advice = row.advice;
    final situation = advice.situation;
    final power = advice.power;
    final urgency = advice.urgency;
    rows.add([
      row.second,
      _round(row.alongMeters, 1),
      _round(advice.features.progress.value, 1),
      situation?.state.name,
      situation?.demand.name,
      situation?.phase.name,
      advice.register.name,
      advice.diagnosis?.rule.id,
      advice.decision.advisedAdjustment?.name,
      _round(advice.decision.adjustment.value, 2),
      _round(advice.decision.adjustment.centroid?.lo, 2),
      _round(advice.decision.adjustment.centroid?.hi, 2),
      _round(advice.features.basePower, 1),
      _round(power?.spoken, 0),
      _round(power?.band.lo, 1),
      _round(power?.band.hi, 1),
      _round(power?.floor, 1),
      _round(power?.requested, 1),
      _round(advice.physics?.sustainable, 1),
      _round(advice.physics?.differencePercent, 1),
      _round(advice.cadence?.spoken, 0),
      _round(urgency?.lo, 3),
      _round(urgency?.hi, 3),
      row.message?.wordCount,
      row.message?.text,
    ]);
  }
  return _csv(rows);
}

/// Traza completa: una fila por inferencia, con lo que entró y lo que
/// salió. Es la tabla que alimenta las gráficas del documento y la que
/// delata un cambio de comportamiento entre dos versiones del motor.
String replayTraceCsv(ReplayResult result) {
  final rows = <List<Object?>>[
    const [
      'segundo',
      'metros',
      'potencia_w',
      'pulso_ppm',
      'cadencia_rpm',
      'intensidad',
      'reserva_cardiaca',
      'torque',
      'reserva_wprime_pct',
      'suficiencia',
      'deriva_pct',
      'variabilidad',
      'pendiente_pct',
      'rampa_pct',
      'rugosidad',
      'desnivel_restante_m',
      'avance_pct',
      'ventaja_s',
      'estado',
      'demanda',
      'ajuste',
      'ajuste_lo',
      'ajuste_hi',
      'cadencia_objetivo',
      'urgencia',
      'urgencia_lo',
      'urgencia_hi',
      'tono',
      'habla',
      'motivo',
      'objetivo_w',
      'pedido_w',
      'sostenible_w',
      'brecha_fisica_pct',
      'micros',
    ],
  ];
  for (final row in result.rows) {
    final advice = row.advice;
    final f = advice.features;
    final decision = advice.decision;
    rows.add([
      row.second,
      _round(row.alongMeters, 1),
      _round(f.basePower, 1),
      _round(f.heartRate, 0),
      _round(f.cadence, 1),
      _value(f.intensity, 4),
      _value(f.heartRateReserve, 4),
      _value(f.torque, 4),
      _value(f.reserve, 3),
      _value(f.sufficiency, 4),
      _value(f.decoupling, 3),
      _value(f.variability, 4),
      _value(f.gradientAhead, 2),
      _value(f.maxRamp, 2),
      _value(f.roughness, 3),
      _value(f.climbLeft, 1),
      _value(f.progress, 2),
      _value(f.recordPace, 1),
      _round(decision.effort.value, 2),
      _round(decision.demand.value, 2),
      _round(decision.adjustment.value, 2),
      _round(decision.adjustment.centroid?.lo, 2),
      _round(decision.adjustment.centroid?.hi, 2),
      _round(decision.cadence.value, 1),
      _round(decision.urgency.value, 3),
      _round(decision.urgency.centroid?.lo, 3),
      _round(decision.urgency.centroid?.hi, 3),
      advice.register.name,
      advice.speak ? 1 : 0,
      advice.verdict.reason.name,
      _round(advice.power?.spoken, 0),
      _round(advice.power?.requested, 1),
      _round(advice.physics?.sustainable, 1),
      _round(advice.physics?.differencePercent, 1),
      row.micros,
    ]);
  }
  return _csv(rows);
}

/// Resumen de la corrida, para el índice de resultados.
String replaySummaryCsv(Iterable<ReplayResult> results) {
  final rows = <List<Object?>>[
    const [
      'corrida',
      'modo',
      'segundos',
      'metros',
      'inferencias',
      'avisos',
      'avisos_por_20min',
      'cumplimiento',
      'contrastes_fisica',
      'fuera_de_rango',
      'peor_brecha_pct',
      'micros_p50',
      'micros_p95',
    ],
  ];
  for (final result in results) {
    final compliance = result.compliance();
    final physics = result.physics;
    rows.add([
      result.recording.name,
      result.mode.name,
      result.recording.seconds,
      _round(result.recording.meters, 0),
      result.rows.length,
      result.advices.length,
      _round(result.advicesPer20Minutes, 2),
      _round(compliance.rate, 3),
      physics.checked,
      physics.flagged,
      _round(physics.worst * 100, 1),
      result.inferenceMicros(0.5),
      result.inferenceMicros(0.95),
    ]);
  }
  return _csv(rows);
}

String _csv(List<List<Object?>> rows) =>
    '${rows.map((r) => r.map(_cell).join(',')).join('\n')}\n';

String _cell(Object? value) {
  if (value == null) return '';
  final text = '$value';
  if (!text.contains(RegExp('[",\n]'))) return text;
  return '"${text.replaceAll('"', '""')}"';
}

String? _round(num? value, int digits) =>
    value?.toDouble().toStringAsFixed(digits);

String? _value(UncertainValue? value, int digits) =>
    value?.value.toStringAsFixed(digits);
