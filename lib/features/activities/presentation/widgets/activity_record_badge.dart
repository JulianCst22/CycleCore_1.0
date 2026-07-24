import 'package:flutter/material.dart';

/// Badge de "récord personal" con un resplandor dorado pulsante.
///
/// Se muestra sobre la tarjeta cuando la actividad es la de mayor
/// distancia registrada para su tipo (entrenamiento, carrera, etc.).
/// Es la pieza de gamificación: un pequeño golpe de dopamina de logro
/// cada vez que el usuario ve que superó su marca anterior.
class ActivityRecordBadge extends StatefulWidget {
  const ActivityRecordBadge({super.key});

  static const goldStart = Color(0xFFFFE29A);
  static const goldEnd = Color(0xFFC9962E);

  @override
  State<ActivityRecordBadge> createState() => _ActivityRecordBadgeState();
}

class _ActivityRecordBadgeState extends State<ActivityRecordBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 6, end: 14).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                ActivityRecordBadge.goldStart,
                ActivityRecordBadge.goldEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ActivityRecordBadge.goldEnd.withValues(alpha: 0.55),
                blurRadius: _pulse.value,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 12, color: Colors.black87),
          SizedBox(width: 4),
          Text(
            'Récord personal',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
