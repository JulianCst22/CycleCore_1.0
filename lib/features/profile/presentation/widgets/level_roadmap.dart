import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/level_info.dart';
import '../../domain/rank_tier.dart';
import '../climb_screen.dart';
import '../profile_providers.dart';

/// Reemplaza a `LevelBadge` en el perfil: un mapa de progreso
/// horizontal tipo videojuego con los 6 rangos como nodos --
/// bloqueados (gris + candado), completados (color + check) y el
/// actual (pulso animado + resplandor). Tocar un nodo abre la subida
/// 3D (`ClimbScreen`) centrada en ese rango.
class LevelRoadmap extends ConsumerWidget {
  const LevelRoadmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelAsync = ref.watch(levelInfoProvider);

    return levelAsync.when(
      loading: () => const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) => _RoadmapCard(info: info),
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  final LevelInfo info;
  const _RoadmapCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final currentTierIndex = RankTier.indexOfRank(info.rank);
    final currentTier = RankTier.all[currentTierIndex];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: currentTier.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(currentTier.icon, color: currentTier.color, size: 18),
              const SizedBox(width: 6),
              Text(
                '${currentTier.label} · Nivel ${info.level}',
                style: TextStyle(
                  color: currentTier.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                'faltan ${info.xpRemainingForNextLevel} XP',
                style: const TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 84,
            child: Row(
              children: [
                for (var i = 0; i < RankTier.all.length; i++) ...[
                  _RoadmapNode(
                    tier: RankTier.all[i],
                    isCurrent: i == currentTierIndex,
                    isCompleted: i < currentTierIndex,
                    progressWithinCurrent:
                        i == currentTierIndex ? info.progress : 0,
                  ),
                  if (i != RankTier.all.length - 1)
                    Expanded(
                      child: _RoadmapConnector(
                        filled: i < currentTierIndex,
                        color: RankTier.all[i].color,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapConnector extends StatelessWidget {
  final bool filled;
  final Color color;
  const _RoadmapConnector({required this.filled, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: filled ? 1 : 0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoadmapNode extends StatefulWidget {
  final RankTierInfo tier;
  final bool isCurrent;
  final bool isCompleted;
  final double progressWithinCurrent;

  const _RoadmapNode({
    required this.tier,
    required this.isCurrent,
    required this.isCompleted,
    required this.progressWithinCurrent,
  });

  @override
  State<_RoadmapNode> createState() => _RoadmapNodeState();
}

class _RoadmapNodeState extends State<_RoadmapNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isCurrent) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _RoadmapNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrent) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isLocked => !widget.isCurrent && !widget.isCompleted;

  @override
  Widget build(BuildContext context) {
    final color = _isLocked ? AppColors.textSecondaryOnPanel : widget.tier.color;

    return GestureDetector(
      onTap: () => _openClimb(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final glow = widget.isCurrent ? _pulseController.value : 0.0;
              return SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.isCurrent)
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          value: widget.progressWithinCurrent,
                          strokeWidth: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isLocked
                            ? Colors.white.withValues(alpha: 0.05)
                            : color.withValues(alpha: 0.16),
                        border: Border.all(
                          color: color.withValues(alpha: _isLocked ? 0.3 : 1),
                          width: widget.isCurrent ? 2.5 : 1.5,
                        ),
                        boxShadow: widget.isCurrent
                            ? [
                                BoxShadow(
                                  color:
                                      color.withValues(alpha: 0.25 + glow * 0.35),
                                  blurRadius: 8 + glow * 10,
                                  spreadRadius: glow * 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _isLocked
                            ? Icons.lock_outline
                            : (widget.isCompleted ? Icons.check : widget.tier.icon),
                        color: color,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            widget.tier.label,
            style: TextStyle(
              color: _isLocked
                  ? AppColors.textSecondaryOnPanel.withValues(alpha: 0.6)
                  : color,
              fontSize: 10,
              fontWeight: widget.isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _openClimb(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClimbScreen(focusRank: widget.tier.rank),
      ),
    );
  }
}
