import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/srtm_tile_naming.dart';
import '../../../core/ui/ui.dart';
import '../application/elevation_providers.dart';

/// Popup para descargar las teselas de elevación de la zona actual.
/// Devuelve true si se descargó (o ya estaba todo descargado), false si
/// el usuario eligió "Ahora no, usar GPS normal".
Future<bool> showElevationDownloadDialog(
  BuildContext context,
  List<SrtmTileId> missingTiles,
) async {
  if (missingTiles.isEmpty) return true;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ElevationDownloadDialogContent(missingTiles: missingTiles),
  );

  return result ?? false;
}

class _ElevationDownloadDialogContent extends ConsumerStatefulWidget {
  final List<SrtmTileId> missingTiles;

  const _ElevationDownloadDialogContent({required this.missingTiles});

  @override
  ConsumerState<_ElevationDownloadDialogContent> createState() =>
      _ElevationDownloadDialogContentState();
}

class _ElevationDownloadDialogContentState
    extends ConsumerState<_ElevationDownloadDialogContent> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  /// Las que quedan por bajar: al principio todas, y tras un intento
  /// solo las que fallaron.
  late List<SrtmTileId> _pending = widget.missingTiles;

  /// "No volver a pedir estas": al cerrar con "Ahora no" se recuerdan y
  /// la app deja de ofrecerlas antes de grabar (siguen en Ajustes).
  bool _dontAskAgain = false;

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    final result = await ref
        .read(elevationRepositoryProvider)
        .downloadTiles(
          _pending,
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
        );
    if (!mounted) return;
    if (result.ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _downloading = false;
      _pending = result.failed;
      _error =
          'No se pudieron bajar ${result.failed.length} de las teselas '
          '(${result.firstError}). Las demás ya quedaron.';
    });
  }

  Future<void> _notNow() async {
    if (_dontAskAgain) {
      await ref.read(elevationRepositoryProvider).declineTiles(_pending);
    }
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CcColors.surfaceHi,
      title: Text(
        'Mapa de elevación de tu zona',
        style: CcType.displayStyle(size: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Unos 25 MB por tesela SRTM1 (las SRTM3 pesan ~3 MB).
            'Vamos a descargar el mapa de elevación de tu zona '
            '(~${_pending.length * 25} MB) para calcular pendientes con '
            'precisión, sin depender del barómetro del celular.',
            style: const TextStyle(color: CcColors.inkDim, height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _pending
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
                        color: CcColors.inkDim,
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
              value: _progress == 0 ? null : _progress,
              color: CcColors.orange,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: CcColors.danger, fontSize: 12),
            ),
          ],
          if (!_downloading) ...[
            const SizedBox(height: 6),
            CheckboxListTile(
              value: _dontAskAgain,
              onChanged: (v) => setState(() => _dontAskAgain = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: Text(
                'No volver a pedir estas al grabar',
                style: CcType.label(size: 12, color: CcColors.inkDim),
              ),
            ),
          ],
        ],
      ),
      actions: _downloading
          ? []
          : [
              TextButton(
                onPressed: _notNow,
                child: const Text(
                  'Ahora no, usar GPS',
                  style: TextStyle(color: CcColors.inkDim),
                ),
              ),
              FilledButton(
                onPressed: _download,
                style: FilledButton.styleFrom(
                  backgroundColor: CcColors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(_error == null ? 'Descargar' : 'Reintentar'),
              ),
            ],
    );
  }
}
