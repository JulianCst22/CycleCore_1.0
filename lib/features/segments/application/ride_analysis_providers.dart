import 'dart:isolate';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../data/gpx_ride_reader.dart';
import '../data/segments_repository.dart';
import '../domain/climb_finder.dart';
import '../domain/ride_track.dart';
import '../domain/segment_detector.dart';
import '../domain/segment_pass_finder.dart';
import '../domain/segment_profile_access.dart';
import '../domain/segment_profile_builder.dart';
import '../domain/segment_source.dart';
import '../domain/segment_splits.dart';
import '../domain/segment_stats_calculator.dart';
import 'segments_providers.dart';

/// De dónde viene la salida que se analiza.
enum RideSourceKind {
  /// Un GPX de otro aparato (Garmin...): sus tiempos son "de antes de la
  /// app".
  gpx,

  /// Una actividad grabada con la app.
  activity,
}

/// Un paso por uno de tus segmentos dentro de un GPX.
class FoundSegmentPass {
  final Segment segment;
  final SegmentPass pass;

  /// Ese tiempo ya está guardado como marca de antes.
  final bool alreadySaved;

  const FoundSegmentPass({
    required this.segment,
    required this.pass,
    required this.alreadySaved,
  });
}

/// Una salida analizada: sus subidas y, si es un GPX, los segmentos que
/// ya tienes por los que pasa.
class RideAnalysis {
  final RideSourceKind kind;
  final String title;
  final DateTime? date;
  final RideTrack track;
  final List<DetectedClimb> climbs;
  final List<FoundSegmentPass> passes;

  /// La actividad, si [kind] es [RideSourceKind.activity].
  final Activity? activity;

  const RideAnalysis({
    required this.kind,
    required this.title,
    required this.track,
    required this.climbs,
    this.date,
    this.passes = const [],
    this.activity,
  });

  bool get isGpx => kind == RideSourceKind.gpx;
}

/// Analiza salidas y guarda lo que el ciclista elige de ellas.
class RideAnalyzer {
  final SegmentsRepository _repo;

  RideAnalyzer(this._repo);

  /// Lee el GPX y busca sus subidas y tus segmentos, en otro isolate (un
  /// GPX de 200 km tiene decenas de miles de puntos).
  Future<RideAnalysis> analyzeGpx(
    String xml, {
    required String fileName,
  }) async {
    final detectorSegments = await _detectorSegments();
    final (name, track, climbs, passes) = await Isolate.run(() {
      final ride = const GpxRideReader().read(xml);
      final track = RideTrack(ride.points);
      return (
        ride.name,
        track,
        findClimbs(track),
        findSegmentPasses(track, detectorSegments),
      );
    });

    final found = <FoundSegmentPass>[];
    for (final pass in passes) {
      final segment = await _repo.getSegmentById(pass.segmentId);
      if (segment == null) continue;
      found.add(
        FoundSegmentPass(
          segment: segment,
          pass: pass,
          alreadySaved: await _isSaved(segment.id, pass.completedAt),
        ),
      );
    }

    return RideAnalysis(
      kind: RideSourceKind.gpx,
      title: name ?? _stripExtension(fileName),
      date: track.points.first.time,
      track: track,
      climbs: climbs,
      passes: found,
    );
  }

  /// Las subidas de una actividad grabada con la app. Sus pasos por tus
  /// segmentos ya se midieron en vivo, así que no se buscan de nuevo.
  RideAnalysis analyzeActivity(Activity activity) {
    final points = activity.routePoints;
    final track = RideTrack(
      [
        for (final p in points)
          RideTrackPoint(
            latitude: p.latitude,
            longitude: p.longitude,
            altitude: p.altitude,
            time: activity.startedAt.add(Duration(seconds: p.secondsFromStart)),
            heartRate: p.heartRateBpm,
            power: p.powerWatts,
          ),
      ],
      distances: [for (final p in points) p.distanceFromStartMeters],
    );
    return RideAnalysis(
      kind: RideSourceKind.activity,
      title: activity.title,
      date: activity.startedAt,
      track: track,
      climbs: findClimbs(track),
      activity: activity,
    );
  }

  /// Guarda el tramo [from]-[to] de la salida como segmento. Si la salida
  /// es un GPX con horas y [saveTime], guarda además cuánto tardaste ahí
  /// como marca de antes de la app (medida con el mismo detector que en
  /// vivo). Devuelve el id del segmento.
  ///
  /// Lanza [SegmentCreationException] si el tramo no sirve.
  Future<int> saveSegment(
    RideAnalysis analysis, {
    required int from,
    required int to,
    required String name,
    required bool saveTime,
  }) async {
    final activity = analysis.activity;
    if (activity != null) {
      return _repo.createSegmentFromActivity(
        activity: activity,
        startPointIndex: from,
        endPointIndex: to,
        name: name,
      );
    }

    final t = analysis.track;
    final profile = profilePointsFromRawTrack([
      for (var i = from; i <= to; i++)
        (
          lat: t.points[i].latitude,
          lng: t.points[i].longitude,
          altitude: t.altitudes[i],
        ),
    ]);
    final stats = computeSegmentStats(profile);
    if (profile.length < 3 || stats.isTooShort) {
      throw SegmentCreationException(
        'El segmento debe medir al menos '
        '${kMinSegmentDistanceMeters.round()} metros.',
      );
    }
    final id = await _repo.createSegmentFromGpx(
      name: name,
      profilePoints: profile,
      stats: stats,
      startBearingDegrees: computeStartBearing(profile),
      source: SegmentSource.gpxImport,
    );

    if (saveTime && t.hasTime) {
      final segment = await _repo.getSegmentById(id);
      if (segment != null) {
        final passes = findSegmentPasses(t, [_toDetector(segment)]);
        if (passes.isNotEmpty) {
          // El paso que corresponde a este tramo (el GPX pudo pasar dos
          // veces por el mismo sitio).
          passes.sort(
            (a, b) => (a.startIndex - from).abs().compareTo(
              (b.startIndex - from).abs(),
            ),
          );
          await saveTimeFromPass(analysis, segment, passes.first);
        }
      }
    }
    return id;
  }

  /// Guarda un paso del GPX por un segmento como marca de antes de la app.
  Future<void> saveTimeFromPass(
    RideAnalysis analysis,
    Segment segment,
    SegmentPass pass,
  ) async {
    if (await _isSaved(segment.id, pass.completedAt)) return;
    final t = analysis.track;
    final seconds = pass.elapsed.inSeconds;
    if (seconds <= 0) return;
    await _repo.recordBaselineEffort(
      BaselineEffortsCompanion.insert(
        segmentId: segment.id,
        completedAt: pass.completedAt,
        durationSeconds: seconds,
        avgSpeedKmh: (segment.distanceMeters / 1000) / (seconds / 3600),
        avgHeartRate: Value(
          t.averageBetween(pass.startIndex, pass.endIndex, (p) => p.heartRate),
        ),
        avgPower: Value(
          t.averageBetween(pass.startIndex, pass.endIndex, (p) => p.power),
        ),
        splitsJson: Value(encodeSplits(pass.splits)),
        sourceName: Value(analysis.title),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<DetectorSegment>> _detectorSegments() async {
    return [
      for (final s in await _repo.getAllSegments())
        if (s.profile.points.length >= 2) _toDetector(s),
    ];
  }

  static DetectorSegment _toDetector(Segment s) => DetectorSegment(
    id: s.id,
    name: s.name,
    profile: s.profile.points,
    startBearingDegrees: s.startBearingDegrees,
  );

  Future<bool> _isSaved(int segmentId, DateTime completedAt) async {
    for (final b in await _repo.getBaselineEfforts(segmentId)) {
      if (b.completedAt.difference(completedAt).inSeconds.abs() < 120) {
        return true;
      }
    }
    return false;
  }

  static String _stripExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }
}

final rideAnalyzerProvider = Provider<RideAnalyzer>((ref) {
  return RideAnalyzer(ref.watch(segmentsRepositoryProvider));
});
