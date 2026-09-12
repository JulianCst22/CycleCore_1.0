import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import 'package:cyclecore_core/gamification/rank_tier.dart';
import 'pedaling_cyclist.dart';

/// Cinemática breve que corta a **vista de perfil** para darle
/// protagonismo a la bici y al maillot:
///
/// - Al cruzar un arco de rango (nivel 5/10/15/20/25/30): la cámara
///   gira a perfil, un pórtico de meta del color del rango nuevo baja y
///   se planta sobre la vía, el ciclista hace un wheelie debajo, un
///   destello barre el cuadro y tu nombre aparece pintado en el piso.
///   Luego vuelve a la cámara de atrás. ([level] no nulo.)
/// - "Inspeccionar" (al tocar el ciclista): lo mismo pero sin banner ni
///   texto de rango -- sólo para ver el equipo. ([level] nulo.)
class LevelCinematic extends StatelessWidget {
  final Animation<double> progress;
  final int? level;
  final RankTierInfo rank;
  final CyclistKitVisual kit;

  /// Color del maillot (para el `PedalingCyclist`).
  final Color jerseyColor;
  final String? riderName;
  final VoidCallback? onSkip;

  const LevelCinematic({
    super.key,
    required this.progress,
    required this.level,
    required this.rank,
    required this.kit,
    required this.jerseyColor,
    required this.riderName,
    this.onSkip,
  });

  double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final isRankArch = level != null;

    return GestureDetector(
      onTap: onSkip,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final t = progress.value;

          // Movimiento de cámara: entra girada desde "atrás" y se asienta
          // despacio en la vista de perfil (easeOut, ~38% del tiempo), y
          // sale por el otro lado al final. `away` = cuánto está la
          // cámara todavía fuera del perfil (1 = de atrás, 0 = de lado).
          final inT = Curves.easeOutCubic.transform((t / 0.38).clamp(0.0, 1.0));
          final outT = Curves.easeInCubic.transform(
            ((t - 0.8) / 0.2).clamp(0.0, 1.0),
          );
          final away = ((1 - inT) + outT).clamp(0.0, 1.0);

          final fade = (t / 0.12).clamp(0.0, 1.0) * (1 - _seg(t, 0.92, 1));

          return Opacity(
            opacity: fade,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0016)
                ..translateByDouble(away * 26.0, away * 34.0, 0, 1)
                ..rotateY(away * 1.32)
                ..scaleByDouble(1 - away * 0.26, 1 - away * 0.26, 1, 1),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return _Scene(
                    t: t,
                    size: size,
                    isRankArch: isRankArch,
                    level: level ?? 0,
                    rank: rank,
                    kit: kit,
                    jerseyColor: jerseyColor,
                    riderName: riderName,
                    seg: _seg,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  final double t;
  final Size size;
  final bool isRankArch;
  final int level;
  final RankTierInfo rank;
  final CyclistKitVisual kit;
  final Color jerseyColor;
  final String? riderName;
  final double Function(double, double, double) seg;

  const _Scene({
    required this.t,
    required this.size,
    required this.isRankArch,
    required this.level,
    required this.rank,
    required this.kit,
    required this.jerseyColor,
    required this.riderName,
    required this.seg,
  });

  @override
  Widget build(BuildContext context) {
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.72;
    final cyclistSize = (h * 0.42).clamp(160.0, 320.0);
    // El ciclista rueda un poco de izquierda a derecha.
    final cyclistX = w * (0.42 + seg(t, 0.1, 0.9) * 0.06);

    return Stack(
      children: [
        // Fondo oscuro + resplandor del rango.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.2,
                colors: [rank.color.withValues(alpha: 0.16), CcColors.bg],
              ),
            ),
          ),
        ),
        // Piso + nombre pintado.
        Positioned(
          left: 0,
          right: 0,
          top: groundY,
          bottom: 0,
          child: CustomPaint(
            painter: _GroundPainter(name: riderName, accent: rank.color, t: t),
          ),
        ),
        // Pórtico del arco (sólo en cambio de rango): baja, se asienta y
        // se QUEDA fijo sobre la cabeza del ciclista -- después de que la
        // cámara se acomoda. El fundido general lo saca al final.
        if (isRankArch)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ArchPainter(
                  color: rank.color,
                  progress: seg(t, 0.40, 0.60),
                ),
              ),
            ),
          ),
        // Ciclista de perfil, grande, haciendo wheelie.
        Positioned(
          left: cyclistX - cyclistSize / 2,
          top: groundY - cyclistSize * 0.76,
          child: IgnorePointer(
            child: PedalingCyclist(
              color: jerseyColor,
              size: cyclistSize,
              cadence: 1.7,
              kit: kit,
              forceGesture: isRankArch ? CyclistGesture.wheelie : null,
            ),
          ),
        ),
        // Destello que barre el cuadro.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GleamPainter(progress: seg(t, 0.5, 0.86)),
            ),
          ),
        ),
        // Texto.
        Positioned(
          left: 0,
          right: 0,
          top: h * 0.09,
          child: Opacity(
            opacity: seg(t, 0.44, 0.54) * (1 - seg(t, 0.84, 0.94)),
            child: Column(
              children: [
                Text(
                  isRankArch ? 'NIVEL $level' : 'TU EQUIPO',
                  textAlign: TextAlign.center,
                  style: CcType.displayStyle(size: 30, color: CcColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  isRankArch ? rank.label.toUpperCase() : '',
                  textAlign: TextAlign.center,
                  style: CcType.label(
                    size: 15,
                    color: rank.color,
                  ).copyWith(letterSpacing: 3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GroundPainter extends CustomPainter {
  final String? name;
  final Color accent;
  final double t;

  _GroundPainter({required this.name, required this.accent, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF20242E), const Color(0xFF10131A)],
        ).createShader(Offset.zero & size),
    );
    // Línea del horizonte + líneas de fuga: dan sensación de plano 3D.
    final vanish = Offset(size.width * 0.5, -size.height * 0.55);
    final fugue = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1.5;
    for (var i = -3; i <= 3; i++) {
      canvas.drawLine(
        Offset(size.width * (0.5 + i * 0.34), size.height),
        vanish,
        fugue,
      );
    }
    canvas.drawLine(
      Offset(0, 2),
      Offset(size.width, 2),
      Paint()
        ..color = accent.withValues(alpha: 0.45)
        ..strokeWidth = 2,
    );

    final n = name?.trim();
    if (n == null || n.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: n.split(RegExp(r'\s+')).first.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Rubik',
          fontSize: 72,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final scale = (size.width * 0.7) / tp.width;
    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.55);
    canvas.scale(scale, scale * 0.42);
    canvas.rotate(-0.04);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GroundPainter old) => old.name != name;
}

class _ArchPainter extends CustomPainter {
  final Color color;

  /// 0 = el pórtico está fuera de cuadro por arriba; 1 = ya bajó y quedó
  /// FIJO sobre la cabeza del ciclista. No sigue de largo ni desaparece
  /// por abajo: se asienta y se mantiene (el fundido general de la
  /// cinemática lo saca al final).
  final double progress;

  _ArchPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width;
    final h = size.height;
    final e = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));

    // Todo el pórtico (viga + postes + guirnalda) es RÍGIDO: entra como
    // una sola pieza desde un poco más arriba y se asienta -- nada se
    // estira ni se desconecta. `op` lo desvanece de entrada.
    final op = (progress / 0.45).clamp(0.0, 1.0);
    final offY = -(1 - e) * h * 0.14;

    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: op),
    );
    canvas.translate(0, offY);

    final beamH = h * 0.055;
    final beamTop = h * 0.205;
    final beamBottom = beamTop + beamH;
    final postX1 = w * 0.10;
    final postX2 = w * 0.90;

    // Postes anclados al piso.
    final postPaint = Paint()
      ..color = const Color(0xFF2B303C)
      ..strokeWidth = w * 0.013
      ..strokeCap = StrokeCap.square;
    for (final px in [postX1, postX2]) {
      canvas.drawLine(Offset(px, beamBottom), Offset(px, h + 48), postPaint);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(px, beamBottom + beamH * 0.35),
          width: w * 0.03,
          height: beamH * 0.9,
        ),
        Paint()..color = color,
      );
    }

    // Viga / banner cruzando de lado a lado.
    canvas.drawRect(
      Rect.fromLTWH(0, beamTop, w, beamH),
      Paint()..color = color,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, beamTop, w, beamH * 0.22),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );

    // Guirnalda de banderines colgada entre los postes, con pandeo y un
    // leve balanceo: se lee como algo puesto a propósito, no cayendo.
    const n = 11;
    final sag = beamH * 0.92;
    final sway = math.sin(progress * math.pi * 2.0) * beamH * 0.12;
    Offset ropePoint(double u) {
      final x = postX1 + (postX2 - postX1) * u;
      final droop = math.sin(u * math.pi) * (sag + sway);
      return Offset(x, beamBottom + droop);
    }

    final rope = Path()..moveTo(postX1, beamBottom);
    for (var i = 1; i <= 28; i++) {
      final p = ropePoint(i / 28);
      rope.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      rope,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.0026
        ..color = Colors.white.withValues(alpha: 0.5),
    );

    final flagH = beamH * 0.95;
    final flagW = (postX2 - postX1) / n * 0.58;
    for (var i = 0; i < n; i++) {
      final u = (i + 0.5) / n;
      final a = ropePoint(u);
      final path = Path()
        ..moveTo(a.dx - flagW / 2, a.dy)
        ..lineTo(a.dx + flagW / 2, a.dy)
        ..lineTo(a.dx, a.dy + flagH)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = (i.isEven ? color : Colors.white).withValues(alpha: 0.92),
      );
    }

    // Placa central con borde del color del rango.
    final plateRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w / 2, beamTop + beamH * 0.5),
        width: w * 0.34,
        height: beamH * 1.5,
      ),
      Radius.circular(beamH * 0.3),
    );
    canvas.drawRRect(
      plateRRect,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    canvas.drawRRect(
      plateRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = beamH * 0.16
        ..color = color,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArchPainter old) =>
      old.progress != progress || old.color != color;
}

class _GleamPainter extends CustomPainter {
  final double progress;

  _GleamPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final x = -size.width * 0.4 + progress * size.width * 1.6;
    final band = size.width * 0.18;
    canvas.save();
    canvas.translate(x, size.height / 2);
    canvas.rotate(-0.35);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: band,
        height: size.height * 2,
      ),
      Paint()
        ..shader =
            LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(
                  alpha: 0.22 * (1 - (progress - 0.5).abs() * 2),
                ),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCenter(
                center: Offset.zero,
                width: band,
                height: size.height * 2,
              ),
            ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GleamPainter old) => old.progress != progress;
}
