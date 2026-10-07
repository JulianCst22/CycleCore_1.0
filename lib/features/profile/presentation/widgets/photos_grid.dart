import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/ui.dart';
import '../../../stats/stats.dart';
import '../../application/extension_points.dart';
import '../photo_gallery_screen.dart';

/// El álbum del perfil: **todas** las fotos que el ciclista ha subido a
/// sus salidas, de la más reciente a la más vieja.
///
/// Antes solo se veían las de las salidas que fueron récord, y eso
/// dejaba fuera casi todo lo rodado. Acá se muestran las primeras
/// [preview] y, si hay más, un botón abre la galería completa; así la
/// vitrina no se convierte en una lista infinita.
///
/// Las que además fueron récord llevan su medallita, que era lo único
/// que valía la pena conservar del criterio anterior.
class PhotosGrid extends ConsumerWidget {
  /// Cuántas caben antes de mandar a la galería.
  final int preview;

  const PhotosGrid({super.key, this.preview = 9});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(allPhotosProvider);
    final records = ref.watch(recordPhotoPathsProvider);
    final openDetail = ref.read(openActivityDetailProvider);

    return photosAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (photos) {
        if (photos.isEmpty) return const _Empty();
        final shown = photos.take(preview).toList();
        final rest = photos.length - shown.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PhotoMosaic(
              photos: shown,
              records: records,
              onTap: openDetail == null
                  ? null
                  : (photo) => openDetail(context, photo.activityId),
            ),
            if (rest > 0) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PhotoGalleryScreen(),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: CcColors.blue,
                  minimumSize: const Size(0, 40),
                ),
                child: Text('Ver las $rest restantes'),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Cuadrícula de tres columnas que pintan [PhotosGrid] y la galería.
class PhotoMosaic extends StatelessWidget {
  final List<FeaturedPhoto> photos;
  final Set<String> records;
  final void Function(FeaturedPhoto photo)? onTap;

  /// Cuando la cuadrícula ya vive dentro de otra lista que se desplaza.
  final bool shrinkWrap;

  const PhotoMosaic({
    super.key,
    required this.photos,
    required this.records,
    required this.onTap,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: shrinkWrap,
    physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
    padding: EdgeInsets.zero,
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
          onTap: onTap == null ? null : () => onTap!(photo),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(photo.photoPath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: CcColors.surface,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: CcColors.inkDim,
                  ),
                ),
              ),
              if (records.contains(photo.photoPath))
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
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 24),
    alignment: Alignment.center,
    child: const Text(
      'Las fotos que le pongas a tus salidas aparecerán acá',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textSecondaryOnPanel, fontSize: 12),
    ),
  );
}
