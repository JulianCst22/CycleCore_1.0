import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/level_info.dart';
import '../../domain/rank_tier.dart';
import '../climb_screen.dart';
import '../profile_providers.dart';

/// Punto de entrada único para disparar el festejo de "subiste de
/// nivel" desde cualquier pantalla.
///
/// Úsalo justo después de guardar una actividad, en tu pantalla de
/// resumen post-actividad (el archivo que aún no tengo):
///
/// ```dart
/// // después de await activitiesRepository.insertActivity(...):
/// await LevelUpFlow.showIfLeveledUp(context, ref);
/// ```
///
/// Internamente compara el nivel actual contra el último reconocido
/// (`levelAcknowledgementProvider`) y solo muestra el overlay si de
/// verdad hubo una subida.
class LevelUpFlow {
  LevelUpFlow._();

  static Future<void> showIfLeveledUp(BuildContext context, WidgetRef ref) async {
    final levelInfo = ref.read(levelInfoProvider).valueOrNull;
    if (levelInfo == null) return;

    final leveledUp = ref
        .read(levelAcknowledgementProvider.notifier)
        .consumeLevelUp(levelInfo.level);

    if (!leveledUp || !context.mounted) return;

    await showLevelUpOverlay(context, levelInfo);
  }

  static Future<void> showLevelUpOverlay(
    BuildContext context,
    LevelInfo levelInfo,
  ) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Subiste de nivel',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, _, __) => LevelUpOverlay(levelInfo: levelInfo),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}

/// La celebración en sí: rango + nivel nuevo, con un pulso de anillos
/// expandiéndose y un ícono que rebota, temáticos del color del rango
/// alcanzado.
class LevelUpOverlay extends StatefulWidget {
  final LevelInfo levelInfo;
  const LevelUpOverlay({super.key, required this.levelInfo});

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = RankTier.forRank(widget.levelInfo.rank);

    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) => CustomPaint(
                        size: const Size(180, 180),
                        painter: _PulseRingsPainter(
                          progress: _pulseController.value,
                          color: tier.color,
                        ),
                      ),
                    ),
                    ScaleTransition(
                      scale: Tween(begin: 0.94, end: 1.06).animate(
                        CurvedAnimation(
                          parent: _bounceController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tier.color.withValues(alpha: 0.18),
                          border: Border.all(color: tier.color, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: tier.color.withValues(alpha: 0.5),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(tier.icon, color: tier.color, size: 46),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '¡SUBISTE DE NIVEL!',
                style: TextStyle(
                  color: AppColors.textPrimaryOnPanel,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nivel ${widget.levelInfo.level}',
                style: TextStyle(
                  color: tier.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tier.label,
                style: TextStyle(
                  color: tier.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: tier.color),
                onPressed: () {
                  Navigator.of(context).maybePop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClimbScreen(focusRank: widget.levelInfo.rank),
                    ),
                  );
                },
                child: const Text('Ver tu progreso'),
              ),
              const SizedBox(height: 10),
              Text(
                'Toca fuera para cerrar',
                style: TextStyle(
                  color: AppColors.textSecondaryOnPanel.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseRingsPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _PulseRingsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    for (var ring = 0; ring < 3; ring++) {
      final ringProgress = (progress + ring / 3) % 1.0;
      final radius = maxRadius * (0.35 + ringProgress * 0.65);
      final opacity = (1 - ringProgress) * 0.5;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity.clamp(0.0, 0.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseRingsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
