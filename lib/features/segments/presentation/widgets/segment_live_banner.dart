import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../geospatial/presentation/map_providers.dart'
    show secondTickerProvider;
import '../segment_detection_providers.dart';

/// Banner compacto que aparece sobre el mapa mientras el ciclista está
/// dentro de un segmento vigilado (Fase C). La pantalla de segmento
/// completa y editable llega en la Fase D -- esto es lo mínimo para
/// probar la detección en campo: nombre, barra de progreso, cuánto
/// falta, tu tiempo y (si hay mejor marca con splits) el delta contra
/// el fantasma.
class SegmentLiveBanner extends ConsumerWidget {
  const SegmentLiveBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(segmentDetectionProvider).active;
    if (active == null) return const SizedBox.shrink();

    // Refresca el tiempo/delta cada segundo aunque no llegue un punto GPS.
    ref.watch(secondTickerProvider);

    final delta = active.deltaVsGhost();

    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flag,
                  color: AppColors.segmentActiveTrack,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    active.segment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimaryOnPanel,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  formatElapsedShort(active.elapsedNow()),
                  style: const TextStyle(
                    color: AppColors.textPrimaryOnPanel,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: active.progressFraction,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.segmentActiveTrack,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Faltan ${formatDistanceKm(active.remainingMeters)} km',
                  style: const TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (delta != null)
                  Text(
                    delta.inSeconds == 0
                        ? 'igual que tu PR'
                        : '${formatSignedDuration(delta)} vs PR',
                    style: TextStyle(
                      color: delta.isNegative
                          ? AppColors.ghostAhead
                          : (delta.inSeconds == 0
                              ? AppColors.textSecondaryOnPanel
                              : AppColors.ghostBehind),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (active.bestEffort == null)
                  const Text(
                    'primer intento',
                    style: TextStyle(
                      color: AppColors.textSecondaryOnPanel,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
