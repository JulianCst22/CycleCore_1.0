import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/cc_colors.dart';
import '../../../core/theme/cc_type.dart';
import '../../../core/utils/format_utils.dart';
import '../domain/segment_profile.dart';
import '../domain/segment_source.dart';
import 'segments_providers.dart';
import 'widgets/segment_altitude_profile.dart';
import 'widgets/segment_mini_map.dart';
import 'widgets/segment_progress_chart.dart';

/// Detalle de un segmento: dónde está (mapa), cómo es (perfil), tu
/// mejor marca, tu progreso a lo largo del tiempo y el historial
/// completo de esfuerzos.
///
/// Recibe solo el `segmentId` para poder reaccionar si el usuario lo
/// renombra o lo activa/desactiva desde otra pantalla mientras el
/// detalle sigue abierto (ver `segmentByIdProvider`).
class SegmentDetailScreen extends ConsumerWidget {
  final int segmentId;

  const SegmentDetailScreen({super.key, required this.segmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentAsync = ref.watch(segmentByIdProvider(segmentId));

    return Scaffold(
      backgroundColor: CcColors.bg,
      body: segmentAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CcColors.orange),
        ),
        error: (error, _) =>
            const _CenteredMessage('No se pudo cargar el segmento.'),
        data: (segment) => segment == null
            ? const _CenteredMessage('Este segmento ya no existe.')
            : _SegmentDetailBody(segment: segment),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final String text;

  const _CenteredMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: CcColors.inkDim),
        ),
      ),
    );
  }
}

class _SegmentDetailBody extends ConsumerWidget {
  final Segment segment;

  const _SegmentDetailBody({required this.segment});

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CcColors.surfaceHi,
        title: const Text(
          '¿Borrar todos los tiempos?',
          style: TextStyle(color: CcColors.ink),
        ),
        content: const Text(
          'Se elimina TODO el historial de esfuerzos de este segmento. '
          'El segmento en sí se mantiene. No se puede deshacer.',
          style: TextStyle(color: CcColors.inkDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Borrar todo',
              style: TextStyle(color: CcColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(segmentsRepositoryProvider).deleteAllEfforts(segment.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilePoints = segment.profile.points;
    final source = SegmentSource.fromWire(segment.source);
    final effortsAsync = ref.watch(segmentEffortsProvider(segment.id));
    final efforts = effortsAsync.valueOrNull ?? const <SegmentEffort>[];
    final best = efforts.isEmpty ? null : efforts.first; // ya viene asc

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: CcColors.bg,
          pinned: true,
          expandedHeight: profilePoints.length > 1 ? 248 : 0,
          iconTheme: const IconThemeData(color: CcColors.ink),
          title: Text(
            segment.name,
            style: const TextStyle(color: CcColors.ink),
          ),
          actions: [
            if (efforts.isNotEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: CcColors.ink),
                color: CcColors.surfaceHi,
                onSelected: (value) {
                  if (value == 'clear') _confirmClearAll(context, ref);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'clear',
                    child: Text(
                      'Borrar todos los tiempos',
                      style: TextStyle(color: CcColors.ink),
                    ),
                  ),
                ],
              ),
          ],
          flexibleSpace: profilePoints.length > 1
              ? FlexibleSpaceBar(
                  background: SegmentMiniMap(
                    profilePoints: profilePoints,
                    height: 248,
                  ),
                )
              : null,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _MetaLine(
                source: source,
                isActive: segment.isActive,
                onToggle: () => ref
                    .read(segmentsRepositoryProvider)
                    .setActive(segment.id, !segment.isActive),
              ),
              const SizedBox(height: 6),
              _StatRow(segment: segment),
              if (best != null) ...[
                const SizedBox(height: 16),
                _BestEffortCard(effort: best),
              ],
              const SizedBox(height: 20),
              const _SectionLabel('Perfil de altimetría'),
              const SizedBox(height: 8),
              SegmentAltitudeProfile(points: profilePoints, height: 116),
              if (efforts.length >= 2) ...[
                const SizedBox(height: 22),
                SegmentProgressChart(efforts: efforts),
              ],
              const SizedBox(height: 24),
              _HistorySection(efforts: efforts, segmentId: segment.id),
            ]),
          ),
        ),
      ],
    );
  }
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

class _MetaLine extends StatelessWidget {
  final SegmentSource source;
  final bool isActive;
  final VoidCallback onToggle;

  const _MetaLine({
    required this.source,
    required this.isActive,
    required this.onToggle,
  });

  String get _sourceLabel => switch (source) {
    SegmentSource.activity => 'De una actividad',
    SegmentSource.gpxImport => 'Importado (GPX)',
    SegmentSource.nativeCatalog => 'Segmento oficial',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: CcColors.line),
          ),
          child: Text(
            _sourceLabel.toUpperCase(),
            style: CcType.label(size: 9, color: CcColors.inkDim),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggle,
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
        ),
      ],
    );
  }
}

/// Distancia · desnivel+ · pendiente media · pendiente máx -- las
/// cuatro stats congeladas al crear el segmento, en fila con filete.
class _StatRow extends StatelessWidget {
  final Segment segment;

  const _StatRow({required this.segment});

  @override
  Widget build(BuildContext context) {
    final cells = <(String, String, String)>[
      ('Distancia', formatDistanceKm(segment.distanceMeters), 'km'),
      ('Desnivel+', segment.elevationGainMeters.toStringAsFixed(0), 'm'),
      ('Pend prom', formatSlopePercent(segment.avgSlopePercent), '%'),
      ('Pend máx', formatSlopePercent(segment.maxSlopePercent), '%'),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: CcColors.lineSoft),
          bottom: BorderSide(color: CcColors.lineSoft),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cells.length; i++)
              Expanded(
                child: Container(
                  padding: EdgeInsets.fromLTRB(i == 0 ? 0 : 11, 10, 3, 10),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            left: BorderSide(color: CcColors.lineSoft),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cells[i].$1.toUpperCase(),
                        style: CcType.label(
                          size: 8,
                          color: CcColors.inkFaint,
                        ).copyWith(letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              cells[i].$2,
                              style: CcType.displayStyle(
                                size: 16,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              cells[i].$3,
                              style: const TextStyle(
                                color: CcColors.inkDim,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BestEffortCard extends StatelessWidget {
  final SegmentEffort effort;

  const _BestEffortCard({required this.effort});

  @override
  Widget build(BuildContext context) {
    final extras = <String>[
      '${effort.avgSpeedKmh.toStringAsFixed(1)} km/h prom',
      if (effort.avgHeartRate != null) '${effort.avgHeartRate} ppm',
      if (effort.avgPower != null) '${effort.avgPower} W',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CcColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CcColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: CcColors.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 18,
              color: CcColors.gold,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatElapsedShort(Duration(seconds: effort.durationSeconds)),
                  style: CcType.displayStyle(
                    size: 22,
                    weight: FontWeight.w800,
                    color: CcColors.gold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDate(effort.completedAt)} · ${extras.join(' · ')}',
                  style: const TextStyle(
                    color: CcColors.inkDim,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Historial completo de esfuerzos, del más rápido al más lento
/// (`efforts` ya llega ordenado así). Cada fila se puede deslizar a la
/// izquierda para borrarla.
class _HistorySection extends ConsumerWidget {
  final List<SegmentEffort> efforts;
  final int segmentId;

  const _HistorySection({required this.efforts, required this.segmentId});

  Future<bool> _confirmDeleteEffort(
    BuildContext context,
    WidgetRef ref,
    SegmentEffort effort,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CcColors.surfaceHi,
        title: const Text(
          '¿Borrar este tiempo?',
          style: TextStyle(color: CcColors.ink),
        ),
        content: Text(
          'Se elimina el esfuerzo del ${_formatDate(effort.completedAt)} '
          '(${formatElapsedShort(Duration(seconds: effort.durationSeconds))}). '
          'No se puede deshacer.',
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
              'Borrar',
              style: TextStyle(color: CcColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(segmentsRepositoryProvider).deleteEffort(effort.id);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (efforts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Historial'),
          const SizedBox(height: 10),
          const Text(
            'Todavía no has completado este segmento. Actívalo y grábalo '
            'en una próxima salida.',
            style: TextStyle(color: CcColors.inkDim, fontSize: 13, height: 1.5),
          ),
        ],
      );
    }

    final best = efforts.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionLabel('Historial · ${efforts.length}'),
            const Spacer(),
            const Text(
              'desliza para borrar',
              style: TextStyle(color: CcColors.inkFaint, fontSize: 10.5),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final effort in efforts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Dismissible(
              key: ValueKey(effort.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmDeleteEffort(context, ref, effort),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: CcColors.danger.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: _EffortTile(
                effort: effort,
                bestDurationSeconds: best.durationSeconds,
                isBest: effort.id == best.id,
              ),
            ),
          ),
      ],
    );
  }
}

class _EffortTile extends StatelessWidget {
  final SegmentEffort effort;
  final int bestDurationSeconds;
  final bool isBest;

  const _EffortTile({
    required this.effort,
    required this.bestDurationSeconds,
    required this.isBest,
  });

  @override
  Widget build(BuildContext context) {
    final delta = Duration(
      seconds: effort.durationSeconds - bestDurationSeconds,
    );
    final sub = <String>[
      '${effort.avgSpeedKmh.toStringAsFixed(1)} km/h',
      if (effort.avgHeartRate != null) '${effort.avgHeartRate} ppm',
      if (effort.avgPower != null) '${effort.avgPower} W',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: CcColors.surfaceHi.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(effort.completedAt),
                  style: const TextStyle(
                    color: CcColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    color: CcColors.inkFaint,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatElapsedShort(Duration(seconds: effort.durationSeconds)),
                style: CcType.displayStyle(
                  size: 14,
                  weight: FontWeight.w800,
                  color: isBest ? CcColors.gold : CcColors.ink,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                isBest ? 'Mejor marca' : '+${formatElapsedShort(delta)}',
                style: TextStyle(
                  color: isBest ? CcColors.gold : CcColors.inkFaint,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const List<String> _monthAbbreviations = [
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

/// 'd mmm yyyy, HH:mm' sin depender de `intl`.
String _formatDate(DateTime date) {
  final month = _monthAbbreviations[date.month - 1];
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${date.day} $month ${date.year}, $hh:$mm';
}
