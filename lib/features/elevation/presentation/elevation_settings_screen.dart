import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/srtm_tile_naming.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_platform/core_platform.dart';
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
  static const double _radiusKm = 15;

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
      await ref.read(elevationRepositoryProvider).downloadTiles(
            _missing!,
            onProgress: (p) => setState(() => _progress = p),
          );
      await _loadMissing();
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
              const Expanded(
                child: Text(
                  'Elevación de tu zona (radio de 15 km)',
                  style: TextStyle(
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
                : 'Faltan ${_missing!.length} teselas para cubrir tu '
                    'zona actual.',
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
                              tile.tileName,
                              style: const TextStyle(
                                color: AppColors.textPrimaryOnPanel,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                fontFamily: 'monospace',
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
