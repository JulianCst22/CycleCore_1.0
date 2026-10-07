import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/ui.dart';
import '../../../recording/recording.dart' show secondTickerProvider;
import '../../application/extension_points.dart';
import '../../application/segment_detection_providers.dart';

/// Lo que se ve sobre el mapa mientras el ciclista está dentro de un
/// segmento y tiene el panel recogido: UNA tarjeta, no dos.
///
/// Arriba, el tramo (nombre, tiempo, avance, cuánto falta y la
/// diferencia con la mejor marca); abajo, en la misma tarjeta, la franja
/// del coach (punto de extensión `segmentLiveNoticeProvider`). Antes eran
/// dos tarjetas apiladas que tapaban medio mapa.
class SegmentLiveBanner extends ConsumerWidget {
  const SegmentLiveBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(segmentDetectionProvider).active;
    if (active == null) return const SizedBox.shrink();

    // Refresca el tiempo/delta cada segundo aunque no llegue un punto GPS.
    ref.watch(secondTickerProvider);
    final notice = ref.watch(segmentLiveNoticeProvider);

    final delta = active.deltaVsGhost();
    final km = (active.remainingMeters / 1000)
        .toStringAsFixed(active.remainingMeters >= 1000 ? 1 : 2)
        .replaceAll('.', ',');

    return Material(
      color: CcColors.glassDeep,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flag,
                  color: CcColors.segmentActiveTrack,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    active.segment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcType.label(size: 13, color: CcColors.ink),
                  ),
                ),
                Text(
                  '$km km',
                  style: CcType.displayStyle(size: 15, weight: FontWeight.w800),
                ),
                const SizedBox(width: 10),
                if (delta != null)
                  Text(
                    delta.inSeconds == 0
                        ? '= PR'
                        : '${formatSignedDuration(delta)} PR',
                    style: CcType.label(
                      size: 12,
                      weight: FontWeight.w700,
                      color: delta.inSeconds == 0
                          ? CcColors.inkDim
                          : (delta.isNegative
                                ? CcColors.ghostAhead
                                : CcColors.ghostBehind),
                    ),
                  )
                else
                  Text(
                    formatElapsedShort(active.elapsedNow()),
                    style: CcType.label(size: 12, color: CcColors.inkDim),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: active.progressFraction,
                minHeight: 4,
                backgroundColor: CcColors.line,
                valueColor: const AlwaysStoppedAnimation(
                  CcColors.segmentActiveTrack,
                ),
              ),
            ),
            if (notice != null) ...[const SizedBox(height: 8), notice],
          ],
        ),
      ),
    );
  }
}
