import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/providers/heart_rate_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../shared_widgets/stat_tile.dart';
import '../../activities/presentation/save_activity_screen.dart';
import '../../profile/presentation/onboarding_screen.dart';
import '../../sensors/presentation/sensors_screen.dart';
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

  /// Muestras de FC tomadas mientras la grabación está activa y sin
  /// pausar, solo para calcular el promedio/máximo de la sesión al
  /// terminar. No se persiste esta lista en ningún lado; es transitoria.
  final List<int> _heartRateSamples = [];

  @override
  Widget build(BuildContext context) {
    final currentPositionAsync = ref.watch(currentPositionProvider);
    final recordingState = ref.watch(routeRecordingProvider);
    final recordingController = ref.read(routeRecordingProvider.notifier);
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

    // Vamos acumulando muestras de FC mientras se graba activamente
    // (no en pausa), para poder calcular promedio/máximo al finalizar.
    ref.listen<int?>(heartRateBpmProvider, (previous, next) {
      final current = ref.read(routeRecordingProvider);
      if (current.isRecording && !current.isPaused && next != null) {
        _heartRateSamples.add(next);
      }
    });

    final elapsed = recordingState.startedAt != null
        ? recordingController.elapsedDuration()
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
              // Barra superior flotante: título + acciones (seguir/perfil).
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
                            if (recordingState.isRecording &&
                                !recordingState.isPaused) ...[
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
                            ] else if (recordingState.isRecording &&
                                recordingState.isPaused) ...[
                              const Icon(
                                Icons.pause_circle_filled,
                                color: AppColors.accentSlope,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'EN PAUSA',
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          const SizedBox(width: 8),
                          _FloatingPill(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const OnboardingScreen(
                                    isEditing: true,
                                  ),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.person_outline,
                              size: 20,
                              color: AppColors.textPrimaryOnPanel,
                            ),
                          ),
                        ],
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
                  avgSpeedKmh:
                      recordingState.averageSpeedKmhOver(elapsed),
                  elevationGainMeters: recordingState.elevationGainMeters,
                  slopePercent: recordingState.currentSlopePercent,
                  isRecording: recordingState.isRecording,
                  isPaused: recordingState.isPaused,
                  onHeartRateTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SensorsScreen(),
                      ),
                    );
                  },
                  onStartPressed: () async {
                    _heartRateSamples.clear();
                    try {
                      await recordingController.startRecording();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  onPauseResumePressed: () {
                    if (recordingState.isPaused) {
                      recordingController.resumeRecording();
                    } else {
                      recordingController.pauseRecording();
                    }
                  },
                  onFinishPressed: () => _confirmAndFinish(
                    context,
                    recordingController,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmAndFinish(
    BuildContext context,
    RouteRecordingController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panelBackground,
        title: const Text(
          '¿Terminar actividad?',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        content: const Text(
          'Vamos a mostrarte el resumen para que le pongas título y la '
          'guardes.',
          style: TextStyle(color: AppColors.textSecondaryOnPanel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Seguir grabando',
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Terminar',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    int? avgHeartRate;
    int? maxHeartRate;
    if (_heartRateSamples.isNotEmpty) {
      avgHeartRate =
          (_heartRateSamples.reduce((a, b) => a + b) /
                  _heartRateSamples.length)
              .round();
      maxHeartRate = _heartRateSamples.reduce((a, b) => a > b ? a : b);
    }

    final summary = await controller.finishRecording(
      avgHeartRate: avgHeartRate,
      maxHeartRate: maxHeartRate,
    );

    _heartRateSamples.clear();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaveActivityScreen(summary: summary),
      ),
    );
  }
}

/// Panel oscuro con los datos del recorrido, anclado al fondo de la
/// pantalla, con los botones de pausar/reanudar y terminar superpuestos
/// en su borde superior (estilo cockpit de ciclocomputador).
class _DataPanel extends StatelessWidget {
  final int? heartRate;
  final Duration elapsed;
  final double distanceMeters;
  final double currentSpeedKmh;
  final double avgSpeedKmh;
  final double elevationGainMeters;
  final double slopePercent;
  final bool isRecording;
  final bool isPaused;
  final VoidCallback onStartPressed;
  final VoidCallback onPauseResumePressed;
  final VoidCallback onFinishPressed;
  final VoidCallback onHeartRateTap;

  const _DataPanel({
    required this.heartRate,
    required this.elapsed,
    required this.distanceMeters,
    required this.currentSpeedKmh,
    required this.avgSpeedKmh,
    required this.elevationGainMeters,
    required this.slopePercent,
    required this.isRecording,
    required this.isPaused,
    required this.onStartPressed,
    required this.onPauseResumePressed,
    required this.onFinishPressed,
    required this.onHeartRateTap,
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
                // --- Tile "hero" de frecuencia cardíaca (táctil) ---
                InkWell(
                  onTap: onHeartRateTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color:
                          AppColors.accentHeartRate.withValues(alpha: 0.12),
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
                              ? 'Sin sensor · toca para conectar'
                              : 'Frecuencia cardíaca',
                          style: const TextStyle(
                            color: AppColors.textSecondaryOnPanel,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondaryOnPanel,
                          size: 18,
                        ),
                      ],
                    ),
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

        // --- Botones superpuestos sobre el borde del panel ---
        Positioned(
          top: -28,
          child: isRecording
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircleActionButton(
                      icon: isPaused ? Icons.play_arrow : Icons.pause,
                      backgroundColor: AppColors.accentSlope,
                      onTap: onPauseResumePressed,
                      size: 56,
                    ),
                    const SizedBox(width: 16),
                    _CircleActionButton(
                      icon: Icons.flag,
                      backgroundColor: AppColors.recordButtonActive,
                      onTap: onFinishPressed,
                      size: 56,
                    ),
                  ],
                )
              : _CircleActionButton(
                  icon: Icons.fiber_manual_record,
                  backgroundColor: AppColors.recordButtonInactive,
                  onTap: onStartPressed,
                  size: 64,
                ),
        ),
      ],
    );
  }
}

/// Botón circular reutilizable para las acciones sobre el borde del panel
/// (grabar, pausar/reanudar, terminar).
class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;
  final double size;

  const _CircleActionButton({
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: AppColors.panelBackground, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.42),
      ),
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