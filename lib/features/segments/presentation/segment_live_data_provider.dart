import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/heart_rate_provider.dart';
import '../../geospatial/presentation/map_providers.dart'
    show routeRecordingProvider, secondTickerProvider;
import '../../sensors/presentation/cadence_providers.dart';
import '../../sensors/presentation/power_providers.dart';
import '../domain/segment_cockpit_field.dart';
import 'segment_detection_providers.dart';

/// Arma el `SegmentLiveData` que consume la pantalla de segmento en
/// vivo (Fase D) a partir de:
///  - el segmento activo y tu avance (`segmentDetectionProvider`),
///  - el perfil congelado del segmento (pendiente/altitud/desnivel por
///    distancia -- GPX o HGT, NUNCA sensores en vivo),
///  - los sensores en vivo (FC / potencia / cadencia / velocidad),
///  - la mejor marca previa, para el fantasma.
///
/// `null` cuando no estás dentro de ningún segmento.
final segmentLiveDataProvider = Provider<SegmentLiveData?>((ref) {
  final active = ref.watch(segmentDetectionProvider).active;
  if (active == null) return null;

  // Refresca el tiempo/estimados cada segundo aunque no llegue GPS.
  ref.watch(secondTickerProvider);

  final rec = ref.watch(routeRecordingProvider);
  final hr = ref.watch(heartRateBpmProvider);
  final power = ref.watch(powerWattsProvider);
  final cadence = ref.watch(cadenceRpmProvider);

  final profile = active.profile;
  final along = active.alongMeters;
  final total = active.segment.distanceMeters;
  final elapsed = active.elapsedNow();
  final elapsedSecs = elapsed.inSeconds;

  final avgSpeedInSegmentKmh =
      elapsedSecs > 0 ? (along / 1000) / (elapsedSecs / 3600) : 0.0;

  // --- Proyección de meta ---
  final ghostHere = active.ghostSecondsHere();
  final bestSecs = active.bestEffort?.durationSeconds;
  Duration? projected;
  if (ghostHere != null && ghostHere > 0 && bestSecs != null && elapsedSecs > 0) {
    // Mantenés tu ritmo RELATIVO al fantasma hasta el final.
    projected =
        Duration(seconds: (bestSecs * (elapsedSecs / ghostHere)).round());
  } else if (avgSpeedInSegmentKmh > 1) {
    // Sin fantasma: proyectá con tu velocidad media dentro del segmento.
    final remainingSecs =
        (active.remainingMeters / (avgSpeedInSegmentKmh / 3.6)).round();
    projected = Duration(seconds: elapsedSecs + remainingSecs);
  }

  return SegmentLiveData(
    elapsedInSegment: elapsed,
    alongMeters: along,
    remainingMeters: active.remainingMeters,
    totalMeters: total,
    progressFraction: active.progressFraction,
    remainingElevationGainMeters:
        profile.elevationGainBetween(along, total),
    currentSlopePercent: profile.slopePercentAtDistance(along) ??
        active.segment.avgSlopePercent,
    avgSegmentSlopePercent: active.segment.avgSlopePercent,
    currentSpeedKmh: rec.currentSpeedKmh,
    avgSpeedInSegmentKmh: avgSpeedInSegmentKmh,
    currentAltitudeMeters: profile.altitudeAtDistance(along) ?? 0,
    heartRateBpm: hr,
    powerWatts: power,
    cadenceRpm: cadence,
    deltaVsPr: active.deltaVsGhost(),
    projectedFinish: projected,
    bestTime: bestSecs != null ? Duration(seconds: bestSecs) : null,
  );
});
