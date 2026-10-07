import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/physiology/physiology.dart';
import '../../bikes/bikes.dart';
import '../../profile/profile.dart';
import '../../recording/recording.dart'
    show routeRecordingProvider, secondTickerProvider;
import '../../segments/segments.dart';
import '../../sensors/sensors.dart';
import '../../stats/stats.dart';
import '../../voice/voice.dart';
import '../domain/athlete.dart';
import '../domain/coaching_preferences.dart';
import '../domain/coaching_session.dart';
import '../domain/inference_clock.dart';
import '../domain/extraction/effort_tracker.dart';
import '../domain/extraction/sensor_credibility.dart';
import '../domain/extraction/terrain_reader.dart';
import '../domain/message/message_bank.dart';
import '../domain/message/message_composer.dart';
import '../domain/message/message_values.dart';
import 'coaching_providers.dart';
import 'coaching_settings_providers.dart';

/// Puentes con el resto de la app: el coach depende de estos datos, no
/// de quién los produce. En los tests se reemplazan por valores fijos y
/// el controlador corre sin levantar la detección ni la grabación.
final coachActiveSegmentProvider = Provider<ActiveSegmentLive?>(
  (ref) => ref.watch(segmentDetectionProvider).active,
);

final coachRideStartedAtProvider = Provider<DateTime?>(
  (ref) => ref.watch(routeRecordingProvider).startedAt,
);

/// La salida está detenida (pausa manual o automática). Parado no se
/// aconseja: el tiempo corre y la reserva se recupera, pero nadie quiere
/// oír «apriétale» en un semáforo o descansando a mitad de la subida.
final coachRideStoppedProvider = Provider<bool>((ref) {
  final rec = ref.watch(routeRecordingProvider);
  return rec.isPaused || rec.isAutoPaused;
});

/// Variables que el coach acaba de nombrar en voz alta. La pantalla
/// resalta su recuadro unos segundos para que el oído y la vista miren
/// al mismo lugar (ADR-6).
///
/// Es un proveedor aparte del controlador a propósito: la cuadrícula del
/// cockpit lo mira en cada tarjeta y no debe arrastrar consigo toda la
/// sesión del coach.
final coachMentionedValuesProvider = StateProvider<Set<MessageValue>>(
  (ref) => const {},
);

/// Lo que el coach tiene para mostrar y decir ahora mismo.
final class CoachingLiveState {
  /// Segmento en el que está trabajando; `null` si no hay ninguno (fuera
  /// de un segmento el coach no habla).
  final int? segmentId;

  /// Último consejo calculado, hable o no.
  final Advice? advice;

  /// Último mensaje dicho.
  final SpokenMessage? spoken;

  /// Segundo (dentro del segmento) en que se dijo.
  final int? spokenAt;

  /// Por qué el coach no puede trabajar, si es el caso.
  final String? blocked;

  /// Microsegundos que tardaron las últimas inferencias, para medir en
  /// el teléfono (criterio de la fase: p95 < 5 ms).
  final List<int> inferenceMicros;

  /// Cómo van coincidiendo las reglas y la física en esta subida
  /// (F12): cuántas veces se contrastaron, cuántas se separaron más de
  /// lo tolerado y cuál fue la peor separación, en tanto por uno.
  final ({int evaluations, int flagged, double worst}) physics;

  const CoachingLiveState({
    this.segmentId,
    this.advice,
    this.spoken,
    this.spokenAt,
    this.blocked,
    this.inferenceMicros = const [],
    this.physics = (evaluations: 0, flagged: 0, worst: 0),
  });

  bool get isActive => segmentId != null;

  /// Percentil 95 de lo que tarda una inferencia; `null` sin medidas.
  int? get inferenceP95Micros {
    if (inferenceMicros.isEmpty) return null;
    final sorted = [...inferenceMicros]..sort();
    final index = ((sorted.length - 1) * 0.95).round();
    return sorted[index];
  }

  CoachingLiveState copyWith({
    int? segmentId,
    Advice? advice,
    SpokenMessage? spoken,
    int? spokenAt,
    String? blocked,
    List<int>? inferenceMicros,
    ({int evaluations, int flagged, double worst})? physics,
    bool clearSegment = false,
    bool clearBlocked = false,
  }) => CoachingLiveState(
    segmentId: clearSegment ? null : (segmentId ?? this.segmentId),
    advice: clearSegment ? null : (advice ?? this.advice),
    spoken: clearSegment ? null : (spoken ?? this.spoken),
    spokenAt: clearSegment ? null : (spokenAt ?? this.spokenAt),
    blocked: clearBlocked ? null : (blocked ?? this.blocked),
    inferenceMicros: inferenceMicros ?? this.inferenceMicros,
    physics: clearSegment
        ? (evaluations: 0, flagged: 0, worst: 0)
        : (physics ?? this.physics),
  );
}

/// El coach en vivo: junta el segmento activo, los sensores y el reloj,
/// alimenta la sesión difusa segundo a segundo y, cuando el gobernador
/// deja hablar, arma la frase y la manda a la voz.
///
/// Fuera de un segmento no existe sesión: el coach no dice nada.
class CoachingController extends StateNotifier<CoachingLiveState> {
  final Ref _ref;

  /// Cada cuántos segundos se corre la inferencia.
  final int inferenceEverySeconds;

  /// Cuánto después de un consejo se revisa si el ciclista hizo caso.
  final int followUpSeconds;

  /// Diferencia en vatios que todavía se considera «hizo caso».
  final double complianceWatts;

  /// Cuánto queda resaltado el recuadro de la variable nombrada.
  final int highlightSeconds;

  /// Mínimo entre dos inferencias disparadas por un cambio de terreno.
  final int eventGapSeconds;

  /// Semilla del compositor. En la calle va con el reloj, para que dos
  /// salidas seguidas no suenen igual; los tests y la reproducción de
  /// una actividad la fijan para obtener siempre la misma frase.
  final int? composerSeed;

  CoachingSession? _session;
  MessageComposer? _composer;
  DateTime? _rideStartedAt;
  int? _segmentId;
  InferenceClock? _clock;
  int _pendingFollowUpAt = -1;
  double? _pendingTarget;
  ProviderSubscription<AsyncValue<int>>? _ticker;
  Timer? _highlightTimer;

  CoachingController(
    this._ref, {
    this.inferenceEverySeconds = 5,
    this.followUpSeconds = 30,
    this.complianceWatts = 8,
    this.highlightSeconds = 6,
    this.eventGapSeconds = 2,
    this.composerSeed,
  }) : super(const CoachingLiveState()) {
    // El ciclista se calibra con datos que se cargan de la base (curva de
    // potencia, bicicleta, cadencia aprendida). Se dejan cargando desde
    // que se abre la salida: si se leyeran recién al entrar al segmento,
    // la primera sesión podía arrancar con una bicicleta genérica.
    _ref.listen<CoachAthlete?>(coachAthleteProvider, (_, _) {});
    _ref.listen<ActiveSegmentLive?>(
      coachActiveSegmentProvider,
      (_, next) => _syncSegment(next),
      fireImmediately: true,
    );
  }

  /// Entrar o salir de un segmento abre y cierra la sesión del coach.
  void _syncSegment(ActiveSegmentLive? active) {
    if (active == null) {
      if (_session != null) stop();
      return;
    }
    if (active.segment.id == _segmentId) return;
    _start(active);
  }

  void _start(ActiveSegmentLive active) {
    stop();
    final athlete = _ref.read(coachAthleteProvider);
    if (athlete == null) {
      state = state.copyWith(
        blocked:
            'Sin potencia crítica: el coach necesita tu FTP o una '
            'salida con potenciómetro.',
      );
      return;
    }
    _segmentId = active.segment.id;
    _rideStartedAt = _ref.read(coachRideStartedAtProvider);
    final preferences = _ref.read(coachingPreferencesProvider);
    _session = CoachingSession(
      athlete: athlete,
      profile: active.profile,
      reference: _referenceOf(active),
      goal: preferences.goal,
      pace: preferences.pace,
    );
    _clock = InferenceClock(
      gradient: clockGradientAt(active.profile, active.alongMeters),
      everySeconds: inferenceEverySeconds,
      eventGapSeconds: eventGapSeconds,
    );
    _pendingFollowUpAt = -1;
    _pendingTarget = null;
    state = CoachingLiveState(
      segmentId: active.segment.id,
      inferenceMicros: state.inferenceMicros,
    );
    _ticker = _ref.listen<AsyncValue<int>>(
      secondTickerProvider,
      (_, _) => _onSecond(),
    );
    _loadBank();
  }

  /// Cierra la sesión (se salió del segmento o se terminó la salida).
  void stop() {
    _ticker?.close();
    _ticker = null;
    _highlightTimer?.cancel();
    _highlightTimer = null;
    _session = null;
    _clock = null;
    _composer = null;
    _segmentId = null;
    state = state.copyWith(clearSegment: true, clearBlocked: true);
  }

  Future<void> _loadBank() async {
    final persona = _ref.read(voiceSettingsProvider).persona.id;
    final MessageBank bank;
    try {
      bank = await _ref.read(messageBankRepositoryProvider).load(persona);
    } on Object {
      return; // sin banco el coach se queda mudo, pero la sesión sigue
    }
    if (_session == null) return;
    _composer = MessageComposer(
      bank,
      seed: composerSeed ?? DateTime.now().second,
    );
  }

  static ReferenceEffort? _referenceOf(ActiveSegmentLive active) {
    final splits = active.bestSplits;
    if (splits.length < 2) return null;
    return ReferenceEffort([
      for (final s in splits)
        (meters: s.distanceMeters, seconds: s.secondsFromStart.toDouble()),
    ]);
  }

  /// Un segundo de salida: alimenta la sesión y, cada
  /// [inferenceEverySeconds], vuelve a pensar.
  void _onSecond() {
    final session = _session;
    final clock = _clock;
    final active = _ref.read(coachActiveSegmentProvider);
    if (session == null || clock == null || active == null) return;

    final stopped = _ref.read(coachRideStoppedProvider);
    final measuredPower = _ref.read(powerWattsProvider)?.toDouble();
    final heartRate = _ref.read(heartRateBpmProvider)?.toDouble();
    final cadence = _ref.read(cadenceRpmProvider);
    final gradient =
        active.profile.slopePercentAtDistance(active.alongMeters) ?? 0;
    // La velocidad va siempre: sin potenciómetro es con lo que el motor
    // estima la potencia (ver `EffortTracker.add`). Del GPS de la
    // grabación si no hay sensor de rueda.
    final speedKmh =
        _ref.read(speedKmhProvider) ??
        _ref.read(routeRecordingProvider).currentSpeedKmh;
    session.addTick(
      RideTick(
        second: session.seconds,
        alongMeters: active.alongMeters,
        // Detenido no se hace trabajo: con potenciómetro llega 0 W (o
        // nada, si se durmió), y sin él la velocidad no sirve para
        // estimar. Se cuenta como 0 W para que la reserva se recupere,
        // que es lo que de verdad pasa al parar.
        power: stopped ? (measuredPower ?? 0) : measuredPower,
        heartRate: heartRate,
        cadence: stopped ? 0 : cadence,
        speed: !stopped && speedKmh > 0 ? speedKmh / 3.6 : null,
        slopePercent: gradient,
      ),
    );

    // El reloj decide cuándo toca pensar; hablar o no sigue siendo cosa
    // del gobernador. Parado no se piensa: no hay nada que aconsejar.
    final clockGradient = clockGradientAt(active.profile, active.alongMeters);
    if (!clock.tick(second: session.seconds, gradient: clockGradient)) return;
    if (stopped) return;
    _think(session, clock, active, gradient);
  }

  void _think(
    CoachingSession session,
    InferenceClock clock,
    ActiveSegmentLive active,
    double gradient,
  ) {
    final stopwatch = Stopwatch()..start();
    final advice = session.evaluate(
      SensorStatus(
        powerAgeSeconds: _ref.read(powerWattsProvider) == null ? null : 0,
        // Lo pone la sesión, que sabe si terminó estimando.
        powerIsEstimated: session.powerIsEstimated,
        heartRateAgeSeconds: _ref.read(heartRateBpmProvider) == null ? null : 0,
        cadenceAgeSeconds: _ref.read(cadenceRpmProvider) == null ? null : 0,
        secondsSinceGradientChange: clock.secondsSinceGradientChange,
        currentGradient: gradient,
        terrainSource: _terrainSourceOf(active.segment.source),
        hasReference: session.reference != null,
      ),
    );
    stopwatch.stop();

    final review = session.physicsReview;
    state = state.copyWith(
      advice: advice,
      inferenceMicros: [
        ...state.inferenceMicros.take(199),
        stopwatch.elapsedMicroseconds,
      ],
      physics: (
        evaluations: review.evaluations,
        flagged: review.flagged,
        worst: review.worst,
      ),
    );

    if (advice.speak) {
      _say(advice, active);
      return;
    }
    _maybeFollowUp(advice, active);
  }

  static TerrainSource _terrainSourceOf(String source) => switch (source) {
    'activity' => TerrainSource.ownActivity,
    'nativeCatalog' => TerrainSource.catalog,
    _ => TerrainSource.gpxImport,
  };

  void _say(Advice advice, ActiveSegmentLive active) {
    final composer = _composer;
    if (composer == null) return;
    final preferences = _ref.read(coachingPreferencesProvider);
    final message = composer.compose(
      advice,
      second: advice.second,
      goal: preferences.goal,
      riderName: _riderName(),
    );
    if (message == null) return;

    _speak(message);
    state = state.copyWith(spoken: message, spokenAt: advice.second);
    // El seguimiento («vas bien, sostén esos 285 vatios») compara vatios
    // contra vatios: con potencia estimada la diferencia es ruido de la
    // estimación, no si el ciclista hizo caso.
    _pendingTarget = advice.features.powerIsEstimated
        ? null
        : advice.power?.spoken;
    _pendingFollowUpAt = preferences.detail == CoachingDetail.completo
        ? advice.second + followUpSeconds
        : -1;
    _record(advice, active, message.text);
  }

  /// Seguimiento: unos segundos después, confirmar si el ciclista llegó
  /// al objetivo. No pasa por el gobernador porque no es un consejo
  /// nuevo, y va con la prioridad más baja.
  void _maybeFollowUp(Advice advice, ActiveSegmentLive active) {
    final composer = _composer;
    final target = _pendingTarget;
    if (composer == null || target == null) return;
    if (_pendingFollowUpAt < 0 || advice.second < _pendingFollowUpAt) return;
    _pendingFollowUpAt = -1;
    final power = advice.features.basePower;
    if (power == null) return;
    final message = composer.followUp(
      advice,
      second: advice.second,
      complying: (power - target).abs() <= complianceWatts,
      riderName: _riderName(),
    );
    if (message == null) return;
    _speak(message);
    state = state.copyWith(spoken: message, spokenAt: advice.second);
  }

  /// Nombre de pila del ciclista, que es como lo llamaría un compañero
  /// de ruta. Sin perfil, las frases que lo usan simplemente no salen.
  String? _riderName() {
    final name = _ref.read(profileProvider).valueOrNull?.name.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  void _speak(SpokenMessage message) {
    if (!_ref.read(coachingPreferencesProvider).enabled) return;
    _highlight(message.mentioned);
    unawaited(
      _ref
          .read(voiceSettingsProvider.notifier)
          .speakText(
            message.text,
            priority: message.isFollowUp
                ? VoicePriority.ambiente
                : (message.isUrgent
                      ? VoicePriority.urgente
                      : VoicePriority.normal),
          ),
    );
  }

  /// Enciende el resaltado de las variables que acaba de nombrar y lo
  /// apaga solo.
  void _highlight(Set<MessageValue> values) {
    _highlightTimer?.cancel();
    if (values.isEmpty) return;
    final mentioned = _ref.read(coachMentionedValuesProvider.notifier);
    mentioned.state = values;
    _highlightTimer = Timer(Duration(seconds: highlightSeconds), () {
      mentioned.state = const {};
    });
  }

  void _record(Advice advice, ActiveSegmentLive active, String message) {
    final startedAt = _rideStartedAt;
    if (startedAt == null) return;
    unawaited(
      _ref
          .read(coachingLogRepositoryProvider)
          .record(
            advice,
            rideStartedAt: startedAt,
            segmentId: active.segment.id,
            alongMeters: active.alongMeters,
            recordedAt: DateTime.now(),
            message: message,
          ),
    );
  }

  @override
  void dispose() {
    _ticker?.close();
    _highlightTimer?.cancel();
    super.dispose();
  }
}

/// El ciclista tal como lo necesita el coach: potencia crítica calibrada
/// más lo que diga su perfil. `null` si todavía no hay con qué calibrar.
final coachAthleteProvider = Provider<CoachAthlete?>((ref) {
  final model = ref.watch(athleteCalibrationProvider).valueOrNull?.model;
  if (model == null) return null;
  final profile = ref.watch(profileProvider).valueOrNull;
  // Con qué masa y qué resistencia se estima la potencia cuando no hay
  // potenciómetro: el peso del perfil más la bicicleta que está en uso,
  // con su tipo de llanta y su posición. Sin bicicleta registrada se
  // supone una de ruta y la banda carga con esa duda.
  final weight = profile?.weightKg ?? 72;
  final bike = ref.watch(defaultBikeProvider);
  final resistance =
      bike?.resistanceWith(riderWeightKg: weight) ??
      RidingResistance(
        massKg: weight + BikeKind.ruta.typicalWeightKg,
        massUncertaintyKg: profile?.weightKg == null ? 8 : 3.5,
        rollingResistance: BikeKind.ruta.rollingResistance,
        rollingResistanceUncertainty:
            BikeKind.ruta.rollingResistanceUncertainty,
        dragArea: BikeKind.ruta.dragArea,
        dragAreaUncertainty: BikeKind.ruta.dragAreaUncertainty,
        // Sin bicicleta registrada se supone un desarrollo más duro que
        // el típico: así el coach nunca pide una cadencia que la
        // bicicleta no dé ni manda subir un piñón que puede no existir.
        lowestGearMeters: BikeKind.ruta.cautiousLowestGearMeters,
        highestGearMeters: BikeKind.ruta.cautiousHighestGearMeters,
      );
  return CoachAthlete(
    power: model,
    resistance: resistance,
    // Sin FC máxima registrada se usa la estimada por edad, y si
    // tampoco hay, un valor típico: las reglas de pulso pesan poco y la
    // credibilidad las baja solas si el dato no cuadra.
    maxHeartRate: Bpm(
      (profile?.maxHr ?? profile?.estimatedMaxHrFromAge ?? 190).toDouble(),
    ),
    restingHeartRate: Bpm((profile?.restingHr ?? 60).toDouble()),
    // Contra esta cadencia se mide el torque. Manda lo que el ciclista
    // puso a mano; si no puso nada, lo que muestran sus propias salidas;
    // y mientras no haya suficientes, la recomendada.
    preferredCadence: Rpm(
      (profile?.preferredCadence ??
              ref.watch(learnedClimbingCadenceProvider)?.round() ??
              recommendedCadenceRpm)
          .toDouble(),
    ),
  );
});

final coachingControllerProvider =
    StateNotifierProvider<CoachingController, CoachingLiveState>(
      CoachingController.new,
    );
