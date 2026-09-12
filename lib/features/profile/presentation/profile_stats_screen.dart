import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import 'package:cyclecore_core/utils/format_utils.dart';
import '../../../shared_widgets/activity_summary_block.dart';
import '../domain/profile_stats.dart';
import 'profile_providers.dart';
import 'widgets/activity_type_breakdown_bar.dart';
import 'widgets/ftp_level_card.dart';
import 'widgets/period_selector.dart';
import 'widgets/stats_trend_chart.dart';

/// Pantalla de estadísticas completas. Rediseño "Resumen + tendencia":
/// héroe de distancia + fila con filete (el mismo lenguaje del detalle
/// de actividad), una tarjeta de tendencia con barras, la ficha de
/// rendimiento (FTP · W/kg · nivel) y los récords del periodo.
class ProfileStatsScreen extends ConsumerWidget {
  const ProfileStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsForPeriodProvider);
    final period = ref.watch(statsPeriodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: [
            const PeriodSelector(),
            statsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(color: CcColors.orange),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No se pudieron cargar las estadísticas:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CcColors.inkDim),
                ),
              ),
              data: (stats) => _StatsBody(stats: stats, period: period),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final ProfileStats stats;
  final StatsPeriod period;

  const _StatsBody({required this.stats, required this.period});

  @override
  Widget build(BuildContext context) {
    // Aunque el periodo no tenga salidas, la pantalla se muestra con
    // todo en ceros -- la ficha de rendimiento (FTP · W/kg · zonas) no
    // depende de haber rodado y debe verse siempre.
    final empty = stats.activityCount == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        ActivitySummaryHero(
          label: 'Distancia · ${_periodLabel(period)}',
          value: formatDistanceKm(stats.totalDistanceMeters),
          unit: 'km',
        ),
        ActivityDividedRow(
          cells: [
            ActivityStatCell(
              label: 'Tiempo',
              value: formatDuration(
                Duration(seconds: stats.totalDurationSeconds),
              ),
            ),
            ActivityStatCell(
              label: 'Desnivel+',
              value: stats.totalElevationGainMeters.toStringAsFixed(0),
              unit: 'm',
            ),
            ActivityStatCell(label: 'Salidas', value: '${stats.activityCount}'),
          ],
        ),

        if (empty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 14,
                color: CcColors.inkFaint,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _emptyMessage(period),
                  style: const TextStyle(
                    color: CcColors.inkFaint,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),
        const StatsTrendChart(),

        const SizedBox(height: 16),
        const FtpLevelCard(),

        const SizedBox(height: 26),
        ActivitySectionLabel('Récords ${_recordsLabel(period)}'),
        const SizedBox(height: 12),
        _RecordsRow(stats: stats),

        const SizedBox(height: 26),
        _ByTypeCard(stats: stats),
      ],
    );
  }

  static String _periodLabel(StatsPeriod period) {
    final now = DateTime.now();
    return switch (period) {
      StatsPeriod.week => 'esta semana',
      StatsPeriod.month => _months[now.month - 1],
      StatsPeriod.year => '${now.year}',
      StatsPeriod.all => 'total',
    };
  }

  static String _recordsLabel(StatsPeriod period) {
    final now = DateTime.now();
    return switch (period) {
      StatsPeriod.week => 'de la semana',
      StatsPeriod.month => 'de ${_months[now.month - 1]}',
      StatsPeriod.year => 'de ${now.year}',
      StatsPeriod.all => 'de siempre',
    };
  }

  static String _emptyMessage(StatsPeriod period) => switch (period) {
    StatsPeriod.week => 'Todavía no hay salidas esta semana.',
    StatsPeriod.month => 'Todavía no hay salidas este mes.',
    StatsPeriod.year => 'Todavía no hay salidas este año.',
    StatsPeriod.all => 'Aún no has guardado ninguna actividad.',
  };

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
}

/// Tres récords del periodo elegido -- la salida más larga, la de más
/// desnivel y la de mayor velocidad media.
class _RecordsRow extends StatelessWidget {
  final ProfileStats stats;

  const _RecordsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RecordCell(
          icon: Icons.timeline,
          value: formatDistanceKm(stats.longestRideMeters),
          unit: 'km',
          label: 'Más larga',
        ),
        const SizedBox(width: 10),
        _RecordCell(
          icon: Icons.terrain,
          value: stats.mostClimbingMeters.toStringAsFixed(0),
          unit: 'm',
          label: 'Más subida',
        ),
        const SizedBox(width: 10),
        _RecordCell(
          icon: Icons.bolt,
          value: formatSpeedKmh(stats.fastestRideKmh),
          unit: 'km/h',
          label: 'Más rápida',
        ),
      ],
    );
  }
}

class _RecordCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;

  const _RecordCell({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: CcColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CcColors.line),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: CcColors.gold),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: CcType.displayStyle(
                      size: 15,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: CcColors.inkDim,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: CcType.label(
                size: 8.5,
                color: CcColors.inkFaint,
              ).copyWith(letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ByTypeCard extends StatelessWidget {
  final ProfileStats stats;

  const _ByTypeCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CcColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POR TIPO DE ACTIVIDAD',
            style: CcType.label(
              size: 11,
              color: CcColors.inkFaint,
            ).copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 14),
          ActivityTypeBreakdownBar(stats: stats),
        ],
      ),
    );
  }
}
