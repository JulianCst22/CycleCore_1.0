import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/location_service.dart';
import '../domain/route_point.dart';

/// Instancia única del servicio de ubicación, compartida por toda la app.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Posición actual del dispositivo, obtenida una sola vez.
/// Se usa para centrar el mapa la primera vez que se abre la pantalla.
final currentPositionProvider = FutureProvider<Position>((ref) async {
  final service = ref.read(locationServiceProvider);
  return service.getCurrentPosition();
});

/// Estado inmutable de una sesión de grabación de ruta.
class RouteRecordingState {
  final bool isRecording;
  final List<RoutePoint> points;

  const RouteRecordingState({
    this.isRecording = false,
    this.points = const [],
  });

  RouteRecordingState copyWith({
    bool? isRecording,
    List<RoutePoint>? points,
  }) {
    return RouteRecordingState(
      isRecording: isRecording ?? this.isRecording,
      points: points ?? this.points,
    );
  }
}

/// Controla el ciclo de vida de grabar una ruta: iniciar, acumular puntos
/// a medida que llegan del GPS, y detener.
///
/// Esta es la pieza que más adelante vamos a extender para, al detener
/// la grabación, guardar la ruta completa en Drift (persistencia local)
/// y habilitar que el usuario defina segmentos (punto A -> punto B) sobre
/// ella.
class RouteRecordingController extends StateNotifier<RouteRecordingState> {
  final LocationService _locationService;
  StreamSubscription<Position>? _positionSubscription;

  RouteRecordingController(this._locationService)
      : super(const RouteRecordingState());

  Future<void> startRecording() async {
    if (state.isRecording) return;

    await _locationService.ensureLocationReady();

    state = state.copyWith(isRecording: true, points: []);

    _positionSubscription = _locationService.watchPosition().listen(
      (position) {
        final newPoint = RoutePoint(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(points: [...state.points, newPoint]);
      },
    );
  }

  Future<void> stopRecording() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    state = state.copyWith(isRecording: false);
    // TODO (siguiente paso): persistir state.points en Drift como una
    // ruta completa, para luego poder definir segmentos sobre ella.
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final routeRecordingProvider =
    StateNotifierProvider<RouteRecordingController, RouteRecordingState>(
  (ref) {
    final service = ref.read(locationServiceProvider);
    return RouteRecordingController(service);
  },
);
