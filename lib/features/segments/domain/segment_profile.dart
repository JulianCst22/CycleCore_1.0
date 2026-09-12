import 'dart:convert';

import 'package:cyclecore_core/database/app_database.dart';

/// Un punto del perfil congelado de un segmento -- ya recortado y
/// re-basado a distancia 0 en el inicio del tramo. Viene de un
/// `RoutePointSnapshot` de una actividad que ya pasó por
/// `ActivityAltitudeFlattener` (Fase 1), así que su altitud y
/// pendiente ya son las "aplanadas" contra HGT, no las fusionadas en
/// vivo con GPS/barómetro.
class SegmentProfilePoint {
  final double distanceFromStartMeters;
  final double latitude;
  final double longitude;
  final double altitude;
  final double slopePercent;

  const SegmentProfilePoint({
    required this.distanceFromStartMeters,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.slopePercent,
  });

  Map<String, dynamic> toJson() => {
        'dist': distanceFromStartMeters,
        'lat': latitude,
        'lng': longitude,
        'alt': altitude,
        'slope': slopePercent,
      };

  factory SegmentProfilePoint.fromJson(Map<String, dynamic> json) {
    return SegmentProfilePoint(
      distanceFromStartMeters: (json['dist'] as num).toDouble(),
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      altitude: (json['alt'] as num).toDouble(),
      slopePercent: (json['slope'] as num).toDouble(),
    );
  }
}

/// Los dos puntos del perfil que "envuelven" una distancia dada, más
/// qué tan lejos está esa distancia entre ambos (0.0 = justo en
/// [before], 1.0 = justo en [after]) -- resultado interno de
/// [SegmentProfile._bracketFor], usado para interpolar altitud y
/// pendiente.
class _ProfileBracket {
  final SegmentProfilePoint before;
  final SegmentProfilePoint after;
  final double t;

  const _ProfileBracket(this.before, this.after, this.t);
}

/// Perfil completo y congelado de un segmento -- lo que
/// `SegmentDetectionService` (Fase 5) consulta por "lookup" mientras
/// el segmento está activo, en vez de recalcular pendiente con
/// sensores en vivo. Es la pieza que reemplaza a
/// `SlopeWindowCalculator`/`SlopePlausibilityFilter` dentro de un
/// segmento: la pendiente ya se conoce de antemano.
///
/// Los puntos deben venir ordenados por `distanceFromStartMeters`
/// ascendente -- así se construyen siempre en
/// `SegmentsRepository.createSegmentFromActivity`.
class SegmentProfile {
  final List<SegmentProfilePoint> points;

  const SegmentProfile(this.points);

  double get totalDistanceMeters =>
      points.isEmpty ? 0 : points.last.distanceFromStartMeters;

  /// Serializa la lista de puntos a JSON -- esto es lo que se guarda
  /// en `Segments.profileJson`.
  static String encode(List<SegmentProfilePoint> points) {
    return jsonEncode(points.map((p) => p.toJson()).toList());
  }

  /// Reconstruye el perfil desde el JSON guardado en
  /// `Segments.profileJson`.
  factory SegmentProfile.decode(String json) {
    final decoded = jsonDecode(json) as List<dynamic>;
    return SegmentProfile(
      decoded
          .map(
            (e) => SegmentProfilePoint.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Altitud interpolada en [distanceMeters] desde el inicio del
  /// segmento. `null` solo si el perfil no tiene ningún punto (no
  /// debería pasar en un segmento persistido correctamente).
  double? altitudeAtDistance(double distanceMeters) {
    final bracket = _bracketFor(distanceMeters);
    if (bracket == null) return null;
    return bracket.before.altitude +
        (bracket.after.altitude - bracket.before.altitude) * bracket.t;
  }

  /// Pendiente interpolada en [distanceMeters] desde el inicio del
  /// segmento.
  double? slopePercentAtDistance(double distanceMeters) {
    final bracket = _bracketFor(distanceMeters);
    if (bracket == null) return null;
    return bracket.before.slopePercent +
        (bracket.after.slopePercent - bracket.before.slopePercent) *
            bracket.t;
  }

  /// Coordenada interpolada en [distanceMeters] desde el inicio -- para
  /// dibujar el marcador "estás aquí" sobre la polilínea del segmento
  /// (pantalla de segmento en vivo, Fase D). `null` si el perfil está
  /// vacío.
  ({double lat, double lng})? positionAtDistance(double distanceMeters) {
    final bracket = _bracketFor(distanceMeters);
    if (bracket == null) return null;
    return (
      lat: bracket.before.latitude +
          (bracket.after.latitude - bracket.before.latitude) * bracket.t,
      lng: bracket.before.longitude +
          (bracket.after.longitude - bracket.before.longitude) * bracket.t,
    );
  }

  /// Desnivel POSITIVO acumulado del perfil congelado entre las
  /// distancias [fromMeters] y [toMeters]. Para "cuánto me falta subir"
  /// se llama con `(alongMeters, totalDistanceMeters)`.
  double elevationGainBetween(double fromMeters, double toMeters) {
    if (points.length < 2) return 0;
    final lo = fromMeters < toMeters ? fromMeters : toMeters;
    final hi = fromMeters < toMeters ? toMeters : fromMeters;

    double? prevAlt = altitudeAtDistance(lo);
    double gain = 0;
    for (final p in points) {
      if (p.distanceFromStartMeters <= lo) continue;
      if (p.distanceFromStartMeters >= hi) break;
      if (prevAlt != null) {
        final delta = p.altitude - prevAlt;
        if (delta > 0) gain += delta;
      }
      prevAlt = p.altitude;
    }
    final endAlt = altitudeAtDistance(hi);
    if (prevAlt != null && endAlt != null && endAlt - prevAlt > 0) {
      gain += endAlt - prevAlt;
    }
    return gain;
  }

  /// Fracción de avance dentro del segmento (0.0 = inicio, 1.0 =
  /// fin), para la pregunta típica "¿cuánto llevo, cuánto falta?".
  /// Se satura a [0, 1] -- si el ciclista se desvía y queda "antes"
  /// del inicio o "después" del fin del tramo congelado, no se
  /// extrapola.
  double progressFraction(double distanceMeters) {
    if (totalDistanceMeters <= 0) return 0;
    return (distanceMeters / totalDistanceMeters).clamp(0.0, 1.0);
  }

  _ProfileBracket? _bracketFor(double distanceMeters) {
    if (points.isEmpty) return null;
    if (points.length == 1) {
      return _ProfileBracket(points.first, points.first, 0);
    }

    if (distanceMeters <= points.first.distanceFromStartMeters) {
      return _ProfileBracket(points.first, points.first, 0);
    }
    if (distanceMeters >= points.last.distanceFromStartMeters) {
      return _ProfileBracket(points.last, points.last, 0);
    }

    for (int i = 0; i < points.length - 1; i++) {
      final before = points[i];
      final after = points[i + 1];
      if (distanceMeters >= before.distanceFromStartMeters &&
          distanceMeters <= after.distanceFromStartMeters) {
        final span =
            after.distanceFromStartMeters - before.distanceFromStartMeters;
        final t = span <= 0
            ? 0.0
            : (distanceMeters - before.distanceFromStartMeters) / span;
        return _ProfileBracket(before, after, t);
      }
    }
    return _ProfileBracket(points.last, points.last, 0);
  }
}

/// Acceso perezoso al perfil parseado de un segmento persistido --
/// mismo patrón que ya usa el proyecto en `activity_json_helpers.dart`
/// para `Activity.routePoints`. Evita decodificar el JSON a mano en
/// cada pantalla que necesite el perfil.
extension SegmentProfileAccess on Segment {
  SegmentProfile get profile => SegmentProfile.decode(profileJson);
}
