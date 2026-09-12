import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import '../../domain/climb_route.dart';
import 'package:cyclecore_core/gamification/rank_tier.dart';
import '../profile_providers.dart';
import 'climb_arch.dart';
import 'climb_road.dart';

/// Cartel del próximo arco, como widget (texto nítido, no pintado en el
/// canvas): sólo el RANGO grande + "NIVEL N" debajo, en una placa
/// "glass" colocada justo encima del arco. Va como hijo directo del
/// `Stack` de la escena.
class ClimbArchLabel extends StatelessWidget {
  final ClimbCamera camera;
  final int level;

  const ClimbArchLabel({super.key, required this.camera, required this.level});

  @override
  Widget build(BuildContext context) {
    final d = level - camera.displayedLevel;
    if (d <= 0.08 || d > 5.5) return const SizedBox.shrink();

    final sc = camera.scale(d);
    // Se desvanece de lejos y también cuando ya casi se cruza (estás
    // por pasar debajo, no hace falta el cartel).
    final near = d < 1.4 ? ((d - 0.5) / 0.9).clamp(0.0, 1.0) : 1.0;
    final opacity = ((sc - 0.32) * 2.2).clamp(0.0, 1.0) * near;
    if (opacity <= 0.05) return const SizedBox.shrink();

    final tier = RankTier.forLevel(level);
    final grandeur = ClimbArchesPainter.grandeurForLevel(level);
    final roadHalf = camera.roadHalfWidth(d);
    final base = camera.roadPoint(d);
    final archH = ClimbArchesPainter.archHeight(roadHalf, grandeur);
    final beamY = base.dy - archH;
    // Despeja los banderines / la corona + rayos de Leyenda, sin
    // meterse debajo del app bar.
    final cy = (beamY - archH * (grandeur >= 5 ? 0.82 : 0.26) - 8).clamp(
      kToolbarHeight + 62.0,
      camera.size.height * 0.55,
    );
    final cx = base.dx;

    final rankSize = (10.0 + sc * 12).clamp(10.0, 22.0);
    final isSummit = level == ClimbRoute.maxLevel;

    return Positioned(
      left: cx,
      top: cy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CcColors.glass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tier.color.withValues(alpha: 0.6)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSummit ? 'META' : tier.label.toUpperCase(),
                  style: CcType.displayStyle(
                    size: rankSize,
                    color: tier.color,
                  ).copyWith(letterSpacing: 1.5),
                ),
                Text(
                  'NIVEL $level',
                  style: CcType.label(
                    size: (rankSize * 0.5).clamp(7.0, 11.0),
                    color: CcColors.inkDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banderín-postal al borde de la carretera para un nivel normal:
/// **se puede tocar** (abre la postal de ese punto). El que sigues
/// ahora se ilumina y late; los demás quedan tenues -- así sabes hacia
/// dónde vas.
class ClimbPoiPennant extends StatefulWidget {
  final ClimbCamera camera;
  final int level;
  final bool onLeft;
  final bool highlighted;
  final VoidCallback onTap;

  const ClimbPoiPennant({
    super.key,
    required this.camera,
    required this.level,
    required this.onLeft,
    required this.highlighted,
    required this.onTap,
  });

  @override
  State<ClimbPoiPennant> createState() => _ClimbPoiPennantState();
}

class _ClimbPoiPennantState extends State<ClimbPoiPennant>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.highlighted) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ClimbPoiPennant old) {
    super.didUpdateWidget(old);
    if (widget.highlighted && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.highlighted && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = widget.camera;
    final d = widget.level - cam.displayedLevel;
    if (d <= 0.12 || d > 4.0) return const SizedBox.shrink();

    final sc = cam.scale(d);
    final opacity = ((sc - 0.16) * 2.0).clamp(0.0, 1.0);
    if (opacity <= 0.04) return const SizedBox.shrink();

    final roadHalf = cam.roadHalfWidth(d);
    final foot = cam.roadEdge(d, left: widget.onLeft);
    final x = foot.dx + (widget.onLeft ? -1 : 1) * roadHalf * 0.16;
    final h = (10.0 + sc * 46).clamp(10.0, 60.0);
    final hitW = math.max(26.0, h * 0.95);
    final tier = RankTier.forLevel(widget.level);

    return Positioned(
      left: x - hitW / 2,
      top: foot.dy - h - 10,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_pulse.value);
            return Opacity(
              opacity: opacity,
              child: SizedBox(
                width: hitW,
                height: h + 20,
                child: CustomPaint(
                  painter: _PennantPainter(
                    color: tier.color,
                    onLeft: widget.onLeft,
                    highlighted: widget.highlighted,
                    pulse: t,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PennantPainter extends CustomPainter {
  final Color color;
  final bool onLeft;
  final bool highlighted;
  final double pulse;

  _PennantPainter({
    required this.color,
    required this.onLeft,
    required this.highlighted,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final poleX = size.width / 2;
    final baseY = size.height - 6;
    final topY = 12.0;
    final poleW = math.max(1.2, size.width * 0.06);

    if (highlighted) {
      canvas.drawCircle(
        Offset(poleX, topY + 6),
        size.width * (0.5 + pulse * 0.15),
        Paint()
          ..color = color.withValues(alpha: 0.28 + pulse * 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(poleX - poleW, topY, poleW * 2, baseY - topY),
      Paint()
        ..color = const Color(
          0xFF6B5647,
        ).withValues(alpha: highlighted ? 1 : 0.7),
    );

    final dir = onLeft ? -1.0 : 1.0;
    final flagLen = size.width * 0.42 * (highlighted ? 1 + pulse * 0.1 : 0.85);
    final flag = Path()
      ..moveTo(poleX + dir * poleW, topY)
      ..lineTo(poleX + dir * (poleW + flagLen), topY + size.height * 0.1)
      ..lineTo(poleX + dir * poleW, topY + size.height * 0.2)
      ..close();
    canvas.drawPath(
      flag,
      Paint()..color = color.withValues(alpha: highlighted ? 1 : 0.7),
    );

    // Puntito en la base -- sugiere "aquí hay algo que tocar".
    canvas.drawCircle(
      Offset(poleX, baseY),
      poleW * 1.6,
      Paint()..color = color.withValues(alpha: highlighted ? 0.9 : 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _PennantPainter old) =>
      old.pulse != pulse ||
      old.color != color ||
      old.highlighted != highlighted;
}

/// Público a los lados de la carretera: muñequitos del mismo estilo
/// "sticker" que el ciclista, levantando los brazos. Hay tribunas junto
/// a cada arco (cada cambio de rango y la cima) más espectadores sueltos
/// entre medias -- el público acompaña toda la subida, no solo el final.
class ClimbCrowd extends StatefulWidget {
  final ClimbCamera camera;

  const ClimbCrowd({super.key, required this.camera});

  @override
  State<ClimbCrowd> createState() => _ClimbCrowdState();
}

class _ClimbCrowdState extends State<ClimbCrowd>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _wave,
          builder: (context, _) => CustomPaint(
            painter: _CrowdPainter(camera: widget.camera, phase: _wave.value),
          ),
        ),
      ),
    );
  }
}

class _CrowdPainter extends CustomPainter {
  final ClimbCamera camera;
  final double phase;

  _CrowdPainter({required this.camera, required this.phase});

  static const _jerseys = [
    Color(0xFF4FC3F7),
    Color(0xFFFFA726),
    Color(0xFF81C784),
    Color(0xFFAB47BC),
    Color(0xFFEF5350),
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Sólo una tribuna pequeña junto al arco que se tiene por delante
    // (o el que se está cruzando ahora mismo) -- no en toda la subida,
    // para no recargar la escena. La cima lleva algo más de público.
    for (final archLevel in ClimbArchesPainter.archLevels) {
      final d = archLevel - camera.displayedLevel;
      if (d < -0.5 || d > 3.0) continue;
      final dense = archLevel == ClimbRoute.maxLevel;
      _cluster(canvas, d, dense ? 4 : 2, seed: archLevel * 7);
    }
  }

  void _cluster(Canvas canvas, double dCenter, int n, {required int seed}) {
    final step = n <= 2 ? 0.5 : 0.3;
    for (final onLeft in const [true, false]) {
      for (var k = 0; k < n; k++) {
        final d = dCenter - (n - 1) * step / 2 + k * step;
        if (d <= 0.12 || d > ClimbRoadPainter.farAhead) continue;
        final sc = camera.scale(d);
        final fade = ((sc - 0.14) * 2.2).clamp(0.0, 1.0);
        if (fade <= 0.03) continue;

        final roadHalf = camera.roadHalfWidth(d);
        final edge = camera.roadEdge(d, left: onLeft);
        final dir = onLeft ? -1.0 : 1.0;
        final row = k.isEven ? 0.0 : 1.0;
        final feet = Offset(
          edge.dx + dir * roadHalf * (0.2 + row * 0.4),
          edge.dy - row * roadHalf * 0.13,
        );
        final s = (sc * 32).clamp(6.0, 38.0);
        final idx = seed + k + (onLeft ? 0 : 3);
        final armT = (0.5 + 0.5 * math.sin(phase * 2 * math.pi + idx * 1.3))
            .clamp(0.0, 1.0);
        _spectator(
          canvas,
          feet,
          s,
          _jerseys[idx % _jerseys.length],
          armT,
          fade,
        );
      }
    }
  }

  void _spectator(
    Canvas canvas,
    Offset feet,
    double s,
    Color jersey,
    double armT,
    double fade,
  ) {
    void stroke(Offset a, Offset b, double w, Color c) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5 * fade)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w * 1.7,
      );
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = c.withValues(alpha: fade)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w,
      );
    }

    final hip = feet.translate(0, -s * 0.9);
    final shoulder = feet.translate(0, -s * 1.7);
    final head = feet.translate(0, -s * 2.05);

    // Piernas.
    stroke(
      hip,
      feet.translate(-s * 0.22, 0),
      s * 0.16,
      const Color(0xFF2C3444),
    );
    stroke(hip, feet.translate(s * 0.22, 0), s * 0.16, const Color(0xFF2C3444));
    // Torso (maillot).
    stroke(hip, shoulder, s * 0.34, jersey);
    // Brazos levantados y saludando.
    final ang = (0.35 + armT * 1.15);
    for (final side in const [-1.0, 1.0]) {
      final hand = shoulder.translate(
        side * math.cos(ang) * s * 0.9,
        -math.sin(ang) * s * 0.9,
      );
      stroke(shoulder, hand, s * 0.14, jersey);
    }
    // Cabeza.
    canvas.drawCircle(
      head,
      s * 0.3,
      Paint()..color = Colors.black.withValues(alpha: 0.5 * fade),
    );
    canvas.drawCircle(
      head,
      s * 0.24,
      Paint()..color = const Color(0xFFE7C9A9).withValues(alpha: fade),
    );
  }

  @override
  bool shouldRepaint(covariant _CrowdPainter old) =>
      old.phase != phase ||
      old.camera.displayedLevel != camera.displayedLevel ||
      old.camera.size != camera.size;
}

/// El nombre del ciclista "pintado" en el asfalto, como los aficionados
/// en las grandes vueltas -- se repite en la vía y va corriendo hacia el
/// espectador a medida que se sube.
class ClimbRoadName extends ConsumerWidget {
  final ClimbCamera camera;

  const ClimbRoadName({super.key, required this.camera});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(profileProvider).valueOrNull?.name.trim();
    if (name == null || name.isEmpty) return const SizedBox.shrink();

    // Sólo el primer nombre, en mayúsculas.
    final painted = name.split(RegExp(r'\s+')).first.toUpperCase();

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _RoadNamePainter(camera: camera, text: painted),
        ),
      ),
    );
  }
}

class _RoadNamePainter extends CustomPainter {
  final ClimbCamera camera;
  final String text;

  _RoadNamePainter({required this.camera, required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    // Un único ciclo largo (5 niveles): una sola pintada visible casi
    // siempre, que aparece de lejos, pasa bajo el ciclista y se va.
    final cycle = camera.displayedLevel % 5.0;
    final d = 4.6 - cycle;
    if (d < 0.35 || d > ClimbRoadPainter.farAhead) return;

    final sc = camera.scale(d);
    final fade = ((sc - 0.12) * 1.9).clamp(0.0, 1.0);
    // Se atenúa justo al pasar bajo el ciclista (d pequeño) para que
    // parezca que la rueda la tapa.
    final pass = d < 0.9 ? (d - 0.35) / 0.55 : 1.0;
    final alpha = 0.6 * fade * pass.clamp(0.0, 1.0);
    if (alpha <= 0.03) return;

    final center = camera.roadPoint(d);
    final roadW = camera.roadHalfWidth(d) * 2;

    // Cada letra por separado, con rotación e inclinación irregulares:
    // pintada a mano de aficionado, no un rótulo.
    final chars = text.split('');
    final painters = [
      for (var i = 0; i < chars.length; i++)
        TextPainter(
          text: TextSpan(
            text: chars[i],
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: alpha),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    final rawWidth = painters.fold<double>(0, (w, p) => w + p.width) * 1.08;
    final targetW = roadW * 0.66;
    final scale = targetW / rawWidth;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Aplastado en vertical + leve giro: se lee como pintado sobre el
    // asfalto en perspectiva, no flotando.
    canvas.scale(scale, scale * 0.4);
    canvas.rotate(math.sin(camera.displayedLevel) * 0.05);

    var x = -rawWidth / 2;
    for (var i = 0; i < painters.length; i++) {
      final p = painters[i];
      final rnd = math.sin(i * 12.9898) * 43758.5453;
      final jitter = (rnd - rnd.floorToDouble());
      canvas.save();
      canvas.translate(x + p.width / 2, (jitter - 0.5) * 16);
      canvas.rotate((jitter - 0.5) * 0.34);
      p.paint(canvas, Offset(-p.width / 2, -p.height / 2));
      canvas.restore();
      x += p.width * 1.08;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoadNamePainter old) =>
      old.text != text ||
      old.camera.displayedLevel != camera.displayedLevel ||
      old.camera.size != camera.size;
}
