import 'package:gpx/gpx.dart';

import '../domain/ride_track.dart';

/// Una salida leída de un GPX.
class GpxRide {
  final String? name;
  final List<RideTrackPoint> points;

  const GpxRide({required this.name, required this.points});

  DateTime? get date => points.isEmpty ? null : points.first.time;
}

/// El GPX no se pudo leer o no trae una traza.
class GpxRideException implements Exception {
  final String message;
  const GpxRideException(this.message);

  @override
  String toString() => message;
}

/// Lee una salida completa de un GPX (Garmin, Wahoo, la app de Strava...):
/// posición, altitud, hora y, si las trae en sus extensiones, pulso y
/// potencia.
class GpxRideReader {
  const GpxRideReader();

  GpxRide read(String xml) {
    final Gpx gpx;
    try {
      gpx = GpxReader().fromString(xml.trimLeft());
    } catch (_) {
      throw const GpxRideException(
        'No se pudo leer el archivo. ¿Seguro que es un GPX?',
      );
    }

    final points = <RideTrackPoint>[];
    void add(Wpt pt) {
      final lat = pt.lat;
      final lon = pt.lon;
      if (lat == null || lon == null) return;
      points.add(
        RideTrackPoint(
          latitude: lat,
          longitude: lon,
          altitude: pt.ele,
          time: pt.time?.toUtc(),
          heartRate: _int(_extension(pt.extensions, const ['hr', 'heartrate'])),
          power: _int(_extension(pt.extensions, const ['power', 'watts'])),
        ),
      );
    }

    for (final trk in gpx.trks) {
      for (final seg in trk.trksegs) {
        seg.trkpts.forEach(add);
      }
    }
    if (points.length < 2) {
      for (final rte in gpx.rtes) {
        rte.rtepts.forEach(add);
      }
    }
    if (points.length < 2) {
      throw const GpxRideException('El GPX no trae una traza con puntos.');
    }

    String? name;
    for (final candidate in [
      gpx.trks.isNotEmpty ? gpx.trks.first.name : null,
      gpx.metadata?.name,
    ]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        name = candidate.trim();
        break;
      }
    }
    return GpxRide(name: name, points: points);
  }

  /// Busca un valor en las extensiones del punto, que llegan como mapas
  /// anidados con el prefijo de cada aparato (`gpxtpx:hr`, `ns3:hr`,
  /// `power`...): se compara solo el nombre después de los dos puntos.
  static String? _extension(Map<String, Object> ext, List<String> names) {
    for (final entry in ext.entries) {
      final key = entry.key.split(':').last.toLowerCase();
      final value = entry.value;
      if (names.contains(key) && value is String) return value;
      if (value is Map<String, Object>) {
        final nested = _extension(value, names);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  static int? _int(String? s) =>
      s == null ? null : double.tryParse(s.trim())?.round();
}
