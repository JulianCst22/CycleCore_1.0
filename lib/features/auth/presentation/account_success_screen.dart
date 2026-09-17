import 'dart:math' as math;
import 'dart:ui' show Tangent;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:core_ui/core_ui.dart';

/// Momento de bienvenida al terminar el registro completo
/// (`AccountSetupWizard` en modo normal). Un ciclista sube un camino de
/// montaña dibujado en código -- el pedaleo lo anima Lottie
/// (`assets/lottie/cyclist.json`) y el recorrido lo controla Flutter con
/// un `AnimationController` sobre un `Path`. Al llegar arriba, aparece la
/// tarjeta con un botón que entra a la app.
///
/// Rediseño: **la animación se conserva íntegra** -- solo cambian los
/// colores (navy + azul + naranja en vez de índigo + violeta).

class AccountSuccessScreen extends StatefulWidget {
  final String name;

  /// true cuando viene de un login, false al terminar el registro.
  /// Solo cambia el texto de la card final.
  final bool isReturning;

  const AccountSuccessScreen({
    super.key,
    required this.name,
    this.isReturning = false,
  });

  @override
  State<AccountSuccessScreen> createState() => _AccountSuccessScreenState();
}

class _AccountSuccessScreenState extends State<AccountSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _climb;
  bool _showCard = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4400),
    );
    _climb = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showCard = true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mountainPath = _MountainPath.build(size);

    return Scaffold(
      backgroundColor: CcColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CcColors.bg, CcColors.surface],
              ),
            ),
          ),
          CustomPaint(
            painter: _MountainPainter(mountainPath),
            size: Size.infinite,
          ),
          AnimatedBuilder(
            animation: _climb,
            builder: (context, child) {
              final metrics = mountainPath.computeMetrics().first;
              final tangent =
                  metrics.getTangentForOffset(metrics.length * _climb.value) ??
                  const Tangent(Offset.zero, Offset(1, 0));
              final slopeAngle = math
                  .atan2(tangent.vector.dy, tangent.vector.dx)
                  .clamp(-0.5, 0.1);
              return Positioned(
                left: tangent.position.dx - 34,
                top: tangent.position.dy - 58,
                child: Transform.rotate(
                  angle: slopeAngle,
                  alignment: Alignment.center,
                  child: child!,
                ),
              );
            },
            child: SizedBox(
              width: 68,
              height: 68,
              child: Lottie.asset(
                'assets/lottie/cyclist.json',
                repeat: true,
                errorBuilder: (context, error, stack) => Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CcColors.orange,
                  ),
                  child: const Icon(
                    Icons.directions_bike_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _showCard ? 1 : 0,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            child: IgnorePointer(
              ignoring: !_showCard,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: CcColors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.isReturning
                            ? '¡Qué bueno tenerte de vuelta, ${widget.name}!'
                            : '¡Bienvenido, ${widget.name}!',
                        textAlign: TextAlign.center,
                        style: CcType.displayStyle(
                          size: 23,
                          weight: FontWeight.w700,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isReturning
                            ? 'Tu próxima subida te espera. A darle.'
                            : 'Todo listo. Ahora sí, que cada subida cuente.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CcColors.inkDim,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _finish,
                          child: const Text('Empezar a rodar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Curva de montaña compartida entre el pintor de fondo y el cálculo de
/// posición del ciclista -- una sola fuente de verdad.
class _MountainPath {
  static Path build(Size size) {
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.74)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.84,
        size.width * 0.30,
        size.height * 0.52,
        size.width * 0.50,
        size.height * 0.47,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.43,
        size.width * 0.70,
        size.height * 0.24,
        size.width * 0.90,
        size.height * 0.18,
      );
    return path;
  }
}

class _MountainPainter extends CustomPainter {
  final Path path;

  _MountainPainter(this.path);

  @override
  void paint(Canvas canvas, Size size) {
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0x00000000),
          CcColors.blue.withValues(alpha: 0.18),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = CcColors.blue.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MountainPainter oldDelegate) => false;
}
