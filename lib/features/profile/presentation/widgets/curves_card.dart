import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/physiology/physiology.dart';
import '../../../../core/ui/ui.dart';
import '../../../stats/stats.dart';
import '../../application/extension_points.dart';

/// Tarjeta «Curvas» de la pantalla de estadísticas: la mejor potencia y
/// el mejor pulso sostenidos de 5 s a 60 min en el periodo elegido. Cada
/// punto sabe de qué salida viene; tocarlo muestra cuál y deja abrirla.
/// En la de potencia van además la CP y el modelo `CP + W′/t`.
class CurvesCard extends ConsumerStatefulWidget {
  const CurvesCard({super.key});

  @override
  ConsumerState<CurvesCard> createState() => _CurvesCardState();
}

class _CurvesCardState extends ConsumerState<CurvesCard> {
  CurveKind _kind = CurveKind.power;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final curveAsync = ref.watch(periodBestCurveProvider(_kind));
    final period = ref.watch(statsPeriodProvider);
    final isPower = _kind == CurveKind.power;
    final summary = isPower ? ref.watch(criticalPowerSummaryProvider) : null;
    final color = isPower ? CcColors.mPower : CcColors.mHeartRate;

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
                'CURVAS',
                style: CcType.label(
                  size: 11,
                  color: CcColors.inkFaint,
                ).copyWith(letterSpacing: 1.2),
              ),
              const Spacer(),
              for (final kind in CurveKind.values) ...[
                const SizedBox(width: 6),
                _KindChip(
                  label: kind == CurveKind.power ? 'Potencia' : 'FC',
                  color: kind == CurveKind.power
                      ? CcColors.mPower
                      : CcColors.mHeartRate,
                  selected: kind == _kind,
                  onTap: () => setState(() {
                    _kind = kind;
                    _selected = null;
                  }),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          curveAsync.when(
            skipLoadingOnReload: true,
            loading: () => const SizedBox(
              height: 190,
              child: Center(
                child: CircularProgressIndicator(color: CcColors.orange),
              ),
            ),
            error: (_, _) =>
                const _EmptyCurve('No se pudieron cargar las curvas.'),
            data: (curve) {
              if (curve.isEmpty) {
                return _EmptyCurve(
                  '${isPower ? 'Sin salidas con potenciómetro' : 'Sin salidas con pulsómetro'} '
                  '${_periodPhrase(period)}.',
                );
              }
              final selected = _selected != null && curve[_selected!] != null
                  ? _selected
                  : null;
              final model = summary?.model;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Readout(
                    point: selected == null ? null : curve[selected],
                    duration: selected,
                    unit: isPower ? 'W' : 'ppm',
                    color: color,
                  ),
                  const SizedBox(height: 8),
                  MeanMaxCurveChart(
                    curve: curve,
                    color: color,
                    selected: selected,
                    onSelect: (d) => setState(() => _selected = d),
                    model: model == null
                        ? null
                        : (t) => model.cp + model.wPrime / t,
                    reference: model?.cp,
                    referenceLabel: model == null ? null : 'CP',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Mejor media de cada duración ${_periodPhrase(period)}'
            "${summary == null ? '' : " · punteada: CP + W'/t"}",
            style: const TextStyle(color: CcColors.inkDim, fontSize: 10),
          ),
          if (summary != null) ...[
            const SizedBox(height: 14),
            _CriticalPowerRow(summary: summary),
          ],
        ],
      ),
    );
  }

  static String _periodPhrase(StatsPeriod period) => switch (period) {
    StatsPeriod.week => 'esta semana',
    StatsPeriod.month => 'este mes',
    StatsPeriod.year => 'este año',
    StatsPeriod.all => 'de siempre',
  };
}

class _KindChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _KindChip({
    required this.label,
    required this.color,
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
          color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.55) : CcColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? color : CcColors.inkDim,
          ),
        ),
      ),
    );
  }
}

/// Lectura del punto elegido: duración, valor y la salida de donde viene
/// (tocable para abrirla).
class _Readout extends ConsumerWidget {
  final MeanMaxPoint? point;
  final int? duration;
  final String unit;
  final Color color;

  const _Readout({
    required this.point,
    required this.duration,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = point;
    final d = duration;
    if (p == null || d == null) {
      return const SizedBox(
        height: 34,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Toca la curva para ver cada esfuerzo y de qué salida viene.',
            style: TextStyle(color: CcColors.inkDim, fontSize: 11.5),
          ),
        ),
      );
    }
    final origin = originOf(p);
    final open = ref.watch(openActivityDetailProvider);
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Text(
            formatCurveDuration(d),
            style: const TextStyle(color: CcColors.inkDim, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            '${p.value.round()} $unit',
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (origin != null)
            Flexible(
              flex: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: open == null
                    ? null
                    : () => open(context, origin.activityId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '${formatShortDate(origin.startedAt)} · ${origin.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CcColors.ink,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (open != null)
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: CcColors.inkFaint,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyCurve extends StatelessWidget {
  final String text;

  const _EmptyCurve(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: CcColors.inkFaint, fontSize: 12),
        ),
      ),
    );
  }
}

/// CP y W′ con su incertidumbre y de dónde salen.
class _CriticalPowerRow extends StatelessWidget {
  final CriticalPowerSummary summary;

  const _CriticalPowerRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final m = summary.model;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ModelValue(
              label: 'Potencia crítica',
              value: '${m.cp.round()}',
              unit: 'W',
              uncertainty: '± ${m.seCp.round()}',
            ),
            const SizedBox(width: 10),
            _ModelValue(
              label: "Reserva anaeróbica W'",
              value: (m.wPrime / 1000).toStringAsFixed(1),
              unit: 'kJ',
              uncertainty: '± ${(m.seWPrime / 1000).toStringAsFixed(1)}',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          summary.basis,
          style: const TextStyle(
            color: CcColors.inkFaint,
            fontSize: 10.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ModelValue extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String uncertainty;

  const _ModelValue({
    required this.label,
    required this.value,
    required this.unit,
    required this.uncertainty,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: CcColors.mPower.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CcColors.mPower.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcType.label(
                size: 8.5,
                color: CcColors.inkFaint,
              ).copyWith(letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: CcType.displayStyle(size: 18, weight: FontWeight.w800),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: const TextStyle(color: CcColors.inkDim, fontSize: 10),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    uncertainty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CcColors.inkFaint,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
