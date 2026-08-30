import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../data/gpx_segment_importer.dart';
import 'segment_catalog_screen.dart';
import 'segment_detail_screen.dart';
import 'segment_import_preview_screen.dart';
import 'segments_providers.dart';

/// Menú de segmentos del usuario: la lista completa (activos e
/// inactivos) con un toggle por segmento que decide si
/// `SegmentDetectionService` (Fase 5) lo vigila mientras se pedalea.
/// No hay concepto de "descarga" todavía -- todo es local, como se
/// definió para este alcance.
///
/// Ahora es una sección de primer nivel de la app (pestaña "Segmentos"
/// en `AppBottomNavBar`, en el lugar que antes ocupaba "Sensores").
class SegmentsListScreen extends ConsumerWidget {
  const SegmentsListScreen({super.key});

  Future<void> _importFromGpx(BuildContext context, WidgetRef ref) async {
    // `FileType.any` abre el explorador de archivos / Documentos del
    // sistema (SAF en Android) mostrando TODO -- el filtro por
    // extensión `.gpx` no funciona bien en Android porque `gpx` no es
    // un MIME type reconocido y el picker termina sin abrir nada. Así
    // que dejamos elegir cualquier archivo y validamos la extensión
    // nosotros después.
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el explorador: $e')),
        );
      }
      return;
    }
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.single;

    final name = file.name.toLowerCase();
    if (!name.endsWith('.gpx')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Elegí un archivo .gpx (ese no lo es).'),
          ),
        );
      }
      return;
    }

    String xml;
    try {
      final bytes = file.bytes;
      if (bytes != null) {
        xml = utf8.decode(bytes);
      } else if (file.path != null) {
        xml = await File(file.path!).readAsString();
      } else {
        throw const GpxImportException('No se pudo leer el archivo elegido.');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo leer el GPX: $e')),
        );
      }
      return;
    }

    GpxImportResult result;
    try {
      result = const GpxSegmentImporter().parse(xml);
    } on GpxImportException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    if (!context.mounted) return;
    final createdId = await Navigator.of(context).push<int?>(
      MaterialPageRoute(
        builder: (_) => SegmentImportPreviewScreen(result: result),
      ),
    );
    if (createdId != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Segmento importado.')),
      );
    }
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Segment segment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panelBackground,
        title: const Text(
          '¿Eliminar segmento?',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        content: Text(
          '"${segment.name}" se va a borrar. Los esfuerzos ya '
          'guardados sobre él también se pierden.',
          style: const TextStyle(color: AppColors.textSecondaryOnPanel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.recordButtonActive),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(segmentsRepositoryProvider).delete(segment.id);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentsAsync = ref.watch(segmentsListProvider);

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
        title: const Text(
          'Mis segmentos',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.add,
              color: AppColors.textPrimaryOnPanel,
            ),
            color: AppColors.panelBackground,
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _importFromGpx(context, ref);
                case 'catalog':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SegmentCatalogScreen(),
                    ),
                  );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'import',
                child: Text(
                  'Importar GPX',
                  style: TextStyle(color: AppColors.textPrimaryOnPanel),
                ),
              ),
              PopupMenuItem(
                value: 'catalog',
                child: Text(
                  'Descargar segmentos',
                  style: TextStyle(color: AppColors.textPrimaryOnPanel),
                ),
              ),
            ],
          ),
        ],
      ),
      body: segmentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => const Center(
          child: Text(
            'No se pudieron cargar tus segmentos.',
            style: TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ),
        data: (segments) {
          if (segments.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: segments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final segment = segments[index];
              return Dismissible(
                key: ValueKey(segment.id),
                direction: DismissDirection.endToStart,
                // No borra al deslizar directamente -- pide
                // confirmación primero y solo se completa el swipe si
                // el usuario confirma, para evitar borrados por error.
                confirmDismiss: (_) => _confirmDelete(context, ref, segment),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.recordButtonActive.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: _SegmentTile(segment: segment),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 40, color: AppColors.textSecondaryOnPanel),
            SizedBox(height: 12),
            Text(
              'Todavía no tienes segmentos.\n\n'
              'Créalos desde el detalle de una actividad, importa un GPX '
              'o descarga los oficiales con el botón "+" de arriba.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTile extends ConsumerWidget {
  final Segment segment;

  const _SegmentTile({required this.segment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            // Toca el nombre/stats para ir al detalle (mapa,
            // altimetría, mejor tiempo e historial de esfuerzos) --
            // el switch de al lado queda fuera de este gesto para no
            // competir con el toggle de activo/inactivo.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SegmentDetailScreen(segmentId: segment.id),
                ),
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  segment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimaryOnPanel,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _InlineStat(
                      icon: Icons.straighten,
                      value: '${formatDistanceKm(segment.distanceMeters)} km',
                    ),
                    const SizedBox(width: 12),
                    _InlineStat(
                      icon: Icons.terrain,
                      value:
                          '${segment.elevationGainMeters.toStringAsFixed(0)} m',
                    ),
                    const SizedBox(width: 12),
                    _InlineStat(
                      icon: Icons.trending_up,
                      value: formatSlopePercent(segment.avgSlopePercent),
                      accentColor: AppColors.accentSlope,
                    ),
                  ],
                ),
              ],
              ),
            ),
          ),
          Switch(
            value: segment.isActive,
            activeColor: AppColors.primary,
            onChanged: (value) => ref
                .read(segmentsRepositoryProvider)
                .setActive(segment.id, value),
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? accentColor;

  const _InlineStat({
    required this.icon,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.textSecondaryOnPanel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}