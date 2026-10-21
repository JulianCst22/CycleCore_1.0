import '../../../core/geo/geo.dart';
import 'ride_track.dart';
import 'segment_detector.dart';

/// Un paso por uno de tus segmentos dentro de una salida que no se grabó
/// en vivo con la app (un GPX de otro aparato).
class SegmentPass {
  final int segmentId;
  final DateTime startedAt;
  final DateTime completedAt;
  final List<SplitPoint> splits;
  final int startIndex;
  final int endIndex;

  const SegmentPass({
    required this.segmentId,
    required this.startedAt,
    required this.completedAt,
    required this.splits,
    required this.startIndex,
    required this.endIndex,
  });

  Duration get elapsed => completedAt.difference(startedAt);
}

/// Entre dos puntos más separados que esto se rellenan puntos: el
/// detector necesita ver pasar al ciclista cerca del inicio y de la meta
/// (radios de 20-30 m), y un archivo grabado cada pocos segundos puede
/// saltárselos.
const double _densifyStepMeters = 12;

/// Más allá de esta distancia entre dos puntos no se rellena: es un
/// hueco de la señal o una pausa, y una recta inventada cortaría curvas.
const double _maxGapToFillMeters = 250;

/// Pasa el [SegmentDetector] por una salida completa, con la misma regla
/// que en vivo: un tiempo de antes de usar la app y uno de después se
/// miden igual, que es lo que permite compararlos.
///
/// Necesita la hora de cada punto (`RideTrack.hasTime`); sin ella no hay
/// tiempos que medir y devuelve vacío.
List<SegmentPass> findSegmentPasses(
  RideTrack track,
  List<DetectorSegment> segments, {
  SegmentDetector detector = const SegmentDetector(),
}) {
  if (!track.hasTime || track.length < 2 || segments.isEmpty) return const [];

  final ticks = <(DetectorTick, int)>[];
  var bearing = 0.0;
  var speedKmh = 0.0;
  final pts = track.points;
  for (var i = 0; i < pts.length; i++) {
    final cur = pts[i];
    final t = cur.time;
    if (t == null) continue;
    if (i == 0 || pts[i - 1].time == null) {
      ticks.add((_tick(cur.latitude, cur.longitude, bearing, 0, t), i));
      continue;
    }
    final prev = pts[i - 1];
    final d = track.distances[i] - track.distances[i - 1];
    final dt = t.difference(prev.time!).inMilliseconds / 1000.0;
    if (d >= 2) {
      bearing = bearingBetween(
        prev.latitude,
        prev.longitude,
        cur.latitude,
        cur.longitude,
      );
    }
    if (dt > 0) speedKmh = d / dt * 3.6;
    if (d > _densifyStepMeters && d <= _maxGapToFillMeters && dt > 0) {
      final pieces = (d / _densifyStepMeters).ceil();
      for (var k = 1; k < pieces; k++) {
        final f = k / pieces;
        ticks.add((
          _tick(
            prev.latitude + (cur.latitude - prev.latitude) * f,
            prev.longitude + (cur.longitude - prev.longitude) * f,
            bearing,
            speedKmh,
            prev.time!.add(Duration(milliseconds: (dt * 1000 * f).round())),
          ),
          i,
        ));
      }
    }
    ticks.add((_tick(cur.latitude, cur.longitude, bearing, speedKmh, t), i));
  }

  var state = SegmentDetectorState.initial;
  final entered = <int, (DateTime, int)>{};
  final found = <SegmentPass>[];
  for (final (tick, index) in ticks) {
    final result = detector.tick(state, segments, tick);
    state = result.state;
    for (final event in result.events) {
      switch (event) {
        case SegmentEnteredEvent(:final segmentId):
          entered[segmentId] = (tick.timestamp, index);
        case SegmentCompletedEvent(:final segmentId, :final splits):
          final start = entered.remove(segmentId);
          if (start == null) break;
          final (startedAt, startIndex) = start;
          if (!tick.timestamp.isAfter(startedAt)) break;
          found.add(
            SegmentPass(
              segmentId: segmentId,
              startedAt: startedAt,
              completedAt: tick.timestamp,
              splits: splits,
              startIndex: startIndex,
              endIndex: index,
            ),
          );
        case SegmentAbandonedEvent(:final segmentId):
          entered.remove(segmentId);
      }
    }
  }
  return found;
}

DetectorTick _tick(
  double lat,
  double lng,
  double bearing,
  double speedKmh,
  DateTime time,
) {
  return DetectorTick(
    lat: lat,
    lng: lng,
    bearingDegrees: bearing,
    speedKmh: speedKmh,
    timestamp: time,
  );
}
