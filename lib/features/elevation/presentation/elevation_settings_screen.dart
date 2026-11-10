import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/elevation_repository.dart';
import '../domain/elevation_dataset.dart';
import '../domain/srtm_tile_naming.dart';
import '../../../core/ui/ui.dart';
import '../../../core/platform/platform.dart';
import '../application/elevation_providers.dart';

/// Pantalla de Ajustes > Elevación. Antes la descarga de teselas HGT
/// solo aparecía como un diálogo justo antes de "Grabar" -- esta
/// pantalla la saca de ahí y la deja como un panel de estado que
/// podés revisar y gestionar con calma, igual que Navegación.
/// El diálogo (`elevation_download_dialog.dart`) puede seguir
/// existiendo para el caso "me faltan teselas justo antes de salir",
/// pero ya no es el único lugar donde se administra esto.
class ElevationSettingsScreen extends ConsumerWidget {
  const ElevationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionAsync = ref.watch(currentPositionProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Elevación',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _SectionLabel('MODELO DE ELEVACIÓN'),
            const SizedBox(height: 8),
            const _DatasetSelector(),
            const SizedBox(height: 28),
            const _SectionLabel('TU ZONA ACTUAL'),
            const SizedBox(height: 8),
            positionAsync.when(
              loading: () => const _InfoCard(
                icon: null,
                message: 'Buscando tu ubicación…',
                loading: true,
              ),
              error: (e, _) => _InfoCard(
                icon: Icons.error_outline,
                message: 'No se pudo obtener tu ubicación: $e',
              ),
              data: (position) => _CurrentZoneCard(
                lat: position.latitude,
                lng: position.longitude,
              ),
            ),
            const SizedBox(height: 28),
            const _SectionLabel('TESELAS DESCARGADAS'),
            const SizedBox(height: 8),
            const _DownloadedTilesList(),
            const SizedBox(height: 28),
            const _SectionLabel('DATOS DE ELEVACIÓN'),
            const SizedBox(height: 8),
            // Atribución y aviso que exigen las licencias de Copernicus
            // (artículo 6) y de FABDEM (CC BY-NC-SA 4.0).
            const _InfoCard(
              icon: Icons.info_outline,
              message: 'Producido con Copernicus WorldDEM-30 © DLR e.V. '
                  '2010-2014 y © Airbus Defence and Space GmbH 2014-2018, '
                  'provisto bajo COPERNICUS por la Unión Europea y la ESA; '
                  'todos los derechos reservados. Los organismos a cargo '
                  'del programa Copernicus no asumen ninguna '
                  'responsabilidad por el uso de Copernicus WorldDEM-30.',
            ),
            const SizedBox(height: 8),
            const _InfoCard(
              icon: Icons.info_outline,
              message: 'FABDEM V1-2 (Hawker et al., 2022, Universidad de '
                  'Bristol / Fathom), licencia CC BY-NC-SA 4.0, solo uso '
                  'no comercial: el modelo Copernicus sin edificios ni '
                  'árboles.',
            ),
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

class _InfoCard extends StatelessWidget {
  final IconData? icon;
  final String message;
  final bool loading;

  const _InfoCard({
    required this.icon,
    required this.message,
    this.loading = false,
  });

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
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else if (icon != null)
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

/// Tarjeta con las teselas que faltan/sobran para un radio alrededor
/// de tu posición actual -- mismo cálculo que ya usás antes de
/// grabar (`missingTilesForRadius`), pero ahora accesible desde
/// Ajustes en cualquier momento.
class _CurrentZoneCard extends ConsumerStatefulWidget {
  final double lat;
  final double lng;
  const _CurrentZoneCard({required this.lat, required this.lng});

  @override
  ConsumerState<_CurrentZoneCard> createState() => _CurrentZoneCardState();
}

class _CurrentZoneCardState extends ConsumerState<_CurrentZoneCard> {
  static const double _radiusKm = elevationDownloadRadiusKm;

  bool _downloading = false;
  double _progress = 0;
  String? _error;
  List<SrtmTileId>? _missing;

  @override
  void initState() {
    super.initState();
    _loadMissing();
  }

  Future<void> _loadMissing() async {
    final repo = ref.read(elevationRepositoryProvider);
    final missing = await repo.missingTilesForRadius(
      centerLat: widget.lat,
      centerLng: widget.lng,
      radiusKm: _radiusKm,
      dataset: ref.read(elevationDatasetProvider),
    );
    if (mounted) setState(() => _missing = missing);
  }

  Future<void> _download() async {
    if (_missing == null || _missing!.isEmpty) return;
    setState(() {
      _downloading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(elevationRepositoryProvider)
          .downloadTiles(
            _missing!,
            dataset: ref.read(elevationDatasetProvider),
            onProgress: (p) => setState(() => _progress = p),
          );
      await _loadMissing();
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = result.ok
              ? null
              : 'No se pudieron bajar ${result.failed.join(', ')}: '
                    '${result.firstError}';
        });
      }
    } catch (e) {
      setState(() {
        _downloading = false;
        _error = 'No se pudo descargar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Al cambiar de modelo se revisan las teselas de ese modelo.
    ref.listen(elevationDatasetProvider, (_, _) {
      setState(() => _missing = null);
      _loadMissing();
    });
    final dataset = ref.watch(elevationDatasetProvider);
    if (_missing == null) {
      return const _InfoCard(icon: null, message: 'Revisando teselas…', loading: true);
    }

    final allDownloaded = _missing!.isEmpty;

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
                allDownloaded
                    ? Icons.check_circle
                    : Icons.download_for_offline_outlined,
                color: allDownloaded
                    ? AppColors.accentElevation
                    : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${dataset.label}: tu zona (radio de '
                  '${elevationDownloadRadiusKm.round()} km)',
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
            allDownloaded
                ? 'Ya tenés todas las teselas de esta zona -- las '
                    'pendientes se calculan con precisión profesional.'
                : 'Faltan o hay que actualizar ${_missing!.length} '
                    'teselas para cubrir tu zona actual.',
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
          if (!allDownloaded && !_downloading) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _download,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Descargar teselas de mi zona'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DownloadedTilesList extends ConsumerWidget {
  const _DownloadedTilesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(elevationRepositoryProvider);

    return StreamBuilder(
      stream: repo.watchDownloadedTiles(),
      builder: (context, snapshot) {
        final tiles = snapshot.data ?? [];
        if (tiles.isEmpty) {
          return const _InfoCard(
            icon: Icons.info_outline,
            message: 'Todavía no descargaste ninguna tesela.',
          );
        }

        return Column(
          children: tiles.map((tile) {
            final sizeMb = (tile.sizeBytes / (1024 * 1024)).toStringAsFixed(1);
            final key = ElevationRepository.splitKey(tile.tileName);
            final dataset = ElevationDataset.byId(key.datasetId);
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
                      const Icon(Icons.terrain_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              key.fileName,
                              style: const TextStyle(
                                color: AppColors.textPrimaryOnPanel,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${dataset?.label ?? 'SRTM (anterior, '
                                        'ya no se usa)'} · $sizeMb MB',
                                    style: const TextStyle(
                                      color: AppColors.textSecondaryOnPanel,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                                if (dataset?.isPremium ?? false) ...[
                                  const SizedBox(width: 6),
                                  const PremiumBadge(),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.textSecondaryOnPanel, size: 20),
                        onPressed: () =>
                            ref.read(elevationRepositoryProvider).deleteTile(
                                  tile.tileName,
                                ),
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

/// Qué modelo de elevación usar: Copernicus (estándar) o FABDEM
/// (premium). Cambiarlo solo afecta a las salidas nuevas; una salida ya
/// guardada se cambia en "Ajustar altimetría".
class _DatasetSelector extends ConsumerWidget {
  const _DatasetSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(elevationDatasetProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final dataset in ElevationDataset.values) ...[
          _DatasetOption(
            dataset: dataset,
            selected: dataset == selected,
            onTap: () =>
                ref.read(elevationDatasetProvider.notifier).select(dataset),
          ),
          const SizedBox(height: 8),
        ],
        const Text(
          'Cambiar el modelo solo afecta a las salidas nuevas. Para una '
          'salida ya guardada, usa "Ajustar altimetría" en la actividad.',
          style: TextStyle(color: AppColors.textSecondaryOnPanel, fontSize: 12),
        ),
      ],
    );
  }
}

class _DatasetOption extends StatelessWidget {
  final ElevationDataset dataset;
  final bool selected;
  final VoidCallback onTap;

  const _DatasetOption({
    required this.dataset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondaryOnPanel,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            dataset.label,
                            style: const TextStyle(
                              color: AppColors.textPrimaryOnPanel,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        if (dataset.isPremium) ...[
                          const SizedBox(width: 8),
                          const PremiumBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dataset.summary,
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
