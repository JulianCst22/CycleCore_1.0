import 'dart:math' as math;

import 'package:flutter/material.dart';

/// El movimiento de la app al pasar de una pantalla a otra. Va en el
/// tema (`AppTheme`), así que lo usa cualquier `MaterialPageRoute` sin
/// tocar cada `Navigator.push`.
///
/// La pantalla nueva entra desde la derecha mientras aparece; la de
/// atrás se queda quieta y se oscurece, como si quedara debajo. Al
/// volver, lo mismo al revés. La de atrás no se mueve a propósito: si
/// se corriera, por el borde se vería el fondo de la app a través de la
/// nueva, que todavía es semitransparente.
class CcPageTransitionsBuilder extends PageTransitionsBuilder {
  const CcPageTransitionsBuilder();

  /// Lo bastante largo para que se lea como un desplazamiento y lo
  /// bastante corto para no hacer esperar.
  static const duration = Duration(milliseconds: 360);

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CcPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

/// La transición en sí, para usarla también en rutas propias.
class CcPageTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const CcPageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    // Opaca en la primera mitad: así casi no se superponen los textos
    // de las dos pantallas.
    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
      reverseCurve: const Interval(0.5, 1, curve: Curves.easeIn),
    );
    final under = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return _Dim(
      animation: under,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(enter),
        child: FadeTransition(opacity: fadeIn, child: child),
      ),
    );
  }
}

/// Oscurece la pantalla que queda debajo mientras otra entra encima.
class _Dim extends AnimatedWidget {
  final Widget child;

  const _Dim({required Animation<double> animation, required this.child})
    : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    if (t == 0) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.35 * t)),
          ),
        ),
      ],
    );
  }
}

/// Cambia entre pantallas hermanas (las pestañas de abajo) con un
/// fundido corto, sin desmontarlas: cada una conserva su estado como en
/// un `IndexedStack`, y las que no se ven no se pintan ni reciben
/// toques.
///
/// De las dos que se cruzan solo se funde la que queda encima en la
/// pila (la de mayor índice): aparece sobre la otra, o se desvanece
/// dejándola ver. La de abajo queda opaca, así nunca se asoma el fondo.
///
/// La animación vive aquí y no en cada pestaña: si la llevara la
/// pestaña que se oculta, un `TickerMode` apagado la congelaría a medio
/// camino y esa pestaña se quedaría tapando a la nueva.
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 220),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  )..addStatusListener(_onStatus);

  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<double> _fadeOut = ReverseAnimation(
    CurvedAnimation(parent: _controller, curve: Curves.easeIn),
  );

  /// La pestaña que se está yendo, mientras dura el fundido.
  int? _previous;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _previous != null) {
      setState(() => _previous = null);
    }
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _previous = oldWidget.index;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _opacityOf(int i) {
    final previous = _previous;
    if (previous == null || i != math.max(previous, widget.index)) {
      return kAlwaysCompleteAnimation;
    }
    return i == widget.index ? _fadeIn : _fadeOut;
  }

  @override
  Widget build(BuildContext context) {
    // La estructura sobre cada pestaña es siempre la misma (solo cambian
    // los valores): si cambiara, Flutter la reconstruiría desde cero y
    // se perdería su estado.
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Visibility(
            visible: i == widget.index || i == _previous,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: IgnorePointer(
              ignoring: i != widget.index,
              child: FadeTransition(
                opacity: _opacityOf(i),
                child: widget.children[i],
              ),
            ),
          ),
      ],
    );
  }
}
