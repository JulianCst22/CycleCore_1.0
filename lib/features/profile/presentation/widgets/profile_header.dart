import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import '../../domain/cyclist_profile.dart';
import '../../domain/rank_tier.dart';
import '../profile_providers.dart';
import 'avatar_viewer_screen.dart';

/// Encabezado tipo "tarjeta de perfil" -- avatar circular, nombre,
/// ciudad y biografía.
///
/// Alrededor de la foto va un **anillo del color del rango** con un arco
/// que marca el progreso dentro del nivel actual: le da peso a la
/// gamificación sin meter otro widget. El detalle de nivel/rango sigue
/// justo debajo, en `LevelRoadmap`.
///
/// El botón de editar se quitó de aquí: "Editar perfil" vive en Ajustes,
/// así este encabezado queda 100% "vitrina". La foto es tocable: al
/// tener avatar, abre una vista en grande con zoom.
class ProfileHeader extends ConsumerWidget {
  final CyclistProfile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAvatar = profile.avatarPath != null;
    final levelInfo = ref.watch(levelInfoProvider).valueOrNull;
    final tier = RankTier.forLevel(levelInfo?.level ?? 1);
    final progress = levelInfo?.progress ?? 0.0;

    return Column(
      children: [
        GestureDetector(
          onTap: !hasAvatar
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AvatarViewerScreen(
                      imageFile: File(profile.avatarPath!),
                      title: profile.name,
                    ),
                  ),
                ),
          child: _RingedAvatar(
            avatarPath: profile.avatarPath,
            ringColor: tier.color,
            progress: progress,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          profile.name,
          style: CcType.displayStyle(size: 20, weight: FontWeight.w700),
        ),
        if (profile.city != null && profile.city!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: CcColors.inkDim,
              ),
              const SizedBox(width: 4),
              Text(
                profile.city!,
                style: const TextStyle(color: CcColors.inkDim, fontSize: 13),
              ),
            ],
          ),
        ],
        if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            profile.bio!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CcColors.inkDim,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _RingedAvatar extends StatelessWidget {
  const _RingedAvatar({
    required this.avatarPath,
    required this.ringColor,
    required this.progress,
  });

  final String? avatarPath;
  final Color ringColor;

  /// Progreso dentro del nivel actual (0..1).
  final double progress;

  static const _avatarRadius = 44.0;
  static const _ringGap = 5.0;
  static const _stroke = 3.5;

  @override
  Widget build(BuildContext context) {
    const dimension = (_avatarRadius + _ringGap + _stroke) * 2;
    final hasAvatar = avatarPath != null;

    return SizedBox(
      width: dimension,
      height: dimension,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Resplandor tenue del color del rango.
          Container(
            width: dimension - _stroke * 2,
            height: dimension - _stroke * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size.square(dimension),
            painter: _RingPainter(color: ringColor, progress: progress),
          ),
          CircleAvatar(
            radius: _avatarRadius,
            backgroundColor: ringColor.withValues(alpha: 0.16),
            backgroundImage: hasAvatar ? FileImage(File(avatarPath!)) : null,
            child: !hasAvatar
                ? Icon(Icons.person, size: 44, color: ringColor)
                : null,
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - _RingedAvatar._stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Carril completo, tenue.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _RingedAvatar._stroke
        ..color = color.withValues(alpha: 0.22),
    );

    // Arco de progreso, desde arriba.
    final sweep = (progress.clamp(0.0, 1.0)) * 2 * math.pi;
    if (sweep > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _RingedAvatar._stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.color != color || old.progress != progress;
}
