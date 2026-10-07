import '../coaching_parameters.dart';
import '../coaching_session.dart';
import '../inference_clock.dart';
import '../message/message_bank.dart';
import '../message/message_composer.dart';
import 'ride_recording.dart';

/// Un instante en que el motor pensó durante la reproducción.
final class ReplayRow {
  /// Segundo de tiempo en movimiento dentro de la grabación.
  final int second;
  final double alongMeters;
  final Advice advice;

  /// La frase que se habría dicho; `null` si el gobernador calló o si no
  /// se le pasó banco de frases.
  final SpokenMessage? message;

  /// Lo que tardó esta inferencia, en microsegundos.
  final int micros;

  const ReplayRow({
    required this.second,
    required this.alongMeters,
    required this.advice,
    required this.message,
    required this.micros,
  });

  bool get spoke => message != null;
}

/// Resultado de reproducir una grabación: la traza completa y el
/// resumen que va al documento.
final class ReplayResult {
  final RideRecording recording;
  final InferenceMode mode;
  final CoachingParameters parameters;
  final List<ReplayRow> rows;

  ReplayResult({
    required this.recording,
    required this.mode,
    required this.parameters,
    required List<ReplayRow> rows,
  }) : rows = List.unmodifiable(rows);

  /// Los instantes en que habló: la tabla de avisos.
  List<ReplayRow> get advices => [
    for (final row in rows)
      if (row.advice.speak) row,
  ];

  /// Percentil [p] de lo que tardaron las inferencias, en microsegundos.
  int? inferenceMicros(double p) {
    if (rows.isEmpty) return null;
    final sorted = [for (final r in rows) r.micros]..sort();
    return sorted[((sorted.length - 1) * p).round()];
  }

  /// Avisos por cada 20 minutos de subida (la meta de la tesis es 4–6).
  double get advicesPer20Minutes =>
      recording.seconds == 0 ? 0 : advices.length * 1200 / recording.seconds;

  /// Cumplimiento: de los avisos que pidieron una potencia, en cuántos
  /// el ciclista llegó a ±[watts] antes de [windowSeconds].
  ///
  /// Se mide sobre la potencia media de 30 s que ya calcula el motor, que
  /// es la misma con la que se dio el consejo.
  ({int asked, int met, double? rate}) compliance({
    double watts = 8,
    int windowSeconds = 30,
  }) {
    var asked = 0, met = 0;
    for (final row in advices) {
      final target = row.advice.power?.spoken;
      if (target == null) continue;
      asked++;
      for (final later in rows) {
        if (later.second <= row.second) continue;
        if (later.second > row.second + windowSeconds) break;
        final power = later.advice.features.basePower;
        if (power != null && (power - target).abs() <= watts) {
          met++;
          break;
        }
      }
    }
    return (asked: asked, met: met, rate: asked == 0 ? null : met / asked);
  }

  /// Verificación física de toda la corrida (F12): en cuántas
  /// inferencias se contrastaron los dos caminos, en cuántas se
  /// separaron más de lo tolerado y cuál fue la peor separación.
  ({int checked, int flagged, double worst}) get physics {
    var checked = 0, flagged = 0;
    var worst = 0.0;
    for (final row in rows) {
      final check = row.advice.physics;
      if (check == null) continue;
      checked++;
      if (check.needsReview) flagged++;
      if (check.difference.abs() > worst.abs()) worst = check.difference;
    }
    return (checked: checked, flagged: flagged, worst: worst);
  }

  /// Cuántos avisos salieron con cada tono.
  Map<String, int> get registers {
    final counts = <String, int>{};
    for (final row in advices) {
      final name = row.advice.register.name;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts;
  }
}

/// Vuelve a vivir una grabación con el motor y devuelve todo lo que
/// pensó.
///
/// Es el mismo camino del coach en vivo —el mismo reloj, el mismo
/// gobernador y el mismo compositor—, solo que los segundos salen del
/// archivo en vez del reloj del teléfono. Con la misma grabación y la
/// misma semilla el resultado es idéntico: por eso sirve de prueba de
/// regresión y de fuente de las figuras de la tesis.
ReplayResult replayRide(
  RideRecording recording, {
  InferenceMode mode = InferenceMode.type2,
  CoachingParameters parameters = const CoachingParameters(),
  MessageBank? bank,
  int composerSeed = 1,
  int inferenceEverySeconds = 5,
  int eventGapSeconds = 2,
}) {
  final session = CoachingSession(
    athlete: recording.athlete,
    profile: recording.profile,
    reference: recording.reference,
    goal: recording.goal,
    mode: mode,
    parameters: parameters,
  );
  final composer = bank == null
      ? null
      : MessageComposer(bank, seed: composerSeed);
  final clock = InferenceClock(
    gradient: clockGradientAt(recording.profile, 0),
    everySeconds: inferenceEverySeconds,
    eventGapSeconds: eventGapSeconds,
  );

  final rows = <ReplayRow>[];
  for (var i = 0; i < recording.ticks.length; i++) {
    final tick = recording.ticks[i];
    session.addTick(tick);
    final gradient = clockGradientAt(recording.profile, tick.alongMeters);
    if (!clock.tick(second: session.seconds, gradient: gradient)) continue;

    final stopwatch = Stopwatch()..start();
    final advice = session.evaluate(
      recording.statusAt(
        i,
        secondsSinceChange: clock.secondsSinceGradientChange,
      ),
    );
    stopwatch.stop();
    rows.add(
      ReplayRow(
        second: advice.second,
        alongMeters: tick.alongMeters,
        advice: advice,
        message: advice.speak
            ? composer?.compose(
                advice,
                second: advice.second,
                goal: recording.goal,
              )
            : null,
        micros: stopwatch.elapsedMicroseconds,
      ),
    );
  }
  return ReplayResult(
    recording: recording,
    mode: mode,
    parameters: parameters,
    rows: rows,
  );
}
