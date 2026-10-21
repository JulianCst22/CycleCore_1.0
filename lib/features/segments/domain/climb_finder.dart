import 'dart:math' as math;

import 'ride_track.dart';

/// Categoría de una subida, con la escala habitual del ciclismo
/// (distancia en metros × pendiente media en %, la misma que usan Strava
/// y las vueltas por etapas).
enum ClimbCategory {
  hc('HC'),
  cat1('Cat. 1'),
  cat2('Cat. 2'),
  cat3('Cat. 3'),
  cat4('Cat. 4'),
  minor('Subida');

  final String label;
  const ClimbCategory(this.label);

  static ClimbCategory of(double distanceMeters, double avgGradePercent) {
    final score = distanceMeters * avgGradePercent;
    if (score >= 80000) return hc;
    if (score >= 64000) return cat1;
    if (score >= 32000) return cat2;
    if (score >= 16000) return cat3;
    if (score >= 8000) return cat4;
    return minor;
  }
}

/// Una subida encontrada en una salida.
class DetectedClimb {
  final int startIndex;
  final int endIndex;
  final SectionStats stats;
  final ClimbCategory category;

  /// Kilómetro de la salida donde empieza.
  final double startMeters;

  const DetectedClimb({
    required this.startIndex,
    required this.endIndex,
    required this.stats,
    required this.category,
    required this.startMeters,
  });
}

/// Qué cuenta como subida.
class ClimbCriteria {
  final double minDistanceMeters;
  final double minAvgGradePercent;
  final double minGainMeters;

  const ClimbCriteria({
    this.minDistanceMeters = 500,
    this.minAvgGradePercent = 3,
    this.minGainMeters = 30,
  });
}

/// Encuentra las subidas de una salida.
///
/// Recorre la altitud (ya suavizada) con histéresis: una subida empieza
/// cuando se gana [_startRiseMeters] desde el punto más bajo, y termina
/// en la cima cuando se baja lo suficiente desde ahí ([_dropTolerance]:
/// un descansito no la corta) o cuando se pasa un buen trecho sin
/// volver a subir. Después se le recortan los extremos planos (la
/// llegada al pie y el falso llano de la cima) y se queda solo si
/// cumple [criteria].
List<DetectedClimb> findClimbs(
  RideTrack track, {
  ClimbCriteria criteria = const ClimbCriteria(),
}) {
  final n = track.length;
  if (n < 3 || !track.hasAltitude) return const [];
  final alt = track.altitudes;
  final dist = track.distances;

  final found = <DetectedClimb>[];
  var climbing = false;
  var minIdx = 0;
  var startIdx = 0;
  var maxIdx = 0;

  void close() {
    final (s, e) = _trim(track, startIdx, maxIdx);
    if (e <= s) return;
    final stats = track.statsBetween(s, e);
    if (stats.distanceMeters < criteria.minDistanceMeters) return;
    if (stats.avgGradePercent < criteria.minAvgGradePercent) return;
    if (alt[e] - alt[s] < criteria.minGainMeters) return;
    found.add(
      DetectedClimb(
        startIndex: s,
        endIndex: e,
        stats: stats,
        category: ClimbCategory.of(stats.distanceMeters, stats.avgGradePercent),
        startMeters: dist[s],
      ),
    );
  }

  for (var i = 1; i < n; i++) {
    if (!climbing) {
      if (alt[i] < alt[minIdx]) {
        minIdx = i;
      } else if (alt[i] - alt[minIdx] >= _startRiseMeters) {
        climbing = true;
        startIdx = minIdx;
        maxIdx = i;
      }
      continue;
    }
    if (alt[i] >= alt[maxIdx]) {
      maxIdx = i;
      continue;
    }
    final gain = alt[maxIdx] - alt[startIdx];
    final drop = alt[maxIdx] - alt[i];
    final sinceTop = dist[i] - dist[maxIdx];
    if (drop >= _dropTolerance(gain) || sinceTop > _maxFlatAfterTopMeters) {
      close();
      climbing = false;
      // Se vuelve a buscar desde lo más bajo después de la cima.
      minIdx = maxIdx;
      for (var k = maxIdx; k <= i; k++) {
        if (alt[k] < alt[minIdx]) minIdx = k;
      }
    }
  }
  if (climbing) close();
  return found;
}

/// Altura ganada sobre el punto más bajo para dar por empezada una
/// subida.
const double _startRiseMeters = 10;

/// Más de esto sin una cima nueva (aunque no se baje) cierra la subida.
const double _maxFlatAfterTopMeters = 1500;

/// Cuánto hay que bajar desde la cima para cerrar la subida: poco en
/// una subida corta, más en una larga (un descanso de 25 m en un puerto
/// de 800 m no lo parte en dos).
double _dropTolerance(double gainSoFar) =>
    math.max(12, math.min(40, gainSoFar * 0.1));

/// Quita el llano del principio (la aproximación al pie) y del final
/// (el falso llano de la cima): mientras los 120 m del borde tengan
/// menos de 2 %, se corre el borde 10 m hacia adentro.
(int, int) _trim(RideTrack t, int start, int end) {
  const look = 120.0;
  const step = 10.0;
  const flat = 2.0;
  var s = start;
  var e = end;
  while (s < e) {
    final j = t.indexAtDistance(t.distances[s] + look);
    if (j >= e) break;
    final span = t.distances[j] - t.distances[s];
    if (span <= 0) break;
    if ((t.altitudes[j] - t.altitudes[s]) / span * 100 >= flat) break;
    s = math.max(s + 1, t.indexAtDistance(t.distances[s] + step));
  }
  while (e > s) {
    final j = t.indexAtDistance(t.distances[e] - look);
    if (j <= s) break;
    final span = t.distances[e] - t.distances[j];
    if (span <= 0) break;
    if ((t.altitudes[e] - t.altitudes[j]) / span * 100 >= flat) break;
    e = math.min(e - 1, t.indexAtDistance(t.distances[e] - step));
  }
  return (s, e);
}
