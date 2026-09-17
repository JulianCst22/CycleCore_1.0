import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_ui/core_ui.dart';
import '../../domain/profile_stats.dart';
import '../../domain/stats_trend.dart';
import '../../application/stats_providers.dart';

/// Tarjeta "Totales" de la pantalla de estadísticas: un selector de
/// métrica (distancia / desnivel / tiempo / salidas) y un gráfico de
/// barras que reparte el periodo elegido en días, semanas, meses o años.
/// La barra del periodo en curso va resaltada y, al tocar cualquier
/// barra, se muestra su valor arriba.
class StatsTrendChart extends ConsumerStatefulWidget {
  const StatsTrendChart({super.key});

  @override
  ConsumerState<StatsTrendChart> createState() => _StatsTrendChartState();
}

class _StatsTrendChartState extends ConsumerState<StatsTrendChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final metric = ref.watch(statsTrendMetricProvider);
    final period = ref.watch(statsPeriodProvider);
    final bucketsAsync = ref.watch(statsTrendProvider);
    final buckets = bucketsAsync.valueOrNull ?? const <StatsTrendBucket>[];

    // Si el selector deja fuera de rango la barra elegida (cambió el
    // periodo o la métrica), se limpia la selección.
    final selected = (_selected != null && _selected! < buckets.length)
        ? _selected
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CcColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TOTALES',
                style: CcType.label(
                  size: 11,
                  color: CcColors.inkFaint,
                ).copyWith(letterSpacing: 1.2),
              ),
              const Spacer(),
              _Readout(
                bucket: selected == null ? null : buckets[selected],
                metric: metric,
                fallback: _average(buckets),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in StatsTrendMetric.values)
                _MetricChip(
                  label: m.label,
                  selected: m == metric,
                  onTap: () {
                    ref.read(statsTrendMetricProvider.notifier).state = m;
                    setState(() => _selected = null);
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          _Bars(
            buckets: buckets,
            selected: selected,
            onTap: (i) => setState(() => _selected = _selected == i ? null : i),
          ),
          const SizedBox(height: 8),
          Text(
            selected == null
                ? '${_periodCaption(period)} · toca una barra para ver su valor'
                : _periodCaption(period),
            style: const TextStyle(color: CcColors.inkDim, fontSize: 10),
          ),
        ],
      ),
    );
  }

  static String _periodCaption(StatsPeriod period) => switch (period) {
    StatsPeriod.week => 'por día de la semana',
    StatsPeriod.month => 'por semana del mes',
    StatsPeriod.year => 'por mes',
    StatsPeriod.all => 'por año',
  };

  static double _average(List<StatsTrendBucket> buckets) {
    final withValue = buckets.where((b) => b.value > 0);
    if (withValue.isEmpty) return 0;
    final sum = withValue.fold<double>(0, (s, b) => s + b.value);
    return sum / withValue.length;
  }
}

String _formatValue(double value, StatsTrendMetric metric) {
  switch (metric) {
    case StatsTrendMetric.distance:
      return value.toStringAsFixed(value >= 100 ? 0 : 1);
    case StatsTrendMetric.elevation:
      return formatThousands(value.round());
    case StatsTrendMetric.movingTime:
      return value.toStringAsFixed(1);
    case StatsTrendMetric.rides:
      return value.round().toString();
  }
}

String _withUnit(double value, StatsTrendMetric metric) {
  final v = _formatValue(value, metric);
  return metric.unit.isEmpty ? v : '$v ${metric.unit}';
}

/// Lectura arriba a la derecha: el valor de la barra tocada, o "media X"
/// cuando no hay ninguna seleccionada.
class _Readout extends StatelessWidget {
  final StatsTrendBucket? bucket;
  final StatsTrendMetric metric;
  final double fallback;

  const _Readout({
    required this.bucket,
    required this.metric,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (bucket == null) {
      return Text(
        'media ${_withUnit(fallback, metric)}',
        style: const TextStyle(color: CcColors.inkDim, fontSize: 10.5),
      );
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11.5, color: CcColors.inkDim),
        children: [
          TextSpan(text: '${bucket!.label} · '),
          TextSpan(
            text: _withUnit(bucket!.value, metric),
            style: const TextStyle(
              color: CcColors.blue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MetricChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? CcColors.blue.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? CcColors.blue.withValues(alpha: 0.5)
                : CcColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? CcColors.blue : CcColors.inkDim,
          ),
        ),
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  final List<StatsTrendBucket> buckets;
  final int? selected;
  final ValueChanged<int> onTap;

  const _Bars({
    required this.buckets,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return const SizedBox(
        height: 96,
        child: Center(
          child: Text(
            'Sin datos en este periodo',
            style: TextStyle(color: CcColors.inkFaint, fontSize: 12),
          ),
        ),
      );
    }

    final maxValue = buckets
        .map((b) => b.value)
        .fold<double>(0, (m, v) => v > m ? v : m);

    return Column(
      children: [
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < buckets.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: maxValue == 0
                              ? 0.02
                              : (buckets[i].value / maxValue).clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _barColor(i, buckets[i].isCurrent),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              border: i == selected
                                  ? Border.all(color: CcColors.ink, width: 1.4)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (var i = 0; i < buckets.length; i++)
              Expanded(
                child: Text(
                  buckets[i].label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: (i == selected || buckets[i].isCurrent)
                        ? CcColors.blue
                        : CcColors.inkFaint,
                    fontWeight: (i == selected || buckets[i].isCurrent)
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color _barColor(int i, bool isCurrent) {
    if (i == selected) return CcColors.blue;
    if (isCurrent) return CcColors.blue.withValues(alpha: 0.75);
    return CcColors.blue.withValues(alpha: 0.3);
  }
}
