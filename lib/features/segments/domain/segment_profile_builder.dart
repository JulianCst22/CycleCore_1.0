import 'package:geolocator/geolocator.dart';

import '../../activities/domain/activity_summary.dart';
import '../../geospatial/domain/slope_window_calculator.dart';
import 'segment_profile.dart';

/// A qué distancia del inicio se toma el punto de referencia para el
/// rumbo de arranque de un segmento (`startBearingDegrees`). Vive acá
/// (y no en `SegmentsRepository`) porque ahora lo necesitan dos
/// orígenes de segmento: el recorte desde una actividad y la
/// importación desde un GPX.
const double kStartBearingReferenceMeters = 25;

/// Construye la lista de `SegmentProfilePoint` (perfil congelado,
/// re-basado a distancia 0 en el inicio) a partir de un tramo de
/// `RoutePointSnapshot` de una actividad YA APLANADA contra HGT (ver
/// `ActivityAltitudeFlattener`).
///
/// Antes esta transformación vivía inline dentro de
/// `SegmentsRepository.createSegmentFromActivity`; se sacó acá para que
/// tanto el guardado real como la vista previa en vivo de
/// `SegmentCreationScreen` produzcan EXACTAMENTE los mismos puntos y,
/// por lo tanto, las mismas stats (ver `computeSegmentStats`).
List<SegmentProfilePoint> profilePointsFromActivitySlice(
  List<RoutePointSnapshot> slice,
) {
  if (slice.isEmpty) return const [];
  final baseDistance = slice.first.distanceFromStartMeters;
  return slice
      .map(
        (point) => SegmentProfilePoint(
          distanceFromStartMeters:
              point.distanceFromStartMeters - baseDistance,
          latitude: point.latitude,
          longitude: point.longitude,
          altitude: point.altitude,
          slopePercent: point.slopePercent,
        ),
      )
      .toList();
}

/// Construye el perfil congelado a partir de una traza cruda de
/// `(lat, lng, altitude)` -- el caso de un GPX importado, donde no hay
/// distancia acumulada ni pendiente pre-calculadas.
///
/// - La distancia acumulada se arma con `Geolocator.distanceBetween`
///   (haversine), igual criterio que el resto de la app.
/// - La pendiente se calcula con el MISMO `SlopeWindowCalculator` que
///   usa `ActivityAltitudeFlattener` post-actividad, para que un
///   segmento importado de GPX y uno recortado de una actividad se
///   "sientan" iguales.
/// - La altitud del GPX se usa TAL CUAL (es barométrica de un
///   ciclocomputador, más fiable que la grilla SRTM) -- solo se
///   suaviza levemente si [smoothingRadius] > 0.
List<SegmentProfilePoint> profilePointsFromRawTrack(
  List<({double lat, double lng, double altitude})> track, {
  double slopeWindowMeters = 40,
  int smoothingRadius = 1,
}) {
  if (track.length < 2) return const [];

  // --- Distancia acumulada ---
  final cumulative = <double>[0];
  for (int i = 1; i < track.length; i++) {
    final d = Geolocator.distanceBetween(
      track[i - 1].lat,
      track[i - 1].lng,
      track[i].lat,
      track[i].lng,
    );
    cumulative.add(cumulative.last + d);
  }

  // --- Suavizado corto de altitud (promedio móvil centrado) ---
  final altitudes = track.map((p) => p.altitude).toList();
  final smoothed = smoothingRadius <= 0
      ? altitudes
      : _movingAverage(altitudes, smoothingRadius);

  // --- Pendiente por regresión de ventana ---
  final slopeCalculator = SlopeWindowCalculator(windowMeters: slopeWindowMeters);
  final result = <SegmentProfilePoint>[];
  for (int i = 0; i < track.length; i++) {
    final slope = slopeCalculator.addSample(
      cumulativeDistanceMeters: cumulative[i],
      altitude: smoothed[i],
    );
    result.add(
      SegmentProfilePoint(
        distanceFromStartMeters: cumulative[i],
        latitude: track[i].lat,
        longitude: track[i].lng,
        altitude: smoothed[i],
        slopePercent: slope,
      ),
    );
  }
  return result;
}

/// Rumbo (0-360) desde el primer punto del perfil hasta el punto más
/// cercano a [kStartBearingReferenceMeters] del inicio -- para que la
/// detección en vivo (Fase C) pueda exigir que el ciclista vaya en el
/// sentido correcto del segmento.
double computeStartBearing(List<SegmentProfilePoint> profilePoints) {
  if (profilePoints.length < 2) return 0;
  final reference = profilePoints.firstWhere(
    (p) => p.distanceFromStartMeters >= kStartBearingReferenceMeters,
    orElse: () => profilePoints.last,
  );
  final raw = Geolocator.bearingBetween(
    profilePoints.first.latitude,
    profilePoints.first.longitude,
    reference.latitude,
    reference.longitude,
  );
  return (raw + 360) % 360;
}

List<double> _movingAverage(List<double> values, int radius) {
  if (radius <= 0 || values.length < 3) return List.of(values);
  final out = <double>[];
  for (int i = 0; i < values.length; i++) {
    final start = (i - radius).clamp(0, values.length - 1);
    final end = (i + radius).clamp(0, values.length - 1);
    double sum = 0;
    int count = 0;
    for (int j = start; j <= end; j++) {
      sum += values[j];
      count++;
    }
    out.add(sum / count);
  }
  return out;
}
