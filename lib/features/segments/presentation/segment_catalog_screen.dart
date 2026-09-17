import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_ui/core_ui.dart';
import '../domain/segment_catalog_entry.dart';
import '../application/segments_providers.dart';

/// Catálogo remoto de segmentos "nativos": la lista que baja del
/// servidor (`SegmentCatalogRepository`), cada uno con un botón para
/// descargarlo. Mismo espíritu que la pantalla de descarga de teselas
/// de elevación / regiones de grafo vial.
class SegmentCatalogScreen extends ConsumerWidget {
  const SegmentCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(segmentCatalogProvider);
    final downloadedIds = ref.watch(downloadedRemoteIdsProvider);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
        title: const Text(
          'Segmentos para descargar',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
      ),
      body: catalogAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => _CatalogError(
          onRetry: () => ref.invalidate(segmentCatalogProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Todavía no hay segmentos oficiales para tu zona.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondaryOnPanel),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(segmentCatalogProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _CatalogTile(
                  entry: entry,
                  alreadyDownloaded: downloadedIds.contains(entry.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  final VoidCallback onRetry;
  const _CatalogError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No se pudo cargar el catálogo. Revisá tu conexión.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Reintentar',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogTile extends ConsumerStatefulWidget {
  final SegmentCatalogEntry entry;
  final bool alreadyDownloaded;

  const _CatalogTile({
    required this.entry,
    required this.alreadyDownloaded,
  });

  @override
  ConsumerState<_CatalogTile> createState() => _CatalogTileState();
}

class _CatalogTileState extends ConsumerState<_CatalogTile> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      await ref
          .read(segmentCatalogRepositoryProvider)
          .downloadAndImport(widget.entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${widget.entry.name}" descargado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo descargar: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final done = widget.alreadyDownloaded;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimaryOnPanel,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (entry.region != null) entry.region!,
                    if (entry.distanceMeters != null)
                      '${formatDistanceKm(entry.distanceMeters!)} km',
                    if (entry.elevationGainMeters != null)
                      '${entry.elevationGainMeters!.toStringAsFixed(0)} m D+',
                    if (entry.avgSlopePercent != null)
                      '${entry.avgSlopePercent!.toStringAsFixed(1)}%',
                  ].join('  ·  '),
                  style: const TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            const Icon(Icons.check_circle, color: AppColors.segmentStart)
          else if (_downloading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.download_for_offline_outlined,
                color: AppColors.primary,
              ),
              onPressed: _download,
              tooltip: 'Descargar',
            ),
        ],
      ),
    );
  }
}
