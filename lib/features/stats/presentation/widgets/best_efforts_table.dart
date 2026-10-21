import 'package:flutter/material.dart';

import '../../../../core/physiology/physiology.dart';
import '../../../../core/ui/ui.dart';
import '../../domain/ride_curves.dart';
import 'mean_max_curve_chart.dart';

/// Duraciones de la tabla de mejores valores: las de Garmin Connect.
const bestEffortsTableDurations = <int>[
  1,
  3,
  5,
  10,
  20,
  30,
  60,
  120,
  300,
  600,
  1200,
  1800,
  3600,
  5400,
  7200,
  18000,
];

/// Tabla de mejores valores bajo la curva, como la de Garmin: una fila
/// por duración con la mejor media.
///
/// Con [comparison] se agrega una segunda columna (en el detalle de una
/// salida: «Tu mejor» de siempre). Con [showOrigin] la segunda columna es
/// la salida de donde viene cada marca, y tocarla la abre con
/// [onOpenOrigin]. Tocar una fila la marca en la curva ([onSelect]).
///
/// Solo aparecen las duraciones con algún valor: una salida de una hora
/// no tiene fila de 2 h.
class BestEffortsTable extends StatelessWidget {
  final MeanMaxCurve curve;
  final String curveLabel;
  final MeanMaxCurve? comparison;
  final String? comparisonLabel;
  final bool showOrigin;
  final void Function(int activityId)? onOpenOrigin;
  final String unit;
  final Color color;

  /// Duraciones en dorado (marcas de esta salida).
  final Set<int> highlighted;
  final int? selected;
  final ValueChanged<int>? onSelect;

  /// Con el peso (y en potencia) se muestran también los W/kg.
  final double? weightKg;

  const BestEffortsTable({
    super.key,
    required this.curve,
    required this.curveLabel,
    required this.unit,
    required this.color,
    this.comparison,
    this.comparisonLabel,
    this.showOrigin = false,
    this.onOpenOrigin,
    this.highlighted = const {},
    this.selected,
    this.onSelect,
    this.weightKg,
  });

  @override
  Widget build(BuildContext context) {
    final durations = [
      for (final d in bestEffortsTableDurations)
        if (curve[d] != null || comparison?[d] != null) d,
    ];
    if (durations.isEmpty) return const SizedBox.shrink();
    final secondLabel = showOrigin ? 'Salida' : comparisonLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: Row(
            children: [
              Expanded(flex: 4, child: _head('Duración')),
              Expanded(flex: 5, child: _head(curveLabel, right: true)),
              if (secondLabel != null)
                Expanded(flex: 6, child: _head(secondLabel, right: true)),
            ],
          ),
        ),
        for (final d in durations)
          _Row(
            label: formatCurveDuration(d),
            mine: curve[d],
            other: comparison?[d],
            showSecond: secondLabel != null,
            showOrigin: showOrigin,
            onOpenOrigin: onOpenOrigin,
            unit: unit,
            color: color,
            gold: highlighted.contains(d),
            selected: selected == d,
            onTap: onSelect == null ? null : () => onSelect!(d),
            weightKg: weightKg,
          ),
      ],
    );
  }

  static Widget _head(String text, {bool right = false}) => Text(
    text.toUpperCase(),
    textAlign: right ? TextAlign.right : TextAlign.left,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: CcType.label(
      size: 9,
      color: CcColors.inkFaint,
    ).copyWith(letterSpacing: 0.8),
  );
}

class _Row extends StatelessWidget {
  final String label;
  final MeanMaxPoint? mine;
  final MeanMaxPoint? other;
  final bool showSecond;
  final bool showOrigin;
  final void Function(int activityId)? onOpenOrigin;
  final String unit;
  final Color color;
  final bool gold;
  final bool selected;
  final VoidCallback? onTap;
  final double? weightKg;

  const _Row({
    required this.label,
    required this.mine,
    required this.other,
    required this.showSecond,
    required this.showOrigin,
    required this.onOpenOrigin,
    required this.unit,
    required this.color,
    required this.gold,
    required this.selected,
    required this.onTap,
    required this.weightKg,
  });

  @override
  Widget build(BuildContext context) {
    final m = mine;
    final origin = m == null || !showOrigin ? null : originOf(m);
    final open = onOpenOrigin;
    return Material(
      color: selected ? color.withValues(alpha: 0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: CcColors.lineSoft)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? CcColors.ink : CcColors.inkDim,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Expanded(flex: 5, child: _value(m, gold ? CcColors.gold : color)),
              if (showSecond)
                Expanded(
                  flex: 6,
                  child: showOrigin
                      ? _origin(context, origin, open)
                      : _value(other, CcColors.inkDim, small: true),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _value(MeanMaxPoint? p, Color c, {bool small = false}) {
    if (p == null) {
      return const Text(
        '—',
        textAlign: TextAlign.right,
        style: TextStyle(color: CcColors.inkFaint, fontSize: 12),
      );
    }
    final kg = weightKg;
    final perKg = unit == 'W' && kg != null && kg > 0
        ? (p.value / kg).toStringAsFixed(1).replaceAll('.', ',')
        : null;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${p.value.round()}',
            style: TextStyle(
              color: c,
              fontSize: small ? 12.5 : 13.5,
              fontWeight: small ? FontWeight.w600 : FontWeight.w800,
            ),
          ),
          TextSpan(
            text: ' $unit',
            style: const TextStyle(color: CcColors.inkFaint, fontSize: 10),
          ),
          if (perKg != null && !small)
            TextSpan(
              text: '  $perKg W/kg',
              style: const TextStyle(color: CcColors.inkFaint, fontSize: 10),
            ),
        ],
      ),
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _origin(
    BuildContext context,
    CurveOrigin? origin,
    void Function(int activityId)? open,
  ) {
    if (origin == null) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: open == null ? null : () => open(origin.activityId),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              formatShortDate(origin.startedAt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: CcColors.ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (open != null)
            const Icon(Icons.chevron_right, size: 15, color: CcColors.inkFaint),
        ],
      ),
    );
  }
}
