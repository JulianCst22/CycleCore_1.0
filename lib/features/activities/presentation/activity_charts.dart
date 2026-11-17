import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/geo/geo.dart';
import '../../../core/ui/ui.dart';
import '../domain/segment_effort_analysis.dart';
import 'activity_colors.dart';
import '../../../core/database/database.dart';

enum ChartOverlay { heartRate, speed, slope, power, cadence }

/// La grabación contra la que se compara en el gráfico: en el análisis de
/// un esfuerzo en un segmento, la mejor marca en ese segmento.
class ChartComparison {
  final List<RoutePointSnapshot> points;

  /// Nombre corto, para el botón: "Mejor marca".
  final String label;

  /// Cómo se dice en una frase: "tu mejor marca".
  final String phrase;

  const ChartComparison({
    required this.points,
    required this.label,
    required this.phrase,
  });
}

/// Tarjeta de análisis de la actividad: gráfico de altimetría coloreado
/// por pendiente (tipo mapa de calor), con overlays opcionales de FC,
/// velocidad, pendiente, potencia y cadencia que se pueden combinar
/// sobre el mismo gráfico, y un "scrubber" que se arrastra para ver los
/// valores exactos en cualquier punto del recorrido -- igual que en
/// Garmin Connect/Strava.
///
/// El eje horizontal es la distancia. Con [comparison] (un esfuerzo en un
/// segmento contra la mejor marca) se pueden superponer las curvas de la
/// otra grabación y aparece debajo la ventaja en segundos punto a punto,
/// con el mismo scrubber.
class ActivityChartsCard extends StatefulWidget {
  final List<RoutePointSnapshot> points;
  final ChartComparison? comparison;

  const ActivityChartsCard({super.key, required this.points, this.comparison});

  @override
  State<ActivityChartsCard> createState() => _ActivityChartsCardState();
}

class _ActivityChartsCardState extends State<ActivityChartsCard> {
  // Un recorrido largo puede tener miles de puntos GPS; pintarlos todos
  // sería costoso y no aportaría resolución visual extra. Se reduce a
  // una muestra uniforme que sigue cubriendo todo el recorrido.
  static const int _maxSamples = 220;

  // Ancho del promedio móvil que suaviza la pendiente antes de
  // dibujarla (tanto el coloreado del área como el overlay "Pendiente").
  // La pendiente instantánea punto a punto es ruidosa -- un tramo
  // llano real puede registrar +3%/-2%/+1% de un punto GPS al
  // siguiente -- y eso se veía como una sucesión de picos que no
  // reflejaban el terreno real. Suavizado, el color/la línea cambian
  // gradualmente, como en Strava/Garmin, sin que el usuario note el
  // ruido punto a punto original.
  static const int _slopeSmoothingWindow = 9;

  late List<RoutePointSnapshot> _sampled;

  /// Altitud de cada punto de [_sampled] en el perfil limpio con que se
  /// mide el desnivel (`cleanRouteProfile`): lo que se dibuja es lo que
  /// se cuenta.
  late List<double> _altitudes;

  /// Posición horizontal (0 a 1) de cada punto de [_sampled]: la
  /// distancia recorrida. Antes era el número de punto, que estiraba las
  /// subidas lentas (más puntos por metro) y las hacía ver más tendidas.
  late List<double> _fractions;
  late List<double> _smoothedSlopes;

  /// La grabación de [ActivityChartsCard.comparison], muestreada igual.
  List<RoutePointSnapshot>? _comparisonSampled;
  List<double>? _comparisonFractions;

  /// Segundos de ventaja sobre la comparación en cada punto de [_sampled].
  List<double>? _advantage;
  bool _showComparison = true;

  final Set<ChartOverlay> _overlays = {};
  int? _scrubIndex;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  /// Puntos nuevos (p. ej. tras "Ajustar altimetría"): se vuelve a
  /// muestrear; si no, el perfil seguía dibujando la altitud vieja.
  @override
  void didUpdateWidget(covariant ActivityChartsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.points, widget.points) ||
        !identical(oldWidget.comparison?.points, widget.comparison?.points)) {
      _prepare();
      final scrub = _scrubIndex;
      if (scrub != null && scrub >= _sampled.length) _scrubIndex = null;
    }
  }

  void _prepare() {
    final points = widget.points;
    final clean = cleanRouteProfile(
      [for (final p in points) p.altitude],
      [for (final p in points) p.distanceFromStartMeters],
    );
    final indices = _downsample(points.length, _maxSamples);
    _sampled = [for (final i in indices) points[i]];
    _altitudes = [for (final i in indices) clean[i]];
    _fractions = _fractionsOf(_sampled);
    _smoothedSlopes = _smoothSlopes(_sampled, _slopeSmoothingWindow);

    final comparison = widget.comparison;
    if (comparison != null && comparison.points.length >= 2) {
      final other = comparison.points;
      final otherIndices = _downsample(other.length, _maxSamples);
      final sampled = [for (final i in otherIndices) other[i]];
      _comparisonSampled = sampled;
      _comparisonFractions = _fractionsOf(sampled);
      _advantage = advantageSeconds(_sampled, other);
    } else {
      _comparisonSampled = null;
      _comparisonFractions = null;
      _advantage = null;
    }
  }

  /// Distancia de cada punto como fracción del total (0 a 1). Si la
  /// grabación no avanzó (rodillo sin sensor), por número de punto.
  static List<double> _fractionsOf(List<RoutePointSnapshot> points) {
    final n = points.length;
    final start = points.first.distanceFromStartMeters;
    final total = points.last.distanceFromStartMeters - start;
    if (total <= 0) {
      return [for (var i = 0; i < n; i++) n < 2 ? 0 : i / (n - 1)];
    }
    return [
      for (final p in points)
        ((p.distanceFromStartMeters - start) / total).clamp(0.0, 1.0),
    ];
  }

  /// Índices de una muestra uniforme de a lo sumo [maxCount] puntos.
  List<int> _downsample(int length, int maxCount) {
    if (length <= maxCount) return List.generate(length, (i) => i);
    final step = length / maxCount;
    return List.generate(
      maxCount,
      (i) => (i * step).floor().clamp(0, length - 1),
    );
  }

  /// Promedio móvil simple sobre `slopePercent` -- los extremos usan
  /// una ventana más angosta (no hay vecinos de sobra a los lados) en
  /// vez de dejarse sin suavizar, para que el inicio/fin del gráfico no
  /// contraste feo contra el resto ya suave.
  List<double> _smoothSlopes(List<RoutePointSnapshot> points, int windowSize) {
    final half = windowSize ~/ 2;
    return List<double>.generate(points.length, (i) {
      final start = math.max(0, i - half);
      final end = math.min(points.length - 1, i + half);
      double sum = 0;
      for (int j = start; j <= end; j++) {
        sum += points[j].slopePercent;
      }
      return sum / (end - start + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sampled.length < 2) return const SizedBox.shrink();

    final hasHeartRateData = _sampled.any((p) => p.heartRateBpm != null);
    final hasPowerData = _sampled.any((p) => p.powerWatts != null);
    final hasCadenceData = _sampled.any((p) => p.cadenceRpm != null);
    final activeIndex = _scrubIndex ?? _sampled.length - 1;
    final activePoint = _sampled[activeIndex];
    final comparison = widget.comparison;
    final comparisonSampled = _comparisonSampled;
    final advantage = _advantage;

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
        Text(
          comparison == null || comparisonSampled == null
              ? 'Desliza el dedo sobre el gráfico para ver el detalle en '
                  'cada punto. Combina overlays para comparar.'
              : 'Desliza el dedo sobre el gráfico para ver el detalle en '
                  'cada punto. Las líneas tenues son de ${comparison.phrase}.',
          style: const TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 11.5,
          ),
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
            if (comparison != null && comparisonSampled != null)
              _OverlayChip(
                label: 'vs. ${comparison.label}',
                color: AppColors.accentTime,
                selected: _showComparison,
                enabled: true,
                onTap: () =>
                    setState(() => _showComparison = !_showComparison),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _Readout(
          point: activePoint,
          altitude: _altitudes[activeIndex],
          isScrubbing: _scrubIndex != null,
          showHeartRate: hasHeartRateData,
          showPower: hasPowerData,
          showCadence: hasCadenceData,
          advantageSeconds: advantage?[activeIndex],
        ),
        const SizedBox(height: 10),
        _InteractiveChart(
          points: _sampled,
          altitudes: _altitudes,
          fractions: _fractions,
          smoothedSlopes: _smoothedSlopes,
          overlays: _overlays,
          comparison: _showComparison ? comparisonSampled : null,
          comparisonFractions: _comparisonFractions,
          scrubIndex: _scrubIndex,
          onScrub: (index) => setState(() => _scrubIndex = index),
        ),
        if (comparison != null && advantage != null) ...[
          const SizedBox(height: 16),
          Text(
            'VENTAJA SOBRE ${comparison.phrase.toUpperCase()}',
            style: const TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Arriba de la línea ibas adelante; abajo, atrás.',
            style: TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 8),
          _AdvantageChart(
            fractions: _fractions,
            advantage: advantage,
            scrubIndex: _scrubIndex,
            onScrub: (index) => setState(() => _scrubIndex = index),
          ),
        ],
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

/// Valores puntuales, ya sea del punto arrastrado (scrub) o del final del
/// recorrido por defecto.
///
/// Todos quedan a la vista: con más de cinco datos van en dos filas.
/// Antes era una sola fila desplazable de lado y en el teléfono solo se
/// veían los cinco primeros -- la potencia y la cadencia quedaban fuera
/// de la pantalla y parecía que no estaban. FC, potencia y cadencia
/// salen solo si la salida trae ese sensor.
///
/// A propósito sigue mostrando `point.slopePercent` SIN suavizar -- acá
/// es un dato puntual ("¿cuánto tengo justo en este metro?"), no una
/// curva que se recorre con la vista, así que no aplica el mismo
/// criterio que en el gráfico.
class _Readout extends StatelessWidget {
  final RoutePointSnapshot point;

  /// Altitud del perfil dibujado en ese punto.
  final double altitude;
  final bool isScrubbing;
  final bool showHeartRate;
  final bool showPower;
  final bool showCadence;

  /// Segundos de ventaja sobre la grabación comparada en este punto
  /// (positivo = adelante), o `null` si no se compara.
  final double? advantageSeconds;

  const _Readout({
    required this.point,
    required this.altitude,
    required this.isScrubbing,
    required this.showHeartRate,
    required this.showPower,
    required this.showCadence,
    this.advantageSeconds,
  });

  static const int _maxPerRow = 5;

  @override
  Widget build(BuildContext context) {
    final stats = <Widget>[
      _ReadoutStat(
        icon: Icons.straighten,
        color: AppColors.accentDistance,
        value: formatDistanceKm(point.distanceFromStartMeters),
        unit: 'km',
      ),
      _ReadoutStat(
        icon: Icons.terrain,
        color: AppColors.accentElevation,
        value: altitude.toStringAsFixed(0),
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
      if (showHeartRate)
        _ReadoutStat(
          icon: Icons.favorite,
          color: AppColors.accentHeartRate,
          value: point.heartRateBpm?.toString() ?? '--',
          unit: 'bpm',
        ),
      if (showPower)
        _ReadoutStat(
          icon: Icons.electric_bolt,
          color: AppColors.accentPower,
          value: point.powerWatts?.toString() ?? '--',
          unit: 'W',
        ),
      if (showCadence)
        _ReadoutStat(
          icon: Icons.autorenew,
          color: AppColors.accentCadence,
          value: point.cadenceRpm?.round().toString() ?? '--',
          unit: 'rpm',
        ),
      if (advantageSeconds != null)
        () {
          final seconds = advantageSeconds!.round();
          return _ReadoutStat(
            icon: Icons.timer_outlined,
            color: seconds > 0
                ? AppColors.ghostAhead
                : seconds < 0
                    ? AppColors.ghostBehind
                    : AppColors.accentTime,
            value: formatElapsedShort(Duration(seconds: seconds)),
            unit: seconds > 0
                ? 'adelante'
                : seconds < 0
                    ? 'atrás'
                    : 'igual',
          );
        }(),
    ];
    // Filas parejas (7 = 4 + 3, 6 = 3 + 3) y la última rellena con
    // huecos para que las columnas queden alineadas.
    final perRow = stats.length <= _maxPerRow
        ? stats.length
        : (stats.length / 2).ceil();
    final rows = <Widget>[];
    for (var i = 0; i < stats.length; i += perRow) {
      final row = stats.sublist(i, math.min(i + perRow, stats.length));
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(
        Row(
          children: [
            for (final stat in row) Expanded(child: stat),
            for (var k = row.length; k < perRow; k++)
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: rows),
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
    return FittedBox(
      fit: BoxFit.scaleDown,
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

/// Índice del punto cuya posición horizontal ([fractions], 0 a 1 y
/// creciente) queda más cerca de [fraction].
int _nearestIndex(List<double> fractions, double fraction) {
  var lo = 0;
  var hi = fractions.length - 1;
  while (lo < hi) {
    final mid = (lo + hi) ~/ 2;
    if (fractions[mid] < fraction) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  if (lo > 0 && (fraction - fractions[lo - 1]) < (fractions[lo] - fraction)) {
    return lo - 1;
  }
  return lo;
}

/// Toques y arrastres sobre un gráfico: la posición horizontal se
/// traduce al punto más cercano en distancia.
class _ScrubArea extends StatelessWidget {
  final List<double> fractions;
  final double height;
  final ValueChanged<int?> onScrub;
  final CustomPainter painter;

  const _ScrubArea({
    required this.fractions,
    required this.height,
    required this.onScrub,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void handle(Offset position) => onScrub(
          _nearestIndex(fractions, (position.dx / width).clamp(0.0, 1.0)),
        );
        return GestureDetector(
          onPanDown: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          onTapDown: (d) => handle(d.localPosition),
          child: SizedBox(
            height: height,
            width: width,
            child: CustomPaint(painter: painter),
          ),
        );
      },
    );
  }
}

/// El gráfico principal: altimetría, overlays y, si se compara, las
/// curvas de la otra grabación.
class _InteractiveChart extends StatelessWidget {
  final List<RoutePointSnapshot> points;
  final List<double> altitudes;
  final List<double> fractions;
  final List<double> smoothedSlopes;
  final Set<ChartOverlay> overlays;
  final List<RoutePointSnapshot>? comparison;
  final List<double>? comparisonFractions;
  final int? scrubIndex;
  final ValueChanged<int?> onScrub;

  const _InteractiveChart({
    required this.points,
    required this.altitudes,
    required this.fractions,
    required this.smoothedSlopes,
    required this.overlays,
    required this.comparison,
    required this.comparisonFractions,
    required this.scrubIndex,
    required this.onScrub,
  });

  @override
  Widget build(BuildContext context) {
    return _ScrubArea(
      fractions: fractions,
      height: 220,
      onScrub: onScrub,
      painter: _ChartPainter(
        points: points,
        altitudes: altitudes,
        fractions: fractions,
        smoothedSlopes: smoothedSlopes,
        overlays: overlays,
        comparison: comparison,
        comparisonFractions: comparisonFractions,
        scrubIndex: scrubIndex,
      ),
    );
  }
}

/// Segundos de ventaja sobre la grabación comparada, a lo largo de la
/// distancia: verde arriba de cero (adelante), rojo abajo (atrás).
class _AdvantageChart extends StatelessWidget {
  final List<double> fractions;
  final List<double> advantage;
  final int? scrubIndex;
  final ValueChanged<int?> onScrub;

  const _AdvantageChart({
    required this.fractions,
    required this.advantage,
    required this.scrubIndex,
    required this.onScrub,
  });

  @override
  Widget build(BuildContext context) {
    return _ScrubArea(
      fractions: fractions,
      height: 110,
      onScrub: onScrub,
      painter: _AdvantagePainter(
        fractions: fractions,
        advantage: advantage,
        scrubIndex: scrubIndex,
      ),
    );
  }
}

class _AdvantagePainter extends CustomPainter {
  final List<double> fractions;
  final List<double> advantage;
  final int? scrubIndex;

  _AdvantagePainter({
    required this.fractions,
    required this.advantage,
    required this.scrubIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (advantage.length < 2) return;
    const pad = 8.0;
    // Simétrico alrededor de cero y con al menos ±10 s: una diferencia
    // de dos segundos no debe llenar el gráfico.
    final peak = math.max(10.0, advantage.map((a) => a.abs()).reduce(math.max));
    final mid = size.height / 2;
    final half = mid - pad;
    double x(int i) => fractions[i] * size.width;
    double y(double seconds) => mid - seconds / peak * half;

    void area(bool ahead) {
      final path = Path()..moveTo(x(0), mid);
      for (var i = 0; i < advantage.length; i++) {
        final a = advantage[i];
        path.lineTo(x(i), y(ahead ? math.max(0, a) : math.min(0, a)));
      }
      path
        ..lineTo(x(advantage.length - 1), mid)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = (ahead ? AppColors.ghostAhead : AppColors.ghostBehind)
              .withValues(alpha: 0.35),
      );
    }

    area(true);
    area(false);

    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );

    final line = Path();
    for (var i = 0; i < advantage.length; i++) {
      final point = Offset(x(i), y(advantage[i]));
      i == 0 ? line.moveTo(point.dx, point.dy) : line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Escala: el máximo arriba y abajo.
    final label = '${peak.round()} s';
    for (final top in [true, false]) {
      final painter = TextPainter(
        text: TextSpan(
          text: top ? '+$label' : '-$label',
          style: const TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(2, top ? 0 : size.height - painter.height),
      );
    }

    final scrub = scrubIndex;
    if (scrub != null) {
      final i = scrub.clamp(0, advantage.length - 1);
      canvas.drawLine(
        Offset(x(i), 0),
        Offset(x(i), size.height),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(
        Offset(x(i), y(advantage[i])),
        4,
        Paint()..color = AppColors.primary,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AdvantagePainter oldDelegate) =>
      oldDelegate.advantage != advantage ||
      oldDelegate.fractions != fractions ||
      oldDelegate.scrubIndex != scrubIndex;
}

class _ChartPainter extends CustomPainter {
  final List<RoutePointSnapshot> points;
  final List<double> altitudes;
  final List<double> fractions;
  final List<double> smoothedSlopes;
  final Set<ChartOverlay> overlays;
  final List<RoutePointSnapshot>? comparison;
  final List<double>? comparisonFractions;
  final int? scrubIndex;

  _ChartPainter({
    required this.points,
    required this.altitudes,
    required this.fractions,
    required this.smoothedSlopes,
    required this.overlays,
    required this.comparison,
    required this.comparisonFractions,
    required this.scrubIndex,
  });

  static const double _topPadding = 16;
  static const double _bottomPadding = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final n = points.length;
    var minAlt = altitudes.reduce(math.min);
    var maxAlt = altitudes.reduce(math.max);
    // Escala mínima: una salida casi plana se ve casi plana.
    if (maxAlt - minAlt < profileChartMinSpanMeters) {
      final mid = (minAlt + maxAlt) / 2;
      minAlt = mid - profileChartMinSpanMeters / 2;
      maxAlt = mid + profileChartMinSpanMeters / 2;
    }
    final altRange = maxAlt - minAlt;

    final chartHeight = size.height - _topPadding - _bottomPadding;
    final xs = [for (final f in fractions) f * size.width];
    final other = comparison;
    final otherFractions = comparisonFractions;
    final otherXs = other == null || otherFractions == null
        ? null
        : [for (final f in otherFractions) f * size.width];

    double xAt(int i) => xs[i];
    double altYAt(int i) =>
        _topPadding +
        chartHeight -
        ((altitudes[i] - minAlt) / altRange) * chartHeight;

    // --- Área de altitud, coloreada tramo a tramo según su pendiente
    // YA SUAVIZADA (`smoothedSlopes`, no `points[i].slopePercent`) --
    // así el color cambia de forma gradual en vez de saltar de un
    // punto GPS al siguiente.
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

      final avgSlope = (smoothedSlopes[i] + smoothedSlopes[i + 1]) / 2;
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

    // --- Overlays normalizados (0 a 1) sobre el mismo alto de gráfico.
    // Con comparación, las dos grabaciones comparten la escala (si no,
    // la línea de la otra no diría nada) y la otra va tenue. ---
    void overlay(
      ChartOverlay kind,
      Color color,
      double Function(RoutePointSnapshot p) valueOf,
    ) {
      if (!overlays.contains(kind)) return;
      final values = [for (final p in points) valueOf(p)];
      final otherValues = other == null
          ? null
          : [for (final p in other) valueOf(p)];
      var minV = values.reduce(math.min);
      var maxV = values.reduce(math.max);
      if (otherValues != null && otherValues.isNotEmpty) {
        minV = math.min(minV, otherValues.reduce(math.min));
        maxV = math.max(maxV, otherValues.reduce(math.max));
      }
      if (otherValues != null && otherXs != null) {
        _drawNormalizedLine(
          canvas,
          values: otherValues,
          xs: otherXs,
          minV: minV,
          maxV: maxV,
          color: color.withValues(alpha: 0.4),
          strokeWidth: 1.4,
          chartHeight: chartHeight,
        );
      }
      _drawNormalizedLine(
        canvas,
        values: values,
        xs: xs,
        minV: minV,
        maxV: maxV,
        color: color,
        strokeWidth: 2,
        chartHeight: chartHeight,
      );
    }

    overlay(
      ChartOverlay.heartRate,
      AppColors.accentHeartRate,
      (p) => (p.heartRateBpm ?? 0).toDouble(),
    );
    overlay(ChartOverlay.speed, AppColors.accentSpeed, (p) => p.speedKmh);
    if (overlays.contains(ChartOverlay.slope)) {
      // El overlay "Pendiente" también usa la versión suavizada -- si
      // usara `p.slopePercent` cruda se vería una sierra de picos
      // encima de un área de altitud ya suave, lo cual se ve
      // inconsistente y menos profesional. Es el mismo terreno en las
      // dos grabaciones, así que no se compara.
      _drawNormalizedLine(
        canvas,
        values: smoothedSlopes,
        xs: xs,
        minV: smoothedSlopes.reduce(math.min),
        maxV: smoothedSlopes.reduce(math.max),
        color: AppColors.accentSlope,
        strokeWidth: 2,
        chartHeight: chartHeight,
      );
    }
    overlay(
      ChartOverlay.power,
      AppColors.accentPower,
      (p) => (p.powerWatts ?? 0).toDouble(),
    );
    overlay(
      ChartOverlay.cadence,
      AppColors.accentCadence,
      (p) => p.cadenceRpm ?? 0,
    );

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
    required List<double> xs,
    required double minV,
    required double maxV,
    required Color color,
    required double strokeWidth,
    required double chartHeight,
  }) {
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = xs[i];
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
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.altitudes != altitudes ||
        oldDelegate.fractions != fractions ||
        oldDelegate.smoothedSlopes != smoothedSlopes ||
        oldDelegate.overlays != overlays ||
        oldDelegate.comparison != comparison ||
        oldDelegate.scrubIndex != scrubIndex;
  }
}