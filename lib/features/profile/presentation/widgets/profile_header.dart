import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/cyclist_profile.dart';
import 'avatar_viewer_screen.dart';

/// Encabezado tipo "tarjeta de perfil" -- avatar circular, nombre,
/// ciudad y biografía.
///
/// El botón de editar (lápiz flotando sobre el avatar) se quitó de
/// aquí: ahora "Editar perfil" vive en Ajustes (`SettingsScreen`),
/// junto con Cuenta y Zonas -- así este encabezado queda 100%
/// "vitrina" (mirar), sin ningún control compitiendo visualmente con
/// el contenido, que era justo lo que se sentía "expuesto" antes.
///
/// La foto ahora es tocable: al tener avatar, abre una vista en
/// grande con zoom (antes no había forma de verla bien, solo el
/// círculo pequeño).
class ProfileHeader extends StatelessWidget {
  final CyclistProfile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = profile.avatarPath != null;

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
          child: CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage:
                hasAvatar ? FileImage(File(profile.avatarPath!)) : null,
            child: !hasAvatar
                ? const Icon(Icons.person, size: 44, color: AppColors.primary)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          profile.name,
          style: const TextStyle(
            color: AppColors.textPrimaryOnPanel,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (profile.city != null && profile.city!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textSecondaryOnPanel,
              ),
              const SizedBox(width: 4),
              Text(
                profile.city!,
                style: const TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                  fontSize: 13,
                ),
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
              color: AppColors.textSecondaryOnPanel,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}
