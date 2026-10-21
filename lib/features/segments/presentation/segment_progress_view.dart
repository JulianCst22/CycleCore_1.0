import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ui.dart';
import '../application/segment_comparison_providers.dart';
import '../domain/segment_comparison.dart';
import 'segment_detail_screen.dart';

/// "Mi progreso": todos los segmentos juntos, con datos del ciclista.
/// Primero, antes y con la app (sus tiempos de los GPX contra los
/// grabados con la app); después, con y sin coach.
class SegmentProgressView extends ConsumerWidget {
  const SegmentProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(comparisonOverviewProvider);
    return overviewAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: CcColors.orange)),
      ),
      error: (_, _) => const _Note(
        icon: Icons.error_outline,
        text: 'No se pudo armar la comparativa.',
      ),
      data: (overview) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PairSection(
            overview: overview,
            pair: ComparisonPair.appVsBefore,
            title: 'Antes y con la app',
            fasterText: (n, total) =>
                'Con la app vas más rápido en $n de $total '
                '${total == 1 ? 'segmento' : 'segmentos'}.',
            slowerText: (n, total) =>
                'Con la app todavía no vas más rápido ($n de $total).',
            detail:
                'Mediana de tus tiempos de antes (de tus GPX) contra los '
                'grabados con la app.',
            empty:
                'Para comparar con antes de la app, busca subidas en un GPX '
                'de tu Garmin (botón + › Buscar subidas en un GPX) y guarda '
                'tu tiempo de esa salida.',
            emptyIcon: Icons.history,
          ),
          const SizedBox(height: 26),
          _PairSection(
            overview: overview,
            pair: ComparisonPair.coachVsNoCoach,
            title: 'Con coach y sin coach',
            fasterText: (n, total) =>
                'Con coach vas más rápido en $n de $total '
                '${total == 1 ? 'segmento' : 'segmentos'}.',
            slowerText: (n, total) =>
                'Con coach todavía no vas más rápido ($n de $total).',
            detail:
                'Mediana de tus subidas con la app. «Con coach» quiere decir '
                'que el coach te habló en ese segmento.',
            empty:
                'Haz el mismo segmento con el coach encendido y apagado para '
                'ver la diferencia.',
            emptyIcon: Icons.record_voice_over_outlined,
          ),
        ],
      ),
    );
  }
}

/// Una comparación (antes/con la app o con/sin coach) en todos los
/// segmentos: la cifra global y una fila por segmento.
class _PairSection extends StatelessWidget {
  final ComparisonOverview overview;
  final ComparisonPair pair;
  final String title;
  final String Function(int faster, int total) fasterText;
  final String Function(int faster, int total) slowerText;
  final String detail;
  final String empty;
  final IconData emptyIcon;

  const _PairSection({
    required this.overview,
    required this.pair,
    required this.title,
    required this.fasterText,
    required this.slowerText,
    required this.detail,
    required this.empty,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    const metric = ComparisonMetric.median;
    final rows = overview.comparable(pair, metric);
    final median = overview.medianDeltaPercent(pair, metric);
    final faster = overview.fasterCount(pair, metric);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(title),
        const SizedBox(height: 8),
        if (median == null)
          _Note(icon: emptyIcon, text: empty)
        else ...[
          _SummaryCard(
            percent: median,
            text: median < 0
                ? fasterText(faster, rows.length)
                : slowerText(faster, rows.length),
            detail: detail,
          ),
          const SizedBox(height: 4),
          _Lollipops(
            rows: rows,
            pair: pair,
            onTap: (id) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SegmentDetailScreen(segmentId: id),
              ),
            ),
          ),
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

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Note({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: CcColors.surfaceHi,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: CcColors.inkDim),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: CcColors.inkDim,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double percent;
  final String text;
  final String detail;

  const _SummaryCard({
    required this.percent,
    required this.text,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final color = percent <= 0 ? CcColors.ok : CcColors.ghostBehind;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: CcColors.surfaceHi,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Row(
        children: [
          Text(
            _percent(percent),
            style: CcType.displayStyle(size: 30, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: CcColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: CcColors.inkDim,
                    fontSize: 11.5,
                    height: 1.35,
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

/// "−1,7 %" con coma decimal y signo.
String _percent(double value) {
  final sign = value < 0 ? '−' : (value > 0 ? '+' : '');
  return '$sign${value.abs().toStringAsFixed(1).replaceAll('.', ',')} %';
}

String _time(num seconds) =>
    formatElapsedShort(Duration(seconds: seconds.round()));

/// "25:12 › 24:40" con una flecha de ícono: Rubik no trae el carácter
/// de flecha.
class _FromTo extends StatelessWidget {
  final num from;
  final num to;

  const _FromTo({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final style = CcType.label(size: 11.5, color: CcColors.inkDim);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_time(from), style: style),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Icon(Icons.arrow_forward, size: 11, color: CcColors.inkFaint),
        ),
        Text(_time(to), style: style),
      ],
    );
  }
}

/// Una fila por segmento: de la raya (antes / sin coach) al punto (con la
/// app / con coach), en una escala común en porcentaje.
class _Lollipops extends StatelessWidget {
  final List<SegmentComparisonRow> rows;
  final ComparisonPair pair;
  final void Function(int segmentId) onTap;

  const _Lollipops({
    required this.rows,
    required this.pair,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const metric = ComparisonMetric.median;
    final values = [
      for (final r in rows) r.comparison.deltaPercent(pair, metric)!,
    ];
    // El cero se corre según hacia dónde van los datos: casi todo
    // negativo (mejoras) deja el cero a la derecha, con espacio para las
    // barras.
    final neg = math.max(0.5, -values.reduce(math.min));
    final pos = math.max(0.5, values.reduce(math.max));
    final total = neg + pos;
    final zero = neg / total;

    (num, num) groups(SegmentComparison c) => switch (pair) {
      ComparisonPair.appVsBefore => (
        c.before.medianSeconds!,
        c.withApp.medianSeconds!,
      ),
      ComparisonPair.coachVsNoCoach => (
        c.withoutCoach.medianSeconds!,
        c.coached.medianSeconds!,
      ),
    };

    return Column(
      children: [
        for (final r in rows)
          InkWell(
            onTap: () => onTap(r.segment.id),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: CcColors.lineSoft)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.segment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CcColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _FromTo(
                        from: groups(r.comparison).$1,
                        to: groups(r.comparison).$2,
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 52,
                        child: Text(
                          _percent(r.comparison.deltaPercent(pair, metric)!),
                          textAlign: TextAlign.right,
                          style: CcType.label(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: r.comparison.deltaPercent(pair, metric)! <= 0
                                ? CcColors.ok
                                : CcColors.ghostBehind,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 12,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _LollipopPainter(
                        zero: zero,
                        value: r.comparison.deltaPercent(pair, metric)! / total,
                      ),
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

class _LollipopPainter extends CustomPainter {
  /// Dónde va el cero (0-1 del ancho).
  final double zero;

  /// El valor en fracción del ancho (negativo = a la izquierda).
  final double value;

  _LollipopPainter({required this.zero, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 6.0;
    final w = size.width - 2 * inset;
    final cy = size.height / 2;
    final x0 = inset + zero * w;
    final x1 = inset + (zero + value) * w;
    final color = value <= 0 ? CcColors.ok : CcColors.ghostBehind;

    canvas.drawLine(
      Offset(inset, cy),
      Offset(size.width - inset, cy),
      Paint()
        ..color = CcColors.lineSoft
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(x0, 0),
      Offset(x0, size.height),
      Paint()
        ..color = CcColors.inkFaint
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(x0, cy),
      Offset(x1, cy),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
    canvas.drawCircle(Offset(x1, cy), 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LollipopPainter old) =>
      old.zero != zero || old.value != value;
}
