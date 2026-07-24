import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/cyclist_profile.dart';
import '../profile_edit_screen.dart';

/// Encabezado tipo "tarjeta de perfil" -- avatar circular, nombre,
/// ciudad y biografía, con acceso directo a edición. Es la primera
/// pieza que ve el usuario en Perfil, igual que en Strava/Garmin
/// Connect.
class ProfileHeader extends StatelessWidget {
  final CyclistProfile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage: profile.avatarPath != null
                  ? FileImage(File(profile.avatarPath!))
                  : null,
              child: profile.avatarPath == null
                  ? const Icon(Icons.person, size: 44, color: AppColors.primary)
                  : null,
            ),
            Positioned(right: 0, bottom: 0, child: _EditButton()),
          ],
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

class _EditButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
        ),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.edit, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
