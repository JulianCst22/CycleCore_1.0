import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/fuzzy_engine/altitude_fusion/altitude_fusion_filter.dart';
import '../../../core/fuzzy_engine/altitude_fusion/altitude_source_reading.dart';
import '../../../core/fuzzy_engine/slope_plausibility/slope_plausibility_filter.dart';
import '../../../core/sensors/altitude_debug_logger.dart';
import '../../../core/sensors/altitude_fusion_service.dart';
import '../../../core/sensors/barometer_service.dart';
import '../../activities/domain/activity_summary.dart';
import '../../elevation/data/elevation_repository.dart';
import '../../elevation/presentation/elevation_providers.dart';
import '../../sensors/presentation/speed_providers.dart';
import '../data/location_service.dart';
import '../domain/route_point.dart';
import '../domain/slope_presentation_formatter.dart';
import '../domain/slope_window_calculator.dart';

/// Instancia única del servicio de ubicación, compartida por toda la app.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Instancia única del servicio de barómetro.
final barometerServiceProvider = Provider<BarometerService>((ref) {
  return BarometerService();
});

/// Posición actual del dispositivo, obtenida una sola vez.
/// Se usa para centrar el mapa la primera vez que se abre la pantalla.
final currentPositionProvider = FutureProvider<Position>((ref) async {
  final service = ref.read(locationServiceProvider);
  return service.getCurrentPosition();
});

/// Emite un evento cada segundo mientras exista algún listener activo.
/// Se usa únicamente para forzar el refresco del tiempo transcurrido en
/// el panel de datos, incluso cuando no ha llegado un nuevo punto GPS.
final secondTickerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (tick) => tick);
});

/// NOTA: heartRateBpmProvider vive ahora en
/// features/sensors/presentation/sensor_providers.dart -- ver el
/// resumen del proyecto para más contexto. Lo mismo aplica a
/// powerWattsProvider y cadenceRpmProvider (features/sensors).

/// Estado inmutable de una sesión de grabación de ruta / entrenamiento.
class RouteRecordingState {
  final bool isRecording;
  final bool isPaused;
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
  final ElevationRepository _elevationRepository;
  final Ref _ref;
  final AltitudeFusionService _altitudeFusion = AltitudeFusionService();
  final SlopeWindowCalculator _slopeCalculator = SlopeWindowCalculator();

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
  /// reporta datos reales.
  final List<double> _liveDistanceHistory = [];
  final List<double> _liveSpeedHistory = [];

  RouteRecordingController(
    this._locationService,
    this._barometerService,
    this._elevationRepository,
    this._ref,
  ) : super(const RouteRecordingState());

  /// Archivo CSV de la sesión más reciente (o ya cerrada), por si la UI
  /// quiere agregar más adelante un botón de "compartir log".
  File? get debugLogFile => _debugLogger.currentFile;

  Future<void> startRecording() async {
    if (state.isRecording) return;

    await _locationService.ensureLocationReady();
    await _locationService.ensureBackgroundLocationReady();
    await _elevationRepository.preloadCatalog();

    _altitudeFusion.reset();
    _slopeCalculator.reset();
    _altitudeFusionFilter.reset();
    _slopePlausibility.reset();
    _slopePresentation.reset();
    _lastPressureHpa = null;
    _accumulatedActiveDuration = Duration.zero;
    _activeSegmentStartedAt = DateTime.now();
    _sensorDistanceOffset = null;
    _liveDistanceHistory.clear();
    _liveSpeedHistory.clear();

    // Espera acotada a que el GPS estabilice ANTES de empezar a grabar
    // -- reduce la probabilidad de arrancar con un fix de cold start
    // malo. No es infalible (puede vencer el timeout con el GPS
    // todavía inestable): el buffer de calentamiento de
    // SlopePlausibilityFilter es la segunda línea de defensa para ese
    // caso. Ver LocationService.waitForStableFix.
    state = state.copyWith(isAcquiringGps: true);
    await _locationService.waitForStableFix();

    await _debugLogger.start(DateTime.now().millisecondsSinceEpoch.toString());

    state = RouteRecordingState(isRecording: true, startedAt: DateTime.now());

    _subscribeToSensors();
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
  }

  Future<void> _unsubscribeFromSensors() async {
    await _positionSubscription?.cancel();
    await _pressureSubscription?.cancel();
    _positionSubscription = null;
    _pressureSubscription = null;
  }

  Future<void> pauseRecording() async {
    if (!state.isRecording || state.isPaused) return;

    await _unsubscribeFromSensors();

    if (_activeSegmentStartedAt != null) {
      _accumulatedActiveDuration +=
          DateTime.now().difference(_activeSegmentStartedAt!);
      _activeSegmentStartedAt = null;
    }

    state = state.copyWith(isPaused: true, currentSpeedKmh: 0);
  }

  void resumeRecording() {
    if (!state.isRecording || !state.isPaused) return;

    _activeSegmentStartedAt = DateTime.now();
    state = state.copyWith(isPaused: false);
    _subscribeToSensors();
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
    // --- Distancia desde el punto anterior (cruda, antes del filtro
    // de ruido -- la necesitamos cruda para las Capas 1 y 2 de altitud,
    // y para decidir si la pendiente se alimenta). ---
    double rawStepDistance = 0;
    if (state.points.isNotEmpty) {
      final previous = state.points.last;
      rawStepDistance = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
    }

    final noiseFloor = _distanceNoiseFloor(position.accuracy);
    final addedDistance = rawStepDistance > noiseFloor ? rawStepDistance : 0.0;

    // --- CAPA 1: fusión difusa multi-fuente de altitud (sin cambios,
    // sigue dependiendo exclusivamente de GPS/barómetro/DEM) ---
    final demAltitude = _elevationRepository.elevationAtSync(
      position.latitude,
      position.longitude,
    );

    final realtimeAltitude = _altitudeFusion.fuse(
      gpsAltitude: position.altitude,
      pressureHpa: _lastPressureHpa,
    );

    final fusionResult = _altitudeFusionFilter.fuse(
      AltitudeSourceReading(
        demAltitude: demAltitude,
        realtimeAltitude: realtimeAltitude,
        gpsAccuracyMeters: position.accuracy,
        stepDistanceMeters: rawStepDistance,
      ),
    );

    // Recalibración del barómetro contra el DEM -- solo cuando la
    // Capa 1 ha visto suficiente distancia SIN sospecha de estructura
    // elevada. Solo tiene sentido cuando efectivamente hay tesela.
    if (demAltitude != null && _altitudeFusionFilter.shouldRecalibrate()) {
      _altitudeFusion.recalibrateOffset(demAltitude);
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
    if (state.points.isNotEmpty) {
      final previous = state.points.last;
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
      );

      trustedSlope = _slopePlausibility.filter(
        rawSlope: rawSlope,
        stepDistanceMeters: rawStepDistance,
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
          demAltitude == null || fusionResult.bridgeSuspected,
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
    await _unsubscribeFromSensors();
    await _debugLogger.stop();
    _activeSegmentStartedAt = null;
    _accumulatedActiveDuration = Duration.zero;
    _sensorDistanceOffset = null;
    _liveDistanceHistory.clear();
    _liveSpeedHistory.clear();
    state = const RouteRecordingState();
  }

  /// Termina la actividad: detiene los sensores, reconstruye cada punto
  /// enriquecido para alimentar los gráficos del detalle, arma el
  /// `ActivitySummary` final, y resetea el estado.
  ///
  /// La pendiente/altitud se reconstruyen igual que antes (instancias
  /// nuevas de los filtros, misma fidelidad punto por punto). La
  /// distancia y velocidad de cada punto YA NO se recalculan con
  /// Geolocator desde cero -- se reutiliza `_liveDistanceHistory`/
  /// `_liveSpeedHistory`, que ya tienen priorizado sensor-vs-GPS
  /// correctamente para cada instante. El incremento entre punto y
  /// punto de esa distancia ya priorizada es lo que decide si se
  /// alimenta la regresión de pendiente (reemplaza el antiguo cálculo
  /// de `stepDistance` vía Geolocator + piso de ruido).
  ///
  /// `powerSamples`/`cadenceSamples` siguen el mismo patrón de "carry
  /// forward" que `heartRateSamples`: cada punto GPS se casa con la
  /// última lectura conocida de ese sensor hasta ese instante. Listas
  /// vacías (sin sensor conectado) simplemente dejan esos campos en
  /// null en cada punto, y avg/max en null en el resumen.
  Future<ActivitySummary> finishRecording({
    required List<HeartRateSample> heartRateSamples,
    required List<PowerSample> powerSamples,
    required List<CadenceSample> cadenceSamples,
  }) async {
    await _unsubscribeFromSensors();
    await _debugLogger.stop();

    final elapsed = elapsedDuration();
    final startedAt = state.startedAt ?? DateTime.now();

    final slopeCalc = SlopeWindowCalculator();
    final slopePlausibility = SlopePlausibilityFilter();
    double lastTrustedSlope = 0;
    int hrIndex = 0;
    int? carriedHr;
    int powerIndex = 0;
    int? carriedPower;
    int cadenceIndex = 0;
    double? carriedCadence;
    final enrichedPoints = <RoutePointSnapshot>[];

    for (int i = 0; i < state.points.length; i++) {
      final point = state.points[i];
      final runningDistance = _liveDistanceHistory[i];
      final pointSpeedKmh = _liveSpeedHistory[i];

      final stepDistance =
          i == 0 ? 0.0 : runningDistance - _liveDistanceHistory[i - 1];

      // Mismo criterio que en vivo: si no hubo movimiento real, no se
      // alimenta la regresión de pendiente ni la Capa 2 -- se conserva
      // la última pendiente calculada.
      if (stepDistance > 0) {
        final rawSlope = slopeCalc.addSample(
          cumulativeDistanceMeters: runningDistance,
          altitude: point.altitude,
        );
        lastTrustedSlope = slopePlausibility.filter(
          rawSlope: rawSlope,
          stepDistanceMeters: stepDistance,
        );
      }
      final trustedSlope = lastTrustedSlope;

      while (hrIndex < heartRateSamples.length &&
          !heartRateSamples[hrIndex].timestamp.isAfter(point.timestamp)) {
        carriedHr = heartRateSamples[hrIndex].bpm;
        hrIndex++;
      }

      while (powerIndex < powerSamples.length &&
          !powerSamples[powerIndex].timestamp.isAfter(point.timestamp)) {
        carriedPower = powerSamples[powerIndex].watts;
        powerIndex++;
      }

      while (cadenceIndex < cadenceSamples.length &&
          !cadenceSamples[cadenceIndex].timestamp.isAfter(point.timestamp)) {
        carriedCadence = cadenceSamples[cadenceIndex].rpm;
        cadenceIndex++;
      }

      enrichedPoints.add(
        RoutePointSnapshot(
          latitude: point.latitude,
          longitude: point.longitude,
          altitude: point.altitude,
          distanceFromStartMeters: runningDistance,
          slopePercent: trustedSlope,
          speedKmh: pointSpeedKmh,
          secondsFromStart: point.timestamp.difference(startedAt).inSeconds,
          heartRateBpm: carriedHr,
          powerWatts: carriedPower,
          cadenceRpm: carriedCadence,
        ),
      );
    }

    final finalDistance =
        _liveDistanceHistory.isEmpty ? 0.0 : _liveDistanceHistory.last;

    int? avgHeartRate;
    int? maxHeartRate;
    if (heartRateSamples.isNotEmpty) {
      final bpmValues = heartRateSamples.map((s) => s.bpm);
      avgHeartRate =
          (bpmValues.reduce((a, b) => a + b) / bpmValues.length).round();
      maxHeartRate = bpmValues.reduce((a, b) => a > b ? a : b);
    }

    int? avgPower;
    int? maxPower;
    if (powerSamples.isNotEmpty) {
      final wattValues = powerSamples.map((s) => s.watts);
      avgPower =
          (wattValues.reduce((a, b) => a + b) / wattValues.length).round();
      maxPower = wattValues.reduce((a, b) => a > b ? a : b);
    }

    int? avgCadence;
    int? maxCadence;
    if (cadenceSamples.isNotEmpty) {
      final rpmValues = cadenceSamples.map((s) => s.rpm);
      avgCadence =
          (rpmValues.reduce((a, b) => a + b) / rpmValues.length).round();
      maxCadence = rpmValues.reduce((a, b) => a > b ? a : b).round();
    }

    final summary = ActivitySummary(
      startedAt: startedAt,
      endedAt: DateTime.now(),
      duration: elapsed,
      distanceMeters: finalDistance,
      avgSpeedKmh: state.averageSpeedKmhOver(elapsed),
      maxSpeedKmh: state.maxSpeedKmh,
      elevationGainMeters: state.elevationGainMeters,
      avgHeartRate: avgHeartRate,
      maxHeartRate: maxHeartRate,
      avgPower: avgPower,
      maxPower: maxPower,
      avgCadence: avgCadence,
      maxCadence: maxCadence,
      routePoints: enrichedPoints,
    );

    _activeSegmentStartedAt = null;
    _accumulatedActiveDuration = Duration.zero;
    _sensorDistanceOffset = null;
    _liveDistanceHistory.clear();
    _liveSpeedHistory.clear();
    state = const RouteRecordingState();

    return summary;
  }

  @override
  void dispose() {
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
      final elevationRepository = ref.read(elevationRepositoryProvider);
      return RouteRecordingController(
        locationService,
        barometerService,
        elevationRepository,
        ref,
      );
    });
