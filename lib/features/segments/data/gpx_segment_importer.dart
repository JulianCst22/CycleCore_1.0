import 'package:gpx/gpx.dart';

import '../domain/segment_profile.dart';
import '../domain/segment_profile_builder.dart';
import '../domain/segment_stats_calculator.dart';

/// Se lanza cuando un GPX no sirve para volverse segmento. El
/// `message` ya viene en español, listo para un SnackBar.
class GpxImportException implements Exception {
  final String message;
  const GpxImportException(this.message);

  @override
  String toString() => message;
}

/// Resultado de parsear un GPX -- todo lo que necesita
/// `SegmentsRepository.createSegmentFromGpx` para persistir el
/// segmento, más lo que la pantalla de previsualización necesita para
/// mostrarlo antes de guardar.
class GpxImportResult {
  final List<SegmentProfilePoint> profilePoints;
  final SegmentStatsPreview stats;
  final double startBearingDegrees;

  /// Nombre sugerido, tomado de `<trk><name>` o `<metadata><name>` del
  /// GPX. `null` si el archivo no trae ninguno -- la UI cae a un
  /// nombre genérico y deja que el usuario lo edite.
  final String? suggestedName;

  /// Cuántos puntos del track traían altitud (`<ele>`). Si es una
  /// fracción baja del total, la pendiente del segmento no va a ser
  /// fiable y la UI debería avisarlo -- aunque el segmento igual sirve
  /// para posición/distancia.
  final int pointsWithElevation;
  final int totalPoints;

  const GpxImportResult({
    required this.profilePoints,
    required this.stats,
    required this.startBearingDegrees,
    required this.suggestedName,
    required this.pointsWithElevation,
    required this.totalPoints,
  });

  bool get elevationLooksReliable =>
      totalPoints > 0 && pointsWithElevation / totalPoints >= 0.8;
}

/// Convierte el XML de un GPX (típicamente exportado de Garmin Connect,
/// Strava, Wahoo, etc.) en un perfil de segmento congelado.
///
/// Toma los `<trkpt>` de todos los `<trk>/<trkseg>`; si no hay ninguno,
/// cae a los `<rtept>` de las rutas. La altitud (`<ele>`) se usa TAL
/// CUAL: en un GPX de ciclocomputador es barométrica y más fiable que
/// la grilla SRTM (por eso es prioridad 1 sobre HGT). La distancia
/// acumulada y la pendiente se calculan en
/// `profilePointsFromRawTrack`, con el mismo criterio que el resto de
/// la app.
class GpxSegmentImporter {
  const GpxSegmentImporter();

  GpxImportResult parse(String gpxXml) {
    final Gpx gpx;
    try {
      gpx = GpxReader().fromString(gpxXml);
    } catch (e) {
      throw const GpxImportException(
        'No se pudo leer el archivo -- ¿seguro que es un GPX válido?',
      );
    }

    final raw = <({double lat, double lng, double? ele})>[];

    for (final trk in gpx.trks) {
      for (final seg in trk.trksegs) {
        for (final pt in seg.trkpts) {
          if (pt.lat == null || pt.lon == null) continue;
          raw.add((lat: pt.lat!, lng: pt.lon!, ele: pt.ele));
        }
      }
    }

    if (raw.length < 2) {
      for (final rte in gpx.rtes) {
        for (final pt in rte.rtepts) {
          if (pt.lat == null || pt.lon == null) continue;
          raw.add((lat: pt.lat!, lng: pt.lon!, ele: pt.ele));
        }
      }
    }

    if (raw.length < 2) {
      throw const GpxImportException(
        'El GPX no tiene una traza con puntos suficientes.',
      );
    }

    final pointsWithElevation = raw.where((p) => p.ele != null).length;

    // Los puntos sin `<ele>` heredan la última altitud conocida (o 0 si
    // aún no hubo ninguna) -- así la serie no tiene huecos y
    // `profilePointsFromRawTrack` puede suavizar/derivar pendiente.
    double lastEle =
        raw
            .firstWhere(
              (p) => p.ele != null,
              orElse: () => (lat: 0, lng: 0, ele: 0),
            )
            .ele ??
        0;
    final track = raw.map((p) {
      if (p.ele != null) lastEle = p.ele!;
      return (lat: p.lat, lng: p.lng, altitude: lastEle);
    }).toList();

    final profilePoints = profilePointsFromRawTrack(track);
    final stats = computeSegmentStats(profilePoints);

    if (stats.isTooShort) {
      throw GpxImportException(
        'La traza mide ${(stats.distanceMeters).round()} m -- un segmento '
        'debe medir al menos ${kMinSegmentDistanceMeters.round()} m.',
      );
    }

    final suggestedName = _firstNonEmpty([
      gpx.trks.isNotEmpty ? gpx.trks.first.name : null,
      gpx.metadata?.name,
      gpx.rtes.isNotEmpty ? gpx.rtes.first.name : null,
    ]);

    return GpxImportResult(
      profilePoints: profilePoints,
      stats: stats,
      startBearingDegrees: computeStartBearing(profilePoints),
      suggestedName: suggestedName,
      pointsWithElevation: pointsWithElevation,
      totalPoints: raw.length,
    );
  }

  String? _firstNonEmpty(List<String?> candidates) {
    for (final c in candidates) {
      final trimmed = c?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
