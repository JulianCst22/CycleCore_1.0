import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:core_database/core_database.dart';
import '../domain/altitude_fusion/altitude_fusion_filter.dart';
import '../domain/altitude_fusion/altitude_source_reading.dart';
import '../domain/slope_plausibility/slope_plausibility_filter.dart';
import '../data/altitude_debug_logger.dart';
import '../domain/altitude_fusion/altitude_fusion_service.dart';
import '../data/barometer_service.dart';
import 'package:core_platform/core_platform.dart';
import '../../elevation/elevation.dart';
import '../../sensors/sensors.dart';
import '../data/recording_journal.dart';
import '../domain/activity_altitude_flattener.dart';
import '../domain/auto_pause_detector.dart';
import '../domain/activity_summary_builder.dart';
import '../domain/live_slope_calculator.dart';
import '../domain/recording_snapshot.dart';
import '../domain/route_point.dart';
import '../domain/slope_presentation_formatter.dart';
import 'auto_pause_providers.dart';

/// Instancia única del servicio de barómetro.
final barometerServiceProvider = Provider<BarometerService>((ref) {
  return BarometerService();
});

/// Diario de la grabación en curso -- ver `RecordingJournal`. Lo
/// comparten el motor de grabación (puntos), la bitácora de sensores
/// (FC/potencia/cadencia) y la recuperación al abrir la app.
final recordingJournalProvider = Provider<RecordingJournal>((ref) {
  return RecordingJournal(ref.watch(appDatabaseProvider));
});

/// Emite un evento cada segundo mientras exista algún listener activo.
/// Se usa únicamente para forzar el refresco del tiempo transcurrido en
/// el panel de datos, incluso cuando no ha llegado un nuevo punto GPS.
final secondTickerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (tick) => tick);
});

/// Estado inmutable de una sesión de grabación de ruta / entrenamiento.
class RouteRecordingState {
  final bool isRecording;

  /// Pausa MANUAL (botón): deja de escuchar el GPS y los sensores.
  final bool isPaused;

  /// Pausa AUTOMÁTICA: el ciclista se detuvo y el tiempo en movimiento
  /// se congeló, pero el GPS y la rueda se siguen escuchando para
  /// reanudar solos al volver a rodar. Ver `AutoPauseDetector`.
  final bool isAutoPaused;

  final List<RoutePoint> points;
  final DateTime? startedAt;
  final double cumulativeDistanceMeters;
  final double elevationGainMeters;

  /// Pendiente "de confianza" -- salida de la Capa 2 (filtro de
  /// plausibilidad difuso). Es la que se guarda en RoutePointSnapshot y
  /// alimenta los gráficos; NO tiene el banding/histéresis de
  /// presentación.
  final double currentSlopePercent;

  /// Pendiente formateada para mostrar en el panel en vivo (bandas de
  /// 0.5% + histéresis, estilo Garmin). Solo para UI -- ver
  /// SlopePresentationFormatter.
  final double displaySlopePercent;

  final double currentSpeedKmh;
  final double maxSpeedKmh;
  final double currentBearingDegrees;

  /// true cuando el ÚLTIMO punto no tuvo tesela DEM disponible, O
  /// cuando sí la tuvo pero la Capa 1 detectó posible estructura
  /// elevada (puente/viaducto) y priorizó el sensor en tiempo real. La
  /// UI usa esto para el indicador de "modo aproximado".
  final bool isApproximateElevation;

  /// true mientras se espera un fix de GPS con precisión razonable
  /// justo después de pedir iniciar grabación (ver
  /// LocationService.waitForStableFix) -- todavía no es
  /// `isRecording`. La UI puede mostrar un spinner tipo "Buscando señal
  /// GPS..." mientras esto esté en true.
  final bool isAcquiringGps;

  const RouteRecordingState({
    this.isRecording = false,
    this.isPaused = false,
    this.isAutoPaused = false,
    this.points = const [],
    this.startedAt,
    this.cumulativeDistanceMeters = 0,
    this.elevationGainMeters = 0,
    this.currentSlopePercent = 0,
    this.displaySlopePercent = 0,
    this.currentSpeedKmh = 0,
    this.maxSpeedKmh = 0,
    this.currentBearingDegrees = 0,
    this.isApproximateElevation = true,
    this.isAcquiringGps = false,
  });

  RouteRecordingState copyWith({
    bool? isRecording,
    bool? isPaused,
    bool? isAutoPaused,
    List<RoutePoint>? points,
    DateTime? startedAt,
    double? cumulativeDistanceMeters,
    double? elevationGainMeters,
    double? currentSlopePercent,
    double? displaySlopePercent,
    double? currentSpeedKmh,
    double? maxSpeedKmh,
    double? currentBearingDegrees,
    bool? isApproximateElevation,
    bool? isAcquiringGps,
  }) {
    return RouteRecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      isAutoPaused: isAutoPaused ?? this.isAutoPaused,
      points: points ?? this.points,
      startedAt: startedAt ?? this.startedAt,
      cumulativeDistanceMeters:
          cumulativeDistanceMeters ?? this.cumulativeDistanceMeters,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      currentSlopePercent: currentSlopePercent ?? this.currentSlopePercent,
      displaySlopePercent: displaySlopePercent ?? this.displaySlopePercent,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      currentBearingDegrees:
          currentBearingDegrees ?? this.currentBearingDegrees,
      isApproximateElevation:
          isApproximateElevation ?? this.isApproximateElevation,
      isAcquiringGps: isAcquiringGps ?? this.isAcquiringGps,
    );
  }

  /// true mientras de verdad se está sumando actividad: grabando, sin
  /// pausa manual ni automática.
  bool get isCapturing => isRecording && !isPaused && !isAutoPaused;

  /// Velocidad promedio basada en el tiempo transcurrido en movimiento
  /// (excluyendo pausas).
  double averageSpeedKmhOver(Duration elapsed) {
    if (cumulativeDistanceMeters <= 0 || elapsed.inSeconds <= 0) return 0;
    final km = cumulativeDistanceMeters / 1000;
    final hours = elapsed.inSeconds / 3600;
    return km / hours;
  }
}

class RouteRecordingController extends StateNotifier<RouteRecordingState> {
  final LocationService _locationService;
  final BarometerService _barometerService;

  /// Cadena de prioridades de elevación: GPX > HGT > fusión en vivo.
  final ElevationResolver _elevation;
  final Ref _ref;
  final AltitudeFusionService _altitudeFusion = AltitudeFusionService();

  // Ventana de TIEMPO (no de distancia) -- ver LiveSlopeCalculator
  // para el porqué. Reemplaza a SlopeWindowCalculator SOLO acá, en el
  // cockpit en vivo; el aplanado post-actividad (Fase 1) sigue usando
  // SlopeWindowCalculator sin cambios.
  final LiveSlopeCalculator _slopeCalculator = LiveSlopeCalculator();

  // --- Capas del modelo geoespacial nuevo ---
  final AltitudeFusionFilter _altitudeFusionFilter = AltitudeFusionFilter();
  final SlopePlausibilityFilter _slopePlausibility = SlopePlausibilityFilter();
  final SlopePresentationFormatter _slopePresentation =
      SlopePresentationFormatter();

  // --- Diagnóstico de campo ---
  final AltitudeDebugLogger _debugLogger = AltitudeDebugLogger();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<double>? _pressureSubscription;
  double? _lastPressureHpa;

  /// Tiempo real de movimiento acumulado, EXCLUYENDO las pausas.
  Duration _accumulatedActiveDuration = Duration.zero;
  DateTime? _activeSegmentStartedAt;

  // --- Fuente de distancia/velocidad: sensor BLE con prioridad, GPS
  // como respaldo. `_sensorDistanceOffset` se recalcula cada vez que el
  // sensor pasa de "no disponible" a "disponible" (al inicio de la
  // grabación, o tras reconectar a mitad de ella) para que la distancia
  // mostrada nunca salte ni se duplique -- ver _onNewPosition.
  double? _sensorDistanceOffset;

  /// Historial punto a punto de la distancia/velocidad YA priorizada
  /// (sensor o GPS, lo que haya aplicado en cada momento) -- alineado
  /// índice a índice con `state.points`. `finishRecording()` reutiliza
  /// esto en vez de recalcular todo desde cero con Geolocator, para que
  /// el resumen final sea fiel a lo que se vio en vivo -- crítico para
  /// actividades indoor, donde el GPS no se mueve pero el sensor sí
  /// reporta datos reales. También es la entrada de distancia que usa
  /// `ActivityAltitudeFlattener` para recalcular la pendiente aplanada.
  final List<double> _liveDistanceHistory = [];
  final List<double> _liveSpeedHistory = [];

  /// Caja negra de la sesión -- ver `RecordingJournal`.
  final RecordingJournal _journal;
  Timer? _journalTimer;

  /// Cada cuánto se escribe al diario lo acumulado en memoria. Es lo
  /// máximo que se pierde si la app se cierra de golpe.
  static const Duration journalFlushInterval = Duration(seconds: 5);

  /// true justo después de reanudar una grabación recuperada: el
  /// siguiente punto GPS NO se une con el último guardado antes del
  /// cierre -- entre ambos pudo haber kilómetros sin grabar, y contarlos
  /// como una línea recta inflaría la distancia y el desnivel.
  bool _hasGapBeforeNextPoint = false;

  /// Pausa automática al detenerse -- ver `AutoPauseDetector`. Vigila
  /// mientras se escucha a los sensores (entre `_subscribeToSensors` y
  /// `_unsubscribeFromSensors`), es decir, fuera de la pausa manual.
  final AutoPauseDetector _autoPause = AutoPauseDetector();
  Timer? _autoPauseTimer;
  ProviderSubscription<double?>? _wheelDistanceSubscription;

  RouteRecordingController(
    this._locationService,
    this._barometerService,
    this._elevation,
    this._journal,
    this._ref,
  ) : super(const RouteRecordingState());

  /// Archivo CSV de la sesión más reciente (o ya cerrada), por si la UI
  /// quiere agregar más adelante un botón de "compartir log".
  File? get debugLogFile => _debugLogger.currentFile;

  Future<void> startRecording() async {
    if (state.isRecording) return;

    await _prepareToRecord();

    _accumulatedActiveDuration = Duration.zero;
    _liveDistanceHistory.clear();
    _liveSpeedHistory.clear();

    final startedAt = DateTime.now();
    await _journal.open(startedAt);

    _activeSegmentStartedAt = startedAt;
    state = RouteRecordingState(isRecording: true, startedAt: startedAt);

    _subscribeToSensors();
    _startJournalTimer();
  }

  /// Reanuda una grabación recuperada del diario tras un cierre
  /// inesperado de la app: vuelve a cargar sus puntos, distancia y
  /// tiempo en movimiento, y sigue grabando en la misma sesión como si
  /// nunca se hubiera cerrado.
  ///
  /// El rato que la app estuvo cerrada cuenta como pausa: no suma tiempo
  /// en movimiento, ni distancia entre el último punto guardado y el
  /// primero nuevo (ver [_hasGapBeforeNextPoint]). La bitácora de
  /// sensores se restaura por separado ANTES de llamar a esto -- ver
  /// `RideSensorLogController.restore`.
  Future<void> resumeFrom(RecordingSnapshot snapshot) async {
    if (state.isRecording) return;

    await _prepareToRecord();

    _accumulatedActiveDuration = snapshot.movingTime;
    _liveDistanceHistory
      ..clear()
      ..addAll(snapshot.points.map((p) => p.distanceMeters));
    _liveSpeedHistory
      ..clear()
      ..addAll(snapshot.points.map((p) => p.speedKmh));
    _hasGapBeforeNextPoint = true;

    _journal.resume(snapshot);

    final points = snapshot.routePoints;
    _activeSegmentStartedAt = DateTime.now();
    state = RouteRecordingState(
      isRecording: true,
      startedAt: snapshot.startedAt,
      points: points,
      cumulativeDistanceMeters: snapshot.distanceMeters,
      elevationGainMeters: snapshot.liveElevationGainMeters,
      maxSpeedKmh: snapshot.maxSpeedKmh,
      currentBearingDegrees: points.isEmpty ? 0 : points.last.bearingDegrees,
    );

    _subscribeToSensors();
    _startJournalTimer();
  }

  /// Lo que comparten [startRecording] y [resumeFrom] antes de grabar el
  /// primer punto: permisos, fuentes de elevación, motores del modelo
  /// geoespacial en limpio y un fix de GPS estable.
  Future<void> _prepareToRecord() async {
    await _locationService.ensureLocationReady();
    await _locationService.ensureBackgroundLocationReady();
    await _elevation.preload();

    _altitudeFusion.reset();
    _slopeCalculator.reset();
    _altitudeFusionFilter.reset();
    _slopePlausibility.reset();
    _slopePresentation.reset();
    _lastPressureHpa = null;
    _sensorDistanceOffset = null;
    _hasGapBeforeNextPoint = false;

    // Espera acotada a que el GPS estabilice ANTES de empezar a grabar
    // -- reduce la probabilidad de arrancar con un fix de cold start
    // malo. No es infalible (puede vencer el timeout con el GPS
    // todavía inestable): el buffer de calentamiento de
    // SlopePlausibilityFilter es la segunda línea de defensa para ese
    // caso. Ver LocationService.waitForStableFix.
    state = state.copyWith(isAcquiringGps: true);
    await _locationService.waitForStableFix();

    await _debugLogger.start(DateTime.now().millisecondsSinceEpoch.toString());
  }

  void _startJournalTimer() {
    _journalTimer?.cancel();
    _journalTimer = Timer.periodic(journalFlushInterval, (_) => flushJournal());
  }

  void _stopJournalTimer() {
    _journalTimer?.cancel();
    _journalTimer = null;
  }

  /// Escribe ya al diario lo que haya en memoria. Además del ciclo
  /// periódico, se llama al pausar y cuando la app pasa a segundo plano
  /// (ver `routeRecordingProvider`) -- el momento en que Android puede
  /// matarla.
  Future<void> flushJournal() async {
    if (!state.isRecording) return;
    await _journal.flush(
      movingTime: elapsedDuration(),
      isPaused: state.isPaused,
    );
  }

  void _subscribeToSensors() {
    _pressureSubscription = _barometerService.watchPressureHpa().listen(
      (pressure) => _lastPressureHpa = pressure,
      onError: (_) {
        // Dispositivo sin barómetro: se ignora, fallback a GPS puro.
        // AltitudeFusionService ya sabe manejar pressureHpa == null.
      },
    );

    _positionSubscription = _locationService.watchPosition().listen(
      _onNewPosition,
    );

    // Evidencia de movimiento del sensor de rueda: el odómetro solo
    // cambia cuando la rueda gira de verdad.
    _wheelDistanceSubscription = _ref.listen<double?>(
      speedDistanceMetersProvider,
      (previous, next) {
        if (previous == null || next == null || next <= previous) return;
        _applyAutoPause(_autoPause.onMovement(DateTime.now()));
      },
    );
    _autoPause.reset(DateTime.now());
    _autoPauseTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onAutoPauseTick(),
    );
  }

  Future<void> _unsubscribeFromSensors() async {
    _autoPauseTimer?.cancel();
    _autoPauseTimer = null;
    _wheelDistanceSubscription?.close();
    _wheelDistanceSubscription = null;
    await _positionSubscription?.cancel();
    await _pressureSubscription?.cancel();
    _positionSubscription = null;
    _pressureSubscription = null;
  }

  Future<void> pauseRecording() async {
    if (!state.isRecording || state.isPaused) return;

    await _unsubscribeFromSensors();

    // Si ya estaba en pausa automática, el tiempo en movimiento ya se
    // cortó ahí (`_activeSegmentStartedAt` es null).
    if (_activeSegmentStartedAt != null) {
      _accumulatedActiveDuration +=
          DateTime.now().difference(_activeSegmentStartedAt!);
      _activeSegmentStartedAt = null;
    }

    state = state.copyWith(
      isPaused: true,
      isAutoPaused: false,
      currentSpeedKmh: 0,
    );
    await flushJournal();
  }

  void resumeRecording() {
    if (!state.isRecording || !state.isPaused) return;

    _activeSegmentStartedAt = DateTime.now();
    state = state.copyWith(isPaused: false);
    _subscribeToSensors();
  }

  /// Revisión periódica de la pausa automática.
  void _onAutoPauseTick() {
    if (!state.isRecording || state.isPaused) return;
    final now = DateTime.now();

    if (!_ref.read(autoPauseEnabledProvider)) {
      // Se apagó en Ajustes con la actividad detenida: se retoma ya.
      if (state.isAutoPaused) {
        _autoPause.reset(now);
        _applyAutoPause(AutoPauseTransition.resumed);
      }
      return;
    }

    _applyAutoPause(_autoPause.onTick(now));
  }

  /// Refleja en el estado lo que decidió `AutoPauseDetector`. Nada que
  /// hacer con `null` (sin cambio).
  void _applyAutoPause(AutoPauseTransition? transition) {
    if (transition == null || !state.isRecording || state.isPaused) return;

    switch (transition) {
      case AutoPauseTransition.paused:
        // El tiempo en movimiento se corta en el último instante con
        // movimiento, no ahora: los segundos que se tardó en confirmar la
        // parada no fueron pedaleo.
        final stoppedAt = _autoPause.lastMovementAt ?? DateTime.now();
        final activeSince = _activeSegmentStartedAt;
        if (activeSince != null && stoppedAt.isAfter(activeSince)) {
          _accumulatedActiveDuration += stoppedAt.difference(activeSince);
        }
        _activeSegmentStartedAt = null;
        state = state.copyWith(isAutoPaused: true, currentSpeedKmh: 0);
        unawaited(flushJournal());

      case AutoPauseTransition.resumed:
        if (!state.isAutoPaused) return;
        _activeSegmentStartedAt = DateTime.now();
        state = state.copyWith(isAutoPaused: false);
    }
  }

  /// Umbral mínimo adaptativo de distancia para contarla como
  /// movimiento real en vez de ruido/jitter del GPS. Sigue aplicando
  /// SOLO a la pendiente (ver comentario en _onNewPosition) -- la
  /// distancia/velocidad ya no dependen de este piso cuando hay sensor
  /// BLE conectado.
  static double _distanceNoiseFloor(double? gpsAccuracyMeters) {
    if (gpsAccuracyMeters == null) return 4.0;
    return (gpsAccuracyMeters * 0.5).clamp(2.0, 8.0);
  }

  void _onNewPosition(Position position) {
    // --- Pausa automática. Con sensor de rueda conectado, la evidencia
    // de movimiento la da la rueda (ver `_subscribeToSensors`): la
    // velocidad GPS parado tiene ruido. Sin sensor, la da el GPS. ---
    if (_ref.read(speedKmhProvider) == null) {
      _applyAutoPause(_autoPause.onSpeed(position.speed * 3.6, DateTime.now()));
    }
    // Detenido en pausa automática, el punto no se graba: el GPS quieto
    // "baila" y ensuciaría el trazado y la distancia. Solo sirvió para
    // notar si se volvió a rodar (arriba).
    if (state.isAutoPaused) return;

    // --- Distancia y tiempo desde el punto anterior (crudos, antes
    // del filtro de ruido -- se necesitan crudos para las Capas 1 y 2
    // de altitud, y para decidir si la pendiente se alimenta).
    // `stepDurationSeconds` es lo nuevo: LiveSlopeCalculator y
    // SlopePlausibilityFilter lo usan para que su tiempo de respuesta
    // no dependa de la velocidad (ver LiveSlopeCalculator). Tras
    // reanudar una grabación recuperada, el primer punto nuevo no tiene
    // "anterior" -- ver `_hasGapBeforeNextPoint`. ---
    final RoutePoint? previous = _hasGapBeforeNextPoint || state.points.isEmpty
        ? null
        : state.points.last;
    _hasGapBeforeNextPoint = false;

    double rawStepDistance = 0;
    double stepDurationSeconds = 0;
    if (previous != null) {
      rawStepDistance = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
      stepDurationSeconds =
          DateTime.now().difference(previous.timestamp).inMilliseconds /
              1000.0;
    }

    final noiseFloor = _distanceNoiseFloor(position.accuracy);
    final addedDistance = rawStepDistance > noiseFloor ? rawStepDistance : 0.0;

    // --- CAPA 1: fusión difusa multi-fuente de altitud. La referencia
    // "confiable" ahora sale de la cadena de prioridades (GPX > HGT);
    // si ninguna tiene dato en esta coordenada, se cae al GPS/barómetro
    // fusionado y el punto queda marcado como aproximado. El aplanado
    // post-actividad (ActivityAltitudeFlattener) usa la MISMA cadena. ---
    final refAltitude = _elevation
        .resolve(position.latitude, position.longitude)
        .altitudeMeters;

    final realtimeAltitude = _altitudeFusion.fuse(
      gpsAltitude: position.altitude,
      pressureHpa: _lastPressureHpa,
    );

    final fusionResult = _altitudeFusionFilter.fuse(
      AltitudeSourceReading(
        demAltitude: refAltitude,
        realtimeAltitude: realtimeAltitude,
        gpsAccuracyMeters: position.accuracy,
        stepDistanceMeters: rawStepDistance,
      ),
    );

    // Recalibración del barómetro contra la referencia confiable
    // (GPX/HGT) -- solo cuando la Capa 1 ha visto suficiente distancia
    // SIN sospecha de estructura elevada, y solo si hay referencia.
    if (refAltitude != null && _altitudeFusionFilter.shouldRecalibrate()) {
      _altitudeFusion.recalibrateOffset(refAltitude);
    }

    final newPoint = RoutePoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: fusionResult.fusedAltitude,
      speedMetersPerSecond: position.speed,
      bearingDegrees: position.heading,
      accuracyMeters: position.accuracy,
      timestamp: DateTime.now(),
    );

    double addedElevationGain = 0;
    if (previous != null) {
      final altitudeDelta = newPoint.altitude - previous.altitude;
      if (altitudeDelta > 0) {
        addedElevationGain = altitudeDelta;
      }
    }

    // --- Distancia y velocidad: sensor de velocidad BLE con
    // prioridad, GPS como respaldo. El offset se recalcula solo cuando
    // el sensor "aparece" (pasa de no disponible a disponible), para
    // no saltar ni duplicar distancia ya acumulada por GPS antes de que
    // se conectara (o tras una reconexión a mitad de la grabación). Si
    // el sensor se desconecta, se cae de vuelta a GPS sin más -- el
    // offset se limpia para recalcularse la próxima vez que reaparezca.
    final sensorSpeedKmh = _ref.read(speedKmhProvider);
    final sensorTotalDistance = _ref.read(speedDistanceMetersProvider);
    final sensorAvailable =
        sensorSpeedKmh != null && sensorTotalDistance != null;

    double newCumulativeDistance;
    double clampedSpeedKmh;

    if (sensorAvailable) {
      _sensorDistanceOffset ??=
          sensorTotalDistance - state.cumulativeDistanceMeters;
      newCumulativeDistance = sensorTotalDistance - _sensorDistanceOffset!;
      clampedSpeedKmh = sensorSpeedKmh < 0 ? 0.0 : sensorSpeedKmh;
    } else {
      _sensorDistanceOffset = null;
      newCumulativeDistance = state.cumulativeDistanceMeters + addedDistance;
      final speedKmh = newPoint.speedMetersPerSecond * 3.6;
      clampedSpeedKmh = speedKmh < 0 ? 0.0 : speedKmh;
    }

    // La ventana de regresión de pendiente sigue dependiendo SOLO del
    // piso de ruido de GPS (addedDistance) para decidir si se alimenta
    // -- esto es intencional, la pendiente no cambia de fuente, solo
    // distancia/velocidad.
    double trustedSlope = state.currentSlopePercent;
    double displaySlope = state.displaySlopePercent;

    if (addedDistance > 0) {
      final rawSlope = _slopeCalculator.addSample(
        cumulativeDistanceMeters: newCumulativeDistance,
        altitude: newPoint.altitude,
        timestamp: newPoint.timestamp,
      );

      trustedSlope = _slopePlausibility.filter(
        rawSlope: rawSlope,
        stepDistanceMeters: rawStepDistance,
        stepDurationSeconds: stepDurationSeconds,
      );
      displaySlope = _slopePresentation.format(trustedSlope);
    }

    _debugLogger.logSample(
      timestamp: DateTime.now(),
      gpsAltitude: position.altitude,
      smoothedPressureHpa:
          _altitudeFusion.lastDebugSnapshot?.smoothedPressureHpa,
      barometricAltitude:
          _altitudeFusion.lastDebugSnapshot?.barometricAltitude,
      barometricDeltaRaw:
          _altitudeFusion.lastDebugSnapshot?.barometricDeltaRaw ?? 0,
      barometricDeltaClamped:
          _altitudeFusion.lastDebugSnapshot?.barometricDeltaClamped ?? 0,
      fusedAltitude: fusionResult.fusedAltitude,
      slopePercent: trustedSlope,
    );

    _liveDistanceHistory.add(newCumulativeDistance);
    _liveSpeedHistory.add(clampedSpeedKmh);
    _journal.addPoint(
      JournalPoint(
        point: newPoint,
        distanceMeters: newCumulativeDistance,
        speedKmh: clampedSpeedKmh,
      ),
    );

    state = state.copyWith(
      points: [...state.points, newPoint],
      cumulativeDistanceMeters: newCumulativeDistance,
      elevationGainMeters: state.elevationGainMeters + addedElevationGain,
      currentSlopePercent: trustedSlope,
      displaySlopePercent: displaySlope,
      currentSpeedKmh: clampedSpeedKmh,
      maxSpeedKmh:
          clampedSpeedKmh > state.maxSpeedKmh
              ? clampedSpeedKmh
              : state.maxSpeedKmh,
      currentBearingDegrees: newPoint.bearingDegrees,
      isApproximateElevation:
          refAltitude == null || fusionResult.bridgeSuspected,
    );
  }

  Duration elapsedDuration() {
    if (state.startedAt == null) return Duration.zero;
    if (state.isPaused || _activeSegmentStartedAt == null) {
      return _accumulatedActiveDuration;
    }
    return _accumulatedActiveDuration +
        DateTime.now().difference(_activeSegmentStartedAt!);
  }

  Future<void> cancelRecording() async {
    _stopJournalTimer();
    await _unsubscribeFromSensors();
    await _debugLogger.stop();
    _activeSegmentStartedAt = null;
    _accumulatedActiveDuration = Duration.zero;
    _sensorDistanceOffset = null;
    _liveDistanceHistory.clear();
    _liveSpeedHistory.clear();
    state = const RouteRecordingState();
    await _journal.clear();
  }

  /// Termina la actividad: detiene los sensores, APLANA la altimetría
  /// completa contra HGT (Fase 1 -- ver `ActivityAltitudeFlattener`),
  /// arma el `ActivitySummary` final (ver `buildActivitySummary`) y
  /// resetea el estado.
  ///
  /// La distancia y velocidad de cada punto siguen sin recalcularse
  /// con Geolocator desde cero -- se reutiliza
  /// `_liveDistanceHistory`/`_liveSpeedHistory`, que ya tienen
  /// priorizado sensor-vs-GPS correctamente para cada instante (y es
  /// la misma distancia que usa el flattener para su regresión de
  /// pendiente).
  ///
  /// La sesión queda marcada como terminada en el diario, pero NO se
  /// borra: si la app se cierra en la pantalla de guardar, al volver a
  /// abrirla se ofrece guardarla. Quien guarde o descarte la actividad
  /// es quien vacía el diario.
  Future<ActivitySummary> finishRecording({
    required List<HeartRateSample> heartRateSamples,
    required List<PowerSample> powerSamples,
    required List<CadenceSample> cadenceSamples,
  }) async {
    _stopJournalTimer();
    await _unsubscribeFromSensors();
    await _debugLogger.stop();

    final elapsed = elapsedDuration();
    final startedAt = state.startedAt ?? DateTime.now();
    final endedAt = DateTime.now();

    await _journal.flush(
      movingTime: elapsed,
      isPaused: state.isPaused,
      endedAt: endedAt,
    );

    final summary = _summarize(
      points: state.points,
      distances: _liveDistanceHistory,
      speeds: _liveSpeedHistory,
      startedAt: startedAt,
      endedAt: endedAt,
      movingTime: elapsed,
      heartRateSamples: heartRateSamples,
      powerSamples: powerSamples,
      cadenceSamples: cadenceSamples,
    );

    _activeSegmentStartedAt = null;
    _accumulatedActiveDuration = Duration.zero;
    _sensorDistanceOffset = null;
    _liveDistanceHistory.clear();
    _liveSpeedHistory.clear();
    state = const RouteRecordingState();

    return summary;
  }

  /// Termina, sin reanudarla, una grabación recuperada del diario tras un
  /// cierre inesperado -- el mismo resumen que habría dado
  /// [finishRecording] con lo que alcanzó a guardarse. Si la sesión
  /// nunca llegó a "Terminar", el fin es su último dato conocido.
  Future<ActivitySummary> finishRecovered(RecordingSnapshot snapshot) async {
    await _elevation.preload();

    final endedAt = snapshot.lastDataAt;
    if (!snapshot.isFinished) {
      _journal.resume(snapshot);
      await _journal.flush(
        movingTime: snapshot.movingTime,
        isPaused: snapshot.isPaused,
        endedAt: endedAt,
      );
    }

    return _summarize(
      points: snapshot.routePoints,
      distances: [for (final p in snapshot.points) p.distanceMeters],
      speeds: [for (final p in snapshot.points) p.speedKmh],
      startedAt: snapshot.startedAt,
      endedAt: endedAt,
      movingTime: snapshot.movingTime,
      heartRateSamples: snapshot.heartRate,
      powerSamples: snapshot.power,
      cadenceSamples: snapshot.cadence,
    );
  }

  /// Aplanado de altimetría contra la cadena de prioridades (GPX > HGT >
  /// fusión en vivo) + resumen final. `distances` va alineado índice a
  /// índice con `points`.
  ActivitySummary _summarize({
    required List<RoutePoint> points,
    required List<double> distances,
    required List<double> speeds,
    required DateTime startedAt,
    required DateTime endedAt,
    required Duration movingTime,
    required List<HeartRateSample> heartRateSamples,
    required List<PowerSample> powerSamples,
    required List<CadenceSample> cadenceSamples,
  }) {
    final flattened = ActivityAltitudeFlattener(
      _elevation,
    ).flatten(points: points, cumulativeDistanceMeters: distances);
    return buildActivitySummary(
      points: points,
      distances: distances,
      speeds: speeds,
      flattened: flattened,
      startedAt: startedAt,
      endedAt: endedAt,
      movingTime: movingTime,
      heartRateSamples: heartRateSamples,
      powerSamples: powerSamples,
      cadenceSamples: cadenceSamples,
    );
  }

  @override
  void dispose() {
    _stopJournalTimer();
    _autoPauseTimer?.cancel();
    _positionSubscription?.cancel();
    _pressureSubscription?.cancel();
    super.dispose();
  }
}

final routeRecordingProvider =
    StateNotifierProvider<RouteRecordingController, RouteRecordingState>((
      ref,
    ) {
      final locationService = ref.read(locationServiceProvider);
      final barometerService = ref.read(barometerServiceProvider);
      final elevationResolver = ref.read(elevationResolverProvider);
      final controller = RouteRecordingController(
        locationService,
        barometerService,
        elevationResolver,
        ref.read(recordingJournalProvider),
        ref,
      );

      // Al pasar a segundo plano (pantalla bloqueada, otra app) Android
      // puede matar el proceso sin más aviso: se escribe al diario ya,
      // sin esperar al siguiente ciclo.
      final lifecycle = AppLifecycleListener(
        onHide: () => unawaited(controller.flushJournal()),
      );
      ref.onDispose(lifecycle.dispose);

      return controller;
    });
