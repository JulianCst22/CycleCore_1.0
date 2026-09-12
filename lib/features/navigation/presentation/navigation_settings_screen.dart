import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/navigation/road_region_id.dart';
import 'package:cyclecore_core/theme/app_colors.dart';
import 'navigation_providers.dart';

/// Pantalla de Ajustes > Navegación. A diferencia del diálogo de
/// elevación (que aparece justo antes de grabar), acá la detección de
/// región es automática apenas entrás a la pantalla -- el usuario
/// prepara la descarga con calma antes de salir a andar, no en el
/// momento de dar "Grabar".
class NavigationSettingsScreen extends ConsumerWidget {
  const NavigationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionAsync = ref.watch(currentRoadRegionProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Navegación',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _SectionLabel('TU ZONA ACTUAL'),
            const SizedBox(height: 8),
            regionAsync.when(
              loading: () => const _RegionCardLoading(),
              error: (e, _) => _RegionCardMessage(
                icon: Icons.error_outline,
                message: 'No se pudo obtener tu ubicación: $e',
              ),
              data: (region) => region == null
                  ? const _RegionCardMessage(
                      icon: Icons.location_off,
                      message:
                          'Todavía no hay mapa vial disponible para tu '
                          'zona actual.',
                    )
                  : _CurrentRegionCard(region: region),
            ),
            const SizedBox(height: 28),
            const _SectionLabel('REGIONES DESCARGADAS'),
            const SizedBox(height: 8),
            const _DownloadedRegionsList(),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondaryOnPanel,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _RegionCardLoading extends StatelessWidget {
  const _RegionCardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Buscando tu ubicación…',
            style: TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ],
      ),
    );
  }
}

class _RegionCardMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  const _RegionCardMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondaryOnPanel, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con la región donde estás parado ahora -- muestra estado
/// (descargada / disponible para descargar), tamaño estimado y
/// progreso de descarga.
class _CurrentRegionCard extends ConsumerStatefulWidget {
  final RoadRegionId region;
  const _CurrentRegionCard({required this.region});

  @override
  ConsumerState<_CurrentRegionCard> createState() =>
      _CurrentRegionCardState();
}

class _CurrentRegionCardState extends ConsumerState<_CurrentRegionCard> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _error = null;
    });
    try {
      await ref.read(roadRegionRepositoryProvider).downloadRegion(
            widget.region,
            onProgress: (p) => setState(() => _progress = p),
          );
      // Refresca hasNavigationDataProvider / currentRoadRegionProvider
      // para que el resto de la app se entere de inmediato.
      ref.invalidate(hasNavigationDataProvider);
      if (mounted) setState(() => _downloading = false);
    } catch (e) {
      setState(() {
        _downloading = false;
        _error = 'No se pudo descargar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ref
          .read(roadRegionRepositoryProvider)
          .isRegionDownloaded(widget.region.id),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isDownloaded
                        ? Icons.check_circle
                        : Icons.download_for_offline_outlined,
                    color: isDownloaded
                        ? AppColors.accentElevation
                        : AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.region.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnPanel,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isDownloaded
                    ? 'Ya podés navegar sin conexión en esta zona.'
                    : 'Descargá el mapa vial de esta zona para poder '
                        'trazar rutas y recibir indicaciones por voz, '
                        'sin depender de internet mientras andás.',
                style: const TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                  fontSize: 12.5,
                ),
              ),
              if (_downloading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progress,
                  color: AppColors.primary,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.recordButtonActive,
                    fontSize: 12,
                  ),
                ),
              ],
              if (!isDownloaded && !_downloading) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _download,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Descargar mapa de navegación'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DownloadedRegionsList extends ConsumerWidget {
  const _DownloadedRegionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(roadRegionRepositoryProvider);

    return StreamBuilder(
      stream: repo.watchDownloadedRegions(),
      builder: (context, snapshot) {
        final regions = snapshot.data ?? [];
        if (regions.isEmpty) {
          return const _RegionCardMessage(
            icon: Icons.info_outline,
            message: 'Todavía no descargaste ninguna región.',
          );
        }

        return Column(
          children: regions.map((entry) {
            final catalogRegion = RoadRegionId.byId(entry.regionId);
            final sizeMb = (entry.sizeBytes / (1024 * 1024)).toStringAsFixed(1);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              catalogRegion?.displayName ?? entry.regionId,
                              style: const TextStyle(
                                color: AppColors.textPrimaryOnPanel,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              '$sizeMb MB',
                              style: const TextStyle(
                                color: AppColors.textSecondaryOnPanel,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.textSecondaryOnPanel, size: 20),
                        onPressed: () async {
                          await repo.deleteRegion(entry.regionId);
                          ref.invalidate(hasNavigationDataProvider);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
