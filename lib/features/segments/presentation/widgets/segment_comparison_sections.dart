import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/ui/ui.dart';
import '../../application/segment_comparison_providers.dart';
import '../../application/segments_providers.dart';
import '../../domain/segment_comparison.dart';

/// Las dos comparaciones del detalle de un segmento, con datos del
/// ciclista: antes y con la app (sus GPX contra lo grabado con la app),
/// y con y sin coach.
class SegmentComparisonSections extends ConsumerWidget {
  final int segmentId;

  const SegmentComparisonSections({super.key, required this.segmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(segmentComparisonProvider(segmentId)).valueOrNull;
    if (c == null || c.efforts.isEmpty) return const SizedBox.shrink();
    final baseline = [
      for (final b
          in ref.watch(allBaselineEffortsProvider).valueOrNull ??
              const <BaselineEffort>[])
        if (b.segmentId == segmentId) b,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const _Label('Antes y con la app'),
        const SizedBox(height: 8),
        _BeforeAfterCard(c: c),
        if (baseline.isNotEmpty) ...[
          const SizedBox(height: 10),
          _BaselineList(efforts: baseline),
        ],
        if (!c.withApp.isEmpty) ...[
          const SizedBox(height: 20),
          const _Label('Con coach y sin coach'),
          const SizedBox(height: 8),
          _CoachCard(c: c),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

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

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: CcColors.surfaceHi,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

String _time(num seconds) =>
    formatElapsedShort(Duration(seconds: seconds.round()));

/// "47 s" o "1:05".
String _gap(num seconds) {
  final s = seconds.abs().round();
  return s < 60 ? '$s s' : formatElapsedShort(Duration(seconds: s));
}

/// Dos grupos lado a lado: mediana, cuántos y la mejor marca.
class _Duo extends StatelessWidget {
  final String leftLabel;
  final EffortGroupStats left;
  final String leftEmpty;
  final String rightLabel;
  final EffortGroupStats right;
  final String rightEmpty;

  const _Duo({
    required this.leftLabel,
    required this.left,
    required this.leftEmpty,
    required this.rightLabel,
    required this.right,
    required this.rightEmpty,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, EffortGroupStats g, String empty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            g.isEmpty
                ? label.toUpperCase()
                : '${label.toUpperCase()} · ${g.count}',
            style: CcType.label(
              size: 9.5,
              color: CcColors.inkDim,
            ).copyWith(letterSpacing: 0.9),
          ),
          const SizedBox(height: 3),
          Text(
            g.isEmpty ? '—' : _time(g.medianSeconds!),
            style: CcType.displayStyle(
              size: 23,
              color: g.isEmpty ? CcColors.inkFaint : CcColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            g.isEmpty ? empty : 'mediana · mejor ${_time(g.bestSeconds!)}',
            style: const TextStyle(color: CcColors.inkDim, fontSize: 10.5),
          ),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cell(leftLabel, left, leftEmpty)),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: CcColors.line,
          ),
          Expanded(child: cell(rightLabel, right, rightEmpty)),
        ],
      ),
    );
  }
}

/// Pastilla con la diferencia: verde si mejoró, naranja si no.
class _DeltaPill extends StatelessWidget {
  final double seconds;
  final String fasterText;
  final String slowerText;

  const _DeltaPill({
    required this.seconds,
    required this.fasterText,
    required this.slowerText,
  });

  @override
  Widget build(BuildContext context) {
    final faster = seconds <= 0;
    final color = faster ? CcColors.ok : CcColors.ghostBehind;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(faster ? Icons.south : Icons.north, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            seconds.round() == 0
                ? 'Igual'
                : '${_gap(seconds)} ${faster ? fasterText : slowerText}',
            style: CcType.label(
              size: 11.5,
              color: color,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BeforeAfterCard extends StatelessWidget {
  final SegmentComparison c;
  const _BeforeAfterCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final delta = c.deltaSeconds(
      ComparisonPair.appVsBefore,
      ComparisonMetric.median,
    );
    return _Card(
      children: [
        _Duo(
          leftLabel: 'Antes',
          left: c.before,
          leftEmpty: 'Sin marcas de antes',
          rightLabel: 'Con la app',
          right: c.withApp,
          rightEmpty: 'Aún no lo haces con la app',
        ),
        if (delta != null) ...[
          const SizedBox(height: 10),
          _DeltaPill(
            seconds: delta,
            fasterText: 'más rápido con la app',
            slowerText: 'más lento con la app',
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          width: double.infinity,
          child: CustomPaint(painter: _EffortsPainter(c)),
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _Legend(color: CcColors.inkFaint, text: 'Antes (GPX)'),
            _Legend(color: CcColors.blue, text: 'Con la app'),
            _Legend(color: CcColors.orange, text: 'Con coach'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          c.before.isEmpty
              ? 'Para comparar con antes de la app, busca este tramo en un '
                    'GPX de tu Garmin (Segmentos › + › Buscar subidas en un '
                    'GPX) y guarda tu tiempo de esa salida.'
              : 'Cada punto es un paso por el segmento, por fecha. Lo más '
                    'rápido queda arriba.',
          style: const TextStyle(
            color: CcColors.inkDim,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Las marcas de antes de la app de este segmento, para revisar de qué
/// GPX salió cada una y borrar la que no sirva (por ejemplo, una salida
/// en la que paraste a mitad de la subida).
class _BaselineList extends ConsumerWidget {
  final List<BaselineEffort> efforts;
  const _BaselineList({required this.efforts});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    BaselineEffort e,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CcColors.surfaceHi,
        title: const Text('¿Borrar esta marca de antes?'),
        content: Text(
          '${_time(e.durationSeconds)} del '
          '${formatShortDate(e.completedAt.toLocal())} '
          '${e.completedAt.year}. Deja de contar en la comparativa.',
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
    if (ok == true) {
      await ref.read(segmentsRepositoryProvider).deleteBaselineEffort(e.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = [...efforts]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        iconColor: CcColors.inkDim,
        collapsedIconColor: CcColors.inkDim,
        title: Text(
          'Tus marcas de antes · ${efforts.length}',
          style: CcType.label(size: 12.5, color: CcColors.ink),
        ),
        children: [
          for (final e in sorted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: CcColors.lineSoft)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _time(e.durationSeconds),
                          style: CcType.displayStyle(size: 14),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${formatShortDate(e.completedAt.toLocal())} '
                          '${e.completedAt.year}'
                          '${e.sourceName == null ? '' : ' · ${e.sourceName}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CcType.label(size: 11, color: CcColors.inkDim),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Borrar',
                    onPressed: () => _delete(context, ref, e),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: CcColors.inkFaint,
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

class _CoachCard extends StatelessWidget {
  final SegmentComparison c;
  const _CoachCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final delta = c.deltaSeconds(
      ComparisonPair.coachVsNoCoach,
      ComparisonMetric.median,
    );
    return _Card(
      children: [
        _Duo(
          leftLabel: 'Con coach',
          left: c.coached,
          leftEmpty: 'Sin subidas con coach',
          rightLabel: 'Sin coach',
          right: c.withoutCoach,
          rightEmpty: 'Sin subidas sin coach',
        ),
        if (delta != null) ...[
          const SizedBox(height: 10),
          _DeltaPill(
            seconds: delta,
            fasterText: 'más rápido con coach',
            slowerText: 'más lento con coach',
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          '«Con coach» quiere decir que el coach te habló en ese segmento.',
          style: TextStyle(color: CcColors.inkDim, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(color: CcColors.inkDim, fontSize: 10.5),
        ),
      ],
    );
  }
}

/// Los pasos por el segmento en orden de fecha: lo más rápido arriba, el
/// color dice si fue antes de la app, con la app o con coach.
class _EffortsPainter extends CustomPainter {
  final SegmentComparison c;

  _EffortsPainter(this.c);

  @override
  void paint(Canvas canvas, Size size) {
    final efforts = c.efforts;
    if (efforts.isEmpty) return;

    var lo = efforts.map((e) => e.seconds).reduce(math.min).toDouble();
    var hi = efforts.map((e) => e.seconds).reduce(math.max).toDouble();
    final pad = math.max(5.0, (hi - lo) * 0.12);
    lo -= pad;
    hi += pad;

    const labelWidth = 34.0;
    const top = 6.0;
    final bottom = size.height - 6;
    double y(num seconds) => top + (seconds - lo) / (hi - lo) * (bottom - top);

    final grid = Paint()
      ..color = CcColors.lineSoft
      ..strokeWidth = 1;
    canvas.drawLine(Offset(labelWidth, top), Offset(size.width, top), grid);
    canvas.drawLine(
      Offset(labelWidth, bottom),
      Offset(size.width, bottom),
      grid,
    );
    _text(canvas, _time(lo), Offset(0, top - 6));
    _text(canvas, _time(hi), Offset(0, bottom - 6));

    // Dónde empezó a usarse la app: una línea punteada.
    final firstApp = efforts.indexWhere((e) => e.withApp);
    final usable = size.width - labelWidth - 12;
    final step = efforts.length == 1 ? 0.0 : usable / (efforts.length - 1);
    double x(int i) => efforts.length == 1
        ? labelWidth + usable / 2 + 6
        : labelWidth + 6 + i * step;
    if (firstApp > 0) {
      final mx = (x(firstApp - 1) + x(firstApp)) / 2;
      final dash = Paint()
        ..color = CcColors.inkFaint
        ..strokeWidth = 1;
      for (var yy = top; yy < bottom; yy += 6) {
        canvas.drawLine(
          Offset(mx, yy),
          Offset(mx, math.min(yy + 3, bottom)),
          dash,
        );
      }
    }

    for (var i = 0; i < efforts.length; i++) {
      final e = efforts[i];
      final color = !e.withApp
          ? CcColors.inkFaint
          : (e.coached ? CcColors.orange : CcColors.blue);
      canvas.drawCircle(
        Offset(x(i), y(e.seconds)),
        3.6,
        Paint()..color = color,
      );
    }
  }

  void _text(Canvas canvas, String text, Offset at) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: CcColors.inkFaint,
          fontSize: 9,
          fontFamily: CcType.family,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_EffortsPainter old) => old.c != c;
}
