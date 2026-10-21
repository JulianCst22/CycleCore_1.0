import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/navigation_route.dart';
import '../domain/route_progress.dart';

/// Lo que la pantalla necesita saber del avance sobre la ruta activa.
class NavigationProgressState {
  /// Proyección del último fix sobre la ruta. `null` hasta el primero.
  final RouteProgress? progress;

  /// Ya estuvo sobre la ruta (antes de eso, la distancia al primer giro
  /// se mide en línea recta).
  final bool joined;

  /// El último fix quedó por fuera de la ruta.
  final bool offRoute;

  const NavigationProgressState({
    this.progress,
    this.joined = false,
    this.offRoute = false,
  });

  /// Metros que faltan, POR LA RUTA, hasta [instruction]. `null` si
  /// todavía no se sabe dónde va (o no ha llegado a la ruta).
  double? metersTo(RouteInstruction instruction) {
    final p = progress;
    if (p == null || !joined) return null;
    final left = instruction.distanceFromStartMeters - p.alongMeters;
    return left < 0 ? 0 : left;
  }
}

/// Avance fix a fix sobre UNA ruta: recorta lo recorrido, avanza las
/// instrucciones por la distancia sobre la ruta (no en línea recta, que
/// en una curva cerrada se adelantaba), avisa la llegada y pide el
/// recálculo cuando el ciclista toma otro camino.
///
/// No sabe de GPS ni de ruteo: recibe cada fix y avisa por los
/// callbacks, así se prueba sin teléfono.
class NavigationProgressNotifier
    extends StateNotifier<NavigationProgressState> {
  NavigationProgressNotifier(
    this.route, {
    required this.onInstructionIndex,
    required this.onReroute,
    required this.onArrive,
    OffRouteDetector? detector,
  }) : _tracker = route == null ? null : RouteProgressTracker(route),
       _detector = detector ?? OffRouteDetector(),
       super(const NavigationProgressState());

  final NavigationRoute? route;
  final void Function(int index) onInstructionIndex;
  final void Function(double lat, double lng) onReroute;
  final void Function() onArrive;

  final RouteProgressTracker? _tracker;
  final OffRouteDetector _detector;
  int _index = 0;
  bool _arrived = false;

  /// Una instrucción se da por cumplida cuando ya se va pasando su punto
  /// (unos metros, por el error del GPS en la proyección).
  static const double passMarginMeters = 10;

  /// A esta distancia del final, sobre la ruta, ya se llegó.
  static const double arrivalMeters = 25;

  void onPosition(double lat, double lng, double? accuracy, DateTime at) {
    final tracker = _tracker;
    final route = this.route;
    if (tracker == null || route == null || _arrived || !mounted) return;

    final p = tracker.locate(lat, lng);
    if (p == null) return;
    final mustReroute = _detector.update(p.offRouteMeters, accuracy, at);
    state = NavigationProgressState(
      progress: p,
      joined: _detector.joined,
      offRoute: _detector.isOff,
    );

    if (_detector.joined && !_detector.isOff) {
      if (tracker.totalMeters - p.alongMeters <= arrivalMeters) {
        _arrived = true;
        onArrive();
        return;
      }
      final next = _nextIndex(route.instructions, p.alongMeters);
      // Solo hacia adelante: un salto del GPS hacia atrás no debe
      // repetir un giro que ya se anunció.
      if (next > _index) {
        _index = next;
        onInstructionIndex(next);
      }
    }

    if (mustReroute) onReroute(lat, lng);
  }

  static int _nextIndex(List<RouteInstruction> instructions, double along) {
    for (var i = 1; i < instructions.length; i++) {
      if (instructions[i].distanceFromStartMeters > along + passMarginMeters) {
        return i;
      }
    }
    return instructions.length - 1;
  }
}

/// En qué va el recálculo automático de la ruta.
class RerouteState {
  /// Se está calculando la ruta nueva.
  final bool busy;

  /// Por qué no se pudo la última vez (p. ej. fuera del mapa
  /// descargado). Se borra cuando vuelve a la ruta o se recalcula bien.
  final String? problem;

  const RerouteState({this.busy = false, this.problem});

  static const idle = RerouteState();
}
