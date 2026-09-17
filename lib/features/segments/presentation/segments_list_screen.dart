import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_database/core_database.dart';
import 'package:core_ui/core_ui.dart';
import '../data/gpx_segment_importer.dart';
import 'package:core_geo/core_geo.dart';
import '../domain/segment_source.dart';
import '../domain/segments_overview.dart';
import 'segment_catalog_screen.dart';
import 'segment_detail_screen.dart';
import 'segment_import_preview_screen.dart';
import '../application/segments_providers.dart';
import 'widgets/segment_route_thumbnail.dart';
import '../domain/segment_profile_access.dart';

/// Menú de segmentos del usuario -- rediseñado como un registro de
/// entrenamiento de tus tramos, no un inventario: un panel con las
/// cifras, un feed de tus últimos esfuerzos (con el delta contra tu
/// PR) y la lista en tarjetas visuales con la forma de cada segmento.
///
/// Es la pestaña "Segmentos" del `AppBottomNavBar` (índice 1).
class SegmentsListScreen extends ConsumerWidget {
  /// Lleva al historial de actividades, desde donde se crea un segmento
  /// a partir de una ruta propia. Cambiar de pestaña es cosa de quien las
  /// arma (`AppShell`), así que se inyecta; sin él, el botón solo muestra
  /// la indicación.
  final VoidCallback? onBrowseActivities;

  const SegmentsListScreen({super.key, this.onBrowseActivities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(segmentsOverviewProvider);

    return Scaffold(
      backgroundColor: CcColors.bg,
      body: overviewAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CcColors.orange),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No se pudieron cargar tus segmentos.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CcColors.inkDim),
            ),
          ),
        ),
        data: (overview) => _Content(
          overview: overview,
          onBrowseActivities: onBrowseActivities,
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  final SegmentsOverview overview;
  final VoidCallback? onBrowseActivities;

  const _Content({required this.overview, this.onBrowseActivities});

  // --- Añadir segmentos --------------------------------------------

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: CcColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CcColors.inkFaint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(
                Icons.travel_explore,
                color: CcColors.segmentActiveTrack,
              ),
              title: const Text(
                'Descargar segmentos de tu zona',
                style: TextStyle(color: CcColors.ink),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SegmentCatalogScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.upload_file_outlined,
                color: CcColors.blue,
              ),
              title: const Text(
                'Importar un archivo GPX',
                style: TextStyle(color: CcColors.ink),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _importFromGpx(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _goToActivitiesToCreate(BuildContext context) {
    onBrowseActivities?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Abre una actividad y toca "Crear segmento desde esta ruta".',
        ),
      ),
    );
  }

  Future<void> _importFromGpx(BuildContext context, WidgetRef ref) async {
    // `FileType.any` + validación manual de extensión: en Android el
    // filtro `.gpx` no funciona (no es un MIME reconocido) y el picker
    // termina sin abrir nada.
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
    if (!file.name.toLowerCase().endsWith('.gpx')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Elige un archivo .gpx (ese no lo es).'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo leer el GPX: $e')));
      }
      return;
    }

    GpxImportResult result;
    try {
      result = const GpxSegmentImporter().parse(xml);
    } on GpxImportException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Segmento importado.')));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Segment segment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CcColors.surfaceHi,
        title: const Text(
          '¿Eliminar segmento?',
          style: TextStyle(color: CcColors.ink),
        ),
        content: Text(
          '"${segment.name}" se va a borrar. Los esfuerzos ya guardados '
          'sobre él también se pierden.',
          style: const TextStyle(color: CcColors.inkDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: CcColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(segmentsRepositoryProvider).delete(segment.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (overview.isEmpty) {
      return CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SafeArea(bottom: false, child: _Header(total: 0)),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              onExplore: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SegmentCatalogScreen()),
              ),
              onCreate: () => _goToActivitiesToCreate(context),
              onImport: () => _importFromGpx(context, ref),
            ),
          ),
        ],
      );
    }

    final now = DateTime.now();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  total: overview.total,
                  onAdd: () => _showAddSheet(context, ref),
                ),
                _StatsPanel(overview: overview),
              ],
            ),
          ),
        ),
        if (overview.recent.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: _SectionLabel('Esfuerzos recientes'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  for (final r in overview.recent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RecentEffortTile(recent: r, now: now),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _SectionLabel('Tus segmentos'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          sliver: SliverList.separated(
            itemCount: overview.summaries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 13),
            itemBuilder: (context, index) {
              final summary = overview.summaries[index];
              return Dismissible(
                key: ValueKey(summary.segment.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  await _confirmDelete(context, ref, summary.segment);
                  return false; // el stream ya quita la fila si se borró
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: CcColors.danger.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: _SegmentCard(summary: summary, now: now),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int total;
  final VoidCallback? onAdd;

  const _Header({required this.total, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Segmentos',
                  style: CcType.displayStyle(size: 27, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  total == 0
                      ? 'Todavía no tienes ninguno'
                      : '$total ${total == 1 ? 'segmento guardado' : 'segmentos guardados'}',
                  style: const TextStyle(
                    color: CcColors.inkDim,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onAdd != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Material(
                color: CcColors.surfaceHi,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: onAdd,
                  child: const SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(Icons.add, size: 18, color: CcColors.ink),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final SegmentsOverview overview;

  const _StatsPanel({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CcColors.surfaceHi, CcColors.surface],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CcColors.line),
      ),
      child: Row(
        children: [
          _PanelStat(
            value: '${overview.active}',
            label: 'Activos',
            color: CcColors.segmentActiveTrack,
          ),
          const _PanelDivider(),
          _PanelStat(
            value: '${overview.personalBestsThisMonth}',
            label: 'PR este mes',
            color: CcColors.gold,
          ),
          const _PanelDivider(),
          _PanelStat(
            value: '${overview.totalEfforts}',
            label: 'Esfuerzos',
            color: CcColors.ink,
          ),
        ],
      ),
    );
  }
}

class _PanelStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _PanelStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: CcType.displayStyle(
              size: 19,
              weight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: CcType.label(size: 9, color: CcColors.inkFaint),
          ),
        ],
      ),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: CcColors.line);
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: CcType.label(
        size: 11,
        color: CcColors.inkFaint,
      ).copyWith(letterSpacing: 1.4),
    );
  }
}

class _RecentEffortTile extends StatelessWidget {
  final RecentEffort recent;
  final DateTime now;

  const _RecentEffortTile({required this.recent, required this.now});

  @override
  Widget build(BuildContext context) {
    final e = recent.effort;
    final delta = Duration(seconds: recent.deltaSeconds);
    final when = _relativeTime(e.completedAt, now);
    final subtitle = recent.activityTitle == null
        ? when
        : '$when · ${recent.activityTitle}';

    final String deltaText;
    final Color deltaColor;
    if (recent.isFirstEffort) {
      deltaText = 'primer tiempo';
      deltaColor = CcColors.inkFaint;
    } else if (recent.isPersonalBest) {
      deltaText = 'nuevo PR · ${formatSignedDuration(delta)}';
      deltaColor = CcColors.gold;
    } else {
      deltaText = '${formatSignedDuration(delta)} vs PR';
      deltaColor = recent.deltaSeconds <= 0 ? CcColors.ok : CcColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: CcColors.surfaceHi.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color:
                  (recent.isPersonalBest
                          ? CcColors.gold
                          : CcColors.segmentActiveTrack)
                      .withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              recent.isPersonalBest ? Icons.emoji_events : Icons.check,
              size: 15,
              color: recent.isPersonalBest
                  ? CcColors.gold
                  : CcColors.segmentActiveTrack,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recent.segmentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CcColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CcColors.inkFaint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatElapsedShort(Duration(seconds: e.durationSeconds)),
                style: CcType.displayStyle(size: 14, weight: FontWeight.w800),
              ),
              const SizedBox(height: 1),
              Text(
                deltaText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: deltaColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentCard extends ConsumerWidget {
  final SegmentSummary summary;
  final DateTime now;

  const _SegmentCard({required this.summary, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = summary.segment;
    final profilePoints = segment.profile.points;
    final source = SegmentSource.fromWire(segment.source);

    return Material(
      color: CcColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SegmentDetailScreen(segmentId: segment.id),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CcColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentRouteThumbnail(points: profilePoints),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            segment.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CcType.displayStyle(
                              size: 15.5,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SourceChip(label: _sourceLabel(source)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    if (summary.best != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'TU MEJOR',
                            style: CcType.label(
                              size: 9,
                              color: CcColors.inkFaint,
                            ).copyWith(letterSpacing: 1.2),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            formatElapsedShort(
                              Duration(seconds: summary.best!.durationSeconds),
                            ),
                            style: CcType.displayStyle(
                              size: 21,
                              weight: FontWeight.w800,
                              color: CcColors.gold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· ${summary.best!.avgSpeedKmh.toStringAsFixed(1)} km/h',
                            style: const TextStyle(
                              color: CcColors.inkDim,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Sin intentos todavía',
                        style: const TextStyle(
                          color: CcColors.inkFaint,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 6),
                    _MetaRow(segment: segment),
                    if (profilePoints.length >= 2) ...[
                      const SizedBox(height: 7),
                      SizedBox(
                        height: 22,
                        child: CustomPaint(
                          painter: _SparklinePainter(profilePoints),
                          size: Size.infinite,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _ActivePill(
                          isActive: segment.isActive,
                          onTap: () => ref
                              .read(segmentsRepositoryProvider)
                              .setActive(segment.id, !segment.isActive),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            _cardFootnote(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: CcColors.inkFaint,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
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

  String _cardFootnote() {
    if (summary.effortCount == 0) return 'Actívalo para cronometrarlo';
    final n = summary.effortCount;
    final efforts = '$n ${n == 1 ? 'esfuerzo' : 'esfuerzos'}';
    final last = summary.lastEffortAt;
    return last == null ? efforts : '$efforts · ${_relativeTime(last, now)}';
  }
}

class _MetaRow extends StatelessWidget {
  final Segment segment;

  const _MetaRow({required this.segment});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _meta(
          Icons.straighten,
          '${formatDistanceKm(segment.distanceMeters)} km',
          CcColors.inkDim,
        ),
        const SizedBox(width: 12),
        _meta(
          Icons.terrain,
          '${segment.elevationGainMeters.toStringAsFixed(0)} m',
          CcColors.inkDim,
        ),
        const SizedBox(width: 12),
        _meta(
          Icons.trending_up,
          '${formatSlopePercent(segment.avgSlopePercent)}%',
          CcColors.mSlope,
        ),
      ],
    );
  }

  Widget _meta(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: CcColors.inkDim,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;

  const _SourceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CcColors.line),
      ),
      child: Text(
        label.toUpperCase(),
        style: CcType.label(size: 9, color: CcColors.inkDim),
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _ActivePill({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? CcColors.segmentActiveTrack
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: isActive ? null : Border.all(color: CcColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.circle : Icons.pause,
              size: 10,
              color: isActive ? const Color(0xFF06110F) : CcColors.inkDim,
            ),
            const SizedBox(width: 5),
            Text(
              isActive ? 'Activo' : 'Inactivo',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isActive ? const Color(0xFF06110F) : CcColors.inkDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sparkline del perfil de altimetría del segmento -- solo la silueta,
/// sin ejes ni color de pendiente (eso vive en el detalle).
class _SparklinePainter extends CustomPainter {
  final List<SegmentProfilePoint> points;

  _SparklinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final total = points.last.distanceFromStartMeters;
    if (total <= 0) return;
    var minAlt = points.first.altitude;
    var maxAlt = points.first.altitude;
    for (final p in points) {
      if (p.altitude < minAlt) minAlt = p.altitude;
      if (p.altitude > maxAlt) maxAlt = p.altitude;
    }
    final span = maxAlt - minAlt;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (points[i].distanceFromStartMeters / total) * size.width;
      final t = span <= 0 ? 0.5 : (points[i].altitude - minAlt) / span;
      final y = size.height - t * (size.height - 2) - 1;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = CcColors.slopeFlat
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points;
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onExplore;
  final VoidCallback onCreate;
  final VoidCallback onImport;

  const _EmptyState({
    required this.onExplore,
    required this.onCreate,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(34, 0, 34, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flag_outlined,
              size: 52,
              color: CcColors.segmentActiveTrack,
            ),
            const SizedBox(height: 20),
            Text(
              'Marca tus tramos favoritos',
              textAlign: TextAlign.center,
              style: CcType.displayStyle(size: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Un segmento es un tramo — una subida, un sprint — que la app '
              'cronometra sola cada vez que lo pasas, para que compitas '
              'contra tu mejor marca.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CcColors.inkDim,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onExplore,
                icon: const Icon(Icons.travel_explore, size: 18),
                label: const Text('Explorar segmentos de tu zona'),
                style: FilledButton.styleFrom(
                  backgroundColor: CcColors.segmentActiveTrack,
                  foregroundColor: const Color(0xFF06110F),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.content_cut, size: 18),
                label: const Text('Crear desde una actividad'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onImport,
              child: const Text('o importa un archivo GPX'),
            ),
          ],
        ),
      ),
    );
  }
}

String _sourceLabel(SegmentSource source) => switch (source) {
  SegmentSource.activity => 'Actividad',
  SegmentSource.gpxImport => 'GPX',
  SegmentSource.nativeCatalog => 'Oficial',
};

/// "hace 3 días", "ayer", "hace 2 semanas" -- sin `intl`, igual que el
/// resto de la feature de segmentos.
String _relativeTime(DateTime when, DateTime now) {
  final diff = now.difference(when);
  if (diff.inDays >= 14) return 'hace ${diff.inDays ~/ 7} semanas';
  if (diff.inDays >= 7) return 'hace 1 semana';
  if (diff.inDays >= 2) return 'hace ${diff.inDays} días';
  if (diff.inDays == 1) return 'ayer';
  if (diff.inHours >= 1) return 'hace ${diff.inHours} h';
  if (diff.inMinutes >= 1) return 'hace ${diff.inMinutes} min';
  return 'recién';
}
