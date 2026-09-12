import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/climb_route.dart';
import 'package:cyclecore_core/gamification/rank_tier.dart';
import 'climb_road.dart';

/// Dibuja los **arcos** sobre la carretera en perspectiva: uno grande
/// por cada cambio de rango (niveles 5, 10, 15, 20, 25 -- entrar a
/// Rodador, Escalador, Fondista, Élite, Leyenda) más el de la cima
/// (nivel 30, la meta). El color es el del rango al que entras y su
/// grandeza crece con el rango: del arco de tubo de Rodador al
/// monumento con corona y antorchas de Leyenda; el de la cima lleva
/// además la línea de cuadros de meta.
///
/// El cartel con el nombre del rango y los banderines-postal de los
/// niveles normales NO se pintan aquí: son widgets aparte
/// (`ClimbArchLabel`, `ClimbPoiPennant`) para que el texto se vea
/// nítido y las postales se puedan tocar.
class ClimbArchesPainter extends CustomPainter {
  final ClimbCamera camera;

  const ClimbArchesPainter({required this.camera});

  /// El maderamen / piedra de los rangos bajos.
  static const Color _wood = Color(0xFF6B5647);

  /// Niveles con arco grande: cada cambio de rango + el techo (nivel
  /// 30 = cima real del Alto de Patios).
  static final List<int> archLevels = [
    for (final tier in RankTier.all)
      if (tier.minLevel > 1) tier.minLevel,
    if (!RankTier.all.any((t) => t.minLevel == ClimbRoute.maxLevel))
      ClimbRoute.maxLevel,
  ];

  static bool isArchLevel(int level) => archLevels.contains(level);

  /// El próximo arco (nivel) al que se dirige el ciclista, o `null` si
  /// ya pasó el último.
  static int? nextArchLevel(double displayedLevel) {
    for (final lvl in archLevels) {
      if (lvl > displayedLevel + 0.001) return lvl;
    }
    return null;
  }

  /// Grandeza visual (1..5) del arco de un nivel = índice del rango que
  /// estrena.
  static int grandeurForLevel(int level) =>
      RankTier.indexOfRank(RankTier.forLevel(level).rank).clamp(1, 5);

  /// Alto del arco en píxeles -- lo usa `ClimbArchLabel` para colocar
  /// el cartel justo encima.
  static double archHeight(double roadHalf, int grandeur) =>
      roadHalf * (1.0 + grandeur * 0.2);

  @override
  void paint(Canvas canvas, Size size) {
    final nextArch = nextArchLevel(camera.displayedLevel);
    for (final lvl in archLevels.reversed) {
      final d = lvl - camera.displayedLevel;
      if (d <= 0.03 || d > ClimbRoadPainter.farAhead) continue;
      _paintArch(canvas, lvl, d, isNext: lvl == nextArch);
    }
  }

  void _paintArch(Canvas canvas, int level, double d, {required bool isNext}) {
    final tier = RankTier.forLevel(level);
    final grandeur = grandeurForLevel(level);
    final sc = camera.scale(d);
    final base = camera.roadPoint(d);
    final roadHalf = camera.roadHalfWidth(d);

    // Fundido: los arcos lejanos se desvanecen y el que ya casi se cruza
    // también (para que no "salte" al pasar por debajo).
    final fade =
        ((sc - 0.34) * 2.4).clamp(0.0, 1.0) * (d < 0.18 ? d / 0.18 : 1.0);
    if (fade <= 0.02) return;

    final structural = Color.lerp(_wood, tier.color, grandeur / 5)!;
    final postX = roadHalf * 1.05;
    final postW = math.max(1.4, roadHalf * 0.08 * (0.8 + grandeur * 0.06));
    final archH = archHeight(roadHalf, grandeur);
    final beamY = base.dy - archH;

    canvas.save();

    // --- Línea de cuadros de meta, sólo en la cima ---
    if (level == ClimbRoute.maxLevel) {
      _paintFinishLine(canvas, d, fade);
    }

    // Resplandor detrás del próximo arco -- lo separa del resto.
    if (isNext) {
      canvas.drawCircle(
        Offset(base.dx, beamY + archH * 0.3),
        archH * 0.95,
        Paint()
          ..color = tier.color.withValues(alpha: 0.14 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
      );
    }

    // Sombra de contacto de cada poste con el asfalto.
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.22 * fade);
    for (final sign in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(base.dx + sign * postX, base.dy + postW * 0.4),
          width: postW * 3.4,
          height: postW * 1.3,
        ),
        shadow,
      );
    }

    Paint fill(Color c, double a) =>
        Paint()..color = c.withValues(alpha: a * fade);

    // --- Postes / pilares ---
    for (final sign in const [-1.0, 1.0]) {
      final x = base.dx + sign * postX;
      final taper = grandeur >= 4 ? postW * 0.35 : 0.0;
      final post = Path()
        ..moveTo(x - postW, base.dy)
        ..lineTo(x - postW + taper, beamY)
        ..lineTo(x + postW - taper, beamY)
        ..lineTo(x + postW, base.dy)
        ..close();
      canvas.drawPath(post, fill(structural, 0.95));
      canvas.drawPath(
        post,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      // Base de piedra de los pilares grandes.
      if (grandeur >= 4) {
        canvas.drawRect(
          Rect.fromLTWH(
            x - postW * 1.5,
            base.dy - postW * 1.4,
            postW * 3,
            postW * 1.4,
          ),
          fill(structural, 0.9),
        );
      }
    }

    // --- Remate superior ---
    final leftInner = base.dx - postX;
    final rightInner = base.dx + postX;
    if (grandeur >= 4) {
      // Arco curvo.
      final rise = archH * 0.22;
      final top = Path()
        ..moveTo(leftInner - postW, beamY + postW)
        ..quadraticBezierTo(
          base.dx,
          beamY - rise,
          rightInner + postW,
          beamY + postW,
        )
        ..quadraticBezierTo(
          base.dx,
          beamY - rise + postW * 2.2,
          leftInner - postW,
          beamY + postW,
        )
        ..close();
      canvas.drawPath(top, fill(structural, 0.95));
      canvas.drawPath(
        Path()
          ..moveTo(leftInner - postW, beamY + postW)
          ..quadraticBezierTo(
            base.dx,
            beamY - rise,
            rightInner + postW,
            beamY + postW,
          ),
        Paint()
          ..color = tier.color.withValues(alpha: 0.9 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, postW * 0.5),
      );
    } else {
      // Viga recta (Rodador / Escalador).
      final beamH = postW * 1.7;
      canvas.drawRect(
        Rect.fromLTWH(
          leftInner - postW,
          beamY,
          (rightInner - leftInner) + postW * 2,
          beamH,
        ),
        fill(structural, 0.95),
      );
      canvas.drawRect(
        Rect.fromLTWH(
          leftInner - postW,
          beamY,
          (rightInner - leftInner) + postW * 2,
          beamH * 0.32,
        ),
        fill(tier.color, 0.85),
      );
    }

    // --- Banderines cruzando el arco (Escalador en adelante) ---
    if (grandeur >= 2) {
      final flagCount = 5 + grandeur;
      for (var i = 0; i <= flagCount; i++) {
        final f = i / flagCount;
        final fx = leftInner + (rightInner - leftInner) * f;
        final sag = math.sin(f * math.pi) * archH * 0.06;
        final fy = beamY - postW * 0.4 + sag;
        final flag = Path()
          ..moveTo(fx - postW * 0.7, fy)
          ..lineTo(fx + postW * 0.7, fy)
          ..lineTo(fx, fy + postW * 1.6)
          ..close();
        canvas.drawPath(flag, fill(i.isEven ? tier.color : Colors.white, 0.85));
      }
    }

    // --- Luces sobre el remate (Fondista en adelante) ---
    if (grandeur >= 3) {
      final lights = 4 + grandeur;
      for (var i = 0; i < lights; i++) {
        final f = (i + 0.5) / lights;
        final lx = leftInner + (rightInner - leftInner) * f;
        canvas.drawCircle(
          Offset(lx, beamY - postW * 0.2),
          math.max(1.0, postW * 0.4),
          fill(const Color(0xFFFFE7B0), 0.9),
        );
      }
    }

    // --- Corona + antorchas + rayos: sólo Leyenda ---
    if (grandeur >= 5) {
      final crown = Path()
        ..moveTo(base.dx - roadHalf * 0.5, beamY - archH * 0.16)
        ..lineTo(base.dx, beamY - archH * 0.42)
        ..lineTo(base.dx + roadHalf * 0.5, beamY - archH * 0.16)
        ..close();
      canvas.drawPath(crown, fill(tier.color, 0.95));
      for (final sign in const [-1.0, 1.0]) {
        final tx = base.dx + sign * (postX + postW);
        canvas.drawCircle(
          Offset(tx, beamY - postW),
          postW * 1.3,
          fill(const Color(0xFFFF8A4C), 0.8),
        );
      }
      final rayPaint = Paint()
        ..color = tier.color.withValues(alpha: 0.35 * fade)
        ..strokeWidth = 2;
      for (var i = 0; i < 8; i++) {
        final ang = -math.pi / 2 + (i - 3.5) * 0.32;
        final from = Offset(base.dx, beamY - archH * 0.2);
        canvas.drawLine(
          from,
          from + Offset(math.cos(ang), math.sin(ang)) * archH * 0.5,
          rayPaint,
        );
      }
    }

    canvas.restore();
  }

  /// Banda de cuadros blanco/negro cruzando la carretera justo delante
  /// del arco de la cima -- la línea de meta.
  void _paintFinishLine(Canvas canvas, double dArch, double fade) {
    final d0 = (dArch - 0.16).clamp(0.05, ClimbRoadPainter.farAhead);
    final d1 = (dArch + 0.02).clamp(0.05, ClimbRoadPainter.farAhead);
    final nearL = camera.roadEdge(d0, left: true);
    final nearR = camera.roadEdge(d0, left: false);
    final farL = camera.roadEdge(d1, left: true);
    final farR = camera.roadEdge(d1, left: false);

    const cols = 10;
    const rows = 3;
    for (var r = 0; r < rows; r++) {
      final t0 = r / rows;
      final t1 = (r + 1) / rows;
      final lA = Offset.lerp(nearL, farL, t0)!;
      final rA = Offset.lerp(nearR, farR, t0)!;
      final lB = Offset.lerp(nearL, farL, t1)!;
      final rB = Offset.lerp(nearR, farR, t1)!;
      for (var c = 0; c < cols; c++) {
        final u0 = c / cols;
        final u1 = (c + 1) / cols;
        final quad = Path()
          ..moveTo(Offset.lerp(lA, rA, u0)!.dx, Offset.lerp(lA, rA, u0)!.dy)
          ..lineTo(Offset.lerp(lA, rA, u1)!.dx, Offset.lerp(lA, rA, u1)!.dy)
          ..lineTo(Offset.lerp(lB, rB, u1)!.dx, Offset.lerp(lB, rB, u1)!.dy)
          ..lineTo(Offset.lerp(lB, rB, u0)!.dx, Offset.lerp(lB, rB, u0)!.dy)
          ..close();
        final white = (c + r).isEven;
        canvas.drawPath(
          quad,
          Paint()
            ..color = (white ? Colors.white : const Color(0xFF12151C))
                .withValues(alpha: 0.92 * fade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ClimbArchesPainter oldDelegate) =>
      oldDelegate.camera.displayedLevel != camera.displayedLevel ||
      oldDelegate.camera.size != camera.size;
}
