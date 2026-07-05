import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../shared_widgets/stat_tile.dart';
import 'map_providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  /// Cuando está en true, el mapa recentra automáticamente la cámara
  /// sobre la posición actual a medida que llegan nuevos puntos GPS.
  /// El ciclista puede desactivarlo tocando el botón de ubicación si
  /// quiere explorar el mapa manualmente mientras graba.
  bool _followMe = true;

  @override
  Widget build(BuildContext context) {
    final currentPositionAsync = ref.watch(currentPositionProvider);
    final recordingState = ref.watch(routeRecordingProvider);
    final heartRate = ref.watch(heartRateBpmProvider);

    // Solo nos interesa que este provider dispare un rebuild cada
    // segundo para refrescar el tiempo transcurrido; no usamos su valor.
    ref.watch(secondTickerProvider);

    // Efecto secundario: si el usuario tiene activado "seguirme", movemos
    // la cámara del mapa cada vez que llega un nuevo punto GPS.
    ref.listen<RouteRecordingState>(routeRecordingProvider, (previous, next) {
      if (_followMe && next.points.isNotEmpty) {
        final last = next.points.last;
        _mapController.move(
          latlng.LatLng(last.latitude, last.longitude),
          _mapController.camera.zoom,
        );
      }
    });

    final elapsed = recordingState.startedAt != null
        ? DateTime.now().difference(recordingState.startedAt!)
        : Duration.zero;

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      body: currentPositionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo obtener tu ubicación:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimaryOnPanel),
            ),
          ),
        ),
        data: (position) {
          final initialCenter = latlng.LatLng(
            position.latitude,
            position.longitude,
          );

          final recordedLatLngs = recordingState.points
              .map((p) => latlng.LatLng(p.latitude, p.longitude))
              .toList();

          return Stack(
            children: [
              // ---------------------------------------------------
              // Mapa a pantalla completa, de fondo.
              // ---------------------------------------------------
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 16,
                  onPositionChanged: (position, hasGesture) {
                    // Si el usuario arrastra el mapa manualmente,
                    // dejamos de seguirlo automáticamente.
                    if (hasGesture && _followMe) {
                      setState(() => _followMe = false);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.cyclecore_app',
                  ),
                  if (recordedLatLngs.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: recordedLatLngs,
                          strokeWidth: 5,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: recordedLatLngs.isNotEmpty
                            ? recordedLatLngs.last
                            : initialCenter,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          // Rotamos el ícono según el bearing (rumbo) real
                          // reportado por el GPS, para que apunte hacia
                          // donde el ciclista se está moviendo en vez de
                          // quedar fijo hacia arriba.
                          child: Transform.rotate(
                            angle: recordingState.currentBearingDegrees *
                                (3.14159265 / 180),
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ---------------------------------------------------
              // Barra superior flotante: título + indicador de grabación.
              // ---------------------------------------------------
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _FloatingPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (recordingState.isRecording) ...[
                              const _PulsingDot(),
                              const SizedBox(width: 8),
                              const Text(
                                'GRABANDO',
                                style: TextStyle(
                                  color: AppColors.textPrimaryOnPanel,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ] else
                              const Text(
                                'CycleCore',
                                style: TextStyle(
                                  color: AppColors.textPrimaryOnPanel,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _FloatingPill(
                        onTap: () {
                          setState(() => _followMe = !_followMe);
                          if (_followMe) {
                            _mapController.move(
                              recordedLatLngs.isNotEmpty
                                  ? recordedLatLngs.last
                                  : initialCenter,
                              _mapController.camera.zoom,
                            );
                          }
                        },
                        child: Icon(
                          _followMe
                              ? Icons.my_location
                              : Icons.location_searching,
                          size: 20,
                          color: _followMe
                              ? AppColors.primary
                              : AppColors.textSecondaryOnPanel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------------------------------------------------
              // Panel inferior tipo "cockpit" con todos los datos.
              // ---------------------------------------------------
              Align(
                alignment: Alignment.bottomCenter,
                child: _DataPanel(
                  heartRate: heartRate,
                  elapsed: elapsed,
                  distanceMeters: recordingState.cumulativeDistanceMeters,
                  currentSpeedKmh: recordingState.currentSpeedKmh,
                  avgSpeedKmh: recordingState.averageSpeedKmh(),
                  elevationGainMeters: recordingState.elevationGainMeters,
                  slopePercent: recordingState.currentSlopePercent,
                  isRecording: recordingState.isRecording,
                  onRecordPressed: () async {
                    final controller = ref.read(
                      routeRecordingProvider.notifier,
                    );
                    if (recordingState.isRecording) {
                      final pointsCount = recordingState.points.length;
                      await controller.stopRecording();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Ruta grabada con $pointsCount puntos.',
                            ),
                          ),
                        );
                      }
                    } else {
                      try {
                        await controller.startRecording();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Panel oscuro con los datos del recorrido, anclado al fondo de la
/// pantalla, con el botón de grabar/detener superpuesto en su borde
/// superior (estilo cockpit de ciclocomputador).
class _DataPanel extends StatelessWidget {
  final int? heartRate;
  final Duration elapsed;
  final double distanceMeters;
  final double currentSpeedKmh;
  final double avgSpeedKmh;
  final double elevationGainMeters;
  final double slopePercent;
  final bool isRecording;
  final VoidCallback onRecordPressed;

  const _DataPanel({
    required this.heartRate,
    required this.elapsed,
    required this.distanceMeters,
    required this.currentSpeedKmh,
    required this.avgSpeedKmh,
    required this.elevationGainMeters,
    required this.slopePercent,
    required this.isRecording,
    required this.onRecordPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
          decoration: const BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Tile "hero" de frecuencia cardíaca ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentHeartRate.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: AppColors.accentHeartRate,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        heartRate?.toString() ?? '--',
                        style: const TextStyle(
                          color: AppColors.textPrimaryOnPanel,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'bpm',
                        style: TextStyle(
                          color: AppColors.textSecondaryOnPanel,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        heartRate == null
                            ? 'Sin sensor conectado'
                            : 'Frecuencia cardíaca',
                        style: const TextStyle(
                          color: AppColors.textSecondaryOnPanel,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // --- Grid de métricas derivadas del GPS ---
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.15,
                  children: [
                    StatTile(
                      icon: Icons.timer_outlined,
                      accentColor: AppColors.accentTime,
                      value: formatDuration(elapsed),
                      unit: '',
                      label: 'TIEMPO',
                    ),
                    StatTile(
                      icon: Icons.straighten,
                      accentColor: AppColors.accentDistance,
                      value: formatDistanceKm(distanceMeters),
                      unit: 'km',
                      label: 'DISTANCIA',
                    ),
                    StatTile(
                      icon: Icons.speed,
                      accentColor: AppColors.accentSpeed,
                      value: formatSpeedKmh(currentSpeedKmh),
                      unit: 'km/h',
                      label: 'VELOCIDAD',
                    ),
                    StatTile(
                      icon: Icons.bar_chart,
                      accentColor: AppColors.accentSpeed,
                      value: formatSpeedKmh(avgSpeedKmh),
                      unit: 'km/h',
                      label: 'PROMEDIO',
                    ),
                    StatTile(
                      icon: Icons.terrain,
                      accentColor: AppColors.accentElevation,
                      value: elevationGainMeters.toStringAsFixed(0),
                      unit: 'm',
                      label: 'DESNIVEL',
                    ),
                    StatTile(
                      icon: Icons.trending_up,
                      accentColor: AppColors.accentSlope,
                      value: formatSlopePercent(slopePercent),
                      unit: '%',
                      label: 'PENDIENTE',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // --- Botón de grabar/detener, superpuesto sobre el borde ---
        Positioned(
          top: -28,
          child: GestureDetector(
            onTap: onRecordPressed,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording
                    ? AppColors.recordButtonActive
                    : AppColors.recordButtonInactive,
                border: Border.all(color: AppColors.panelBackground, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.stop : Icons.fiber_manual_record,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Contenedor "pastilla" translúcido usado en la barra superior flotante.
class _FloatingPill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _FloatingPill({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: child,
        ),
      ),
    );
  }
}

/// Punto rojo parpadeante que indica que hay una grabación en curso.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.25).animate(_controller),
      child: const CircleAvatar(
        radius: 5,
        backgroundColor: AppColors.recordButtonActive,
      ),
    );
  }
}
