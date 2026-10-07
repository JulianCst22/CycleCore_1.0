import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/geo/geo.dart';
import '../../../../core/ui/ui.dart';
import '../../domain/segment_cockpit_field.dart';

/// Cabecera fija de la pantalla de segmento: dónde vas dentro del tramo.
///
/// Junta en un solo bloque lo que antes eran tres recuadros sueltos
/// (mapa, perfil y barra de progreso): el trazado con lo recorrido
/// encendido, cuánto falta y el perfil de altimetría con el «estás
/// aquí». Siempre está, no se configura: es la respuesta a «¿cuánto me
/// queda?», que es lo primero que se pregunta en una subida.
///
/// Se dibuja sin teselas de mapa a propósito: en la montaña muchas veces
/// no hay señal, y un mapa gris no dice nada. La forma del tramo sí.
class SegmentRouteHeader extends StatelessWidget {
  final List<SegmentProfilePoint> points;
  final SegmentLiveData data;

  const SegmentRouteHeader({
    super.key,
    required this.points,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (data.progressFraction * 100).clamp(0, 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: CcColors.surfaceHi,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: CcColors.surfaceInset,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: points.length < 2
                    ? const Icon(Icons.flag, color: CcColors.inkFaint)
                    : CustomPaint(
                        painter: _RouteShapePainter(
                          points: points,
                          alongMeters: data.alongMeters,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _km(data.remainingMeters),
                          style: CcType.displayStyle(
                            size: 30,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'km',
                          style: CcType.label(size: 13, color: CcColors.inkDim),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'para coronar',
                          style: CcType.label(size: 11, color: CcColors.inkDim),
                        ),
                        const Spacer(),
                        _DeltaChip(data: data),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${data.remainingElevationGainMeters.round()} m por subir',
                      style: CcType.label(size: 12, color: CcColors.inkDim),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: data.progressFraction.clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: CcColors.line,
                              valueColor: const AlwaysStoppedAnimation(
                                CcColors.segmentActiveTrack,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$percent %',
                          style: CcType.label(size: 11, color: CcColors.ink),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (points.length >= 2) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: CustomPaint(
                painter: _ProfilePainter(
                  points: points,
                  alongMeters: data.alongMeters,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Kilómetros con coma decimal: «3,2»; con menos de 1 km, «0,45».
  static String _km(double meters) {
    final km = meters / 1000;
    final text = km >= 1 ? km.toStringAsFixed(1) : km.toStringAsFixed(2);
    return text.replaceAll('.', ',');
  }
}

/// Ventaja o retraso contra la mejor marca, en el mismo punto del tramo.
class _DeltaChip extends StatelessWidget {
  final SegmentLiveData data;

  const _DeltaChip({required this.data});

  @override
  Widget build(BuildContext context) {
    final delta = data.deltaVsPr;
    if (delta == null) {
      return Text(
        data.bestTime == null ? '1.er intento' : '',
        style: CcType.label(size: 11, color: CcColors.inkFaint),
      );
    }
    final ahead = delta.isNegative;
    final even = delta.inSeconds == 0;
    final color = even
        ? CcColors.inkDim
        : (ahead ? CcColors.ghostAhead : CcColors.ghostBehind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        even ? '= PR' : '${formatSignedDuration(delta)} PR',
        style: CcType.label(size: 12, color: color, weight: FontWeight.w700),
      ),
    );
  }
}

/// Forma del tramo: lo recorrido en turquesa, lo que falta en gris, y el
/// punto donde vas.
class _RouteShapePainter extends CustomPainter {
  final List<SegmentProfilePoint> points;
  final double alongMeters;

  _RouteShapePainter({required this.points, required this.alongMeters});

  @override
  void paint(Canvas canvas, Size size) {
    var minLat = points.first.latitude, maxLat = minLat;
    var minLng = points.first.longitude, maxLng = minLng;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    // Proyección equirectangular: a esta escala basta con corregir la
    // longitud por el coseno de la latitud para no deformar la forma.
    final cosLat = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final w = math.max((maxLng - minLng) * cosLat, 1e-9);
    final h = math.max(maxLat - minLat, 1e-9);
    const pad = 9.0;
    final scale = math.min(
      (size.width - 2 * pad) / w,
      (size.height - 2 * pad) / h,
    );
    final dx = (size.width - w * scale) / 2;
    final dy = (size.height - h * scale) / 2;
    Offset at(double lat, double lng) => Offset(
      dx + (lng - minLng) * cosLat * scale,
      dy + (maxLat - lat) * scale,
    );

    final all = Path();
    for (var i = 0; i < points.length; i++) {
      final o = at(points[i].latitude, points[i].longitude);
      i == 0 ? all.moveTo(o.dx, o.dy) : all.lineTo(o.dx, o.dy);
    }

    // Lo recorrido: hasta el último punto pasado y, de ahí, un trozo
    // interpolado hasta donde va.
    final done = Path();
    var here = at(points.first.latitude, points.first.longitude);
    done.moveTo(here.dx, here.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1], p = points[i];
      final o = at(p.latitude, p.longitude);
      if (p.distanceFromStartMeters <= alongMeters) {
        done.lineTo(o.dx, o.dy);
        here = o;
        continue;
      }
      final span = p.distanceFromStartMeters - prev.distanceFromStartMeters;
      final t = span <= 0
          ? 0.0
          : (alongMeters - prev.distanceFromStartMeters) / span;
      here = Offset.lerp(here, o, t.clamp(0.0, 1.0))!;
      done.lineTo(here.dx, here.dy);
      break;
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      all,
      stroke
        ..color = CcColors.segmentIdleTrack
        ..strokeWidth = 3,
    );
    canvas.drawPath(
      done,
      stroke
        ..color = CcColors.segmentActiveTrack
        ..strokeWidth = 3.5,
    );

    final start = at(points.first.latitude, points.first.longitude);
    final end = at(points.last.latitude, points.last.longitude);
    canvas.drawCircle(start, 3.5, Paint()..color = CcColors.segmentStart);
    canvas.drawCircle(end, 4, Paint()..color = CcColors.ink);
    canvas.drawCircle(end, 2, Paint()..color = CcColors.surfaceInset);
    canvas.drawCircle(here, 6, Paint()..color = CcColors.ink);
    canvas.drawCircle(here, 4, Paint()..color = CcColors.segmentActiveTrack);
  }

  @override
  bool shouldRepaint(covariant _RouteShapePainter old) =>
      old.points != points || old.alongMeters != alongMeters;
}

/// Perfil de altimetría con lo recorrido apagado y lo que viene teñido
/// por la pendiente: así se ve de un vistazo dónde está la próxima rampa.
class _ProfilePainter extends CustomPainter {
  final List<SegmentProfilePoint> points;
  final double alongMeters;

  _ProfilePainter({required this.points, required this.alongMeters});

  @override
  void paint(Canvas canvas, Size size) {
    final total = points.last.distanceFromStartMeters;
    if (total <= 0) return;
    var minAlt = points.first.altitude, maxAlt = minAlt;
    for (final p in points) {
      minAlt = math.min(minAlt, p.altitude);
      maxAlt = math.max(maxAlt, p.altitude);
    }
    final span = maxAlt - minAlt;
    Offset at(double distance, double altitude) {
      final t = span <= 0 ? 0.5 : (altitude - minAlt) / span;
      return Offset(
        distance / total * size.width,
        size.height - 2 - t * (size.height - 6),
      );
    }

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final pa = at(a.distanceFromStartMeters, a.altitude);
      final pb = at(b.distanceFromStartMeters, b.altitude);
      final ridden = b.distanceFromStartMeters <= alongMeters;
      final slope = (a.slopePercent + b.slopePercent) / 2;
      canvas.drawPath(
        Path()
          ..moveTo(pa.dx, size.height)
          ..lineTo(pa.dx, pa.dy)
          ..lineTo(pb.dx, pb.dy)
          ..lineTo(pb.dx, size.height)
          ..close(),
        Paint()
          ..color = CyclecorePalette.slopeColorFor(
            slope,
          ).withValues(alpha: ridden ? 0.18 : 0.62),
      );
    }

    final line = Path();
    for (var i = 0; i < points.length; i++) {
      final o = at(points[i].distanceFromStartMeters, points[i].altitude);
      i == 0 ? line.moveTo(o.dx, o.dy) : line.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = CcColors.ink.withValues(alpha: 0.75),
    );

    // «Estás aquí».
    final x = (alongMeters / total).clamp(0.0, 1.0) * size.width;
    var altitude = points.first.altitude;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      if (b.distanceFromStartMeters < alongMeters) continue;
      final d = b.distanceFromStartMeters - a.distanceFromStartMeters;
      final t = d <= 0 ? 0.0 : (alongMeters - a.distanceFromStartMeters) / d;
      altitude = a.altitude + (b.altitude - a.altitude) * t.clamp(0.0, 1.0);
      break;
    }
    final y = at(alongMeters, altitude).dy;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = CcColors.segmentActiveTrack.withValues(alpha: 0.7)
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(Offset(x, y), 5, Paint()..color = CcColors.ink);
    canvas.drawCircle(
      Offset(x, y),
      3.5,
      Paint()..color = CcColors.segmentActiveTrack,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter old) =>
      old.points != points || old.alongMeters != alongMeters;
}
