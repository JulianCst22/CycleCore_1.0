import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../domain/activity_colors.dart';
import '../domain/activity_summary.dart';

enum ChartOverlay { heartRate, speed, slope, power, cadence }

/// Tarjeta de análisis de la actividad: gráfico de altimetría coloreado
/// por pendiente (tipo mapa de calor), con overlays opcionales de FC,
/// velocidad, pendiente, potencia y cadencia que se pueden combinar
/// sobre el mismo gráfico, y un "scrubber" que se arrastra para ver los
/// valores exactos en cualquier punto del recorrido -- igual que en
/// Garmin Connect/Strava.
class ActivityChartsCard extends StatefulWidget {
  final List<RoutePointSnapshot> points;

  const ActivityChartsCard({super.key, required this.points});

  @override
  State<ActivityChartsCard> createState() => _ActivityChartsCardState();
}

class _ActivityChartsCardState extends State<ActivityChartsCard> {
  // Un recorrido largo puede tener miles de puntos GPS; pintarlos todos
  // sería costoso y no aportaría resolución visual extra. Se reduce a
  // una muestra uniforme que sigue cubriendo todo el recorrido.
  static const int _maxSamples = 220;

  late final List<RoutePointSnapshot> _sampled;
  final Set<ChartOverlay> _overlays = {};
  int? _scrubIndex;

  @override
  void initState() {
    super.initState();
    _sampled = _downsample(widget.points, _maxSamples);
  }

  List<RoutePointSnapshot> _downsample(
    List<RoutePointSnapshot> points,
    int maxCount,
  ) {
    if (points.length <= maxCount) return points;
    final step = points.length / maxCount;
    return List.generate(
      maxCount,
      (i) => points[(i * step).floor().clamp(0, points.length - 1)],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sampled.length < 2) return const SizedBox.shrink();

    final hasHeartRateData = _sampled.any((p) => p.heartRateBpm != null);
    final hasPowerData = _sampled.any((p) => p.powerWatts != null);
    final hasCadenceData = _sampled.any((p) => p.cadenceRpm != null);
    final activeIndex = _scrubIndex ?? _sampled.length - 1;
    final activePoint = _sampled[activeIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ALTIMETRÍA Y ANÁLISIS',
          style: TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Desliza el dedo sobre el gráfico para ver el detalle en cada '
          'punto. Combina overlays para comparar.',
          style: TextStyle(color: AppColors.textSecondaryOnPanel, fontSize: 11.5),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _OverlayChip(
              label: 'FC',
              color: AppColors.accentHeartRate,
              selected: _overlays.contains(ChartOverlay.heartRate),
              enabled: hasHeartRateData,
              onTap: () => _toggleOverlay(ChartOverlay.heartRate),
            ),
            _OverlayChip(
              label: 'Velocidad',
              color: AppColors.accentSpeed,
              selected: _overlays.contains(ChartOverlay.speed),
              enabled: true,
              onTap: () => _toggleOverlay(ChartOverlay.speed),
            ),
            _OverlayChip(
              label: 'Pendiente',
              color: AppColors.accentSlope,
              selected: _overlays.contains(ChartOverlay.slope),
              enabled: true,
              onTap: () => _toggleOverlay(ChartOverlay.slope),
            ),
            _OverlayChip(
              label: 'Potencia',
              color: AppColors.accentPower,
              selected: _overlays.contains(ChartOverlay.power),
              enabled: hasPowerData,
              onTap: () => _toggleOverlay(ChartOverlay.power),
            ),
            _OverlayChip(
              label: 'Cadencia',
              color: AppColors.accentCadence,
              selected: _overlays.contains(ChartOverlay.cadence),
              enabled: hasCadenceData,
              onTap: () => _toggleOverlay(ChartOverlay.cadence),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Readout(point: activePoint, isScrubbing: _scrubIndex != null),
        const SizedBox(height: 10),
        _InteractiveChart(
          points: _sampled,
          overlays: _overlays,
          scrubIndex: _scrubIndex,
          onScrub: (index) => setState(() => _scrubIndex = index),
        ),
      ],
    );
  }

  void _toggleOverlay(ChartOverlay overlay) {
    setState(() {
      if (_overlays.contains(overlay)) {
        _overlays.remove(overlay);
      } else {
        _overlays.add(overlay);
      }
    });
  }
}

class _OverlayChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _OverlayChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimaryOnPanel
                      : AppColors.textSecondaryOnPanel,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de valores puntuales, ya sea del punto arrastrado (scrub) o del
/// final del recorrido por defecto. Se vuelve desplazable horizontalmente
/// porque con potencia y cadencia ya son 7 estadísticas -- en pantallas
/// angostas no caben todas cómodas en una sola fila fija.
class _Readout extends StatelessWidget {
  final RoutePointSnapshot point;
  final bool isScrubbing;

  const _Readout({required this.point, required this.isScrubbing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ReadoutStat(
              icon: Icons.straighten,
              color: AppColors.accentDistance,
              value: formatDistanceKm(point.distanceFromStartMeters),
              unit: 'km',
            ),
            _ReadoutStat(
              icon: Icons.terrain,
              color: AppColors.accentElevation,
              value: point.altitude.toStringAsFixed(0),
              unit: 'm',
            ),
            _ReadoutStat(
              icon: Icons.trending_up,
              color: AppColors.accentSlope,
              value: formatSlopePercent(point.slopePercent),
              unit: '%',
            ),
            _ReadoutStat(
              icon: Icons.speed,
              color: AppColors.accentSpeed,
              value: formatSpeedKmh(point.speedKmh),
              unit: 'km/h',
            ),
            _ReadoutStat(
              icon: Icons.favorite,
              color: AppColors.accentHeartRate,
              value: point.heartRateBpm?.toString() ?? '--',
              unit: 'bpm',
            ),
            _ReadoutStat(
              icon: Icons.electric_bolt,
              color: AppColors.accentPower,
              value: point.powerWatts?.toString() ?? '--',
              unit: 'W',
            ),
            _ReadoutStat(
              icon: Icons.autorenew,
              color: AppColors.accentCadence,
              value: point.cadenceRpm?.round().toString() ?? '--',
              unit: 'rpm',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadoutStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String unit;

  const _ReadoutStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: Column(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimaryOnPanel,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

/// El área táctil del gráfico: detecta toques/arrastres y traduce la
/// posición horizontal al índice de punto más cercano.
class _InteractiveChart extends StatelessWidget {
  final List<RoutePointSnapshot> points;
  final Set<ChartOverlay> overlays;
  final int? scrubIndex;
  final ValueChanged<int?> onScrub;

  const _InteractiveChart({
    required this.points,
    required this.overlays,
    required this.scrubIndex,
    required this.onScrub,
  });

  void _handle(Offset localPosition, double width) {
    final fraction = (localPosition.dx / width).clamp(0.0, 1.0);
    final index = (fraction * (points.length - 1)).round();
    onScrub(index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanDown: (d) => _handle(d.localPosition, constraints.maxWidth),
          onPanUpdate: (d) => _handle(d.localPosition, constraints.maxWidth),
          onTapDown: (d) => _handle(d.localPosition, constraints.maxWidth),
          child: SizedBox(
            height: 220,
            width: constraints.maxWidth,
            child: CustomPaint(
              painter: _ChartPainter(
                points: points,
                overlays: overlays,
                scrubIndex: scrubIndex,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<RoutePointSnapshot> points;
  final Set<ChartOverlay> overlays;
  final int? scrubIndex;

  _ChartPainter({
    required this.points,
    required this.overlays,
    required this.scrubIndex,
  });

  static const double _topPadding = 16;
  static const double _bottomPadding = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final n = points.length;
    final altitudes = points.map((p) => p.altitude).toList();
    final minAlt = altitudes.reduce(math.min);
    final maxAlt = altitudes.reduce(math.max);
    final altRange = (maxAlt - minAlt).abs() < 1 ? 1.0 : (maxAlt - minAlt);

    final chartHeight = size.height - _topPadding - _bottomPadding;
    final stepX = size.width / (n - 1);

    double xAt(int i) => i * stepX;
    double altYAt(int i) =>
        _topPadding +
        chartHeight -
        ((points[i].altitude - minAlt) / altRange) * chartHeight;

    // --- Área de altitud, coloreada tramo a tramo según su pendiente ---
    for (int i = 0; i < n - 1; i++) {
      final x1 = xAt(i);
      final x2 = xAt(i + 1);
      final y1 = altYAt(i);
      final y2 = altYAt(i + 1);
      final baseline = _topPadding + chartHeight;

      final segmentPath = Path()
        ..moveTo(x1, baseline)
        ..lineTo(x1, y1)
        ..lineTo(x2, y2)
        ..lineTo(x2, baseline)
        ..close();

      final avgSlope = (points[i].slopePercent + points[i + 1].slopePercent) / 2;
      canvas.drawPath(
        segmentPath,
        Paint()..color = slopeToColor(avgSlope).withValues(alpha: 0.55),
      );
    }

    // Contorno de la altitud, para que se vea nítido sobre el relleno.
    final outline = Path();
    for (int i = 0; i < n; i++) {
      final x = xAt(i);
      final y = altYAt(i);
      if (i == 0) {
        outline.moveTo(x, y);
      } else {
        outline.lineTo(x, y);
      }
    }
    canvas.drawPath(
      outline,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // --- Overlays normalizados (0 a 1) sobre el mismo alto de gráfico ---
    if (overlays.contains(ChartOverlay.heartRate)) {
      _drawNormalizedLine(
        canvas,
        values: points.map((p) => (p.heartRateBpm ?? 0).toDouble()).toList(),
        color: AppColors.accentHeartRate,
        chartHeight: chartHeight,
        stepX: stepX,
      );
    }
    if (overlays.contains(ChartOverlay.speed)) {
      _drawNormalizedLine(
        canvas,
        values: points.map((p) => p.speedKmh).toList(),
        color: AppColors.accentSpeed,
        chartHeight: chartHeight,
        stepX: stepX,
      );
    }
    if (overlays.contains(ChartOverlay.slope)) {
      _drawNormalizedLine(
        canvas,
        values: points.map((p) => p.slopePercent).toList(),
        color: AppColors.accentSlope,
        chartHeight: chartHeight,
        stepX: stepX,
      );
    }
    if (overlays.contains(ChartOverlay.power)) {
      _drawNormalizedLine(
        canvas,
        values: points.map((p) => (p.powerWatts ?? 0).toDouble()).toList(),
        color: AppColors.accentPower,
        chartHeight: chartHeight,
        stepX: stepX,
      );
    }
    if (overlays.contains(ChartOverlay.cadence)) {
      _drawNormalizedLine(
        canvas,
        values: points.map((p) => p.cadenceRpm ?? 0).toList(),
        color: AppColors.accentCadence,
        chartHeight: chartHeight,
        stepX: stepX,
      );
    }

    // --- Línea vertical de "scrubbing" ---
    if (scrubIndex != null) {
      final i = scrubIndex!.clamp(0, n - 1);
      final x = xAt(i);
      canvas.drawLine(
        Offset(x, _topPadding),
        Offset(x, _topPadding + chartHeight),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(Offset(x, altYAt(i)), 4, Paint()..color = AppColors.primary);
    }
  }

  void _drawNormalizedLine(
    Canvas canvas, {
    required List<double> values,
    required Color color,
    required double chartHeight,
    required double stepX,
  }) {
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = _topPadding + chartHeight - ((values[i] - minV) / range) * chartHeight;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.overlays != overlays ||
        oldDelegate.scrubIndex != scrubIndex;
  }
}
