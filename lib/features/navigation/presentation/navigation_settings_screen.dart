import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/ui/ui.dart';
import '../application/navigation_providers.dart';
import 'region_picker_screen.dart';
import 'widgets/region_widgets.dart';

/// Ajustes › Navegación: el mapa vial para trazar rutas sin conexión.
///
/// Arriba, dónde estás y el mapa que te sirve ("Estás en Bogotá · Bogotá
/// y Cundinamarca"); después, el acceso a los demás departamentos y lo
/// que ya tienes descargado. Los mapas vienen del servidor del PC
/// (carpeta "Servidor CycleCore" del escritorio): al entrar se le vuelve
/// a preguntar el catálogo, por si se acaba de prender.
class NavigationSettingsScreen extends ConsumerStatefulWidget {
  const NavigationSettingsScreen({super.key});

  @override
  ConsumerState<NavigationSettingsScreen> createState() =>
      _NavigationSettingsScreenState();
}

class _NavigationSettingsScreenState
    extends ConsumerState<NavigationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(regionCatalogProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lo que cambie acá (descargas, borrados) cambia el botón "Navegar"
    // del mapa.
    ref.listen(downloadedRegionsProvider, (_, _) {
      ref.invalidate(hasNavigationDataProvider);
    });
    final regionCount =
        ref.watch(regionCatalogProvider).valueOrNull?.catalog.regions.length ??
        0;

    return Scaffold(
      appBar: AppBar(title: const Text('Navegación')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const ServerStatusRow(),
            const SizedBox(height: 22),
            const _Label('TU ZONA'),
            const SizedBox(height: 8),
            const _HereCard(),
            const SizedBox(height: 22),
            const _Label('OTRAS REGIONES'),
            const SizedBox(height: 8),
            _Tile(
              icon: Icons.map_outlined,
              title: 'Mapas por departamento',
              subtitle: regionCount == 0
                  ? 'Conecta el servidor para ver la lista'
                  : 'Los $regionCount mapas · descarga los que necesites',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RegionPickerScreen(),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _Label('EN ESTE TELÉFONO'),
            const SizedBox(height: 8),
            const _DownloadedList(),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: CcType.label(
      size: 11,
      color: CcColors.inkFaint,
    ).copyWith(letterSpacing: 1.2),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: CcColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CcColors.line),
    ),
    child: child,
  );
}

/// Dónde estás y el mapa que te sirve.
class _HereCard extends ConsumerWidget {
  const _HereCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final here = ref.watch(currentRegionProvider);
    final online =
        ref.watch(regionCatalogProvider).valueOrNull?.online ?? false;

    return here.when(
      loading: () => const _Card(
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Buscando dónde estás…',
              style: TextStyle(color: CcColors.inkDim),
            ),
          ],
        ),
      ),
      error: (e, _) => _Card(
        child: Text(
          'No se pudo obtener tu ubicación: $e',
          style: const TextStyle(color: CcColors.inkDim),
        ),
      ),
      data: (found) {
        if (found == null) {
          return _Card(
            child: Text(
              'Tu ubicación no está en ninguno de los mapas. Búscalo en '
              '«Mapas por departamento».',
              style: const TextStyle(color: CcColors.inkDim),
            ),
          );
        }
        final region = found.region;
        final place = found.part?.name ?? region.name;
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: CcColors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: CcColors.blue,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estás en $place',
                          style: CcType.displayStyle(
                            size: 18,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tu mapa: ${region.name} · '
                          '${formatMegabytes(region.downloadBytes)}',
                          style: CcType.label(size: 12, color: CcColors.inkDim),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              RegionActionButton(region: region, online: online),
            ],
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CcColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CcColors.line),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: onTap == null ? CcColors.inkFaint : CcColors.blue,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CcType.label(size: 14, color: CcColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: CcType.label(size: 11.5, color: CcColors.inkDim),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: onTap == null ? CcColors.lineSoft : CcColors.inkDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Los mapas guardados en el teléfono, con su tamaño y para borrarlos.
class _DownloadedList extends ConsumerWidget {
  const _DownloadedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloaded =
        ref.watch(downloadedRegionsProvider).valueOrNull ?? const [];
    final catalog = ref.watch(regionCatalogProvider).valueOrNull?.catalog;
    final versions =
        ref.watch(installedRegionVersionsProvider).valueOrNull ?? const {};

    if (downloaded.isEmpty) {
      return const _Card(
        child: Text(
          'Todavía no descargaste ningún mapa.',
          style: TextStyle(color: CcColors.inkDim),
        ),
      );
    }
    return Column(
      children: [
        for (final entry in downloaded)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DownloadedRow(
              entry: entry,
              region: catalog?.byId(entry.regionId),
              catalogKnown: (catalog?.regions.isNotEmpty ?? false),
              installedVersion: versions[entry.regionId],
            ),
          ),
      ],
    );
  }
}

class _DownloadedRow extends ConsumerWidget {
  final DownloadedRoadRegion entry;
  final RoadRegion? region;
  final bool catalogKnown;
  final String? installedVersion;

  const _DownloadedRow({
    required this.entry,
    required this.region,
    required this.catalogKnown,
    required this.installedVersion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Un mapa que el catálogo ya no tiene es del formato viejo (el de
    // "Bogotá y Cundinamarca" con las trochas): no se usa para rutear.
    final obsolete = catalogKnown && region == null;
    final outdated =
        region != null && installedVersion != region!.version && !obsolete;
    final name = region?.name ?? (obsolete ? 'Mapa anterior' : entry.regionId);
    final detail = obsolete
        ? 'Ya no se usa: bórralo y descarga el de tu zona'
        : outdated
        ? 'Hay una versión más nueva'
        : installedVersion == null
        ? formatMegabytes(entry.sizeBytes)
        : '${formatMegabytes(entry.sizeBytes)} · mapa del '
              '${formatMapVersion(installedVersion!)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Row(
        children: [
          Icon(
            obsolete ? Icons.warning_amber : Icons.map,
            color: obsolete
                ? CcColors.warn
                : (outdated ? CcColors.orange : CcColors.ok),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: CcType.label(size: 13.5, color: CcColors.ink),
                ),
                Text(
                  detail,
                  style: CcType.label(size: 11, color: CcColors.inkDim),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Borrar',
            icon: const Icon(Icons.delete_outline, color: CcColors.inkDim),
            onPressed: () => _confirmDelete(context, ref, name),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Borrar $name', style: CcType.displayStyle(size: 18)),
        content: const Text(
          'Se libera el espacio. Para volver a navegar en esa zona tendrás '
          'que descargarlo de nuevo con el servidor.',
          style: TextStyle(color: CcColors.inkDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CcColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(regionDownloadsProvider.notifier).delete(entry.regionId);
    }
  }
}
