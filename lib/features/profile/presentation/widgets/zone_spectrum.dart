import 'package:flutter/material.dart';

import '../../../../core/ui/ui.dart';
import '../../domain/training_zones.dart';
import '../../domain/zone_guide.dart';

enum ZoneKind { power, heartRate }

/// Cómo se muestran unas zonas: color, nombre, rango y porcentaje de
/// cada una. Lo comparten la lista y la hoja de detalle.
class ZoneScale {
  final ZoneKind kind;
  final List<TrainingZone> zones;
  final int? ftp;
  final int? maxHr;
  final int? restingHr;

  const ZoneScale({
    required this.kind,
    required this.zones,
    this.ftp,
    this.maxHr,
    this.restingHr,
  });

  ZoneScale withZones(List<TrainingZone> zones) => ZoneScale(
    kind: kind,
    zones: zones,
    ftp: ftp,
    maxHr: maxHr,
    restingHr: restingHr,
  );

  bool get isPower => kind == ZoneKind.power;

  String get unit => isPower ? 'W' : 'ppm';

  /// De tenue a intenso en el color de la métrica: morado la potencia,
  /// rojo el pulso.
  Color colorOf(int i) {
    final (from, to) = isPower
        ? (const Color(0xFF4A3A55), const Color(0xFFD07BE0))
        : (const Color(0xFF553338), CcColors.mHeartRate);
    return Color.lerp(
      from,
      to,
      zones.length <= 1 ? 1 : i / (zones.length - 1),
    )!;
  }

  /// "Z4" de "Z4 · Umbral".
  String codeOf(int i) {
    final name = zones[i].name;
    final dot = name.indexOf(' · ');
    return dot > 0 ? name.substring(0, dot) : 'Z${i + 1}';
  }

  /// "Umbral" de "Z4 · Umbral".
  String labelOf(int i) {
    final name = zones[i].name;
    final dot = name.indexOf(' · ');
    return dot > 0 ? name.substring(dot + 3) : name;
  }

  String rangeOf(int i) {
    final z = zones[i];
    return z.max == null ? '${z.min}+' : '${z.min}–${z.max}';
  }

  /// "90–105 % FTP", o `null` si falta el dato de referencia.
  String? percentOf(int i) {
    final z = zones[i];
    final int Function(int) pct;
    final String suffix;
    if (isPower) {
      final f = ftp;
      if (f == null || f <= 0) return null;
      pct = (v) => (v * 100 / f).round();
      suffix = '% FTP';
    } else {
      final max = maxHr;
      if (max == null) return null;
      final rest = restingHr;
      if (rest != null && max > rest) {
        pct = (v) => ((v - rest) * 100 / (max - rest)).round();
        suffix = '% reserva';
      } else {
        pct = (v) => (v * 100 / max).round();
        suffix = '% FC máx';
      }
    }
    final top = z.max;
    if (z.min == 0 && top != null) return '< ${pct(top)} $suffix';
    final low = pct(i == 0 ? z.min : z.min - 1);
    if (top == null) return '> $low $suffix';
    return '$low–${pct(top)} $suffix';
  }

  ZoneGuide? guideOf(int i) => isPower
      ? ZoneGuide.power(i, zones.length)
      : ZoneGuide.heartRate(i, zones.length);

  int get start => zones.first.min;

  /// Hasta dónde se dibuja la última zona cuando no tiene tope.
  int get end => zones.last.max ?? (zones.last.min * 1.2).round();

  int endOf(int i) => zones[i].max ?? end;
}

/// Todas las zonas en una barra, cada una del ancho de su rango real.
/// Con [highlight], esa zona resalta y las demás se apagan.
class ZoneSpectrum extends StatelessWidget {
  final ZoneScale scale;
  final int? highlight;
  final bool showTicks;
  final double height;

  const ZoneSpectrum({
    super.key,
    required this.scale,
    this.highlight,
    this.showTicks = true,
    this.height = 16,
  });

  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    final zones = scale.zones;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final total = (scale.end - scale.start).clamp(1, 1 << 30);
        final usable = width - _gap * (zones.length - 1);
        double spanOf(int i) =>
            usable * (scale.endOf(i) - zones[i].min).clamp(1, total) / total;

        final lefts = <double>[];
        var x = 0.0;
        for (var i = 0; i < zones.length; i++) {
          lefts.add(x);
          x += spanOf(i) + _gap;
        }

        final bar = ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            width: width,
            child: Stack(
              children: [
                for (var i = 0; i < zones.length; i++)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 160),
                    left: lefts[i],
                    width: spanOf(i),
                    top: 0,
                    bottom: 0,
                    child: ColoredBox(
                      color: scale.colorOf(i).withValues(alpha: _alphaOf(i)),
                    ),
                  ),
              ],
            ),
          ),
        );
        if (!showTicks) return bar;

        // Debajo, el valor donde empieza cada zona. Si dos quedan muy
        // juntos, se salta el segundo para que no se encimen.
        final ticks = <Widget>[];
        var lastLabel = double.negativeInfinity;
        for (var i = 1; i < zones.length; i++) {
          final at = lefts[i] - _gap / 2;
          if (at - lastLabel < 26 || at > width - 10) continue;
          lastLabel = at;
          ticks.add(
            Positioned(
              left: at - 20,
              width: 40,
              top: 0,
              child: Text(
                '${zones[i].min}',
                textAlign: TextAlign.center,
                style: CcType.label(size: 10, color: CcColors.inkFaint),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            bar,
            const SizedBox(height: 4),
            SizedBox(
              height: 14,
              child: Stack(clipBehavior: Clip.none, children: ticks),
            ),
          ],
        );
      },
    );
  }

  double _alphaOf(int i) {
    final h = highlight;
    if (h == null || i == h) return 1;
    return (i - h).abs() == 1 ? 0.45 : 0.22;
  }
}
