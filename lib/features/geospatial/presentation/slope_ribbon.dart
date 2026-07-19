import 'package:flutter/material.dart';

import '../../../core/theme/cyclecore_palette.dart';

/// El elemento visual "firma" del cockpit: una cinta horizontal que se
/// llena y cambia de color en tiempo real según la pendiente actual,
/// con un marcador que se desliza suavemente en vez de saltar.
///
/// Por qué esto y no solo un número: el trabajo real de la app está en
/// decidir CUÁNTO CONFIAR en una pendiente (dos capas de lógica
/// difusa) -- mostrarla como el mismo tile plano que cadencia o
/// potencia desperdicia esa sofisticación. La cinta comunica de un
/// vistazo (sin leer un número) qué tan duro está el tramo, que es
/// exactamente lo que un ciclista subiendo necesita sin distraerse del
/// camino.
///
/// Rango mostrado: -12% a +12%. Pendientes más extremas se clampan
/// visualmente (el marcador se queda en el borde) -- son rarísimas en
/// ciclismo de calle/montaña y priorizar el rango común da más
/// resolución visual donde importa.
class SlopeRibbon extends StatelessWidget {
  final double slopePercent;

  /// true cuando la Capa 1 no tiene DEM confiable para este punto (o
  /// sospecha puente/viaducto) -- mismo criterio que
  /// `RouteRecordingState.isApproximateElevation`.
  final bool isApproximate;

  static const double _rangeMax = 15.0;

  const SlopeRibbon({
    super.key,
    required this.slopePercent,
    required this.isApproximate,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = slopePercent.clamp(-_rangeMax, _rangeMax);
    // 0.0 = extremo izquierdo (-12%), 1.0 = extremo derecho (+12%).
    final fraction = (clamped + _rangeMax) / (2 * _rangeMax);
    final color = CyclecorePalette.slopeColorFor(slopePercent);

    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      decoration: BoxDecoration(
        color: CyclecorePalette.panel,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Línea de referencia en 0% -- ayuda a leer de un vistazo si
          // se está subiendo o bajando.
          Align(
            alignment: Alignment.center,
            child: Container(width: 1.5, color: CyclecorePalette.niebla.withValues(alpha: 0.3)),
          ),

          // Marcador animado -- AnimatedPositionedDirectional-like vía
          // AnimatedAlign, así el desplazamiento se ve fluido en vez de
          // saltar con cada muestra de pendiente nueva.
          AnimatedAlign(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            alignment: Alignment(fraction * 2 - 1, 0),
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.0), color],
                  ),
                ),
                child: isApproximate ? _ApproximateTexture(color: color) : null,
              ),
            ),
          ),

          // Etiqueta del porcentaje, siempre centrada y legible sobre
          // el relleno.
          Center(
            child: Text(
              '${slopePercent >= 0 ? '+' : ''}${slopePercent.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: CyclecorePalette.hueso,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Textura rayada diagonal, sutil, que se dibuja SOBRE el relleno de
/// color cuando la pendiente mostrada es una aproximación (sin DEM
/// confiable o posible puente). Se eligió rayado en vez de parpadeo:
/// un parpadeo constante en un elemento que el ciclista mira a cada
/// rato durante toda una subida larga (justo el escenario del bug de
/// deriva que encontramos en el Águila) resulta molesto/fatigoso; el
/// rayado comunica "esto es una textura distinta" de forma permanente
/// y silenciosa, sin exigir atención activa.
class _ApproximateTexture extends StatelessWidget {
  final Color color;
  const _ApproximateTexture({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DiagonalStripesPainter(color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _DiagonalStripesPainter extends CustomPainter {
  final Color color;
  const _DiagonalStripesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 3;

    const spacing = 9.0;
    final diagonal = size.width + size.height;
    for (double x = -size.height; x < diagonal; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripesPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Utilidad pequeña reutilizada por el overlay de GPS -- un anillo que
/// pulsa (crece y se desvanece), estilo "radar buscando señal".
class PulsingRadarDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingRadarDot({super.key, required this.color, this.size = 64});

  @override
  State<PulsingRadarDot> createState() => _PulsingRadarDotState();
}

class _PulsingRadarDotState extends State<PulsingRadarDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(2, (i) {
              // Dos anillos desfasados 0.5 en el ciclo, para que no
              // aparezcan y desaparezcan sincronizados (se ve más vivo,
              // menos mecánico, con solo dos ondas).
              final t = (_controller.value + (i * 0.5)) % 1.0;
              return Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Container(
                  width: widget.size * t,
                  height: widget.size * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color, width: 2),
                  ),
                ),
              );
            })
              ..add(
                Container(
                  width: widget.size * 0.28,
                  height: widget.size * 0.28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                ),
              ),
          );
        },
      ),
    );
  }
}

/// Pequeño helper matemático usado por el modo navegación del mapa
/// (ver MapScreen) para normalizar ángulos al aplicar la rotación
/// tipo Waze -- vive aquí porque es un detalle de presentación, no de
/// dominio.
double normalizeDegrees(double degrees) {
  var d = degrees % 360.0;
  if (d < 0) d += 360.0;
  return d;
}

/// Diferencia angular más corta entre dos ángulos (-180..180) -- se
/// usa para que la rotación del mapa siempre gire por el camino más
/// corto en vez de dar la vuelta larga cuando el rumbo cruza 0°/360°.
double shortestAngleDelta(double from, double to) {
  var delta = (to - from) % 360.0;
  if (delta > 180) delta -= 360;
  if (delta < -180) delta += 360;
  return delta;
}
