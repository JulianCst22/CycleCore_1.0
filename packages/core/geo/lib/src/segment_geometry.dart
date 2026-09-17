import 'dart:math' as math;

import 'segment_profile.dart';

/// Resultado de proyectar una posición sobre la polilínea congelada de
/// un segmento.
class ProfileProjection {
  /// Distancia acumulada (m) desde el inicio del segmento hasta el
  /// punto proyectado -- "cuánto llevas".
  final double alongMeters;

  /// Distancia perpendicular (m) entre la posición real y la
  /// polilínea -- "qué tan lejos del trazado vas". Se usa para
  /// entrar/abandonar un segmento.
  final double offsetMeters;

  const ProfileProjection({
    required this.alongMeters,
    required this.offsetMeters,
  });
}

/// Proyecta `(lat, lng)` sobre la polilínea de [points] (que debe venir
/// ordenada por `distanceFromStartMeters`). Recorre cada tramo, hace la
/// proyección punto-a-segmento en un plano local (equirectangular
/// alrededor del primer vértice de cada tramo -- válido porque los
/// tramos son de pocos metros) y se queda con el de menor offset.
ProfileProjection projectOntoProfile(
  List<SegmentProfilePoint> points,
  double lat,
  double lng,
) {
  if (points.length < 2) {
    return const ProfileProjection(alongMeters: 0, offsetMeters: 0);
  }

  double bestOffset = double.infinity;
  double bestAlong = 0;

  for (int i = 0; i < points.length - 1; i++) {
    final a = points[i];
    final b = points[i + 1];

    final mPerDegLat = 111320.0;
    final mPerDegLng = 111320.0 * math.cos(a.latitude * math.pi / 180);

    final bx = (b.longitude - a.longitude) * mPerDegLng;
    final by = (b.latitude - a.latitude) * mPerDegLat;
    final px = (lng - a.longitude) * mPerDegLng;
    final py = (lat - a.latitude) * mPerDegLat;

    final segLen2 = bx * bx + by * by;
    final t = segLen2 == 0
        ? 0.0
        : ((px * bx + py * by) / segLen2).clamp(0.0, 1.0);

    final dx = px - bx * t;
    final dy = py - by * t;
    final offset = math.sqrt(dx * dx + dy * dy);

    if (offset < bestOffset) {
      bestOffset = offset;
      bestAlong = a.distanceFromStartMeters +
          t *
              (b.distanceFromStartMeters - a.distanceFromStartMeters);
    }
  }

  return ProfileProjection(alongMeters: bestAlong, offsetMeters: bestOffset);
}

/// Diferencia mínima entre dos rumbos (grados), siempre en `[0, 180]`.
/// Ej: `bearingDelta(350, 10) == 20`.
double bearingDelta(double a, double b) {
  var d = (a - b).abs() % 360;
  if (d > 180) d = 360 - d;
  return d;
}

/// Metros entre dos coordenadas (haversine). Se define acá para que la
/// capa de dominio de segmentos no dependa de `geolocator` -- el
/// `SegmentDetector` tiene que ser Dart puro y testeable con
/// coordenadas fabricadas.
double haversineMeters(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const earthRadius = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Rumbo (0-360) desde `(lat1,lng1)` hacia `(lat2,lng2)`.
double bearingBetween(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  final dLng = (lng2 - lng1) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2 * math.pi / 180);
  final x = math.cos(lat1 * math.pi / 180) * math.sin(lat2 * math.pi / 180) -
      math.sin(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}
