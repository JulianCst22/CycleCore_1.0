import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/ui.dart';
import '../../application/road_region_providers.dart';

/// "56 MB"; lo que no llega a un mega, "< 1 MB".
String formatMegabytes(int bytes) {
  final mb = bytes / 1e6;
  return mb < 1 ? '< 1 MB' : '${mb.round()} MB';
}

/// "2026-08-23-v3" -> "23 ago 2026".
String formatMapVersion(String version) {
  final date = DateTime.tryParse(
    version.length >= 10 ? version.substring(0, 10) : version,
  );
  if (date == null) return version;
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Lo que se puede hacer con una región ahora: descargarla, ver cómo va,
/// reintentar, actualizarla o nada (ya está). Lo usan la tarjeta de "tu
/// zona" y la lista de departamentos.
class RegionActionButton extends ConsumerWidget {
  final RoadRegion region;

  /// Si el catálogo vino del servidor. Sin él, «Actualizar» no se
  /// ofrece: la copia del teléfono puede ser más vieja que el mapa
  /// instalado. Descargar sí: al tocar se vuelve a buscar el servidor.
  final bool online;

  /// En la lista va en una línea; en la tarjeta, a lo ancho.
  final bool compact;

  const RegionActionButton({
    super.key,
    required this.region,
    required this.online,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final download = ref.watch(regionDownloadsProvider)[region.id];
    final downloaded = <String>{
      for (final d in ref.watch(downloadedRegionsProvider).valueOrNull ?? [])
        d.regionId,
    };
    final versions =
        ref.watch(installedRegionVersionsProvider).valueOrNull ?? const {};
    var status = regionStatus(region, downloaded, versions);
    if (status == RegionStatus.outdated && !online) {
      status = RegionStatus.downloaded;
    }
    final notifier = ref.read(regionDownloadsProvider.notifier);

    if (download != null && !download.failed) {
      return _Progress(progress: download.progress, compact: compact);
    }
    if (download != null && download.failed) {
      return _Failed(
        message: download.error!,
        compact: compact,
        onRetry: () => notifier.download(region),
      );
    }
    switch (status) {
      case RegionStatus.downloaded:
        return compact
            ? const Icon(Icons.check_circle, color: CcColors.ok, size: 22)
            : const _Ready();
      case RegionStatus.outdated:
        return _Action(
          label: compact
              ? 'Actualizar'
              : 'Actualizar (${formatMegabytes(region.downloadBytes)})',
          icon: Icons.system_update_alt,
          compact: compact,
          onPressed: () => notifier.download(region),
        );
      case RegionStatus.notDownloaded:
        return _Action(
          label: compact
              ? formatMegabytes(region.downloadBytes)
              : 'Descargar (${formatMegabytes(region.downloadBytes)})',
          icon: Icons.download,
          compact: compact,
          onPressed: () => notifier.download(region),
        );
    }
  }
}

class _Action extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool compact;
  final VoidCallback? onPressed;

  const _Action({
    required this.label,
    required this.icon,
    required this.compact,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: CcColors.blue,
          side: BorderSide(
            color: onPressed == null ? CcColors.line : CcColors.blue,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          visualDensity: VisualDensity.compact,
          // El tema pide botones a todo el ancho (`Size.fromHeight`); en
          // una fila eso es ancho infinito y la lista entera no se dibuja.
          minimumSize: const Size(0, 36),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: CcColors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final double progress;
  final bool compact;

  const _Progress({required this.progress, required this.compact});

  @override
  Widget build(BuildContext context) {
    final percent = '${(progress * 100).round()} %';
    if (compact) {
      return SizedBox(
        width: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress == 0 ? null : progress,
              color: CcColors.blue,
              backgroundColor: CcColors.line,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 4),
            Text(
              percent,
              style: CcType.label(size: 10.5, color: CcColors.inkDim),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress == 0 ? null : progress,
          color: CcColors.orange,
          backgroundColor: CcColors.line,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 6),
        Text(
          progress == 0 ? 'Empezando la descarga…' : 'Descargando · $percent',
          style: CcType.label(size: 12, color: CcColors.inkDim),
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  final String message;
  final bool compact;
  final VoidCallback? onRetry;

  const _Failed({
    required this.message,
    required this.compact,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return TextButton.icon(
        onPressed: onRetry,
        style: TextButton.styleFrom(
          foregroundColor: CcColors.danger,
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Reintentar'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: const TextStyle(color: CcColors.danger, fontSize: 12),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Reintentar'),
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: CcColors.ok, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Descargado: puedes navegar sin conexión en esta zona.',
            style: CcType.label(size: 12.5, color: CcColors.inkDim),
          ),
        ),
      ],
    );
  }
}

/// Si el teléfono está hablando con el servidor del PC.
class ServerStatusRow extends ConsumerWidget {
  const ServerStatusRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(regionCatalogProvider);
    final (color, text) = catalog.when(
      loading: () => (CcColors.inkFaint, 'Buscando el servidor…'),
      error: (e, _) => (CcColors.danger, 'No se pudo leer el catálogo: $e'),
      data: (snapshot) => snapshot.online
          ? (
              CcColors.ok,
              'Servidor conectado · mapas del '
                  '${formatMapVersion(snapshot.catalog.version)}',
            )
          : (
              CcColors.warn,
              'Sin servidor: lo descargado funciona sin conexión. Para bajar '
                  'mapas, conecta el celular por USB y abre INICIAR '
                  'SERVIDOR.bat en el PC.',
            ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: CcType.label(size: 12, color: CcColors.inkDim),
            ),
          ),
          IconButton(
            tooltip: 'Volver a buscar el servidor',
            onPressed: () => ref.invalidate(regionCatalogProvider),
            icon: const Icon(Icons.refresh, size: 18, color: CcColors.inkDim),
          ),
        ],
      ),
    );
  }
}
