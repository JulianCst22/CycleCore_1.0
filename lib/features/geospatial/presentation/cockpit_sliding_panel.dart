import 'package:flutter/material.dart';

/// Panel que interpola entre un contenido "compacto" y uno "expandido"
/// mediante un arrastre real -- reemplaza el salto binario que había
/// antes (`if (_cockpitFullscreen) fullscreen else compacto`, cambiado
/// de golpe con `setState`). Arrastrar hacia arriba/abajo mueve la
/// transición en vivo (como una hoja inferior nativa); al soltar, se
/// anima hasta el extremo más cercano según posición y velocidad.
///
/// Deliberadamente NO usa un `Hero`/`PageTransition`: ambos contenidos
/// (compacto y expandido) coexisten superpuestos con opacidad y un
/// pequeño desplazamiento vertical cruzados en función del progreso
/// `t` -- es una transición barata de calcular y se siente como
/// "un panel deslizándose", que es justo lo que se pidió.
class CockpitSlidingPanel extends StatefulWidget {
  final Widget compact;
  final Widget expanded;

  /// Notifica cuándo el panel queda completamente expandido o
  /// completamente compacto -- útil si algo más en la pantalla
  /// necesita reaccionar (p.ej. no lo usamos hoy, pero queda expuesto
  /// por si hace falta más adelante).
  final ValueChanged<bool>? onExpandedChanged;

  const CockpitSlidingPanel({
    super.key,
    required this.compact,
    required this.expanded,
    this.onExpandedChanged,
  });

  @override
  State<CockpitSlidingPanel> createState() => CockpitSlidingPanelState();
}

class CockpitSlidingPanelState extends State<CockpitSlidingPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  bool? _lastReportedExpanded;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_reportExpandedChangeIfNeeded);
  }

  void _reportExpandedChangeIfNeeded() {
    final expanded = _controller.value > 0.5;
    if (_lastReportedExpanded != expanded) {
      _lastReportedExpanded = expanded;
      widget.onExpandedChanged?.call(expanded);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Permite que el llamador (MapScreen) cierre el panel desde afuera
  /// -- p.ej. cuando el usuario desliza hacia abajo estando ya en modo
  /// edición del cockpit y ese gesto se maneja en otro widget.
  void collapse() => _controller.animateTo(0, curve: Curves.easeOutCubic);
  void expand() => _controller.animateTo(1, curve: Curves.easeOutCubic);
  bool get isExpanded => _controller.value > 0.5;

  void _onDragUpdate(DragUpdateDetails details, double height) {
    if (height <= 0) return;
    final delta = -details.delta.dy / height;
    _controller.value = (_controller.value + delta).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) {
      _controller.animateTo(1, curve: Curves.easeOutCubic);
    } else if (velocity > 300) {
      _controller.animateTo(0, curve: Curves.easeOutCubic);
    } else {
      _controller.animateTo(
        _controller.value > 0.5 ? 1.0 : 0.0,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onVerticalDragUpdate: (d) => _onDragUpdate(d, height),
          onVerticalDragEnd: _onDragEnd,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = Curves.easeOut.transform(_controller.value);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (t < 0.98)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0),
                        child: IgnorePointer(
                          ignoring: t > 0.05,
                          child: Transform.translate(
                            offset: Offset(0, t * 32),
                            child: widget.compact,
                          ),
                        ),
                      ),
                    ),
                  if (t > 0.02)
                    Positioned.fill(
                      child: Opacity(
                        opacity: t,
                        child: IgnorePointer(
                          ignoring: t < 0.95,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * height * 0.18),
                            child: widget.expanded,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
