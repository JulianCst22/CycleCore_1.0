import 'dart:math' as math;

import 'navigation_route.dart';

/// Dónde va el ciclista sobre la ruta sugerida: la proyección de su
/// posición GPS sobre la polilínea.
class RouteProgress {
  /// Metros recorridos sobre la ruta hasta la proyección.
  final double alongMeters;

  /// Distancia entre la posición real y la ruta (perpendicular al tramo
  /// más cercano).
  final double offRouteMeters;

  /// Tramo `[segmentIndex, segmentIndex + 1]` de la polilínea donde cae
  /// la proyección: lo que va antes ya se recorrió.
  final int segmentIndex;

  /// Punto de la ruta donde cae la proyección.
  final double lat;
  final double lng;

  const RouteProgress({
    required this.alongMeters,
    required this.offRouteMeters,
    required this.segmentIndex,
    required this.lat,
    required this.lng,
  });
}

/// Sigue el avance sobre una [NavigationRoute], fix a fix.
///
/// La proyección se busca primero cerca de donde iba (una ventana que
/// empieza un poco atrás y llega unos kilómetros adelante): en una ruta
/// de ida y vuelta por la misma vía, buscar en toda la polilínea podría
/// saltar al tramo de regreso. Solo si en la ventana queda lejos se mira
/// la ruta completa (p. ej. el GPS se perdió un rato o se tomó un atajo
/// que vuelve a caer en la ruta más adelante).
class RouteProgressTracker {
  RouteProgressTracker(this.route) : _cumulative = _cumulativeDistances(route);

  final NavigationRoute route;
  final List<double> _cumulative;
  RouteProgress? _last;

  /// Cuánto se mira hacia atrás y hacia adelante de la última
  /// proyección.
  static const double _windowBackMeters = 100;
  static const double _windowAheadMeters = 3000;

  /// Si en la ventana la ruta queda a más de esto, se busca en toda.
  static const double _globalSearchFromMeters = 60;

  double get totalMeters => _cumulative.isEmpty ? 0 : _cumulative.last;

  /// Distancia sobre la ruta del punto [index] de la polilínea.
  double alongAt(int index) => _cumulative[index];

  RouteProgress? get last => _last;

  /// Proyecta ([lat], [lng]) sobre la ruta. `null` si la ruta no tiene
  /// al menos dos puntos.
  RouteProgress? locate(double lat, double lng) {
    final n = route.polyline.length;
    if (n < 2) return null;

    final previous = _last;
    RouteProgress? best;
    if (previous != null) {
      final from = previous.alongMeters - _windowBackMeters;
      final to = previous.alongMeters + _windowAheadMeters;
      best = _nearest(lat, lng, (i) {
        return _cumulative[i + 1] >= from && _cumulative[i] <= to;
      });
    }
    if (best == null || best.offRouteMeters > _globalSearchFromMeters) {
      final global = _nearest(lat, lng, (_) => true);
      // El salto a otra parte de la ruta solo se acepta si allá de
      // verdad se está mucho más cerca.
      if (global != null &&
          (best == null || global.offRouteMeters < best.offRouteMeters - 30)) {
        best = global;
      }
    }
    _last = best;
    return best;
  }

  RouteProgress? _nearest(
    double lat,
    double lng,
    bool Function(int segment) include,
  ) {
    final pts = route.polyline;
    final cosLat = math.cos(lat * math.pi / 180);
    RouteProgress? best;
    for (var i = 0; i < pts.length - 1; i++) {
      if (!include(i)) continue;
      // Plano local en metros alrededor de la posición: a escala de un
      // tramo de vía el error es despreciable.
      final ax = (pts[i].lng - lng) * cosLat * _metersPerDegree;
      final ay = (pts[i].lat - lat) * _metersPerDegree;
      final bx = (pts[i + 1].lng - lng) * cosLat * _metersPerDegree;
      final by = (pts[i + 1].lat - lat) * _metersPerDegree;
      final dx = bx - ax;
      final dy = by - ay;
      final len2 = dx * dx + dy * dy;
      final t = len2 == 0 ? 0.0 : ((-ax * dx - ay * dy) / len2).clamp(0.0, 1.0);
      final px = ax + t * dx;
      final py = ay + t * dy;
      final dist = math.sqrt(px * px + py * py);
      if (best == null || dist < best.offRouteMeters) {
        final segLen = _cumulative[i + 1] - _cumulative[i];
        best = RouteProgress(
          alongMeters: _cumulative[i] + t * segLen,
          offRouteMeters: dist,
          segmentIndex: i,
          lat: pts[i].lat + t * (pts[i + 1].lat - pts[i].lat),
          lng: pts[i].lng + t * (pts[i + 1].lng - pts[i].lng),
        );
      }
    }
    return best;
  }

  static const double _metersPerDegree = 111320;

  static List<double> _cumulativeDistances(NavigationRoute route) {
    final pts = route.polyline;
    final out = <double>[if (pts.isNotEmpty) 0];
    for (var i = 1; i < pts.length; i++) {
      out.add(
        out[i - 1] +
            haversineMeters(
              pts[i - 1].lat,
              pts[i - 1].lng,
              pts[i].lat,
              pts[i].lng,
            ),
      );
    }
    return out;
  }
}

/// Distancia en metros entre dos coordenadas (haversine).
double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final p1 = lat1 * math.pi / 180;
  final p2 = lat2 * math.pi / 180;
  final dp = p2 - p1;
  final dl = (lng2 - lng1) * math.pi / 180;
  final a =
      math.sin(dp / 2) * math.sin(dp / 2) +
      math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(a)));
}

/// Qué hacer con un fix según qué tan lejos quedó de la ruta: decide
/// cuándo el ciclista se salió de verdad (y hay que recalcular) sin
/// reaccionar a un salto suelto del GPS.
///
/// Mientras no ha llegado a la ruta (arrancó a unos metros de la vía, o
/// la ruta nueva empieza en el nodo más cercano), no se exige estar
/// encima: solo se recalcula si se va alejando claramente.
class OffRouteDetector {
  OffRouteDetector({
    this.minThresholdMeters = 35,
    this.maxThresholdMeters = 80,
    this.confirmFixes = 3,
    this.confirmAfter = const Duration(seconds: 5),
    this.approachSlackMeters = 150,
  });

  final double minThresholdMeters;
  final double maxThresholdMeters;

  /// Fixes seguidos fuera de la ruta, y tiempo mínimo, para darlo por
  /// salido.
  final int confirmFixes;
  final Duration confirmAfter;

  /// Antes de llegar a la ruta: cuánto más lejos que al comienzo tiene
  /// que estar para recalcular.
  final double approachSlackMeters;

  bool _joined = false;
  double? _startOffMeters;
  int _offFixes = 0;
  DateTime? _offSince;

  /// Ya estuvo sobre la ruta al menos una vez.
  bool get joined => _joined;

  /// Va por fuera de la ruta (aunque todavía no se haya confirmado).
  bool get isOff => _offFixes > 0;

  /// Umbral para un fix con la precisión dada: con mala señal el punto
  /// "baila" más, así que se tolera más.
  double thresholdFor(double? accuracyMeters) => ((accuracyMeters ?? 10) * 2)
      .clamp(minThresholdMeters, maxThresholdMeters);

  /// `true` si con este fix ya hay que recalcular la ruta.
  bool update(double offRouteMeters, double? accuracyMeters, DateTime at) {
    final threshold = thresholdFor(accuracyMeters);
    _startOffMeters ??= offRouteMeters;

    final bool off;
    if (offRouteMeters <= threshold) {
      _joined = true;
      off = false;
    } else if (_joined) {
      off = true;
    } else {
      off = offRouteMeters > _startOffMeters! + approachSlackMeters;
    }

    if (!off) {
      _offFixes = 0;
      _offSince = null;
      return false;
    }
    _offFixes++;
    _offSince ??= at;
    return _offFixes >= confirmFixes &&
        at.difference(_offSince!) >= confirmAfter;
  }
}
