import 'dart:math' as math;

import '../../../core/geo/geo.dart';

/// Un punto de una salida: de un GPX (Garmin u otro aparato) o de una
/// actividad grabada con la app.
class RideTrackPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final DateTime? time;
  final int? heartRate;
  final int? power;

  const RideTrackPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.time,
    this.heartRate,
    this.power,
  });
}

/// Las cifras de un tramo de la salida.
class SectionStats {
  final double distanceMeters;
  final double elevationGainMeters;

  /// Pendiente media neta: (altitud final - inicial) / distancia.
  final double avgGradePercent;

  /// La pendiente más dura sostenida 100 m dentro del tramo.
  final double maxGradePercent;

  /// Cuánto tardó el ciclista en este tramo, si la salida trae horas.
  final Duration? duration;

  const SectionStats({
    required this.distanceMeters,
    required this.elevationGainMeters,
    required this.avgGradePercent,
    required this.maxGradePercent,
    this.duration,
  });
}

/// Un pedazo del tramo con su pendiente, para leerlo "tramo por tramo".
class SlopeChunk {
  final int startIndex;
  final int endIndex;
  final double startMeters;
  final double endMeters;
  final double gradePercent;

  const SlopeChunk({
    required this.startIndex,
    required this.endIndex,
    required this.startMeters,
    required this.endMeters,
    required this.gradePercent,
  });
}

/// Una salida completa lista para analizar: distancia acumulada y
/// altitud limpia por punto, y las cifras de cualquier tramo.
class RideTrack {
  final List<RideTrackPoint> points;

  /// Metros desde el inicio de la salida, por punto.
  final List<double> distances;

  /// Altitud por punto, sin huecos y apenas suavizada (el ruido del
  /// GPS/barómetro inflaría el desnivel y las pendientes).
  final List<double> altitudes;

  final bool hasAltitude;
  final bool hasTime;

  RideTrack._(
    this.points,
    this.distances,
    this.altitudes,
    this.hasAltitude,
    this.hasTime,
  );

  /// Arma la traza. Las distancias se calculan entre puntos salvo que
  /// vengan dadas (una actividad de la app ya las trae, y conviene usar
  /// las mismas con las que se va a guardar el segmento).
  factory RideTrack(List<RideTrackPoint> points, {List<double>? distances}) {
    final n = points.length;
    final dist = distances ?? List<double>.filled(n, 0);
    if (distances == null) {
      for (var i = 1; i < n; i++) {
        dist[i] =
            dist[i - 1] +
            haversineMeters(
              points[i - 1].latitude,
              points[i - 1].longitude,
              points[i].latitude,
              points[i].longitude,
            );
      }
    }

    final hasAltitude = points.any((p) => p.altitude != null);
    final raw = List<double>.filled(n, 0);
    double? last;
    for (final p in points) {
      if (p.altitude != null) {
        last = p.altitude;
        break;
      }
    }
    for (var i = 0; i < n; i++) {
      last = points[i].altitude ?? last;
      raw[i] = last ?? 0;
    }

    return RideTrack._(
      points,
      dist,
      _smoothByDistance(raw, dist, 30),
      hasAltitude,
      n > 1 && points.first.time != null && points.last.time != null,
    );
  }

  int get length => points.length;
  double get totalDistance => distances.isEmpty ? 0 : distances.last;

  /// El punto más cercano a [meters] desde el inicio (búsqueda binaria).
  int indexAtDistance(double meters) {
    if (points.isEmpty) return 0;
    var lo = 0;
    var hi = distances.length - 1;
    if (meters <= distances[lo]) return lo;
    if (meters >= distances[hi]) return hi;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (distances[mid] < meters) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (meters - distances[lo]) <= (distances[hi] - meters) ? lo : hi;
  }

  /// Pendiente local en [index] (sobre unos 60 m alrededor).
  double gradeAt(int index) {
    final d = distances[index];
    final a = indexAtDistance(d - 30);
    final b = indexAtDistance(d + 30);
    final span = distances[b] - distances[a];
    if (span < 10) return 0;
    return (altitudes[b] - altitudes[a]) / span * 100;
  }

  /// Las cifras del tramo entre [from] y [to] (índices, inclusive).
  SectionStats statsBetween(int from, int to) {
    final a = math.min(from, to);
    final b = math.max(from, to);
    final distance = distances[b] - distances[a];
    final gain = computeGainLoss(
      altitudes.sublist(a, b + 1),
      minChangeMeters: 2,
    ).gainMeters;
    final avg = distance > 0
        ? (altitudes[b] - altitudes[a]) / distance * 100
        : 0.0;

    // Pendiente máxima sostenida 100 m (o el tramo entero si es más
    // corto): dos punteros sobre la distancia acumulada.
    final window = math.min(100.0, distance);
    var maxGrade = avg;
    var j = a;
    for (var i = a; i <= b && window > 0; i++) {
      while (j < b && distances[j] - distances[i] < window) {
        j++;
      }
      final span = distances[j] - distances[i];
      if (span < window * 0.9) break;
      final g = (altitudes[j] - altitudes[i]) / span * 100;
      if (g > maxGrade) maxGrade = g;
    }

    Duration? duration;
    final ta = points[a].time;
    final tb = points[b].time;
    if (ta != null && tb != null && !tb.isBefore(ta)) {
      duration = tb.difference(ta);
    }

    return SectionStats(
      distanceMeters: distance,
      elevationGainMeters: gain,
      avgGradePercent: avg,
      maxGradePercent: maxGrade,
      duration: duration,
    );
  }

  /// El tramo partido en pedazos de [chunkMeters] (el último puede ser
  /// más corto), con la pendiente de cada uno.
  List<SlopeChunk> chunks(int from, int to, double chunkMeters) {
    final out = <SlopeChunk>[];
    var start = from;
    while (start < to) {
      final target = distances[start] + chunkMeters;
      var end = indexAtDistance(target);
      if (end <= start) end = start + 1;
      if (end > to || distances[to] - distances[end] < chunkMeters * 0.35) {
        end = to;
      }
      final span = distances[end] - distances[start];
      out.add(
        SlopeChunk(
          startIndex: start,
          endIndex: end,
          startMeters: distances[start] - distances[from],
          endMeters: distances[end] - distances[from],
          gradePercent: span > 0
              ? (altitudes[end] - altitudes[start]) / span * 100
              : 0,
        ),
      );
      start = end;
    }
    return out;
  }

  /// Promedio de [read] entre dos índices, sin contar los vacíos.
  int? averageBetween(int from, int to, int? Function(RideTrackPoint) read) {
    var sum = 0;
    var count = 0;
    for (var i = from; i <= to; i++) {
      final v = read(points[i]);
      if (v == null) continue;
      sum += v;
      count++;
    }
    return count == 0 ? null : (sum / count).round();
  }
}

/// Promedio móvil por distancia: cada punto se promedia con los que
/// caen a menos de [radiusMeters].
List<double> _smoothByDistance(
  List<double> values,
  List<double> distances,
  double radiusMeters,
) {
  final n = values.length;
  if (n < 3) return List.of(values);
  final out = List<double>.filled(n, 0);
  var lo = 0;
  var hi = 0;
  var sum = 0.0;
  for (var i = 0; i < n; i++) {
    while (hi < n && distances[hi] - distances[i] <= radiusMeters) {
      sum += values[hi];
      hi++;
    }
    while (distances[i] - distances[lo] > radiusMeters) {
      sum -= values[lo];
      lo++;
    }
    out[i] = sum / (hi - lo);
  }
  return out;
}
