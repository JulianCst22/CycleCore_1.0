import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ui.dart';
import '../application/navigation_providers.dart';
import '../domain/climb_detection.dart';

/// Tarjeta inferior mientras se calcula una ruta: ocupa el mismo lugar
/// que la de "Confirmar la ruta" y se transforma en ella al terminar.
///
/// Antes el mapa se quedaba quieto unos segundos sin decir nada (la
/// primera vez cargaba el grafo de la región). Ahora se ve una ruta
/// trazándose de A a B, con la bici avanzando, y en qué paso va.
class RouteComputingCard extends ConsumerStatefulWidget {
  const RouteComputingCard({super.key});

  @override
  ConsumerState<RouteComputingCard> createState() => _RouteComputingCardState();
}

class _RouteComputingCardState extends ConsumerState<RouteComputingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _stageText(RouteComputeStage stage) => switch (stage) {
    RouteComputeStage.loadingMap => 'Cargando el mapa de tu región…',
    RouteComputeStage.routing => 'Buscando vías principales y pavimentadas…',
    RouteComputeStage.profile => 'Calculando la altimetría…',
  };

  @override
  Widget build(BuildContext context) {
    final computing = ref.watch(routeComputingProvider);
    if (computing == null) return const SizedBox.shrink();
    final target = computing.target;
    final climb = looksLikeClimb(target.name);
    final accent = climb ? CcColors.mSlope : CcColors.blue;

    return Container(
      decoration: const BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CcColors.inkFaint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      climb ? Icons.terrain : Icons.place,
                      size: 18,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trazando la ruta',
                          style: CcType.label(size: 11, color: CcColors.inkDim),
                        ),
                        Text(
                          target.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CcType.displayStyle(
                            size: 17,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 58,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _TracingRoutePainter(
                      t: _controller.value,
                      accent: accent,
                    ),
                    child: _RidingBike(t: _controller.value),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Align(
                        key: ValueKey(computing.stage),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _stageText(computing.stage),
                          style: CcType.label(
                            size: 12.5,
                            color: CcColors.inkDim,
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(navigationControllerProvider)
                        .cancelComputing(),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La curva por la que avanza la bici: una vía de montaña de A a B.
Offset _pointOnRoad(Size size, double t) {
  const pad = 16.0;
  final x = pad + (size.width - 2 * pad) * t;
  final y =
      size.height * 0.62 -
      size.height * 0.28 * math.sin(t * math.pi * 1.5) +
      size.height * 0.08 * math.sin(t * math.pi * 5);
  return Offset(x, y);
}

class _TracingRoutePainter extends CustomPainter {
  final double t;
  final Color accent;

  _TracingRoutePainter({required this.t, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    // Base punteada: todo el camino posible.
    const steps = 64;
    final dot = Paint()..color = CcColors.line;
    for (var i = 0; i <= steps; i += 2) {
      canvas.drawCircle(_pointOnRoad(size, i / steps), 1.6, dot);
    }

    // Lo que ya se trazó en esta vuelta: de A hasta la bici.
    final head = Curves.easeInOutCubic.transform(t);
    final traced = Path();
    for (var i = 0; i <= steps; i++) {
      final p = i / steps;
      if (p > head) break;
      final o = _pointOnRoad(size, p);
      i == 0 ? traced.moveTo(o.dx, o.dy) : traced.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      traced,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [accent.withValues(alpha: 0.1), accent],
        ).createShader(Offset.zero & size),
    );

    // A y B; el destino late.
    final a = _pointOnRoad(size, 0), b = _pointOnRoad(size, 1);
    canvas.drawCircle(a, 5, Paint()..color = CcColors.segmentStart);
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);
    canvas.drawCircle(
      b,
      8 + 6 * pulse,
      Paint()..color = accent.withValues(alpha: 0.25 * (1 - pulse)),
    );
    canvas.drawCircle(b, 6, Paint()..color = accent);
    canvas.drawCircle(b, 2.5, Paint()..color = CcColors.surface);
  }

  @override
  bool shouldRepaint(covariant _TracingRoutePainter old) =>
      old.t != t || old.accent != accent;
}

/// La bici que avanza con la punta del trazo.
class _RidingBike extends StatelessWidget {
  final double t;

  const _RidingBike({required this.t});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final head = Curves.easeInOutCubic.transform(t);
        final o = _pointOnRoad(size, head);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: o.dx - 11,
              top: o.dy - 24,
              child: const Icon(
                Icons.directions_bike,
                size: 22,
                color: CcColors.ink,
              ),
            ),
          ],
        );
      },
    );
  }
}
