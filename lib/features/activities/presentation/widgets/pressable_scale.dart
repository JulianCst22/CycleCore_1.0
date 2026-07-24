import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Envoltorio que da feedback táctil premium a cualquier tarjeta o
/// botón: al presionar se encoge levemente (efecto "squeeze" tipo
/// Duolingo/Strava) y dispara un haptic sutil en el momento del toque.
///
/// Reemplaza el `InkWell` plano -- no hay ripple, pero el feedback de
/// escala + haptic se percibe como más "vivo" y es lo que suele
/// generar la sensación de calidad en apps premium.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableScale({super.key, required this.child, this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    final target = pressed ? 0.97 : 1.0;
    if (_scale != target) {
      setState(() => _scale = target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) {
        _setPressed(true);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
