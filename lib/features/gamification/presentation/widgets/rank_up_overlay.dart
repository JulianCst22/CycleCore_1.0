import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import 'package:core_ui/core_ui.dart';
import '../../domain/rank_tier.dart';
import '../rank_tier_style.dart';

/// El festejo IMPONENTE de cambio de rango (niveles 5/10/15/20/25).
///
/// Distinto -- más grande -- que `LevelUpOverlay` (subida de nivel
/// normal dentro del mismo rango): estallido de luz + rayos girando +
/// el ícono del rango nuevo enorme + confeti, sobre el color del rango.
class RankUpFlow {
  RankUpFlow._();

  static Future<void> showRankUp(
    BuildContext context, {
    required RankTierInfo newRank,
    required RankTierInfo previousRank,
    int? totalXp,
  }) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Nuevo rango',
      barrierColor: Colors.black.withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, _, _) => RankUpOverlay(
        newRank: newRank,
        previousRank: previousRank,
        totalXp: totalXp,
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }
}

class RankUpOverlay extends StatefulWidget {
  final RankTierInfo newRank;
  final RankTierInfo previousRank;
  final int? totalXp;

  const RankUpOverlay({
    super.key,
    required this.newRank,
    required this.previousRank,
    this.totalXp,
  });

  @override
  State<RankUpOverlay> createState() => _RankUpOverlayState();
}

class _RankUpOverlayState extends State<RankUpOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _rays;
  late final AnimationController _bounce;
  late final AnimationController _fireworks;

  @override
  void initState() {
    super.initState();
    _rays = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _fireworks = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _rays.dispose();
    _bounce.dispose();
    _fireworks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.newRank.color;

    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rays,
                builder: (context, _) => CustomPaint(
                  painter: _BurstPainter(turns: _rays.value, color: color),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _fireworks,
                builder: (context, _) => CustomPaint(
                  painter: _FireworksPainter(
                    progress: _fireworks.value,
                    color: color,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.92, end: 1.08).animate(
                    CurvedAnimation(parent: _bounce, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.16),
                      border: Border.all(color: color, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.55),
                          blurRadius: 34,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(widget.newRank.icon, color: color, size: 58),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  '¡NUEVO RANGO!',
                  style: CcType.label(
                    size: 14,
                    color: CcColors.inkDim,
                  ).copyWith(letterSpacing: 3),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.newRank.label.toUpperCase(),
                  style: CcType.displayStyle(size: 40, color: color),
                ),
                const SizedBox(height: 10),
                Text(
                  'Coronaste el rango ${widget.previousRank.label}',
                  style: const TextStyle(color: CcColors.ink, fontSize: 14),
                ),
                if (widget.totalXp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_thousands(widget.totalXp!)} XP',
                    style: CcType.label(size: 12, color: CcColors.gold),
                  ),
                ],
                const SizedBox(height: 30),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Seguir subiendo'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Toca fuera para cerrar',
                  style: CcType.label(size: 11, color: CcColors.inkFaint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _thousands(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _BurstPainter extends CustomPainter {
  final double turns;
  final Color color;

  _BurstPainter({required this.turns, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.longestSide;

    canvas.drawCircle(
      center,
      size.shortestSide * 0.7,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                color.withValues(alpha: 0.28),
                color.withValues(alpha: 0.06),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.45, 1.0],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.shortestSide * 0.7),
            ),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(turns * 2 * math.pi);
    final ray = Paint()..color = color.withValues(alpha: 0.10);
    for (var i = 0; i < 12; i++) {
      canvas.rotate(2 * math.pi / 12);
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(-maxR * 0.04, maxR)
        ..lineTo(maxR * 0.04, maxR)
        ..close();
      canvas.drawPath(path, ray);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.turns != turns || old.color != color;
}

/// Fuegos artificiales: varios cohetes que suben y estallan en una
/// corona de partículas que caen y se apagan, escalonados y en bucle.
class _FireworksPainter extends CustomPainter {
  final double progress;
  final Color color;

  _FireworksPainter({required this.progress, required this.color});

  static const int _shells = 5;
  static const double _riseEnd = 0.32;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(21);
    final palette = [
      color,
      CcColors.gold,
      Colors.white,
      Color.lerp(color, Colors.white, 0.5)!,
    ];

    for (var i = 0; i < _shells; i++) {
      final launchX = size.width * (0.14 + rnd.nextDouble() * 0.72);
      final burstY = size.height * (0.10 + rnd.nextDouble() * 0.30);
      final spokes = 16 + (rnd.nextDouble() * 8).round();
      final c = palette[i % palette.length];

      final t = (progress + i / _shells) % 1.0;

      if (t < _riseEnd) {
        // Cohete subiendo.
        final rt = Curves.easeOut.transform(t / _riseEnd);
        final y = size.height - (size.height - burstY) * rt;
        canvas.drawCircle(
          Offset(launchX, y),
          2.2,
          Paint()..color = c.withValues(alpha: 0.9),
        );
        canvas.drawCircle(
          Offset(launchX, y + 10),
          1.3,
          Paint()..color = c.withValues(alpha: 0.3),
        );
        continue;
      }

      // Explosión.
      final et = (t - _riseEnd) / (1 - _riseEnd);
      final radius = 4 + Curves.easeOut.transform(et) * size.shortestSide * 0.3;
      final op = (1 - et * et).clamp(0.0, 1.0);
      final gravity = et * et * size.height * 0.06;

      if (et < 0.14) {
        final f = 1 - et / 0.14;
        canvas.drawCircle(
          Offset(launchX, burstY),
          14 * f,
          Paint()..color = Colors.white.withValues(alpha: 0.75 * f),
        );
      }

      final dot = Paint()..color = c.withValues(alpha: op * 0.95);
      for (var k = 0; k < spokes; k++) {
        final ang = k * 2 * math.pi / spokes;
        final p = Offset(
          launchX + math.cos(ang) * radius,
          burstY + math.sin(ang) * radius + gravity,
        );
        canvas.drawCircle(p, 1.7 * op + 0.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) =>
      old.progress != progress || old.color != color;
}
