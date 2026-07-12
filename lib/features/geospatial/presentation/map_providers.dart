import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/sensors/altitude_debug_logger.dart';
import '../../../core/sensors/altitude_fusion_service.dart';
import '../../../core/sensors/barometer_service.dart';
import '../../activities/domain/activity_summary.dart';
import '../data/location_service.dart';
import '../domain/route_point.dart';
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
/// features/sensors/presentation/sensor_providers.dart, junto con toda
/// la lógica de conexión BLE que lo alimenta. Se movió de aquí porque
/// la frecuencia cardíaca es responsabilidad del módulo de sensores,
/// no del módulo geoespacial -- map_screen.dart lo importa desde allá.

/// Estado inmutable de una sesión de grabación de ruta / entrenamiento.
class RouteRecordingState {
  final bool isRecording;
  final bool isPaused;
  final List<RoutePoint> points;
  final DateTime? startedAt;
  final double cumulativeDistanceMeters;
  final double elevationGainMeters;
  final double currentSlopePercent;
  final double currentSpeedKmh;
  final double maxSpeedKmh;
  final double currentBearingDegrees;

  const RouteRecordingState({
    this.isRecording = false,
    this.isPaused = false,
    this.points = const [],
    this.startedAt,
    this.cumulativeDistanceMeters = 0,
    this.elevationGainMeters = 0,
    this.currentSlopePercent = 0,
    this.currentSpeedKmh = 0,
    this.maxSpeedKmh = 0,
    this.currentBearingDegrees = 0,
  });

  RouteRecordingState copyWith({
    bool? isRecording,
    bool? isPaused,
    List<RoutePoint>? points,
    DateTime? startedAt,
    double? cumulativeDistanceMeters,
    double? elevationGainMeters,
    double? currentSlopePercent,
    double? currentSpeedKmh,
    double? maxSpeedKmh,
    double? currentBearingDegrees,
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
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      currentBearingDegrees:
          currentBearingDegrees ?? this.currentBearingDegrees,
    );
  }

  /// Velocidad promedio basada en el tiempo transcurrido en movimiento
  /// (excluyendo pausas). El controller es quien calcula ese tiempo real
  /// vía `elapsedDuration()`; aquí solo se hace la división.
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
  final AltitudeFusionService _altitudeFusion = AltitudeFusionService();
  final SlopeWindowCalculator _slopeCalculator = SlopeWindowCalculator();

  /// TEMPORAL -- herramienta de diagnóstico para el problema de
  /// pendiente en campo real. Ver AltitudeDebugLogger.
  final AltitudeDebugLogger _debugLogger = AltitudeDebugLogger();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<double>? _pressureSubscription;
  double? _lastPressureHpa;

  /// Tiempo real de movimiento acumulado, EXCLUYENDO las pausas. Se va
  /// sumando cada vez que se pausa; al terminar se le suma el tramo
  /// activo actual (ver `elapsedDuration()`).
  Duration _accumulatedActiveDuration = Duration.zero;
  DateTime? _activeSegmentStartedAt;

  RouteRecordingController(this._locationService, this._barometerService)
    : super(const RouteRecordingState());

  Future<void> startRecording() async {
    if (state.isRecording) return;

    await _locationService.ensureLocationReady();

    // No bloqueamos el inicio de la grabación si el usuario niega el
    // permiso de segundo plano -- la app sigue siendo útil grabando
    // solo en primer plano, simplemente se detendrá si se bloquea la
    // pantalla. La UI puede usar este valor para advertir al usuario.
    await _locationService.ensureBackgroundLocationReady();

    _altitudeFusion.reset();
    _slopeCalculator.reset();
    _lastPressureHpa = null;
    _accumulatedActiveDuration = Duration.zero;
    _activeSegmentStartedAt = DateTime.now();

    await _debugLogger.start(DateTime.now().millisecondsSinceEpoch.toString());

    state = RouteRecordingState(isRecording: true, startedAt: DateTime.now());

    _subscribeToSensors();
  }

  void _subscribeToSensors() {
    _pressureSubscription = _barometerService.watchPressureHpa().listen(
      (pressure) => _lastPressureHpa = pressure,
      onError: (_) {
        // Dispositivo sin barómetro: se ignora, fallback a GPS puro.
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

  /// Pausa la grabación: deja de escuchar GPS/barómetro (ahorra batería)
  /// sin perder ni los puntos ni los totales acumulados hasta ahora.
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

  /// Reanuda una grabación pausada, retomando el conteo de tiempo activo
  /// y volviendo a escuchar los sensores.
  void resumeRecording() {
    if (!state.isRecording || !state.isPaused) return;

    _activeSegmentStartedAt = DateTime.now();
    state = state.copyWith(isPaused: false);
    _subscribeToSensors();
  }

  void _onNewPosition(Position position) {
    final fusedAltitude = _altitudeFusion.fuse(
      gpsAltitude: position.altitude,
      pressureHpa: _lastPressureHpa,
    );

    final newPoint = RoutePoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: fusedAltitude,
      speedMetersPerSecond: position.speed,
      bearingDegrees: position.heading,
      timestamp: DateTime.now(),
    );

    double addedDistance = 0;
    double addedElevationGain = 0;

    if (state.points.isNotEmpty) {
      final previous = state.points.last;

      addedDistance = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        newPoint.latitude,
        newPoint.longitude,
      );

      final altitudeDelta = newPoint.altitude - previous.altitude;
      if (altitudeDelta > 0) {
        addedElevationGain = altitudeDelta;
      }
    }

    final newCumulativeDistance =
        state.cumulativeDistanceMeters + addedDistance;

    // La pendiente se calcula con una regresión lineal sobre una
    // ventana móvil de los últimos ~40 metros, no con la diferencia
    // entre solo dos puntos -- ver SlopeWindowCalculator para el
    // porqué (el cálculo de 2 puntos amplificaba el ruido del GPS a
    // niveles inutilizables en campo real).
    final slope = _slopeCalculator.addSample(
      cumulativeDistanceMeters: newCumulativeDistance,
      altitude: newPoint.altitude,
    );

    // TEMPORAL: registro de depuración de la fusión de altitud.
    final debugSnapshot = _altitudeFusion.lastDebugSnapshot;
    if (debugSnapshot != null) {
      _debugLogger.logSample(
        timestamp: newPoint.timestamp,
        gpsAltitude: debugSnapshot.gpsAltitude,
        smoothedPressureHpa: debugSnapshot.smoothedPressureHpa,
        barometricAltitude: debugSnapshot.barometricAltitude,
        barometricDeltaRaw: debugSnapshot.barometricDeltaRaw,
        barometricDeltaClamped: debugSnapshot.barometricDeltaClamped,
        fusedAltitude: fusedAltitude,
        slopePercent: slope,
      );
    }

    final speedKmh = newPoint.speedMetersPerSecond * 3.6;
    final clampedSpeedKmh = speedKmh < 0 ? 0.0 : speedKmh;

    state = state.copyWith(
      points: [...state.points, newPoint],
      cumulativeDistanceMeters: newCumulativeDistance,
      elevationGainMeters: state.elevationGainMeters + addedElevationGain,
      currentSlopePercent: slope,
      currentSpeedKmh: clampedSpeedKmh,
      maxSpeedKmh:
          clampedSpeedKmh > state.maxSpeedKmh
              ? clampedSpeedKmh
              : state.maxSpeedKmh,
      currentBearingDegrees: newPoint.bearingDegrees,
    );
  }

  /// Tiempo real de movimiento transcurrido, excluyendo pausas. Úsalo en
  /// vez de `DateTime.now().difference(startedAt)` en la UI para que el
  /// cronómetro se congele mientras la grabación está pausada.
  Duration elapsedDuration() {
    if (state.startedAt == null) return Duration.zero;
    if (state.isPaused || _activeSegmentStartedAt == null) {
      return _accumulatedActiveDuration;
    }
    return _accumulatedActiveDuration +
        DateTime.now().difference(_activeSegmentStartedAt!);
  }

  /// Detiene la grabación y descarta todo sin guardar nada (usado si el
  /// usuario decide no continuar sin pasar por la pantalla de guardado).
  Future<void> cancelRecording() async {
    await _unsubscribeFromSensors();
    await _debugLogger.stop();
    _activeSegmentStartedAt = null;
    _accumulatedActiveDuration = Duration.zero;
    state = const RouteRecordingState();
  }

  /// Termina la actividad: detiene los sensores, reconstruye cada punto
  /// enriquecido (distancia acumulada, pendiente y FC más reciente
  /// conocida en ese instante) para alimentar los gráficos del detalle,
  /// arma el `ActivitySummary` final, y resetea el estado para la
  /// próxima sesión.
  Future<ActivitySummary> finishRecording({
    required List<HeartRateSample> heartRateSamples,
  }) async {
    await _unsubscribeFromSensors();
    await _debugLogger.stop();

    final elapsed = elapsedDuration();
    final startedAt = state.startedAt ?? DateTime.now();

    // Recalculamos la pendiente con una instancia NUEVA del calculador
    // (la del controller ya consumió toda la sesión y no sirve para
    // reconstruir la curva histórica desde cero) y vamos "casando" cada
    // punto GPS con la última lectura de FC conocida hasta ese momento.
    final slopeCalc = SlopeWindowCalculator();
    double runningDistance = 0;
    int hrIndex = 0;
    int? carriedHr;
    final enrichedPoints = <RoutePointSnapshot>[];

    for (int i = 0; i < state.points.length; i++) {
      final point = state.points[i];

      if (i > 0) {
        final previous = state.points[i - 1];
        runningDistance += Geolocator.distanceBetween(
          previous.latitude,
          previous.longitude,
          point.latitude,
          point.longitude,
        );
      }

      final slope = slopeCalc.addSample(
        cumulativeDistanceMeters: runningDistance,
        altitude: point.altitude,
      );

      while (hrIndex < heartRateSamples.length &&
          !heartRateSamples[hrIndex].timestamp.isAfter(point.timestamp)) {
        carriedHr = heartRateSamples[hrIndex].bpm;
        hrIndex++;
      }

      final pointSpeedKmh = point.speedMetersPerSecond * 3.6;

      enrichedPoints.add(
        RoutePointSnapshot(
          latitude: point.latitude,
          longitude: point.longitude,
          altitude: point.altitude,
          distanceFromStartMeters: runningDistance,
          slopePercent: slope,
          speedKmh: pointSpeedKmh < 0 ? 0 : pointSpeedKmh,
          secondsFromStart: point.timestamp.difference(startedAt).inSeconds,
          heartRateBpm: carriedHr,
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

    final summary = ActivitySummary(
      startedAt: startedAt,
      endedAt: DateTime.now(),
      duration: elapsed,
      distanceMeters: state.cumulativeDistanceMeters,
      avgSpeedKmh: state.averageSpeedKmhOver(elapsed),
      maxSpeedKmh: state.maxSpeedKmh,
      elevationGainMeters: state.elevationGainMeters,
      avgHeartRate: avgHeartRate,
      maxHeartRate: maxHeartRate,
      routePoints: enrichedPoints,
    );

    _activeSegmentStartedAt = null;
    _accumulatedActiveDuration = Duration.zero;
    state = const RouteRecordingState();

    return summary;
  }

  /// TEMPORAL: archivo del log de depuración de la sesión más reciente,
  /// para compartirlo con share_plus desde la UI.
  File? get debugLogFile => _debugLogger.currentFile;

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
      return RouteRecordingController(locationService, barometerService);
    });
