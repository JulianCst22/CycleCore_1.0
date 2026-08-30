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
import '../../profile/presentation/profile_providers.dart';
import '../../segments/presentation/segment_creation_screen.dart';
import '../../segments/presentation/segment_detail_screen.dart';
import '../../segments/presentation/segments_providers.dart';
import '../domain/activity_calories.dart';
import '../domain/activity_colors.dart';
import '../domain/activity_json_helpers.dart';
import '../domain/activity_records.dart';
import '../domain/activity_summary.dart';
import '../domain/elevation_gain_loss.dart';
import 'activities_providers.dart';
import 'activity_charts.dart';
import 'adjust_altitude_screen.dart';
import 'save_activity_screen.dart';
import 'share_activity_screen.dart';
import 'widgets/personal_record_banner.dart';
import 'widgets/photo_viewer_screen.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  final int activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  ConsumerState<ActivityDetailScreen> createState() =>
      _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  late Future<Activity?> _activityFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  // Vuelve a pedir la actividad a la base de datos. Se llama al volver
  // de editar, para que los cambios se reflejen sin salir de la
  // pantalla de detalle.
  void _reload() {
    final database = ref.read(appDatabaseProvider);
    _activityFuture = database.getActivityById(widget.activityId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      body: FutureBuilder<Activity?>(
        future: _activityFuture,
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

          return _ActivityDetailBody(
            activity: activity,
            onEdited: () => setState(_reload),
          );
        },
      ),
    );
  }
}

/// Estadísticas derivadas de la serie completa de puntos (no vienen ya
/// calculadas en la tabla, se obtienen recorriendo `routePoints` una
/// sola vez). Si la actividad se grabó antes de que existiera este nivel
/// de detalle por punto, simplemente quedan en null/--.
///
/// Nota: ya NO incluye pendiente máxima/mínima -- se sacaron de "TODOS
/// LOS DATOS" a pedido, porque esos dos picos puntuales (a menudo
/// ruido de un solo punto GPS) no aportaban información útil y
/// generaban dudas sobre la fiabilidad del resto de las stats.
class _DerivedStats {
  final double? minAltitude;
  final double? maxAltitude;
  final double? elevationLossMeters;

  const _DerivedStats({
    this.minAltitude,
    this.maxAltitude,
    this.elevationLossMeters,
  });

  factory _DerivedStats.fromPoints(List<RoutePointSnapshot> points) {
    if (points.length < 2) return const _DerivedStats();

    double minAlt = points.first.altitude;
    double maxAlt = points.first.altitude;
    for (final p in points) {
      minAlt = math.min(minAlt, p.altitude);
      maxAlt = math.max(maxAlt, p.altitude);
    }

    // Desnivel negativo con histéresis -- MISMO método que el
    // aplanador (`computeGainLoss`). Sumar cada delta negativo, como
    // hacía antes, inflaba la pérdida en cualquier serie con ruido
    // (p.ej. una subida pura marcaba "desnivel −" alto).
    final loss = computeGainLoss(
      points.map((p) => p.altitude).toList(),
    ).lossMeters;

    return _DerivedStats(
      minAltitude: minAlt,
      maxAltitude: maxAlt,
      elevationLossMeters: loss,
    );
  }
}

class _ActivityDetailBody extends ConsumerWidget {
  final Activity activity;
  final VoidCallback onEdited;

  const _ActivityDetailBody({required this.activity, required this.onEdited});

  Future<void> _edit(BuildContext context) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => SaveActivityScreen(existingActivity: activity),
      ),
    );
    if (!context.mounted) return;
    if (result == 'deleted') {
      // La actividad ya no existe -- cerramos también el detalle.
      Navigator.of(context).pop();
    } else if (result == true) {
      onEdited();
    }
  }

  // Eliminar la actividad ya no vive acá -- se hace desde "Editar
  // actividad" (botón "Eliminar" dentro de esa pantalla), para tener
  // un solo lugar de CRUD.

  void _share(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareActivityScreen(activity: activity),
      ),
    );
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

    // Récord personal: se compara contra el resto de actividades del
    // mismo tipo (misma fuente que usa la lista, así el badge de la
    // lista y este desglose siempre coinciden). Mientras el listado
    // completo no haya cargado, simplemente no se muestra nada -- en
    // cuanto llega, este widget se reconstruye solo.
    final weightKg = ref.watch(profileProvider).valueOrNull?.weightKg;
    final calories = estimateCalories(
      avgPowerWatts: activity.avgPower,
      durationSeconds: activity.durationSeconds,
      elevationGainMeters: activity.elevationGainMeters,
      avgSpeedKmh: activity.avgSpeedKmh,
      weightKg: weightKg,
    );

    final allActivitiesAsync = ref.watch(activitiesListProvider);
    final personalRecords = allActivitiesAsync.maybeWhen(
      data: (all) => computeActivityRecords(
        activity: activity,
        allActivities: all,
      ).records,
      orElse: () => const <RecordType>{},
    );

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
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textPrimaryOnPanel,
              ),
              color: AppColors.panelBackground,
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _edit(context);
                  case 'share':
                    _share(context);
                  case 'altitude':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AdjustAltitudeScreen(activityId: activity.id),
                      ),
                    );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: _MenuRow(
                    icon: Icons.edit_outlined,
                    label: 'Editar actividad',
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: _MenuRow(
                    icon: Icons.ios_share,
                    label: 'Compartir actividad',
                  ),
                ),
                PopupMenuItem(
                  value: 'altitude',
                  child: _MenuRow(
                    icon: Icons.terrain_outlined,
                    label: 'Ajustar altimetría',
                  ),
                ),
              ],
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

                  // Debajo de "Entrenamiento": el desglose de récord
                  // personal, con qué métrica(s) se superaron y su
                  // valor -- esto es lo que faltaba en el badge de la
                  // lista, que solo decía "Récord personal" sin decir
                  // de qué.
                  if (personalRecords.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    PersonalRecordBanner(
                      activity: activity,
                      records: personalRecords,
                    ),
                  ],

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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.straighten,
                          accentColor: AppColors.accentDistance,
                          value: formatDistanceKm(activity.distanceMeters),
                          unit: 'km',
                          label: 'DISTANCIA',
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.timer_outlined,
                          accentColor: AppColors.accentTime,
                          value: formatDuration(
                            Duration(seconds: activity.durationSeconds),
                          ),
                          unit: '',
                          label: 'TIEMPO',
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.speed,
                          accentColor: AppColors.accentSpeed,
                          value: formatSpeedKmh(activity.avgSpeedKmh),
                          unit: 'km/h',
                          label: 'PROMEDIO',
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.bolt,
                          accentColor: AppColors.accentSpeed,
                          value: formatSpeedKmh(activity.maxSpeedKmh),
                          unit: 'km/h',
                          label: 'VEL. MÁX',
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.terrain,
                          accentColor: AppColors.accentElevation,
                          value:
                              activity.elevationGainMeters.toStringAsFixed(0),
                          unit: 'm',
                          label: 'DESNIVEL +',
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.favorite,
                          accentColor: AppColors.accentHeartRate,
                          value: activity.avgHeartRate?.toString() ?? '--',
                          unit: 'bpm',
                          label: 'FC PROM.',
                        ),
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.favorite,
                          accentColor: AppColors.accentHeartRate,
                          value: activity.maxHeartRate?.toString() ?? '--',
                          unit: 'bpm',
                          label: 'FC MÁXIMA',
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.south,
                          accentColor: AppColors.accentElevation,
                          value: derived.elevationLossMeters
                                  ?.toStringAsFixed(0) ??
                              '--',
                          unit: 'm',
                          label: 'DESNIVEL −',
                        ),
                      ),
                      // Esta era la tarjeta que se desbordaba ("right
                      // overflowed by 1.6 px") con valores de 4 dígitos
                      // como 2587 -- el FittedBox la achica solo lo
                      // necesario para que quepa, sin tocar StatTile.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.height,
                          accentColor: AppColors.accentElevation,
                          value:
                              derived.minAltitude?.toStringAsFixed(0) ?? '--',
                          unit: 'm',
                          label: 'ALT. MÍNIMA',
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.height,
                          accentColor: AppColors.accentElevation,
                          value:
                              derived.maxAltitude?.toStringAsFixed(0) ?? '--',
                          unit: 'm',
                          label: 'ALT. MÁXIMA',
                        ),
                      ),
                      // --- Potencia y cadencia (Fase C) ---
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.electric_bolt,
                          accentColor: AppColors.accentPower,
                          value: activity.avgPower?.toString() ?? '--',
                          unit: 'W',
                          label: 'POT. PROM.',
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.bolt,
                          accentColor: AppColors.accentPower,
                          value: activity.maxPower?.toString() ?? '--',
                          unit: 'W',
                          label: 'POT. MÁX',
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.autorenew,
                          accentColor: AppColors.accentCadence,
                          value: activity.avgCadence?.toString() ?? '--',
                          unit: 'rpm',
                          label: 'CAD. PROM.',
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.loop,
                          accentColor: AppColors.accentCadence,
                          value: activity.maxCadence?.toString() ?? '--',
                          unit: 'rpm',
                          label: 'CAD. MÁX',
                        ),
                      ),
                      // Calorías estimadas -- con potencia se calcula del
                      // trabajo mecánico; si no, modelo MET + desnivel
                      // usando el peso del perfil (ver activity_calories.dart).
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatTile(
                          icon: Icons.local_fire_department,
                          accentColor: AppColors.accentSlope,
                          value: calories?.toString() ?? '--',
                          unit: 'kcal',
                          label: 'CALORÍAS',
                        ),
                      ),
                    ],
                  ),

                  // --- Segmentos completados en esta ruta + crear uno
                  // nuevo -- antes el botón de "crear segmento" vivía
                  // junto a los totales, arriba; ahora vive acá abajo,
                  // junto a la lista de segmentos ya hechos en esta
                  // actividad, para que todo lo relacionado con
                  // segmentos quede junto.
                  if (routePoints.length > 2) ...[
                    const SizedBox(height: 24),
                    _SegmentsInRouteSection(activity: activity),
                  ],

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

/// Sección "Segmentos en esta ruta": qué segmentos (ya creados por el
/// usuario, en cualquier actividad) se completaron durante ESTA
/// actividad puntual, cada uno con el tiempo hecho ese día y un tap
/// que lleva a `SegmentDetailScreen`. El botón para recortar un
/// segmento nuevo desde esta misma ruta vive al final, dentro de la
/// misma sección.
class _SegmentsInRouteSection extends ConsumerWidget {
  final Activity activity;

  const _SegmentsInRouteSection({required this.activity});

  Future<void> _createSegment(BuildContext context) async {
    final createdId = await Navigator.of(context).push<int?>(
      MaterialPageRoute(
        builder: (_) => SegmentCreationScreen(activity: activity),
      ),
    );
    if (createdId != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Segmento creado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(segmentsForActivityProvider(activity.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SEGMENTOS EN ESTA RUTA',
          style: TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        entriesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (error, _) => const Text(
            'No se pudieron cargar los segmentos de esta ruta.',
            style: TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'No completaste ningún segmento activo en esta ruta.',
                  style: TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 13,
                  ),
                ),
              );
            }
            return Column(
              children: entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SegmentEffortTile(entry: entry),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _createSegment(context),
            icon: const Icon(Icons.flag_outlined, color: AppColors.primary),
            label: const Text(
              'Crear segmento desde esta ruta',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _SegmentEffortTile extends StatelessWidget {
  final SegmentActivityEntry entry;

  const _SegmentEffortTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final segment = entry.segment;
    final effort = entry.effort;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SegmentDetailScreen(segmentId: segment.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimaryOnPanel,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatDistanceKm(segment.distanceMeters)} km',
                    style: const TextStyle(
                      color: AppColors.textSecondaryOnPanel,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatEffortDuration(effort.durationSeconds),
              style: const TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondaryOnPanel,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// 'mm:ss' o 'h:mm:ss' si el esfuerzo pasó de una hora.
String _formatEffortDuration(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) return '$hours:$mm:$ss';
  return '$minutes:$ss';
}

/// Mapa real (con tiles) mostrando la ruta completa, encuadrado
/// automáticamente y coloreada tramo a tramo según la pendiente -- el
/// mismo lenguaje visual que el gráfico de altimetría de abajo.
///
/// A diferencia de la versión anterior, acá el trazado se dibuja
/// SUAVIZADO en vez de punto a punto crudo: el GPS trae ruido natural
/// (cada punto se desvía un poco de la trayectoria real), y unir esos
/// puntos crudos con líneas rectas se veía como una cremallera --
/// dentado, poco profesional. El promedio móvil de abajo corrige eso
/// solo para el dibujo (no toca los datos reales de la actividad), y
/// agrupar puntos consecutivos del mismo color en un solo tramo (en
/// vez de un `Polyline` nuevo por cada par de puntos) hace que la
/// línea se vea de un tirón en vez de "piecitas" pegadas.
class _RouteMap extends StatelessWidget {
  final List<RoutePointSnapshot> points;

  const _RouteMap({required this.points});

  @override
  Widget build(BuildContext context) {
    final rawLatLngs =
        points.map((p) => latlng.LatLng(p.latitude, p.longitude)).toList();
    final bounds = LatLngBounds.fromPoints(rawLatLngs);

    final smoothLatLngs = _smoothCoordinates(rawLatLngs);
    final smoothSlopes = _smoothSlopes(points);
    final coloredSegments = _buildColoredSegments(smoothLatLngs, smoothSlopes);

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
        // Halo oscuro debajo de la ruta -- le da profundidad y
        // disimula cualquier unión imperfecta entre tramos de color,
        // el mismo truco visual que usan apps como Strava/Garmin para
        // que el trazado se vea pulido sobre el mapa en vez de plano.
        PolylineLayer(
          polylines: [
            Polyline(
              points: smoothLatLngs,
              strokeWidth: 7,
              color: Colors.black.withValues(alpha: 0.25),
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          ],
        ),
        PolylineLayer(polylines: coloredSegments),
        MarkerLayer(
          markers: [
            Marker(
              point: rawLatLngs.first,
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
              point: rawLatLngs.last,
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

/// Promedio móvil simple sobre lat/lng -- suaviza el ruido típico del
/// GPS para que la polilínea se vea pareja en vez de dentada. Los dos
/// extremos (inicio/fin real de la actividad) se dejan intactos, para
/// no "mover" dónde arrancó o terminó la ruta.
List<latlng.LatLng> _smoothCoordinates(
  List<latlng.LatLng> points, {
  int windowSize = 5,
}) {
  if (points.length < 3) return points;
  final half = windowSize ~/ 2;

  final smoothed = List<latlng.LatLng>.generate(points.length, (i) {
    final start = math.max(0, i - half);
    final end = math.min(points.length - 1, i + half);
    double sumLat = 0;
    double sumLng = 0;
    for (int j = start; j <= end; j++) {
      sumLat += points[j].latitude;
      sumLng += points[j].longitude;
    }
    final count = end - start + 1;
    return latlng.LatLng(sumLat / count, sumLng / count);
  });

  smoothed[0] = points.first;
  smoothed[smoothed.length - 1] = points.last;
  return smoothed;
}

/// Mismo promedio móvil, pero sobre la pendiente -- así el color de la
/// ruta cambia de forma gradual en vez de saltar de un punto al
/// siguiente.
List<double> _smoothSlopes(
  List<RoutePointSnapshot> points, {
  int windowSize = 5,
}) {
  final half = windowSize ~/ 2;
  return List<double>.generate(points.length, (i) {
    final start = math.max(0, i - half);
    final end = math.min(points.length - 1, i + half);
    double sum = 0;
    for (int j = start; j <= end; j++) {
      sum += points[j].slopePercent;
    }
    return sum / (end - start + 1);
  });
}

/// Junta puntos consecutivos que caen en el mismo color en un solo
/// tramo de `Polyline` -- antes se creaba un `Polyline` nuevo por cada
/// PAR de puntos (uno por cada segmento entre punto y punto), lo que
/// se veía como una sucesión de piecitas cortas pegadas entre sí (el
/// efecto "cremallera"). Ahora cada color se dibuja de un tirón, con
/// extremos redondeados, así que las uniones internas no se notan.
List<Polyline> _buildColoredSegments(
  List<latlng.LatLng> smoothLatLngs,
  List<double> smoothSlopes,
) {
  if (smoothLatLngs.length < 2) return const [];

  final result = <Polyline>[];
  var runStart = 0;
  var runColor = slopeToColor(smoothSlopes[0]);

  for (int i = 1; i < smoothLatLngs.length; i++) {
    final color = slopeToColor(smoothSlopes[i]);
    if (color != runColor) {
      result.add(
        Polyline(
          points: smoothLatLngs.sublist(runStart, i + 1),
          strokeWidth: 4.5,
          color: runColor,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
      runStart = i;
      runColor = color;
    }
  }
  result.add(
    Polyline(
      points: smoothLatLngs.sublist(runStart),
      strokeWidth: 4.5,
      color: runColor,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    ),
  );
  return result;
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
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PhotoViewerScreen(
                          photoPaths: widget.photoPaths,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Image.file(
                    File(widget.photoPaths[index]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
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
/// Fila ícono + texto para los ítems del menú de 3 puntos del
/// detalle de actividad.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textPrimaryOnPanel),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
      ],
    );
  }
}
