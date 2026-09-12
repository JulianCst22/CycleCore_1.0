import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/database/app_database.dart';
import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import 'package:cyclecore_core/utils/format_utils.dart';
import '../segments_providers.dart';

/// Franja "Progreso" del detalle de segmento: TODOS los esfuerzos como
/// puntos en el tiempo (arriba = más rápido, la mejor marca en dorado),
/// dentro de un scroll horizontal que arranca en lo más reciente y se
/// desliza a la izquierda para ver desde el primer intento -- mismo
/// patrón que el mapa de niveles de la gamificación.
///
/// Un toggle decide entre puntos sueltos (se lee la dispersión: qué tan
/// constante eres) y línea de tendencia (se lee la trayectoria).
class SegmentProgressChart extends ConsumerStatefulWidget {
  final List<SegmentEffort> efforts;

  const SegmentProgressChart({super.key, required this.efforts});

  @override
  ConsumerState<SegmentProgressChart> createState() =>
      _SegmentProgressChartState();
}

class _SegmentProgressChartState extends ConsumerState<SegmentProgressChart> {
  final _scrollController = ScrollController();

  static const double _spacing = 48;
  static const double _sidePadding = 30;
  static const double _bandHeight = 150;

  late final List<SegmentEffort> _chronological;

  @override
  void initState() {
    super.initState();
    _chronological = [...widget.efforts]
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    // Arranca mostrando lo más reciente (extremo derecho).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(segmentProgressModeProvider);
    final contentWidth = _chronological.length * _spacing + _sidePadding * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'PROGRESO · ${_chronological.length} esfuerzos',
                style: CcType.label(
                  size: 11,
                  color: CcColors.inkFaint,
                ).copyWith(letterSpacing: 1.4),
              ),
            ),
            _ModeToggle(
              mode: mode,
              onChanged: (m) =>
                  ref.read(segmentProgressModeProvider.notifier).state = m,
            ),
          ],
        ),
        const SizedBox(height: 11),
        Container(
          height: _bandHeight,
          decoration: BoxDecoration(
            color: CcColors.surfaceInset,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CcColors.lineSoft),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = contentWidth < constraints.maxWidth
                  ? constraints.maxWidth
                  : contentWidth;
              final scrollable = width > constraints.maxWidth + 1;
              return Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: width,
                      height: _bandHeight,
                      child: CustomPaint(
                        painter: _ProgressPainter(
                          efforts: _chronological,
                          mode: mode,
                          spacing: _spacing,
                          sidePadding: _sidePadding,
                        ),
                      ),
                    ),
                  ),
                  if (scrollable)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          width: 48,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CcColors.surfaceInset,
                                Color(0x0012161E),
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: CcColors.inkFaint,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _LegendDot(color: CcColors.gold, label: 'Tu mejor marca'),
            const SizedBox(width: 14),
            _LegendDot(
              color: CcColors.inkDim,
              label: 'Cada intento (arriba = más rápido)',
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final SegmentProgressMode mode;
  final ValueChanged<SegmentProgressMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CcColors.surfaceInset,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('Puntos', SegmentProgressMode.dots),
          _seg('Línea', SegmentProgressMode.line),
        ],
      ),
    );
  }

  Widget _seg(String label, SegmentProgressMode value) {
    final selected = mode == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? CcColors.segmentActiveTrack : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF06110F) : CcColors.inkDim,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: CcColors.inkFaint, fontSize: 10.5),
        ),
      ],
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final List<SegmentEffort> efforts;
  final SegmentProgressMode mode;
  final double spacing;
  final double sidePadding;

  _ProgressPainter({
    required this.efforts,
    required this.mode,
    required this.spacing,
    required this.sidePadding,
  });

  static const double _topPad = 26;
  static const double _bottomPad = 22;

  @override
  void paint(Canvas canvas, Size size) {
    if (efforts.isEmpty) return;

    var minSeconds = efforts.first.durationSeconds;
    var maxSeconds = efforts.first.durationSeconds;
    for (final e in efforts) {
      if (e.durationSeconds < minSeconds) minSeconds = e.durationSeconds;
      if (e.durationSeconds > maxSeconds) maxSeconds = e.durationSeconds;
    }
    final range = maxSeconds - minSeconds;
    final plotH = size.height - _topPad - _bottomPad;

    double xAt(int i) => sidePadding + i * spacing;
    double yAt(int seconds) {
      if (range == 0) return _topPad + plotH / 2;
      return _topPad + ((seconds - minSeconds) / range) * plotH;
    }

    // Guías horizontales tenues.
    final guide = Paint()
      ..color = CcColors.line
      ..strokeWidth = 1;
    for (final f in const [0.33, 0.66]) {
      final y = _topPad + plotH * f;
      _dashedLine(canvas, Offset(0, y), Offset(size.width, y), guide);
    }

    final offsets = [
      for (var i = 0; i < efforts.length; i++)
        Offset(xAt(i), yAt(efforts[i].durationSeconds)),
    ];

    if (mode == SegmentProgressMode.line) {
      final area = Path()
        ..moveTo(offsets.first.dx, size.height - _bottomPad + 6);
      for (final o in offsets) {
        area.lineTo(o.dx, o.dy);
      }
      area.lineTo(offsets.last.dx, size.height - _bottomPad + 6);
      area.close();
      canvas.drawPath(
        area,
        Paint()..color = CcColors.segmentActiveTrack.withValues(alpha: 0.12),
      );

      final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final o in offsets.skip(1)) {
        line.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = CcColors.segmentActiveTrack
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round,
      );
    }

    var bestLabelDrawn = false;
    for (var i = 0; i < efforts.length; i++) {
      final o = offsets[i];
      final isBest = efforts[i].durationSeconds == minSeconds;
      if (isBest) {
        canvas.drawCircle(
          o,
          12,
          Paint()..color = CcColors.gold.withValues(alpha: 0.22),
        );
        canvas.drawCircle(o, 6, Paint()..color = CcColors.gold);
        if (!bestLabelDrawn) {
          _text(
            canvas,
            'PR ${formatElapsedShort(Duration(seconds: efforts[i].durationSeconds))}',
            Offset(o.dx, o.dy - 22),
            CcColors.gold,
          );
          bestLabelDrawn = true;
        }
      } else {
        canvas.drawCircle(
          o,
          mode == SegmentProgressMode.line ? 3.5 : 4.5,
          Paint()..color = CcColors.inkDim,
        );
      }
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 3.0;
    const gap = 5.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final start = a + dir * drawn;
      final end = a + dir * (drawn + dash).clamp(0, total).toDouble();
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }

  void _text(Canvas canvas, String value, Offset center, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: CcType.family,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) =>
      oldDelegate.efforts != efforts || oldDelegate.mode != mode;
}
