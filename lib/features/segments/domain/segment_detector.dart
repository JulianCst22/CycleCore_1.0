import 'dart:math' as math;

import 'package:core_geo/core_geo.dart';

/// Un segmento vigilado, en la forma mínima que el detector necesita --
/// sin depender de la fila Drift `Segment`. El controlador (capa de
/// presentación) adapta `Segment` -> `DetectorSegment`.
class DetectorSegment {
  final int id;
  final String name;
  final List<SegmentProfilePoint> profile;
  final double startBearingDegrees;

  DetectorSegment({
    required this.id,
    required this.name,
    required this.profile,
    required this.startBearingDegrees,
  });

  double get totalDistanceMeters =>
      profile.isEmpty ? 0 : profile.last.distanceFromStartMeters;
}

/// Una muestra de GPS ya normalizada para el detector.
class DetectorTick {
  final double lat;
  final double lng;

  /// Rumbo de desplazamiento (0-360). El controlador lo deriva de los
  /// últimos puntos si el `heading` del GPS no es fiable a baja
  /// velocidad.
  final double bearingDegrees;
  final double speedKmh;
  final DateTime timestamp;

  const DetectorTick({
    required this.lat,
    required this.lng,
    required this.bearingDegrees,
    required this.speedKmh,
    required this.timestamp,
  });
}

/// Un punto de la curva tiempo-vs-distancia del esfuerzo en curso.
class SplitPoint {
  final double distanceMeters;
  final int secondsFromStart;

  const SplitPoint(this.distanceMeters, this.secondsFromStart);

  Map<String, dynamic> toJson() => {'d': distanceMeters, 't': secondsFromStart};

  factory SplitPoint.fromJson(Map<String, dynamic> j) => SplitPoint(
        (j['d'] as num).toDouble(),
        (j['t'] as num).toInt(),
      );
}

/// El esfuerzo en curso dentro de un segmento activo.
class ActiveRun {
  final int segmentId;
  final DateTime enteredAt;
  final double alongMeters;
  final double maxAlongMeters;
  final double offRouteSeconds;
  final List<SplitPoint> splits;
  final DateTime lastTickAt;

  const ActiveRun({
    required this.segmentId,
    required this.enteredAt,
    required this.alongMeters,
    required this.maxAlongMeters,
    required this.offRouteSeconds,
    required this.splits,
    required this.lastTickAt,
  });

  double progressFraction(double totalMeters) =>
      totalMeters <= 0 ? 0 : (alongMeters / totalMeters).clamp(0.0, 1.0);
}

class SegmentDetectorState {
  final ActiveRun? run;

  /// segmentId -> cuándo terminó/se abandonó por última vez, para no
  /// re-disparar el mismo segmento de inmediato (debounce).
  final Map<int, DateTime> endedAt;

  const SegmentDetectorState({this.run, this.endedAt = const {}});

  static const initial = SegmentDetectorState();
}

sealed class SegmentDetectorEvent {
  const SegmentDetectorEvent();
}

class SegmentEnteredEvent extends SegmentDetectorEvent {
  final int segmentId;
  const SegmentEnteredEvent(this.segmentId);
}

class SegmentCompletedEvent extends SegmentDetectorEvent {
  final int segmentId;
  final Duration elapsed;
  final List<SplitPoint> splits;
  const SegmentCompletedEvent(this.segmentId, this.elapsed, this.splits);
}

class SegmentAbandonedEvent extends SegmentDetectorEvent {
  final int segmentId;

  /// `off_route` | `wrong_way` | `removed`.
  final String reason;
  const SegmentAbandonedEvent(this.segmentId, this.reason);
}

class SegmentDetectorResult {
  final SegmentDetectorState state;
  final List<SegmentDetectorEvent> events;
  const SegmentDetectorResult(this.state, this.events);
}

/// Máquina de estados PURA (sin Flutter, sin Riverpod, sin geolocator)
/// que decide, en cada punto GPS, si el ciclista entró/salió/completó
/// un segmento vigilado.
///
/// Falsos positivos que evita:
///  - contravía / calle paralela: exige que el rumbo de desplazamiento
///    coincida con `startBearingDegrees` (±[bearingToleranceDegrees]) y
///    que la posición caiga dentro de un corredor estrecho alrededor
///    del trazado.
///  - dispararse parado sobre el punto A (semáforo): exige
///    [minEnterSpeedKmh].
///  - dispararse "a mitad" de un segmento porque pasaste cerca del
///    trazado: exige que la proyección esté cerca del inicio
///    ([enterMaxAlongMeters]).
///  - re-disparar el mismo segmento al toque de terminarlo: debounce
///    [debounceSeconds].
class SegmentDetector {
  final double enterRadiusMeters;
  final double enterCorridorMeters;
  final double enterMaxAlongMeters;
  final double bearingToleranceDegrees;
  final double minEnterSpeedKmh;
  final double corridorMeters;
  final double abandonAfterSeconds;
  final double finishRadiusMeters;
  final double wrongWaySlackMeters;
  final int debounceSeconds;
  final double minSplitAdvanceMeters;

  const SegmentDetector({
    this.enterRadiusMeters = 30,
    this.enterCorridorMeters = 25,
    this.enterMaxAlongMeters = 45,
    this.bearingToleranceDegrees = 50,
    this.minEnterSpeedKmh = 4,
    this.corridorMeters = 30,
    this.abandonAfterSeconds = 12,
    this.finishRadiusMeters = 20,
    this.wrongWaySlackMeters = 45,
    this.debounceSeconds = 45,
    this.minSplitAdvanceMeters = 5,
  });

  SegmentDetectorResult tick(
    SegmentDetectorState state,
    List<DetectorSegment> segments,
    DetectorTick t,
  ) {
    final events = <SegmentDetectorEvent>[];
    final endedAt = Map<int, DateTime>.of(state.endedAt);

    // --- Sin segmento activo: buscar uno para entrar. ---
    if (state.run == null) {
      for (final seg in segments) {
        if (seg.profile.length < 2) continue;

        final last = endedAt[seg.id];
        if (last != null &&
            t.timestamp.difference(last).inSeconds < debounceSeconds) {
          continue;
        }
        if (t.speedKmh < minEnterSpeedKmh) continue;

        final start = seg.profile.first;
        final dToStart =
            haversineMeters(t.lat, t.lng, start.latitude, start.longitude);
        if (dToStart > enterRadiusMeters) continue;

        if (bearingDelta(t.bearingDegrees, seg.startBearingDegrees) >
            bearingToleranceDegrees) {
          continue;
        }

        final proj = projectOntoProfile(seg.profile, t.lat, t.lng);
        if (proj.offsetMeters > enterCorridorMeters) continue;
        if (proj.alongMeters > enterMaxAlongMeters) continue;

        final run = ActiveRun(
          segmentId: seg.id,
          enteredAt: t.timestamp,
          alongMeters: proj.alongMeters,
          maxAlongMeters: proj.alongMeters,
          offRouteSeconds: 0,
          splits: const [SplitPoint(0, 0)],
          lastTickAt: t.timestamp,
        );
        events.add(SegmentEnteredEvent(seg.id));
        return SegmentDetectorResult(
          SegmentDetectorState(run: run, endedAt: endedAt),
          events,
        );
      }
      return SegmentDetectorResult(
        SegmentDetectorState(run: null, endedAt: endedAt),
        events,
      );
    }

    // --- Segmento activo: actualizar. ---
    final run = state.run!;
    DetectorSegment? seg;
    for (final s in segments) {
      if (s.id == run.segmentId) {
        seg = s;
        break;
      }
    }
    if (seg == null) {
      endedAt[run.segmentId] = t.timestamp;
      events.add(SegmentAbandonedEvent(run.segmentId, 'removed'));
      return SegmentDetectorResult(
        SegmentDetectorState(run: null, endedAt: endedAt),
        events,
      );
    }

    final dt =
        t.timestamp.difference(run.lastTickAt).inMilliseconds / 1000.0;
    final proj = projectOntoProfile(seg.profile, t.lat, t.lng);
    final secondsSinceEnter =
        t.timestamp.difference(run.enteredAt).inSeconds;

    // ¿Llegó a la meta?
    final lastPt = seg.profile.last;
    final dToEnd =
        haversineMeters(t.lat, t.lng, lastPt.latitude, lastPt.longitude);
    final reachedEnd = proj.alongMeters >= seg.totalDistanceMeters - 15 ||
        dToEnd < finishRadiusMeters;
    if (reachedEnd && proj.offsetMeters <= corridorMeters) {
      final splits = [
        ...run.splits,
        SplitPoint(seg.totalDistanceMeters, secondsSinceEnter),
      ];
      endedAt[seg.id] = t.timestamp;
      events.add(
        SegmentCompletedEvent(
          seg.id,
          Duration(seconds: secondsSinceEnter),
          splits,
        ),
      );
      return SegmentDetectorResult(
        SegmentDetectorState(run: null, endedAt: endedAt),
        events,
      );
    }

    // ¿Se salió del trazado o va en contravía?
    final wrongWay = proj.alongMeters < run.maxAlongMeters - wrongWaySlackMeters;
    var offRoute = run.offRouteSeconds;
    if (proj.offsetMeters > corridorMeters || wrongWay) {
      offRoute += dt;
    } else {
      offRoute = 0;
    }
    if (offRoute > abandonAfterSeconds) {
      endedAt[seg.id] = t.timestamp;
      events.add(
        SegmentAbandonedEvent(seg.id, wrongWay ? 'wrong_way' : 'off_route'),
      );
      return SegmentDetectorResult(
        SegmentDetectorState(run: null, endedAt: endedAt),
        events,
      );
    }

    final splits = List<SplitPoint>.of(run.splits);
    if (proj.alongMeters > run.alongMeters + minSplitAdvanceMeters) {
      splits.add(SplitPoint(proj.alongMeters, secondsSinceEnter));
    }

    return SegmentDetectorResult(
      SegmentDetectorState(
        run: ActiveRun(
          segmentId: seg.id,
          enteredAt: run.enteredAt,
          alongMeters: proj.alongMeters,
          maxAlongMeters: math.max(run.maxAlongMeters, proj.alongMeters),
          offRouteSeconds: offRoute,
          splits: splits,
          lastTickAt: t.timestamp,
        ),
        endedAt: endedAt,
      ),
      events,
    );
  }
}
