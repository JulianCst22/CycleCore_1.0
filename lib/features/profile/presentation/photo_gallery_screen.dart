import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ui.dart';
import '../../stats/stats.dart';
import '../application/extension_points.dart';
import 'widgets/photos_grid.dart';

/// Todas las fotos del ciclista, agrupadas por mes.
///
/// Es la pantalla a la que lleva el perfil cuando el álbum ya no cabe
/// en la vitrina. Tocar una foto abre la salida de la que salió, que es
/// lo que uno quiere saber al ver una foto vieja: dónde fue eso.
class PhotoGalleryScreen extends ConsumerWidget {
  const PhotoGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(allPhotosProvider);
    final records = ref.watch(recordPhotoPathsProvider);
    final openDetail = ref.read(openActivityDetailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tus fotos')),
      body: SafeArea(
        child: photosAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: CcColors.orange),
          ),
          error: (error, _) => Center(
            child: Text(
              'No se pudieron cargar las fotos:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CcColors.inkDim),
            ),
          ),
          data: (photos) {
            if (photos.isEmpty) {
              return const Center(
                child: Text(
                  'Todavía no le has puesto fotos a ninguna salida',
                  style: TextStyle(color: CcColors.inkDim),
                ),
              );
            }

            final months = _byMonth(photos);
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0) const SizedBox(height: 22),
                    ActivitySectionLabel(month.label),
                    const SizedBox(height: 10),
                    PhotoMosaic(
                      photos: month.photos,
                      records: records,
                      onTap: openDetail == null
                          ? null
                          : (photo) => openDetail(context, photo.activityId),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Agrupa en orden, que ya viene de la más reciente a la más vieja.
  static List<({String label, List<FeaturedPhoto> photos})> _byMonth(
    List<FeaturedPhoto> photos,
  ) {
    final groups = <({String label, List<FeaturedPhoto> photos})>[];
    String? current;
    for (final photo in photos) {
      final label = _monthLabel(photo.startedAt);
      if (label != current) {
        groups.add((label: label, photos: <FeaturedPhoto>[]));
        current = label;
      }
      groups.last.photos.add(photo);
    }
    return groups;
  }

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String _monthLabel(DateTime date) =>
      '${_months[date.month - 1]} ${date.year}';
}
