import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/sensors/altitude_fusion_service.dart';
import '../../../core/sensors/barometer_service.dart';
import '../data/location_service.dart';
import '../domain/route_point.dart';

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
/// el panel de datos, incluso cuando no ha llegado un nuevo punto GPS
/// (por ejemplo, si el ciclista está detenido momentáneamente).
final secondTickerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (tick) => tick);
});

/// Frecuencia cardíaca en tiempo real, en latidos por minuto.
///
/// PLACEHOLDER: hoy siempre es `null` porque todavía no existe la
/// integración BLE con la banda de frecuencia cardíaca. Cuando se
/// construya el módulo de sensores, ese módulo va a escribir aquí
/// (vía `ref.read(heartRateBpmProvider.notifier).state = nuevoValor`)
/// y este mismo tile del panel de datos empezará a mostrar el valor
/// real sin necesidad de tocar la UI.
final heartRateBpmProvider = StateProvider<int?>((ref) => null);

/// Estado inmutable de una sesión de grabación de ruta / entrenamiento.
///
/// Incluye tanto los puntos crudos (para dibujar la línea en el mapa)
/// como las métricas ya calculadas de forma incremental (distancia,
/// desnivel, pendiente, velocidad) -- calcularlas de forma incremental
/// evita recorrer toda la lista de puntos en cada frame, lo cual
/// importa para sesiones largas de varias horas.
class RouteRecordingState {
  final bool isRecording;
  final List<RoutePoint> points;
  final DateTime? startedAt;
  final double cumulativeDistanceMeters;
  final double elevationGainMeters;
  final double currentSlopePercent;
  final double currentSpeedKmh;
  final double currentBearingDegrees;

  const RouteRecordingState({
    this.isRecording = false,
    this.points = const [],
    this.startedAt,
    this.cumulativeDistanceMeters = 0,
    this.elevationGainMeters = 0,
    this.currentSlopePercent = 0,
    this.currentSpeedKmh = 0,
    this.currentBearingDegrees = 0,
  });

  RouteRecordingState copyWith({
    bool? isRecording,
    List<RoutePoint>? points,
    DateTime? startedAt,
    double? cumulativeDistanceMeters,
    double? elevationGainMeters,
    double? currentSlopePercent,
    double? currentSpeedKmh,
    double? currentBearingDegrees,
  }) {
    return RouteRecordingState(
      isRecording: isRecording ?? this.isRecording,
      points: points ?? this.points,
      startedAt: startedAt ?? this.startedAt,
      cumulativeDistanceMeters:
          cumulativeDistanceMeters ?? this.cumulativeDistanceMeters,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      currentSlopePercent: currentSlopePercent ?? this.currentSlopePercent,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      currentBearingDegrees:
          currentBearingDegrees ?? this.currentBearingDegrees,
    );
  }

  /// Velocidad promedio de todo el recorrido hasta ahora, en km/h.
  /// Se calcula sobre la marcha a partir de distancia y tiempo totales,
  /// no se guarda como campo propio porque no aporta nada tener dos
  /// fuentes de verdad para el mismo dato derivado.
  double averageSpeedKmh() {
    if (startedAt == null || cumulativeDistanceMeters <= 0) return 0;
    final elapsedSeconds = DateTime.now().difference(startedAt!).inSeconds;
    if (elapsedSeconds <= 0) return 0;
    final km = cumulativeDistanceMeters / 1000;
    final hours = elapsedSeconds / 3600;
    return km / hours;
  }
}

/// Controla el ciclo de vida de grabar una ruta: iniciar, acumular puntos
/// y métricas derivadas a medida que llegan del GPS (fusionadas con el
/// barómetro para altitud), y detener.
class RouteRecordingController extends StateNotifier<RouteRecordingState> {
  final LocationService _locationService;
  final BarometerService _barometerService;
  final AltitudeFusionService _altitudeFusion = AltitudeFusionService();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<double>? _pressureSubscription;

  /// Última presión barométrica conocida. Se actualiza de forma
  /// continua e independiente del GPS, porque el barómetro emite
  /// lecturas con mucha más frecuencia. Cuando llega un nuevo punto
  /// GPS, usamos el valor más reciente que tengamos aquí.
  double? _lastPressureHpa;

  RouteRecordingController(this._locationService, this._barometerService)
    : super(const RouteRecordingState());

  Future<void> startRecording() async {
    if (state.isRecording) return;

    await _locationService.ensureLocationReady();

    _altitudeFusion.reset();
    _lastPressureHpa = null;

    state = RouteRecordingState(isRecording: true, startedAt: DateTime.now());

    // Escuchamos el barómetro de forma continua. Si el dispositivo no
    // tiene sensor de presión, este stream simplemente nunca emite y
    // _lastPressureHpa se queda en null -- AltitudeFusionService ya
    // sabe hacer fallback a GPS puro en ese caso, sin código extra aquí.
    _pressureSubscription = _barometerService.watchPressureHpa().listen(
      (pressure) => _lastPressureHpa = pressure,
      onError: (_) {
        // Dispositivo sin barómetro u otro error de sensor: se ignora,
        // el fallback a GPS puro es automático.
      },
    );

    _positionSubscription = _locationService.watchPosition().listen(
      _onNewPosition,
    );
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
    double slope = state.currentSlopePercent;

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

      // Solo recalculamos la pendiente si hubo un desplazamiento
      // horizontal significativo -- con distancias muy pequeñas incluso
      // la altitud ya fusionada puede producir porcentajes absurdos.
      if (addedDistance > 2) {
        slope = (altitudeDelta / addedDistance) * 100;
      }
    }

    final speedKmh = newPoint.speedMetersPerSecond * 3.6;

    state = state.copyWith(
      points: [...state.points, newPoint],
      cumulativeDistanceMeters: state.cumulativeDistanceMeters + addedDistance,
      elevationGainMeters: state.elevationGainMeters + addedElevationGain,
      currentSlopePercent: slope,
      currentSpeedKmh: speedKmh < 0 ? 0 : speedKmh,
      currentBearingDegrees: newPoint.bearingDegrees,
    );
  }

  Future<void> stopRecording() async {
    await _positionSubscription?.cancel();
    await _pressureSubscription?.cancel();
    _positionSubscription = null;
    _pressureSubscription = null;
    state = state.copyWith(isRecording: false);
    // TODO (siguiente paso): persistir la ruta completa (state.points +
    // métricas agregadas) en Drift, para luego poder definir segmentos
    // sobre ella y consultar el historial de sesiones.
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
      return RouteRecordingController(locationService, barometerService);
    });
