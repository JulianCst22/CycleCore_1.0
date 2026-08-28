import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../domain/segment_profile.dart';
import 'segments_providers.dart';
import 'widgets/segment_altitude_profile.dart';
import 'widgets/segment_mini_map.dart';

/// Detalle de un segmento puntual: dónde está (mapa con su trazado),
/// cómo es (perfil de altimetría), su mejor marca destacada y el
/// historial completo de esfuerzos -- para poder responder "¿dónde y
/// cuándo hice cada cosa?" sobre un segmento en concreto, algo que el
/// menú de segmentos (Fase 4) no cubre porque solo lista nombre +
/// stats resumidas + el toggle de activo/inactivo.
///
/// Recibe solo el `segmentId` (no el `Segment` completo) para poder
/// reaccionar solo si el usuario lo renombra o lo activa/desactiva
/// desde otra pantalla mientras el detalle sigue abierto -- ver
/// `segmentByIdProvider`.
class SegmentDetailScreen extends ConsumerWidget {
  final int segmentId;

  const SegmentDetailScreen({super.key, required this.segmentId});

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panelBackground,
        title: const Text(
          '¿Borrar todos los tiempos?',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        content: const Text(
          'Se elimina TODO el historial de esfuerzos de este segmento. '
          'El segmento en sí se mantiene. No se puede deshacer.',
          style: TextStyle(color: AppColors.textSecondaryOnPanel),
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
              'Borrar todo',
              style: TextStyle(color: AppColors.segmentEnd),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(segmentsRepositoryProvider).deleteAllEfforts(segmentId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentAsync = ref.watch(segmentByIdProvider(segmentId));
    final hasEfforts = ref
            .watch(segmentEffortsProvider(segmentId))
            .valueOrNull
            ?.isNotEmpty ??
        false;

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
        title: Text(
          segmentAsync.valueOrNull?.name ?? 'Segmento',
          style: const TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        actions: [
          if (hasEfforts)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textPrimaryOnPanel,
              ),
              color: AppColors.panelBackground,
              onSelected: (value) {
                if (value == 'clear') _confirmClearAll(context, ref);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'clear',
                  child: Text(
                    'Borrar todos los tiempos',
                    style: TextStyle(color: AppColors.textPrimaryOnPanel),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: segmentAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => const Center(
          child: Text(
            'No se pudo cargar el segmento.',
            style: TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ),
        data: (segment) {
          if (segment == null) {
            // Se borró (desde la lista, con swipe) mientras el
            // detalle seguía abierto.
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Este segmento ya no existe.',
                  style: TextStyle(color: AppColors.textSecondaryOnPanel),
                ),
              ),
            );
          }
          return _SegmentDetailBody(segment: segment);
        },
      ),
    );
  }
}

class _SegmentDetailBody extends ConsumerWidget {
  final Segment segment;

  const _SegmentDetailBody({required this.segment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilePoints = segment.profile.points;
    final effortsAsync = ref.watch(segmentEffortsProvider(segment.id));

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SegmentMiniMap(profilePoints: profilePoints),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'PERFIL DE ALTIMETRÍA',
            style: TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentAltitudeProfile(points: profilePoints),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: _StatsGrid(segment: segment),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
          child: effortsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (error, _) => const Text(
              'No se pudieron cargar los esfuerzos.',
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
            data: (efforts) =>
                _EffortsSection(efforts: efforts, segmentId: segment.id),
          ),
        ),
      ],
    );
  }
}

/// Distancia, desnivel positivo y pendientes -- las mismas 4 stats que
/// ya se guardaron congeladas al crear el segmento (ver
/// `SegmentsRepository.createSegmentFromActivity`), no se recalculan
/// acá.
class _StatsGrid extends StatelessWidget {
  final Segment segment;

  const _StatsGrid({required this.segment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _StatCell(
            label: 'DISTANCIA',
            value: '${formatDistanceKm(segment.distanceMeters)} km',
          ),
          _StatCell(
            label: 'DESNIVEL +',
            value: '${segment.elevationGainMeters.toStringAsFixed(0)} m',
          ),
          _StatCell(
            label: 'PEND. PROM',
            value: formatSlopePercent(segment.avgSlopePercent),
          ),
          _StatCell(
            label: 'PEND. MÁX',
            value: formatSlopePercent(segment.maxSlopePercent),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;

  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimaryOnPanel,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mejor marca destacada + historial completo, del más rápido al más
/// lento -- `efforts` ya llega ordenado así desde
/// `AppDatabase.watchEffortsForSegment`, o sea que `efforts.first`
/// (si la lista no está vacía) es siempre la mejor marca.
class _EffortsSection extends ConsumerWidget {
  final List<SegmentEffort> efforts;
  final int segmentId;

  const _EffortsSection({required this.efforts, required this.segmentId});

  Future<bool> _confirmDeleteEffort(
    BuildContext context,
    WidgetRef ref,
    SegmentEffort effort,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panelBackground,
        title: const Text(
          '¿Borrar este tiempo?',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        content: Text(
          'Se elimina el esfuerzo del '
          '${_formatDate(effort.completedAt)} '
          '(${formatElapsedShort(Duration(seconds: effort.durationSeconds))}). '
          'No se puede deshacer.',
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
              'Borrar',
              style: TextStyle(color: AppColors.segmentEnd),
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Todavía no has completado este segmento.\n'
            'Actívalo desde el menú de segmentos y grábalo en una '
            'próxima salida.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ),
      );
    }

    final best = efforts.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MEJOR TIEMPO',
          style: TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        _BestEffortCard(effort: best),
        const SizedBox(height: 22),
        Text(
          'HISTORIAL (${efforts.length})',
          style: const TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Deslizá un tiempo hacia la izquierda para borrarlo.',
          style: TextStyle(
            color: AppColors.textSecondaryOnPanel.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        ...efforts.map(
          (effort) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Dismissible(
              key: ValueKey(effort.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) =>
                  _confirmDeleteEffort(context, ref, effort),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.segmentEnd.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
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
        ),
      ],
    );
  }
}

class _BestEffortCard extends StatelessWidget {
  final SegmentEffort effort;

  const _BestEffortCard({required this.effort});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatElapsedShort(Duration(seconds: effort.durationSeconds)),
                  style: const TextStyle(
                    color: AppColors.textPrimaryOnPanel,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(effort.completedAt)} · '
                  '${effort.avgSpeedKmh.toStringAsFixed(1)} km/h prom.',
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
    final deltaSeconds = effort.durationSeconds - bestDurationSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                    color: AppColors.textPrimaryOnPanel,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${effort.avgSpeedKmh.toStringAsFixed(1)} km/h prom.'
                  '${effort.avgHeartRate != null ? ' · ${effort.avgHeartRate} ppm' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatElapsedShort(Duration(seconds: effort.durationSeconds)),
                style: const TextStyle(
                  color: AppColors.textPrimaryOnPanel,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isBest
                    ? 'Mejor marca'
                    : '+${formatElapsedShort(Duration(seconds: deltaSeconds))}',
                style: TextStyle(
                  color: isBest
                      ? AppColors.primary
                      : AppColors.textSecondaryOnPanel,
                  fontSize: 11,
                  fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
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

/// 'd mmm yyyy, HH:mm' sin depender de `intl` -- no hay evidencia de
/// que ese paquete ya esté en el proyecto, y agregarlo solo para esto
/// sería una dependencia nueva innecesaria.
String _formatDate(DateTime date) {
  final month = _monthAbbreviations[date.month - 1];
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${date.day} $month ${date.year}, $hh:$mm';
}
