import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import 'activities_providers.dart';
import 'activity_detail_screen.dart';
import '../domain/activity_json_helpers.dart';
import 'widgets/route_hero_background.dart';

class ActivitiesListScreen extends ConsumerWidget {
  const ActivitiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesListProvider);

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        elevation: 0,
        title: const Text(
          'Tus actividades',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
      ),
      body: activitiesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'No se pudieron cargar tus actividades:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ),
        data: (activities) {
          if (activities.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return _ActivityCard(activity: activities[index]);
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.route_outlined,
              size: 56,
              color: AppColors.textSecondaryOnPanel.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes actividades guardadas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Graba tu primer recorrido desde el mapa y aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondaryOnPanel,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta grande tipo "hero" -- carrusel (ruta + fotos) arriba, título
/// y stats destacados abajo. Es `ConsumerStatefulWidget` (y no
/// `StatelessWidget` como antes) porque necesita guardar en qué página
/// del carrusel está el usuario, para animar los puntos indicadores.
class _ActivityCard extends ConsumerStatefulWidget {
  final Activity activity;

  const _ActivityCard({required this.activity});

  @override
  ConsumerState<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends ConsumerState<_ActivityCard> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final typeUi = ActivityTypeUi.fromValue(activity.activityType);
    final dateLabel =
        DateFormat("d MMM · HH:mm", 'es').format(activity.startedAt);
    final photoPaths = activity.photoPaths;
    // Página 0 siempre es el mapa de la ruta; las siguientes son fotos.
    // Así siempre hay algo que mostrar aunque no se hayan agregado fotos.
    final pageCount = 1 + photoPaths.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ActivityDetailScreen(activityId: activity.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMediaHeader(
                context,
                activity: activity,
                typeUi: typeUi,
                dateLabel: dateLabel,
                photoPaths: photoPaths,
                pageCount: pageCount,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnPanel,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroStat(
                            icon: Icons.straighten,
                            value: formatDistanceKm(activity.distanceMeters),
                            unit: 'km',
                            label: 'Distancia',
                          ),
                        ),
                        const _StatDivider(),
                        Expanded(
                          child: _HeroStat(
                            icon: Icons.timer_outlined,
                            value: formatDuration(
                              Duration(seconds: activity.durationSeconds),
                            ),
                            unit: '',
                            label: 'Duración',
                          ),
                        ),
                        const _StatDivider(),
                        Expanded(
                          child: _HeroStat(
                            icon: Icons.terrain,
                            value: activity.elevationGainMeters
                                .toStringAsFixed(0),
                            unit: 'm',
                            label: 'Desnivel',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaHeader(
    BuildContext context, {
    required Activity activity,
    required ActivityTypeUi typeUi,
    required String dateLabel,
    required List<String> photoPaths,
    required int pageCount,
  }) {
    return SizedBox(
      height: 210,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: pageCount,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              if (index == 0) {
                return RouteHeroBackground(
                  points: activity.routePoints,
                  accentColor: typeUi.color,
                );
              }
              final path = photoPaths[index - 1];
              return Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.panelBackground,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondaryOnPanel,
                  ),
                ),
              );
            },
          ),

          // Degradado inferior -- para que la fecha sea legible sobre
          // cualquier foto, sin importar qué tan clara sea.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ),

          Positioned(
            left: 12,
            top: 12,
            child: _TypeChip(typeUi: typeUi),
          ),

          Positioned(
            right: 8,
            top: 8,
            child: _MenuButton(
              onTap: () => _showActivityMenu(context, activity),
            ),
          ),

          Positioned(
            left: 14,
            bottom: 10,
            child: Text(
              dateLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (pageCount > 1)
            Positioned(
              bottom: 12,
              right: 14,
              child: _PageDots(count: pageCount, current: _currentPage),
            ),
        ],
      ),
    );
  }

  Future<void> _showActivityMenu(
    BuildContext context,
    Activity activity,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondaryOnPanel.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.recordButtonActive,
                ),
                title: const Text(
                  'Eliminar actividad',
                  style: TextStyle(color: AppColors.textPrimaryOnPanel),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final confirmed = await _confirmDelete(context);
                  if (confirmed) {
                    ref
                        .read(activitiesRepositoryProvider)
                        .deleteActivity(activity.id);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panelBackground,
        title: const Text(
          '¿Eliminar actividad?',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.textSecondaryOnPanel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.recordButtonActive),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _TypeChip extends StatelessWidget {
  final ActivityTypeUi typeUi;

  const _TypeChip({required this.typeUi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(typeUi.icon, size: 13, color: typeUi.color),
          const SizedBox(width: 5),
          Text(
            typeUi.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(7),
          child: Icon(Icons.more_vert, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: active ? 14 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;

  const _HeroStat({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondaryOnPanel),
            const SizedBox(width: 4),
            Text(
              unit.isEmpty ? value : '$value $unit',
              style: const TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.textSecondaryOnPanel.withValues(alpha: 0.15),
    );
  }
}
