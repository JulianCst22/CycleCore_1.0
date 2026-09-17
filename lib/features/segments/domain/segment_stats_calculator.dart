import 'package:core_geo/core_geo.dart';

/// Un tramo de menos de esto no tiene sentido como segmento --
/// probablemente el usuario apenas movió un marcador sin querer, o el
/// GPX importado quedó recortado a casi nada. Vive acá (capa de
/// dominio) para que la vista previa en vivo (`SegmentCreationScreen`),
/// la importación de GPX (Fase B) y la validación final del
/// repositorio usen el mismo número.
const double kMinSegmentDistanceMeters = 50;

/// Estadísticas derivadas de un perfil de segmento.
class SegmentStatsPreview {
  final double distanceMeters;
  final double elevationGainMeters;
  final double avgSlopePercent;
  final double maxSlopePercent;

  const SegmentStatsPreview({
    required this.distanceMeters,
    required this.elevationGainMeters,
    required this.avgSlopePercent,
    required this.maxSlopePercent,
  });

  static const zero = SegmentStatsPreview(
    distanceMeters: 0,
    elevationGainMeters: 0,
    avgSlopePercent: 0,
    maxSlopePercent: 0,
  );

  bool get isTooShort => distanceMeters < kMinSegmentDistanceMeters;
}

/// Calcula distancia, desnivel y pendiente promedio/máxima de un perfil
/// de segmento (`List<SegmentProfilePoint>`, ya re-basado a distancia 0
/// y con altitud/pendiente pobladas -- ver `segment_profile_builder.dart`).
///
/// Es la ÚNICA implementación de estas 4 stats en el proyecto: la usan
/// la vista previa en vivo de `SegmentCreationScreen`, el guardado real
/// (`SegmentsRepository`) y la importación de GPX (Fase B).
SegmentStatsPreview computeSegmentStats(List<SegmentProfilePoint> points) {
  if (points.length < 2) return SegmentStatsPreview.zero;

  final distanceMeters =
      points.last.distanceFromStartMeters - points.first.distanceFromStartMeters;

  double gain = 0;
  for (int i = 1; i < points.length; i++) {
    final delta = points[i].altitude - points[i - 1].altitude;
    if (delta > 0) gain += delta;
  }

  final slopeValues = points.map((p) => p.slopePercent).toList();
  final avgSlope = slopeValues.reduce((a, b) => a + b) / slopeValues.length;
  final maxSlope = slopeValues.reduce((a, b) => a > b ? a : b);

  return SegmentStatsPreview(
    distanceMeters: distanceMeters,
    elevationGainMeters: gain,
    avgSlopePercent: avgSlope,
    maxSlopePercent: maxSlope,
  );
}
