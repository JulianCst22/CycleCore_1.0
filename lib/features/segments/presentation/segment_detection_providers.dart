import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/database/app_database.dart';
import '../../activities/presentation/ride_sensor_log.dart';
import '../../geospatial/presentation/map_providers.dart'
    show routeRecordingProvider, RouteRecordingState;
import '../../voice/domain/voice_event.dart';
import '../../voice/presentation/voice_providers.dart';
import '../domain/segment_detector.dart';
import '../domain/segment_geometry.dart';
import '../domain/segment_profile.dart';
import '../domain/segment_splits.dart';
import 'segments_providers.dart';

/// El segmento que el ciclista está recorriendo AHORA, con todo lo que
/// la UI necesita para mostrarlo (Fases C/D).
class ActiveSegmentLive {
  final Segment segment;

  /// Perfil congelado ya parseado -- se pasa acá (y no se re-decodifica
  /// de `segment.profileJson` en cada frame) porque la pantalla de
  /// segmento en vivo lo consulta varias veces por segundo.
  final SegmentProfile profile;

  final DateTime enteredAt;

  /// Distancia recorrida dentro del segmento (m).
  final double alongMeters;

  /// 0.0-1.0.
  final double progressFraction;

  /// Mejor marca previa de este segmento (para el fantasma), o null si
  /// nunca se completó.
  final SegmentEffort? bestEffort;

  /// Curva tiempo-distancia de esa mejor marca -- vacía si la mejor
  /// marca es vieja (sin splits) o no hay.
  final List<SplitPoint> bestSplits;

  const ActiveSegmentLive({
    required this.segment,
    required this.profile,
    required this.enteredAt,
    required this.alongMeters,
    required this.progressFraction,
    required this.bestEffort,
    required this.bestSplits,
  });

  double get remainingMeters =>
      (segment.distanceMeters - alongMeters).clamp(0, segment.distanceMeters);

  /// Tu tiempo dentro del segmento, ahora mismo.
  Duration elapsedNow() => DateTime.now().difference(enteredAt);

  /// Segundos que la mejor marca tardó en llegar a donde vas -- el
  /// fantasma. `null` si no hay curva de splits.
  double? ghostSecondsHere() => ghostSecondsAtDistance(bestSplits, alongMeters);

  /// Diferencia contra el fantasma en este punto (+ = vas más lento).
  /// `null` si no hay fantasma.
  Duration? deltaVsGhost() {
    final ghost = ghostSecondsHere();
    if (ghost == null) return null;
    return Duration(
      seconds: (elapsedNow().inSeconds - ghost).round(),
    );
  }
}

class SegmentLiveState {
  final ActiveSegmentLive? active;
  const SegmentLiveState({this.active});
}

/// Datos crudos de un esfuerzo completado durante la grabación,
/// bufferizados hasta que la actividad se guarde y tenga id.
class _PendingEffort {
  final int segmentId;
  final int durationSeconds;
  final double avgSpeedKmh;
  final int? avgHeartRate;
  final int? avgPower;
  final DateTime completedAt;
  final String splitsJson;

  const _PendingEffort({
    required this.segmentId,
    required this.durationSeconds,
    required this.avgSpeedKmh,
    required this.avgHeartRate,
    required this.avgPower,
    required this.completedAt,
    required this.splitsJson,
  });

  SegmentEffortsCompanion toCompanion(int activityId) {
    return SegmentEffortsCompanion.insert(
      segmentId: segmentId,
      activityId: activityId,
      durationSeconds: durationSeconds,
      avgSpeedKmh: avgSpeedKmh,
      avgHeartRate: Value(avgHeartRate),
      avgPower: Value(avgPower),
      completedAt: completedAt,
      splitsJson: Value(splitsJson),
    );
  }
}

class _WatchedMeta {
  final Segment segment;
  final SegmentProfile profile;
  final SegmentEffort? best;
  final List<SplitPoint> bestSplits;
  const _WatchedMeta(this.segment, this.profile, this.best, this.bestSplits);
}

/// Conecta el `SegmentDetector` puro al stream de puntos de la
/// grabación (`routeRecordingProvider`) y a la voz. Bufferiza los
/// esfuerzos completados; `MapScreen` los vuelca (`flushPendingEfforts`)
/// una vez que la actividad se guardó y tiene id.
class SegmentDetectionController extends StateNotifier<SegmentLiveState> {
  final Ref _ref;
  final SegmentDetector _detector;

  SegmentDetectorState _detState = SegmentDetectorState.initial;
  List<DetectorSegment> _watched = const [];
  final Map<int, _WatchedMeta> _meta = {};
  final List<_PendingEffort> _pending = [];
  bool _wasRecording = false;
  int _lastTickPointCount = 0;

  SegmentDetectionController(this._ref, {SegmentDetector? detector})
      : _detector = detector ?? const SegmentDetector(),
        super(const SegmentLiveState()) {
    _ref.listen<RouteRecordingState>(
      routeRecordingProvider,
      _onRecordingChanged,
      fireImmediately: true,
    );
  }

  /// Esfuerzos completados que todavía no se persistieron (falta el id
  /// de la actividad).
  bool get hasPendingEfforts => _pending.isNotEmpty;

  void _onRecordingChanged(
    RouteRecordingState? previous,
    RouteRecordingState next,
  ) {
    final started = !_wasRecording && next.isRecording;
    final stopped = _wasRecording && !next.isRecording;

    if (started) {
      _wasRecording = true;
      _startWatching();
      return;
    }
    if (stopped) {
      _wasRecording = false;
      _resetRuntime();
      return;
    }
    if (next.isRecording && !next.isPaused) {
      // Solo procesamos cuando llegó un punto GPS nuevo.
      if (next.points.length != _lastTickPointCount) {
        _lastTickPointCount = next.points.length;
        _tick(next);
      }
    }
  }

  Future<void> _startWatching() async {
    _resetRuntimeState();
    final repo = _ref.read(segmentsRepositoryProvider);
    final segments = await repo.getActiveSegments();

    final watched = <DetectorSegment>[];
    for (final s in segments) {
      final parsedProfile = s.profile;
      if (parsedProfile.points.length < 2) continue;
      watched.add(
        DetectorSegment(
          id: s.id,
          name: s.name,
          profile: parsedProfile.points,
          startBearingDegrees: s.startBearingDegrees,
        ),
      );
      final efforts = await repo.getEfforts(s.id);
      final best = efforts.isEmpty ? null : efforts.first;
      _meta[s.id] = _WatchedMeta(
        s,
        parsedProfile,
        best,
        best == null ? const [] : decodeSplits(best.splitsJson),
      );
    }
    _watched = watched;
  }

  void _resetRuntimeState() {
    _detState = SegmentDetectorState.initial;
    _watched = const [];
    _meta.clear();
    _pending.clear();
    _lastTickPointCount = 0;
    if (state.active != null) state = const SegmentLiveState();
  }

  /// Igual que [_resetRuntimeState] pero conserva los esfuerzos
  /// pendientes -- se llama al terminar de grabar, cuando todavía falta
  /// que `MapScreen` los vuelque a la BD.
  void _resetRuntime() {
    _detState = SegmentDetectorState.initial;
    _watched = const [];
    _meta.clear();
    _lastTickPointCount = 0;
    if (state.active != null) state = const SegmentLiveState();
  }

  void _tick(RouteRecordingState rec) {
    if (_watched.isEmpty || rec.points.isEmpty) return;

    final last = rec.points.last;
    final speed = rec.currentSpeedKmh;

    // El heading del GPS es ruidoso a baja velocidad -- si vamos lento,
    // derivamos el rumbo de los dos últimos puntos.
    double bearing = rec.currentBearingDegrees;
    if (speed < 8 && rec.points.length >= 2) {
      final prev = rec.points[rec.points.length - 2];
      bearing = bearingBetween(
        prev.latitude,
        prev.longitude,
        last.latitude,
        last.longitude,
      );
    }

    final result = _detector.tick(
      _detState,
      _watched,
      DetectorTick(
        lat: last.latitude,
        lng: last.longitude,
        bearingDegrees: bearing,
        speedKmh: speed,
        timestamp: last.timestamp,
      ),
    );
    _detState = result.state;

    for (final event in result.events) {
      _handleEvent(event);
    }

    final run = _detState.run;
    if (run != null) {
      final meta = _meta[run.segmentId];
      if (meta != null) {
        state = SegmentLiveState(
          active: ActiveSegmentLive(
            segment: meta.segment,
            profile: meta.profile,
            enteredAt: run.enteredAt,
            alongMeters: run.alongMeters,
            progressFraction:
                run.progressFraction(meta.segment.distanceMeters),
            bestEffort: meta.best,
            bestSplits: meta.bestSplits,
          ),
        );
      }
    } else if (state.active != null) {
      state = const SegmentLiveState();
    }
  }

  void _handleEvent(SegmentDetectorEvent event) {
    final voice = _ref.read(voiceSettingsProvider.notifier);
    switch (event) {
      case SegmentEnteredEvent():
        voice.speak(VoiceEventType.segmentEntered);

      case SegmentCompletedEvent(:final segmentId, :final elapsed, :final splits):
        final meta = _meta[segmentId];
        if (meta == null) break;
        final enteredAt = DateTime.now().subtract(elapsed);
        final log = _ref.read(rideSensorLogProvider);
        final seconds = elapsed.inSeconds <= 0 ? 1 : elapsed.inSeconds;
        final avgSpeedKmh =
            (meta.segment.distanceMeters / 1000) / (seconds / 3600);

        _pending.add(
          _PendingEffort(
            segmentId: segmentId,
            durationSeconds: elapsed.inSeconds,
            avgSpeedKmh: avgSpeedKmh,
            avgHeartRate:
                log.avgHeartRateBetween(enteredAt, DateTime.now()),
            avgPower: log.avgPowerBetween(enteredAt, DateTime.now()),
            completedAt: DateTime.now(),
            splitsJson: encodeSplits(splits),
          ),
        );

        final isPr = meta.best == null ||
            elapsed.inSeconds < meta.best!.durationSeconds;
        voice.speak(
          isPr ? VoiceEventType.segmentPr : VoiceEventType.segmentCompleted,
        );

      case SegmentAbandonedEvent():
        voice.speak(VoiceEventType.segmentAbandoned);
    }
  }

  /// Vuelca los esfuerzos bufferizados a la BD, ya con el id de la
  /// actividad recién guardada. Llamar desde `SaveActivityScreen`.
  Future<void> flushPendingEfforts(int activityId) async {
    if (_pending.isEmpty) return;
    final repo = _ref.read(segmentsRepositoryProvider);
    for (final p in _pending) {
      await repo.recordEffort(p.toCompanion(activityId));
    }
    _pending.clear();
  }

  /// El usuario descartó la actividad -- se tiran los esfuerzos.
  void discardPendingEfforts() => _pending.clear();
}

final segmentDetectionProvider =
    StateNotifierProvider<SegmentDetectionController, SegmentLiveState>((ref) {
  return SegmentDetectionController(ref);
});
