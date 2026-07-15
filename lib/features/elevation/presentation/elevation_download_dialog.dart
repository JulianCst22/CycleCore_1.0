import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/elevation/srtm_tile_naming.dart';
import '../../../core/theme/app_colors.dart';
import 'elevation_providers.dart';

/// Popup para descargar las teselas de elevación de la zona actual.
/// Devuelve true si se descargó (o ya estaba todo descargado), false si
/// el usuario eligió "Ahora no, usar GPS normal".
Future<bool> showElevationDownloadDialog(
  BuildContext context,
  List<SrtmTileId> missingTiles,
) async {
  if (missingTiles.isEmpty) return true;

  // Estimación aproximada: ajusta este número según la resolución que
  // termines subiendo a tu bucket (SRTM3 ~2-3 MB/tesela, SRTM1 ~25 MB).
  final estimatedMb = missingTiles.length * 25;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ElevationDownloadDialogContent(
      missingTiles: missingTiles,
      estimatedMb: estimatedMb,
    ),
  );

  return result ?? false;
}

class _ElevationDownloadDialogContent extends ConsumerStatefulWidget {
  final List<SrtmTileId> missingTiles;
  final int estimatedMb;

  const _ElevationDownloadDialogContent({
    required this.missingTiles,
    required this.estimatedMb,
  });

  @override
  ConsumerState<_ElevationDownloadDialogContent> createState() =>
      _ElevationDownloadDialogContentState();
}

class _ElevationDownloadDialogContentState
    extends ConsumerState<_ElevationDownloadDialogContent> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _error = null;
    });

    try {
      await ref
          .read(elevationRepositoryProvider)
          .downloadTiles(
            widget.missingTiles,
            onProgress: (p) => setState(() => _progress = p),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _downloading = false;
        _error = 'No se pudo descargar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.panelBackground,
      title: const Text(
        'Mapa de elevación de tu zona',
        style: TextStyle(color: AppColors.textPrimaryOnPanel),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vamos a descargar el mapa de elevación de tu zona '
            '(~${widget.estimatedMb} MB) para calcular pendientes con '
            'precisión profesional, sin depender del barómetro del '
            'celular.',
            style: const TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.missingTiles
                .map(
                  (tile) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tile.fileName,
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (_downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              color: AppColors.primary,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 6),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: AppColors.textSecondaryOnPanel,
                fontSize: 12,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.recordButtonActive,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: _downloading
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Ahora no, usar GPS normal',
                  style: TextStyle(color: AppColors.textSecondaryOnPanel),
                ),
              ),
              ElevatedButton(
                onPressed: _download,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Descargar ahora'),
              ),
            ],
    );
  }
}
