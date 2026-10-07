import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/physiology/physiology.dart';
import '../../../../core/ui/ui.dart';
import '../../../stats/stats.dart';

/// «Curva de esta salida»: la mejor media de cada duración en esta
/// actividad, encima de la mejor de siempre. Los puntos donde esta salida
/// es la marca van en dorado.
class ActivityCurveSection extends ConsumerStatefulWidget {
  final int activityId;
  final bool hasPower;
  final bool hasHeartRate;

  const ActivityCurveSection({
    super.key,
    required this.activityId,
    required this.hasPower,
    required this.hasHeartRate,
  });

  @override
  ConsumerState<ActivityCurveSection> createState() =>
      _ActivityCurveSectionState();
}

class _ActivityCurveSectionState extends ConsumerState<ActivityCurveSection> {
  late CurveKind _kind = widget.hasPower
      ? CurveKind.power
      : CurveKind.heartRate;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final kinds = [
      if (widget.hasPower) CurveKind.power,
      if (widget.hasHeartRate) CurveKind.heartRate,
    ];
    if (kinds.isEmpty) return const SizedBox.shrink();

    final curves = ref.watch(activityCurvesProvider(widget.activityId));
    final best =
        ref.watch(bestCurveProvider((kind: _kind, since: null, until: null))).valueOrNull ??
        const MeanMaxCurve.empty();
    final curve = curves.valueOrNull?[_kind];
    final isPower = _kind == CurveKind.power;
    final color = isPower ? CcColors.mPower : CcColors.mHeartRate;
    final records = <int>{
      if (curve != null)
        for (final d in curve.points.keys)
          if (best[d] case final b?
              when originOf(b)?.activityId == widget.activityId)
            d,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: ActivitySectionLabel('Curva de esta salida')),
            if (kinds.length > 1)
              for (final kind in kinds) ...[
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
        if (curve == null)
          const SizedBox(
            height: 60,
            child: Center(
              child: Text(
                'Calculando la curva…',
                style: TextStyle(color: CcColors.inkFaint, fontSize: 12),
              ),
            ),
          )
        else if (curve.isEmpty)
          const Text(
            'La salida es muy corta para armar la curva.',
            style: TextStyle(color: CcColors.inkFaint, fontSize: 12),
          )
        else ...[
          _Readout(
            duration: _selected,
            mine: _selected == null ? null : curve[_selected!],
            best: _selected == null ? null : best[_selected!],
            isRecord: records.contains(_selected),
            unit: isPower ? 'W' : 'ppm',
            color: color,
          ),
          const SizedBox(height: 8),
          MeanMaxCurveChart(
            curve: curve,
            comparison: best.isEmpty ? null : best,
            color: color,
            selected: _selected != null && curve[_selected!] != null
                ? _selected
                : null,
            highlighted: records,
            onSelect: (d) => setState(() => _selected = d),
          ),
          const SizedBox(height: 8),
          _Legend(color: color, hasRecords: records.isNotEmpty),
        ],
      ],
    );
  }
}

class _Readout extends StatelessWidget {
  final int? duration;
  final MeanMaxPoint? mine;
  final MeanMaxPoint? best;
  final bool isRecord;
  final String unit;
  final Color color;

  const _Readout({
    required this.duration,
    required this.mine,
    required this.best,
    required this.isRecord,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final d = duration;
    final m = mine;
    if (d == null || m == null) {
      return const Text(
        'Toca la curva para comparar cada duración con tu mejor marca.',
        style: TextStyle(color: CcColors.inkDim, fontSize: 11.5),
      );
    }
    final b = best;
    final origin = b == null ? null : originOf(b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          formatCurveDuration(d),
          style: const TextStyle(color: CcColors.inkDim, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Text(
          '${m.value.round()} $unit',
          style: TextStyle(
            color: isRecord ? CcColors.gold : color,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isRecord
                ? 'Tu mejor marca'
                : b == null
                ? ''
                : 'Tu mejor: ${b.value.round()} $unit'
                      '${origin == null ? '' : ' · ${formatShortDate(origin.startedAt)}'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isRecord ? CcColors.gold : CcColors.inkDim,
              fontSize: 11.5,
              fontWeight: isRecord ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final bool hasRecords;

  const _Legend({required this.color, required this.hasRecords});

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 3, color: c),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(color: CcColors.inkDim, fontSize: 10),
        ),
      ],
    );
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        item(color, 'Esta salida'),
        item(CcColors.inkDim, 'Tu mejor de siempre'),
        if (hasRecords) item(CcColors.gold, 'Marca de esta salida'),
      ],
    );
  }
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
