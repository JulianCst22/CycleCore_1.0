import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/presentation/activity_detail_screen.dart';
import '../profile_providers.dart';

/// Grid de fotos "destacadas": las de actividades que fueron récord
/// personal para su tipo (mismo criterio de medalla que en la lista de
/// actividades). Tocar una foto lleva directo al detalle de esa
/// actividad, igual que en Strava.
class FeaturedPhotosGrid extends ConsumerWidget {
  const FeaturedPhotosGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(featuredPhotosProvider);

    return photosAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (photos) {
        if (photos.isEmpty) return const _EmptyFeatured();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final photo = photos[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ActivityDetailScreen(activityId: photo.activityId),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(photo.photoPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.panelBackground,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondaryOnPanel,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: AppColors.primary,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyFeatured extends StatelessWidget {
  const _EmptyFeatured();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: const Text(
        'Tus fotos de récords personales aparecerán aquí',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondaryOnPanel, fontSize: 12),
      ),
    );
  }
}
