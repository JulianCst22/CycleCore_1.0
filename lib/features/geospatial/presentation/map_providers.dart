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

  RouteRecordingController(
    this._locationService,
    this._barometerService,
    this._elevationRepository,
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
  /// movimiento real en vez de ruido/jitter del GPS. Antes se sumaba
  /// SIEMPRE la distancia entre puntos consecutivos, sin importar qué
  /// tan cerca quedaran -- eso hacía que el jitter normal del GPS
  /// (típico detenido en un semáforo o yendo muy lento) se sumara como
  /// si fuera desplazamiento real, inflando la distancia total Y
  /// amplificando el ruido de pendiente (una diferencia de altitud
  /// diminuta dividida entre una distancia diminuta da un porcentaje
  /// absurdo). El umbral se adapta a la precisión reportada por el
  /// GPS: con peor precisión, se necesita más distancia para confiar
  /// en que el movimiento fue real.
  static double _distanceNoiseFloor(double? gpsAccuracyMeters) {
    if (gpsAccuracyMeters == null) return 4.0;
    return (gpsAccuracyMeters * 0.5).clamp(2.0, 8.0);
  }

  void _onNewPosition(Position position) {
    // --- Distancia desde el punto anterior (cruda, antes del filtro
    // de ruido -- la necesitamos cruda para las Capas 1 y 2, que la
    // usan como señal de "qué tan juntos están los puntos"). ---
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

    // --- CAPA 1: fusión difusa multi-fuente de altitud ---
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

    final newCumulativeDistance =
        state.cumulativeDistanceMeters + addedDistance;

    // La ventana de regresión (Capa de pendiente cruda) y la Capa 2
    // solo avanzan cuando hubo movimiento real (addedDistance > 0). Si
    // el paso quedó filtrado por el piso de ruido, meterlo igual
    // repetiría la misma distancia acumulada (mismo X de la regresión)
    // con una altitud distinta solo por ruido de grilla del DEM (Y
    // ruidosa) -- justo el peor punto para alimentar una regresión. En
    // ese caso se conserva la última pendiente calculada tal cual.
    double trustedSlope = state.currentSlopePercent;
    double displaySlope = state.displaySlopePercent;

    if (addedDistance > 0) {
      final rawSlope = _slopeCalculator.addSample(
        cumulativeDistanceMeters: newCumulativeDistance,
        altitude: newPoint.altitude,
      );

      // rawStepDistance == addedDistance en esta rama (los dos ya
      // superaron el mismo piso de ruido) -- se deja rawStepDistance
      // explícito porque es la señal semánticamente correcta ("qué tan
      // juntos están los puntos"), y así queda consistente con lo que
      // hace finishRecording() en la reconstrucción histórica.
      trustedSlope = _slopePlausibility.filter(
        rawSlope: rawSlope,
        stepDistanceMeters: rawStepDistance,
      );
      displaySlope = _slopePresentation.format(trustedSlope);
    }

    final speedKmh = newPoint.speedMetersPerSecond * 3.6;
    final clampedSpeedKmh = speedKmh < 0 ? 0.0 : speedKmh;

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
    state = const RouteRecordingState();
  }

  /// Termina la actividad: detiene los sensores, reconstruye cada punto
  /// enriquecido para alimentar los gráficos del detalle, arma el
  /// `ActivitySummary` final, y resetea el estado.
  ///
  /// Usa instancias NUEVAS de SlopeWindowCalculator y
  /// SlopePlausibilityFilter para que la reconstrucción histórica dé
  /// exactamente el mismo resultado que lo que se vio en vivo, punto
  /// por punto.
  ///
  /// NOTA: aquí no se puede repetir la Capa 1 (fusión de altitud) --
  /// esa ya corrió en vivo y su resultado quedó guardado en
  /// `point.altitude` de cada RoutePoint. Repetirla no tendría sentido
  /// porque dependía de estado en tiempo real (presión del barómetro
  /// en ese instante exacto) que ya no existe.
  ///
  /// El filtro de distancia fantasma usa el MISMO piso de ruido
  /// adaptativo que en vivo (`_distanceNoiseFloor`, basado en
  /// `RoutePoint.accuracyMeters` guardado por punto) -- ya no hay
  /// discrepancia entre lo que se vio en vivo y lo que queda en el
  /// resumen guardado.
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
    double runningDistance = 0;
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

      double stepDistance = 0;
      if (i > 0) {
        final previous = state.points[i - 1];
        final rawStep = Geolocator.distanceBetween(
          previous.latitude,
          previous.longitude,
          point.latitude,
          point.longitude,
        );
        // Mismo piso adaptativo que en vivo, ahora posible porque
        // RoutePoint guarda accuracyMeters por punto.
        final noiseFloor = _distanceNoiseFloor(point.accuracyMeters);
        if (rawStep > noiseFloor) {
          runningDistance += rawStep;
          stepDistance = rawStep;
        }
      }

      // Mismo criterio que en vivo (_onNewPosition): si no hubo
      // movimiento real, no se alimenta la regresión de pendiente ni
      // la Capa 2 -- se conserva la última pendiente calculada. Esto
      // es lo que hace que la reconstrucción sea fiel, punto por
      // punto, a lo que se vio en vivo.
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

      final pointSpeedKmh = point.speedMetersPerSecond * 3.6;

      enrichedPoints.add(
        RoutePointSnapshot(
          latitude: point.latitude,
          longitude: point.longitude,
          altitude: point.altitude,
          distanceFromStartMeters: runningDistance,
          slopePercent: trustedSlope,
          speedKmh: pointSpeedKmh < 0 ? 0 : pointSpeedKmh,
          secondsFromStart: point.timestamp.difference(startedAt).inSeconds,
          heartRateBpm: carriedHr,
          powerWatts: carriedPower,
          cadenceRpm: carriedCadence,
        ),
      );
    }

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
      distanceMeters: runningDistance,
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
      );
    });