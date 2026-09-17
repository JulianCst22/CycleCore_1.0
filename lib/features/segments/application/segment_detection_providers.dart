import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_database/core_database.dart';
import '../../recording/recording.dart';
import '../../voice/voice.dart';
import '../domain/segment_detector.dart';
import 'package:core_geo/core_geo.dart';
import '../domain/segment_splits.dart';
import 'segments_providers.dart';
import '../domain/segment_profile_access.dart';

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
/// esfuerzos completados; `RideScreen` los vuelca (`flushPendingEfforts`)
/// una vez que la actividad se guardó y tiene id.
///
/// Los esfuerzos pendientes viven solo en memoria: si la app se cierra a
/// mitad de la salida, se reconstruyen pasando de nuevo el detector por
/// los puntos que recuperó el diario de grabación (ver `_catchUp` y
/// [recoverEffortsFrom]). Como el detector es puro y trabaja con el
/// instante de cada punto, el resultado es el mismo que en vivo.
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
    await _loadWatchedSegments();
    // La grabación pudo terminar mientras se cargaban los segmentos.
    if (!_wasRecording) return;

    // Una grabación reanudada tras un cierre inesperado arranca con
    // puntos ya grabados (en una nueva, esto no hace nada): se re-procesan
    // en silencio para recuperar los esfuerzos de antes del cierre y, si
    // se iba dentro de un segmento, seguir en él.
    _catchUp(
      _ref.read(routeRecordingProvider).points,
      log: _ref.read(rideSensorLogProvider),
    );
    _publishActiveRun();
  }

  /// Reconstruye los esfuerzos de una grabación recuperada que se va a
  /// guardar SIN reanudarla (ahí la grabación nunca vuelve a arrancar,
  /// así que [_startWatching] no se entera). Quedan pendientes hasta
  /// `flushPendingEfforts`/`discardPendingEfforts`, igual que al terminar
  /// una grabación en vivo.
  Future<void> recoverEffortsFrom({
    required List<RoutePoint> points,
    required RideSensorLog log,
  }) async {
    if (_wasRecording) return;
    _resetRuntimeState();
    await _loadWatchedSegments();
    _catchUp(points, log: log);
    _resetRuntime();
  }

  Future<void> _loadWatchedSegments() async {
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
  /// que `RideScreen` los vuelque a la BD.
  void _resetRuntime() {
    _detState = SegmentDetectorState.initial;
    _watched = const [];
    _meta.clear();
    _lastTickPointCount = 0;
    if (state.active != null) state = const SegmentLiveState();
  }

  void _tick(RouteRecordingState rec) {
    if (_watched.isEmpty || rec.points.isEmpty) return;

    _step(
      rec.points,
      rec.points.length - 1,
      speedKmh: rec.currentSpeedKmh,
      bearingDegrees: rec.currentBearingDegrees,
      log: _ref.read(rideSensorLogProvider),
      announce: true,
    );
    _publishActiveRun();
  }

  /// Pasa el detector, sin voz, por puntos que ya estaban grabados. Usa
  /// la velocidad y el rumbo GPS de cada punto -- los "priorizados"
  /// (sensor BLE) solo existen para el último.
  void _catchUp(List<RoutePoint> points, {required RideSensorLog log}) {
    _lastTickPointCount = points.length;
    if (_watched.isEmpty) return;
    for (var i = 0; i < points.length; i++) {
      _step(
        points,
        i,
        speedKmh: points[i].speedMetersPerSecond * 3.6,
        bearingDegrees: points[i].bearingDegrees,
        log: log,
        announce: false,
      );
    }
  }

  /// Un paso del detector sobre `points[index]`.
  void _step(
    List<RoutePoint> points,
    int index, {
    required double speedKmh,
    required double bearingDegrees,
    required RideSensorLog log,
    required bool announce,
  }) {
    final point = points[index];

    // El heading del GPS es ruidoso a baja velocidad -- si vamos lento,
    // derivamos el rumbo de los dos últimos puntos.
    double bearing = bearingDegrees;
    if (speedKmh < 8 && index >= 1) {
      final prev = points[index - 1];
      bearing = bearingBetween(
        prev.latitude,
        prev.longitude,
        point.latitude,
        point.longitude,
      );
    }

    final result = _detector.tick(
      _detState,
      _watched,
      DetectorTick(
        lat: point.latitude,
        lng: point.longitude,
        bearingDegrees: bearing,
        speedKmh: speedKmh,
        timestamp: point.timestamp,
      ),
    );
    _detState = result.state;

    for (final event in result.events) {
      _handleEvent(event, at: point.timestamp, log: log, announce: announce);
    }
  }

  /// Refleja en [state] el segmento en el que va el detector ahora.
  void _publishActiveRun() {
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

  /// [at] es el instante del punto que disparó el evento -- en vivo es
  /// "ahora"; al ponerse al día con puntos recuperados, el de ese punto.
  void _handleEvent(
    SegmentDetectorEvent event, {
    required DateTime at,
    required RideSensorLog log,
    required bool announce,
  }) {
    void speak(VoiceEventType type) {
      if (announce) _ref.read(voiceSettingsProvider.notifier).speak(type);
    }

    switch (event) {
      case SegmentEnteredEvent():
        speak(VoiceEventType.segmentEntered);

      case SegmentCompletedEvent(
        :final segmentId,
        :final elapsed,
        :final splits,
      ):
        final meta = _meta[segmentId];
        if (meta == null) break;
        final enteredAt = at.subtract(elapsed);
        final seconds = elapsed.inSeconds <= 0 ? 1 : elapsed.inSeconds;
        final avgSpeedKmh =
            (meta.segment.distanceMeters / 1000) / (seconds / 3600);

        _pending.add(
          _PendingEffort(
            segmentId: segmentId,
            durationSeconds: elapsed.inSeconds,
            avgSpeedKmh: avgSpeedKmh,
            avgHeartRate: log.avgHeartRateBetween(enteredAt, at),
            avgPower: log.avgPowerBetween(enteredAt, at),
            completedAt: at,
            splitsJson: encodeSplits(splits),
          ),
        );

        final isPr =
            meta.best == null || elapsed.inSeconds < meta.best!.durationSeconds;
        speak(
          isPr ? VoiceEventType.segmentPr : VoiceEventType.segmentCompleted,
        );

      case SegmentAbandonedEvent():
        speak(VoiceEventType.segmentAbandoned);
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
