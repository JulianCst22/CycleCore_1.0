import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import '../../domain/climb_progress.dart';
import '../../domain/climb_route.dart';
import 'package:cyclecore_core/gamification/rank_tier.dart';
import '../climb_collectibles_provider.dart';

/// El popup "Mi progreso": la altimetría REAL del Alto de Patios
/// (`ElevationProfile`, 2502 -> 3001 msnm en 5.92 km) con el tramo ya
/// conquistado resaltado, un punto por cada uno de los 30 niveles
/// (relleno si ya se descubrió su postal), el marcador "tú", y las 6
/// zonas de rango sobre el eje.
Future<void> showClimbProgressSheet(
  BuildContext context, {
  required double levelValue,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: CcColors.surfaceHi,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _ClimbProgressSheet(levelValue: levelValue),
  );
}

class _ClimbProgressSheet extends ConsumerWidget {
  final double levelValue;

  const _ClimbProgressSheet({required this.levelValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = climbProgressForLevelValue(levelValue);
    final collected = ref.watch(climbCollectiblesProvider).valueOrNull ?? {};
    final accent = progress.rank.color;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CcColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.terrain, size: 18, color: CcColors.inkDim),
                const SizedBox(width: 8),
                Text(
                  'Tu progreso · Alto de Patios',
                  style: CcType.displayStyle(size: 17),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Segmento real Belisario → Alto de Patios · '
              '${ElevationProfile.startAltitude.round()} a '
              '${ElevationProfile.summitAltitude.round()} msnm',
              style: CcType.label(size: 11, color: CcColors.inkFaint),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(
                painter: _ProfilePainter(
                  levelValue: levelValue,
                  collected: collected,
                  accent: accent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _RankZones(currentRank: progress.rank),
            const SizedBox(height: 20),
            Row(
              children: [
                _Stat(
                  label: 'CONQUISTADO',
                  value: 'km ${progress.distanceKm.toStringAsFixed(1)}',
                  sub:
                      'de ${ElevationProfile.totalDistanceKm.toStringAsFixed(1)}',
                  color: accent,
                ),
                _Stat(
                  label: 'POSTALES',
                  value: '${collected.length}',
                  sub: 'de ${ClimbRoute.maxLevel}',
                  color: CcColors.gold,
                ),
                _Stat(
                  label: 'ALTITUD',
                  value: '${progress.altitudeM.round()}',
                  sub: 'msnm',
                  color: CcColors.mElevation,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final double levelValue;
  final Set<int> collected;
  final Color accent;

  _ProfilePainter({
    required this.levelValue,
    required this.collected,
    required this.accent,
  });

  Offset _point(double km, double alt, Size size) {
    final minAlt = ElevationProfile.startAltitude;
    final maxAlt = ElevationProfile.summitAltitude;
    final x = (km / ElevationProfile.totalDistanceKm) * size.width;
    final t = (alt - minAlt) / (maxAlt - minAlt);
    return Offset(x, size.height - t * (size.height - 6) - 3);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final samples = ElevationProfile.samples;
    final line = Path();
    for (var i = 0; i < samples.length; i++) {
      final p = _point(samples[i].distanceKm, samples[i].altitudeM, size);
      i == 0 ? line.moveTo(p.dx, p.dy) : line.lineTo(p.dx, p.dy);
    }

    final currentFraction = climbFractionForLevelValue(levelValue);
    final currentX = currentFraction * size.width;

    // Relleno bajo la curva: conquistado (accent) a la izquierda, por
    // delante (tenue) a la derecha.
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, currentX, size.height));
    canvas.drawPath(fill, Paint()..color = accent.withValues(alpha: 0.28));
    canvas.restore();
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(currentX, 0, size.width - currentX, size.height),
    );
    canvas.drawPath(
      fill,
      Paint()..color = CcColors.inkFaint.withValues(alpha: 0.14),
    );
    canvas.restore();

    canvas.drawPath(
      line,
      Paint()
        ..color = CcColors.ink.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // Un punto por nivel/postal.
    for (var level = 1; level <= ClimbRoute.maxLevel; level++) {
      final poi = ClimbRoute.forLevel(level);
      final f = climbFractionForLevelValue(level.toDouble());
      final p = _point(
        f * ElevationProfile.totalDistanceKm,
        ElevationProfile.altitudeForFraction(f),
        size,
      );
      final reached = level <= levelValue;
      final has = collected.contains(level);
      canvas.drawCircle(
        p,
        has ? 3.4 : 2.6,
        Paint()
          ..color = has
              ? CcColors.gold
              : poi.tier.color.withValues(alpha: reached ? 0.9 : 0.35),
      );
      if (has) {
        canvas.drawCircle(
          p,
          3.4,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    // Marcador "tú".
    final me = _point(
      currentFraction * ElevationProfile.totalDistanceKm,
      ElevationProfile.altitudeForFraction(currentFraction),
      size,
    );
    canvas.drawLine(
      Offset(me.dx, size.height),
      me,
      Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(me, 5.5, Paint()..color = accent);
    canvas.drawCircle(
      me,
      5.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter old) =>
      old.levelValue != levelValue ||
      old.collected.length != collected.length ||
      old.accent != accent;
}

/// Franja de las 6 zonas de rango bajo el eje, alineadas a la fracción
/// de subida que ocupa cada rango.
class _RankZones extends StatelessWidget {
  final RankTierInfo currentRank;

  const _RankZones({required this.currentRank});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        children: [
          for (final tier in RankTier.all)
            Expanded(
              flex: _span(tier),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: tier.color.withValues(
                    alpha: tier.rank == currentRank.rank ? 0.9 : 0.3,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _span(RankTierInfo tier) {
    final max = ClimbRoute.maxLevel;
    final hi = tier.maxLevel > max ? max : tier.maxLevel;
    return (hi - tier.minLevel + 1).clamp(1, max);
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: CcType.label(size: 10, color: CcColors.inkFaint)),
          const SizedBox(height: 4),
          Text(value, style: CcType.displayStyle(size: 19, color: color)),
          Text(sub, style: CcType.label(size: 10, color: CcColors.inkDim)),
        ],
      ),
    );
  }
}
