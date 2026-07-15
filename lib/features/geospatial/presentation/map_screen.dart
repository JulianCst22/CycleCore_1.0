import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/heart_rate_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../shared_widgets/stat_tile.dart';
import '../../activities/domain/activity_summary.dart';
import '../../activities/presentation/activities_list_screen.dart';
import '../../elevation/presentation/elevation_download_dialog.dart';
import '../../elevation/presentation/elevation_providers.dart';
import '../../activities/presentation/save_activity_screen.dart';
import '../../profile/presentation/onboarding_screen.dart';
import '../../sensors/presentation/sensors_screen.dart';
import 'map_providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  /// Cuando está en true, el mapa recentra automáticamente la cámara
  /// sobre la posición actual a medida que llegan nuevos puntos GPS.
  bool _followMe = true;

  final List<HeartRateSample> _heartRateSamples = [];

  // --- Animación del marcador entre puntos GPS reales ("efecto Waze") ---
  //
  // Por qué: el GPS real solo entrega un punto nuevo cada ~2 segundos
  // (ver `intervalDuration` en location_service.dart). Sin animación,
  // el marcador salta de golpe de un punto al siguiente -- a más de
  // 60 km/h esos saltos son de decenas de metros y se ven "a trompicones".
  // Waze/Google Maps no reciben el GPS más rápido; interpolan
  // visualmente el marcador entre una posición y la siguiente durante
  // ese mismo intervalo. Aquí se hace lo mismo con un AnimationController.
  late final AnimationController _markerAnimController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2), // valor inicial, se recalcula por punto
  )..addListener(_onMarkerAnimationTick);

  /// Límites de seguridad para la duración calculada: por debajo de
  /// 300ms la animación sería imperceptible (y el listener dispararía
  /// más rápido de lo necesario); por encima de 6s (p.ej. tras perder
  /// señal GPS un rato) animar el salto completo se vería peor que un
  /// corte directo -- ahí se prefiere el salto instantáneo.
  static const Duration _minAnimDuration = Duration(milliseconds: 300);
  static const Duration _maxAnimDuration = Duration(seconds: 6);

  Animation<double>? _latAnim;
  Animation<double>? _lngAnim;
  latlng.LatLng? _animatedPosition;

  @override
  void dispose() {
    _markerAnimController.dispose();
    super.dispose();
  }

  void _onMarkerAnimationTick() {
    if (_latAnim == null || _lngAnim == null) return;
    final next = latlng.LatLng(_latAnim!.value, _lngAnim!.value);
    setState(() => _animatedPosition = next);
    if (_followMe) {
      _mapController.move(next, _mapController.camera.zoom);
    }
  }

  /// Arranca (o retoma) la animación del marcador hacia [target], desde
  /// la posición animada actual -- así si llega un punto nuevo antes de
  /// que termine la animación anterior, no hay salto brusco, se
  /// re-interpola desde donde iba. [duration] debe ser el tiempo real
  /// transcurrido entre el punto GPS anterior y este (medido por el
  /// llamador con los timestamps reales) -- el GPS no entrega
  /// exactamente cada `intervalDuration` configurado (varía por modo
  /// doze, pérdida de señal, etc.), así que asumir un valor fijo
  /// desincroniza la animación tarde o temprano.
  void _animateMarkerTo(latlng.LatLng target, {Duration? duration}) {
    final start = _animatedPosition ?? target;
    _latAnim = Tween<double>(begin: start.latitude, end: target.latitude)
        .animate(
      CurvedAnimation(parent: _markerAnimController, curve: Curves.linear),
    );
    _lngAnim = Tween<double>(begin: start.longitude, end: target.longitude)
        .animate(
      CurvedAnimation(parent: _markerAnimController, curve: Curves.linear),
    );
    if (duration != null) {
      var clamped = duration;
      if (clamped < _minAnimDuration) clamped = _minAnimDuration;
      if (clamped > _maxAnimDuration) clamped = _maxAnimDuration;
      _markerAnimController.duration = clamped;
    }
    _markerAnimController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final currentPositionAsync = ref.watch(currentPositionProvider);
    final recordingState = ref.watch(routeRecordingProvider);
    final recordingController = ref.read(routeRecordingProvider.notifier);
    final heartRate = ref.watch(heartRateBpmProvider);

    ref.watch(secondTickerProvider);

    // Efecto secundario: cada vez que llega un punto GPS nuevo, se
    // anima el marcador hacia él (y la cámara lo sigue, si _followMe
    // está activo). La duración de la animación se mide con el
    // timestamp real entre el punto anterior y este -- no se asume un
    // intervalo fijo, porque el GPS real no entrega exactamente cada
    // `intervalDuration` configurado.
    ref.listen<RouteRecordingState>(routeRecordingProvider, (previous, next) {
      if (next.points.isEmpty) return;
      final last = next.points.last;

      Duration? gap;
      if (previous != null && previous.points.isNotEmpty) {
        gap = last.timestamp.difference(previous.points.last.timestamp);
      }

      _animateMarkerTo(
        latlng.LatLng(last.latitude, last.longitude),
        duration: gap,
      );
    });

    ref.listen<int?>(heartRateBpmProvider, (previous, next) {
      final current = ref.read(routeRecordingProvider);
      if (current.isRecording && !current.isPaused && next != null) {
        _heartRateSamples.add(
          HeartRateSample(timestamp: DateTime.now(), bpm: next),
        );
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

          final markerPosition = _animatedPosition ??
              (recordedLatLngs.isNotEmpty
                  ? recordedLatLngs.last
                  : initialCenter);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 16,
                  onPositionChanged: (position, hasGesture) {
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
                        point: markerPosition,
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
                            if (recordingState.isRecording &&
                                recordingState.isApproximateElevation) ...[
                              const SizedBox(width: 8),
                              const Tooltip(
                                message:
                                    'Sin DEM confiable para esta zona (o '
                                    'posible puente/viaducto): la pendiente '
                                    'prioriza GPS/barómetro, menos precisa.',
                                child: Icon(
                                  Icons.signal_cellular_alt_outlined,
                                  size: 14,
                                  color: AppColors.textSecondaryOnPanel,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!recordingState.isRecording &&
                              recordingController.debugLogFile != null) ...[
                            _FloatingPill(
                              onTap: () {
                                final file = recordingController.debugLogFile!;
                                Share.shareXFiles(
                                  [XFile(file.path)],
                                    text: 'Log CycleCore',
                                
                                );
                              },
                              child: const Icon(
                                Icons.bug_report_outlined,
                                size: 20,
                                color: AppColors.textPrimaryOnPanel,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          _FloatingPill(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ActivitiesListScreen(),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.list_alt,
                              size: 20,
                              color: AppColors.textPrimaryOnPanel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FloatingPill(
                            onTap: () {
                              setState(() => _followMe = !_followMe);
                              if (_followMe) {
                                _mapController.move(
                                  markerPosition,
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
                  // Se usa la pendiente ya formateada (bandas +
                  // histéresis, estilo Garmin) para el panel en vivo --
                  // ver SlopePresentationFormatter. La pendiente "cruda
                  // de confianza" (currentSlopePercent) sigue siendo la
                  // que se guarda y se grafica.
                  slopePercent: recordingState.displaySlopePercent,
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
                      final missingTiles = await ref.read(
                        missingElevationTilesProvider.future,
                      );
                      if (missingTiles.isNotEmpty && context.mounted) {
                        await showElevationDownloadDialog(
                          context,
                          missingTiles,
                        );
                      }
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

    final summary = await controller.finishRecording(
      heartRateSamples: List.of(_heartRateSamples),
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