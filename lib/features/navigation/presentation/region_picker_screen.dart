import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ui.dart';
import '../application/road_region_providers.dart';
import 'widgets/region_widgets.dart';

/// Todos los mapas que publica el servidor, por departamento, para
/// descargar los que hagan falta (salir a rodar a Boyacá, un viaje a
/// Antioquia...). La lista es la del servidor: si no contesta, la última
/// que mandó; y al tocar «Descargar» se le vuelve a preguntar. La región
/// donde estás va arriba.
class RegionPickerScreen extends ConsumerStatefulWidget {
  const RegionPickerScreen({super.key});

  @override
  ConsumerState<RegionPickerScreen> createState() => _RegionPickerScreenState();
}

class _RegionPickerScreenState extends ConsumerState<RegionPickerScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Al entrar se vuelve a buscar el servidor, por si se prendió
    // después de abrir Ajustes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(regionCatalogProvider);
    });
  }

  static String _plain(String s) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    final lower = s.toLowerCase();
    final buffer = StringBuffer();
    for (final c in lower.split('')) {
      final i = from.indexOf(c);
      buffer.write(i >= 0 ? to[i] : c);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Una descarga que falla lo dice en grande: en la fila solo cabe
    // «Reintentar».
    ref.listen(regionDownloadsProvider, (before, now) {
      for (final MapEntry(key: id, value: download) in now.entries) {
        final error = download.error;
        if (error == null || before?[id]?.error == error) continue;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
      }
    });

    final catalogAsync = ref.watch(regionCatalogProvider);
    final snapshot = catalogAsync.valueOrNull;
    final regions = snapshot?.catalog.regions ?? const <RoadRegion>[];
    final online = snapshot?.online ?? false;
    final hereId = ref.watch(currentRegionProvider).valueOrNull?.region.id;

    final query = _plain(_query.trim());
    final shown =
        [
          for (final r in regions)
            if (query.isEmpty ||
                _plain(r.name).contains(query) ||
                r.parts.any((p) => _plain(p.name).contains(query)))
              r,
        ]..sort((a, b) {
          if (a.id == hereId) return -1;
          if (b.id == hereId) return 1;
          return _plain(a.name).compareTo(_plain(b.name));
        });

    return Scaffold(
      appBar: AppBar(title: const Text('Mapas por departamento')),
      body: SafeArea(
        child: RefreshIndicator(
          color: CcColors.orange,
          onRefresh: () => ref.refresh(regionCatalogProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              const ServerStatusRow(),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Filtrar por nombre',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: CcColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                query.isEmpty
                    ? 'TODOS LOS DEPARTAMENTOS · ${regions.length}'
                    : 'COINCIDEN · ${shown.length}',
                style: CcType.label(
                  size: 11,
                  color: CcColors.inkFaint,
                ).copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              if (regions.isEmpty && catalogAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: CcColors.orange),
                  ),
                )
              else if (regions.isEmpty)
                _NoServer(
                  onRetry: () => ref.refresh(regionCatalogProvider.future),
                ),
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _RegionRow(
                  region: shown[i],
                  isHere: shown[i].id == hereId,
                  online: online,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Sin servidor y sin una lista guardada de antes: qué hacer para verla.
class _NoServer extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _NoServer({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'La lista de mapas la manda el servidor',
            style: CcType.displayStyle(size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '1. Conecta el celular al PC por USB.\n'
            '2. Abre INICIAR SERVIDOR.bat (carpeta «Servidor CycleCore» del '
            'escritorio) y espera «Celular conectado».\n'
            '3. Toca «Buscar de nuevo» o desliza la lista hacia abajo.',
            style: CcType.label(
              size: 12.5,
              color: CcColors.inkDim,
              weight: FontWeight.w400,
            ).copyWith(height: 1.5),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: CcColors.blue,
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Buscar de nuevo'),
          ),
        ],
      ),
    );
  }
}

class _RegionRow extends StatelessWidget {
  final RoadRegion region;
  final bool isHere;
  final bool online;

  const _RegionRow({
    required this.region,
    required this.isHere,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    final includes = region.parts.length > 1
        ? 'Incluye ${region.parts.map((p) => p.name).join(' y ')}'
        : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHere
              ? CcColors.blue.withValues(alpha: 0.6)
              : CcColors.lineSoft,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        region.name,
                        overflow: TextOverflow.ellipsis,
                        style: CcType.label(size: 14, color: CcColors.ink),
                      ),
                    ),
                    if (isHere) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CcColors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Estás aquí',
                          style: CcType.label(size: 10, color: CcColors.blue),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  includes ?? 'Mapa vial para bici de ruta',
                  style: CcType.label(size: 11, color: CcColors.inkDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RegionActionButton(region: region, online: online, compact: true),
        ],
      ),
    );
  }
}
