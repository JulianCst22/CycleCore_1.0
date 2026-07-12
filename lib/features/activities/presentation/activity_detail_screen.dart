import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../shared_widgets/stat_tile.dart';
import '../domain/activity_colors.dart';
import '../domain/activity_json_helpers.dart';
import '../domain/activity_summary.dart';
import 'activities_providers.dart';
import 'activity_charts.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final int activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(appDatabaseProvider);

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      body: FutureBuilder<Activity?>(
        future: database.getActivityById(activityId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final activity = snapshot.data;
          if (activity == null) {
            return const Center(
              child: Text(
                'Esta actividad ya no existe.',
                style: TextStyle(color: AppColors.textSecondaryOnPanel),
              ),
            );
          }

          return _ActivityDetailBody(activity: activity);
        },
      ),
    );
  }
}

/// Estadísticas derivadas de la serie completa de puntos (no vienen ya
/// calculadas en la tabla, se obtienen recorriendo `routePoints` una
/// sola vez). Si la actividad se grabó antes de que existiera este nivel
/// de detalle por punto, simplemente quedan en null/--.
class _DerivedStats {
  final double? minAltitude;
  final double? maxAltitude;
  final double? elevationLossMeters;
  final double? maxSlopePercent;
  final double? minSlopePercent;

  const _DerivedStats({
    this.minAltitude,
    this.maxAltitude,
    this.elevationLossMeters,
    this.maxSlopePercent,
    this.minSlopePercent,
  });

  factory _DerivedStats.fromPoints(List<RoutePointSnapshot> points) {
    if (points.length < 2) return const _DerivedStats();

    double minAlt = points.first.altitude;
    double maxAlt = points.first.altitude;
    double loss = 0;
    double maxSlope = points.first.slopePercent;
    double minSlope = points.first.slopePercent;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      minAlt = math.min(minAlt, p.altitude);
      maxAlt = math.max(maxAlt, p.altitude);
      maxSlope = math.max(maxSlope, p.slopePercent);
      minSlope = math.min(minSlope, p.slopePercent);

      if (i > 0) {
        final delta = p.altitude - points[i - 1].altitude;
        if (delta < 0) loss += -delta;
      }
    }

    return _DerivedStats(
      minAltitude: minAlt,
      maxAltitude: maxAlt,
      elevationLossMeters: loss,
      maxSlopePercent: maxSlope,
      minSlopePercent: minSlope,
    );
  }
}

class _ActivityDetailBody extends ConsumerWidget {
  final Activity activity;

  const _ActivityDetailBody({required this.activity});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
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

    if (confirmed == true) {
      await ref.read(activitiesRepositoryProvider).deleteActivity(activity.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeUi = ActivityTypeUi.fromValue(activity.activityType);
    final routePoints = activity.routePoints;
    final photoPaths = activity.photoPaths;
    final derived = _DerivedStats.fromPoints(routePoints);
    final dateLabel = DateFormat(
      "EEEE d 'de' MMMM 'de' y, HH:mm",
      'es',
    ).format(activity.startedAt);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.panelBackground,
          pinned: true,
          expandedHeight: routePoints.length > 1 ? 240 : 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
          title: Text(
            activity.title,
            style: const TextStyle(color: AppColors.textPrimaryOnPanel),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.textPrimaryOnPanel,
              onPressed: () => _delete(context, ref),
            ),
          ],
          flexibleSpace: routePoints.length > 1
              ? FlexibleSpaceBar(background: _RouteMap(points: routePoints))
              : null,
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(typeUi.icon, size: 16, color: typeUi.color),
                      const SizedBox(width: 6),
                      Text(
                        typeUi.label,
                        style: TextStyle(
                          color: typeUi.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.pedal_bike,
                        size: 15,
                        color: AppColors.textSecondaryOnPanel,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.bikeName,
                        style: const TextStyle(
                          color: AppColors.textSecondaryOnPanel,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondaryOnPanel,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Totales principales ---
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.15,
                    children: [
                      StatTile(
                        icon: Icons.straighten,
                        accentColor: AppColors.accentDistance,
                        value: formatDistanceKm(activity.distanceMeters),
                        unit: 'km',
                        label: 'DISTANCIA',
                      ),
                      StatTile(
                        icon: Icons.timer_outlined,
                        accentColor: AppColors.accentTime,
                        value: formatDuration(
                          Duration(seconds: activity.durationSeconds),
                        ),
                        unit: '',
                        label: 'TIEMPO',
                      ),
                      StatTile(
                        icon: Icons.speed,
                        accentColor: AppColors.accentSpeed,
                        value: formatSpeedKmh(activity.avgSpeedKmh),
                        unit: 'km/h',
                        label: 'PROMEDIO',
                      ),
                      StatTile(
                        icon: Icons.bolt,
                        accentColor: AppColors.accentSpeed,
                        value: formatSpeedKmh(activity.maxSpeedKmh),
                        unit: 'km/h',
                        label: 'VEL. MÁX',
                      ),
                      StatTile(
                        icon: Icons.terrain,
                        accentColor: AppColors.accentElevation,
                        value: activity.elevationGainMeters.toStringAsFixed(0),
                        unit: 'm',
                        label: 'DESNIVEL +',
                      ),
                      StatTile(
                        icon: Icons.favorite,
                        accentColor: AppColors.accentHeartRate,
                        value: activity.avgHeartRate?.toString() ?? '--',
                        unit: 'bpm',
                        label: 'FC PROM.',
                      ),
                    ],
                  ),

                  // --- Gráfico interactivo de altimetría/FC/velocidad ---
                  if (routePoints.length > 1) ...[
                    const SizedBox(height: 24),
                    ActivityChartsCard(points: routePoints),
                  ],

                  // --- Todos los datos, incluyendo los derivados ---
                  const SizedBox(height: 24),
                  const Text(
                    'TODOS LOS DATOS',
                    style: TextStyle(
                      color: AppColors.textSecondaryOnPanel,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.15,
                    children: [
                      StatTile(
                        icon: Icons.favorite,
                        accentColor: AppColors.accentHeartRate,
                        value: activity.maxHeartRate?.toString() ?? '--',
                        unit: 'bpm',
                        label: 'FC MÁXIMA',
                      ),
                      StatTile(
                        icon: Icons.south,
                        accentColor: AppColors.accentElevation,
                        value: derived.elevationLossMeters
                                ?.toStringAsFixed(0) ??
                            '--',
                        unit: 'm',
                        label: 'DESNIVEL −',
                      ),
                      StatTile(
                        icon: Icons.height,
                        accentColor: AppColors.accentElevation,
                        value: derived.minAltitude?.toStringAsFixed(0) ?? '--',
                        unit: 'm',
                        label: 'ALT. MÍNIMA',
                      ),
                      StatTile(
                        icon: Icons.height,
                        accentColor: AppColors.accentElevation,
                        value: derived.maxAltitude?.toStringAsFixed(0) ?? '--',
                        unit: 'm',
                        label: 'ALT. MÁXIMA',
                      ),
                      StatTile(
                        icon: Icons.trending_up,
                        accentColor: AppColors.accentSlope,
                        value: derived.maxSlopePercent != null
                            ? formatSlopePercent(derived.maxSlopePercent!)
                            : '--',
                        unit: '%',
                        label: 'PEND. MÁX',
                      ),
                      StatTile(
                        icon: Icons.trending_down,
                        accentColor: AppColors.accentSlope,
                        value: derived.minSlopePercent != null
                            ? formatSlopePercent(derived.minSlopePercent!)
                            : '--',
                        unit: '%',
                        label: 'PEND. MÍN',
                      ),
                    ],
                  ),

                  if (photoPaths.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'FOTOS',
                      style: TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PhotoGallery(photoPaths: photoPaths),
                  ],

                  if (activity.notes != null &&
                      activity.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'NOTAS',
                      style: TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activity.notes!,
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnPanel,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

/// Mapa real (con tiles) mostrando la ruta completa, encuadrado
/// automáticamente y coloreada tramo a tramo según la pendiente -- el
/// mismo lenguaje visual que el gráfico de altimetría de abajo.
class _RouteMap extends StatelessWidget {
  final List<RoutePointSnapshot> points;

  const _RouteMap({required this.points});

  @override
  Widget build(BuildContext context) {
    final latLngs =
        points.map((p) => latlng.LatLng(p.latitude, p.longitude)).toList();
    final bounds = LatLngBounds.fromPoints(latLngs);

    final segments = <Polyline>[];
    for (int i = 0; i < points.length - 1; i++) {
      final avgSlope =
          (points[i].slopePercent + points[i + 1].slopePercent) / 2;
      segments.add(
        Polyline(
          points: [latLngs[i], latLngs[i + 1]],
          strokeWidth: 4,
          color: slopeToColor(avgSlope),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(32),
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.cyclecore_app',
        ),
        PolylineLayer(polylines: segments),
        MarkerLayer(
          markers: [
            Marker(
              point: latLngs.first,
              width: 16,
              height: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.accentElevation,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            Marker(
              point: latLngs.last,
              width: 16,
              height: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.recordButtonActive,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Galería de fotos deslizable horizontalmente, con indicadores de página
/// tipo Strava/Instagram.
class _PhotoGallery extends StatefulWidget {
  final List<String> photoPaths;

  const _PhotoGallery({required this.photoPaths});

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photoPaths.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                return Image.file(
                  File(widget.photoPaths[index]),
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              },
            ),
          ),
        ),
        if (widget.photoPaths.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.photoPaths.length, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.textSecondaryOnPanel.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
