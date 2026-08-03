import 'dart:math' as math;
import 'dart:ui' show Tangent;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/accent_gradients.dart';

/// Momento de bienvenida único al terminar el registro completo
/// (`AccountSetupWizard` en modo normal, no `linkOnly`). Un ciclista
/// sube un camino de montaña dibujado en código -- el pedaleo en sí
/// lo anima Lottie (`assets/lottie/cyclist.json`, ver README del
/// paquete entregado) y el recorrido/posición los controla Flutter
/// con un `AnimationController` sobre un `Path`. Al llegar arriba,
/// aparece la tarjeta de bienvenida con un botón que entra a la app.
///
/// Si el asset de Lottie no está agregado todavía, el `errorBuilder`
/// cae a un ícono de bici -- nunca rompe el flujo de alta por faltar
/// un archivo de diseño.
class AccountSuccessScreen extends StatefulWidget {
  final String name;

  /// true cuando viene de un login (JWT expirado/cerró sesión antes),
  /// false cuando viene de terminar el registro por primera vez. Solo
  /// cambia el texto de la card final -- la animación es la misma.
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
    // Un frame de margen para que MediaQuery ya tenga el tamaño real
    // antes de arrancar el recorrido.
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    // Vuelve a la raíz (AppGate) -- mismo destino que el resto del
    // asistente, ya con perfil, cuenta y zonas guardados.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mountainPath = _MountainPath.build(size);

    return Scaffold(
      backgroundColor: AccentGradients.indigoDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration:
                BoxDecoration(gradient: AccentGradients.backgroundGradient),
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
              // Ángulo de la pendiente en ese punto del camino -- así el
              // ciclista se inclina siguiendo la subida en vez de ir
              // siempre recto. Se acota un poco para que nunca se vea
              // exagerado, aunque el trazo tenga curvas fuertes.
              final slopeAngle = math.atan2(tangent.vector.dy, tangent.vector.dx)
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AccentGradients.ctaGradient,
                    boxShadow: AccentGradients.ctaGlow(blur: 20),
                  ),
                  child: const Icon(Icons.directions_bike_rounded,
                      color: Colors.white, size: 34),
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
                        decoration: BoxDecoration(
                          gradient: AccentGradients.ctaGradient,
                          shape: BoxShape.circle,
                          boxShadow: AccentGradients.ctaGlow(blur: 30),
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.isReturning
                            ? '¡Bienvenido de nuevo, ${widget.name}!'
                            : '¡Bienvenido, ${widget.name}!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isReturning
                            ? 'Listo para tu próxima salida.'
                            : 'Tu cuenta, tu perfil y tus zonas ya están listos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AccentGradients.ctaGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AccentGradients.ctaGlow(
                                opacity: 0.4, blur: 20),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _finish,
                              child: const Center(
                                child: Text(
                                  'Empezar a rodar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
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

/// Curva de montaña compartida entre el pintor de fondo y el cálculo
/// de posición del ciclista -- una sola fuente de verdad para que
/// nunca se desincronicen.
class _MountainPath {
  static Path build(Size size) {
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.74)
      ..cubicTo(
        size.width * 0.26, size.height * 0.84,
        size.width * 0.30, size.height * 0.52,
        size.width * 0.50, size.height * 0.47,
      )
      ..cubicTo(
        size.width * 0.66, size.height * 0.43,
        size.width * 0.70, size.height * 0.24,
        size.width * 0.90, size.height * 0.18,
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
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00000000), Color(0x336C4CE0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MountainPainter oldDelegate) => false;
}
