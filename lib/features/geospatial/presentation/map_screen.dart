import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/heart_rate_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/cyclecore_palette.dart';
import '../../../shared_widgets/stat_tile.dart';
import '../../activities/domain/activity_summary.dart';
import '../../elevation/presentation/elevation_download_dialog.dart';
import '../../elevation/presentation/elevation_providers.dart';
import '../../activities/presentation/save_activity_screen.dart';
import '../../sensors/presentation/cadence_providers.dart';
import '../../sensors/presentation/power_providers.dart';
import '../data/cockpit_layout_repository.dart';
import '../domain/cockpit_field.dart';
import 'cockpit_field_ui.dart';
import 'cockpit_fullscreen_view.dart';
import 'cockpit_layout_providers.dart';
import 'cockpit_sliding_panel.dart';
import 'gps_status_widgets.dart';
import 'map_providers.dart';
import 'lateral_data_bar.dart';

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

  /// Referencia al panel deslizable -- se usa para poder colapsarlo
  /// desde afuera (p.ej. cuando el cockpit fullscreen pide cerrarse
  /// desde su propia manija de arriba).
  final GlobalKey<CockpitSlidingPanelState> _slidingPanelKey =
      GlobalKey<CockpitSlidingPanelState>();

  final List<HeartRateSample> _heartRateSamples = [];
  final List<PowerSample> _powerSamples = [];
  final List<CadenceSample> _cadenceSamples = [];

  // --- Animación del marcador entre puntos GPS reales ("efecto Waze") ---
  //
  // NOTA: esto es la animación de POSICIÓN del marcador (interpola
  // entre un punto GPS y el siguiente para que no salte de golpe), y
  // sigue igual que antes. Lo que SÍ se quitó de esta pantalla es la
  // rotación/inclinación del MAPA completo tipo navegación GPS -- se
  // probó y no se sintió bien, así que el mapa volvió a ser plano y
  // con norte fijo; el marcador vuelve a rotar según el rumbo real,
  // como al principio.
  late final AnimationController _markerAnimController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..addListener(_onMarkerAnimationTick);

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

  T? _maxOrNull<T extends num>(Iterable<T> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final currentPositionAsync = ref.watch(currentPositionProvider);
    final recordingState = ref.watch(routeRecordingProvider);
    final recordingController = ref.read(routeRecordingProvider.notifier);
    final heartRate = ref.watch(heartRateBpmProvider);
    final powerWatts = ref.watch(powerWattsProvider);
    final cadenceRpm = ref.watch(cadenceRpmProvider);
    final cockpitTiles =
        ref.watch(cockpitLayoutProvider).valueOrNull ??
        CockpitLayoutRepository.defaultTiles;

    ref.watch(secondTickerProvider);

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

    ref.listen<int?>(powerWattsProvider, (previous, next) {
      final current = ref.read(routeRecordingProvider);
      if (current.isRecording && !current.isPaused && next != null) {
        _powerSamples.add(
          PowerSample(timestamp: DateTime.now(), watts: next),
        );
      }
    });

    ref.listen<double?>(cadenceRpmProvider, (previous, next) {
      final current = ref.read(routeRecordingProvider);
      if (current.isRecording && !current.isPaused && next != null) {
        _cadenceSamples.add(
          CadenceSample(timestamp: DateTime.now(), rpm: next),
        );
      }
    });

    final elapsed = recordingState.startedAt != null
        ? recordingController.elapsedDuration()
        : Duration.zero;

    final liveData = CockpitLiveData(
      elapsed: elapsed,
      distanceMeters: recordingState.cumulativeDistanceMeters,
      currentSpeedKmh: recordingState.currentSpeedKmh,
      avgSpeedKmh: recordingState.averageSpeedKmhOver(elapsed),
      maxSpeedKmh: recordingState.maxSpeedKmh,
      elevationGainMeters: recordingState.elevationGainMeters,
      slopePercent: recordingState.displaySlopePercent,
      heartRateBpm: heartRate,
      powerWatts: powerWatts,
      maxPowerWattsSoFar: _maxOrNull(_powerSamples.map((s) => s.watts)),
      cadenceRpm: cadenceRpm,
      maxCadenceRpmSoFar: _maxOrNull(_cadenceSamples.map((s) => s.rpm)),
    );

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

          // Antes esto era un Column con [Expanded(Stack), NavBar] --
          // la nav bar ya no vive acá (la renderiza AppShell una sola
          // vez para toda la app), así que el Stack ocupa directamente
          // toda el área que le da el Scaffold de esta pantalla.
          return Stack(
            children: [
              // --- Mapa: plano, norte fijo -- como estaba
              // originalmente. El marcador rota según el rumbo
              // real (sin depender de que el mapa gire). ---
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
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
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

              // Overlay de "buscando señal GPS".
              if (recordingState.isAcquiringGps)
                const Positioned.fill(child: GpsAcquiringOverlay()),

              // Único elemento flotante que queda sobre el mapa aparte
              // del cockpit: el estado de grabación.
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _StatusPill(
                        isRecording: recordingState.isRecording,
                        isPaused: recordingState.isPaused,
                        isApproximate:
                            recordingState.isApproximateElevation,
                      ),
                      const Spacer(),
                      if (!recordingState.isRecording &&
                          recordingController.debugLogFile != null)
                        _ShareLogButton(
                          onTap: () {
                            final file =
                                recordingController.debugLogFile!;
                            Share.shareXFiles(
                              [XFile(file.path)],
                              text: 'Log CycleCore',
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // --- Panel inferior: cockpit compacto/fullscreen,
              // con transición de desplazamiento real
              // (arrastrar). Ocupa TODO el alto disponible del
              // mapa (antes tenía un tope fijo del 62%, por eso
              // el cockpit fullscreen no llegaba a cubrir toda
              // la pantalla). ---
              Positioned.fill(
                child: CockpitSlidingPanel(
                  key: _slidingPanelKey,
                  compact: _CompactCockpitPanel(
                    liveData: liveData,
                    isRecording: recordingState.isRecording,
                    isPaused: recordingState.isPaused,
                    onStartPressed: () async {
                      _heartRateSamples.clear();
                      _powerSamples.clear();
                      _cadenceSamples.clear();
                      try {
                        final missingTiles = await ref.read(
                          missingElevationTilesProvider.future,
                        );
                        if (missingTiles.isNotEmpty &&
                            context.mounted) {
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
                  expanded: CockpitFullscreenView(
                    tiles: cockpitTiles,
                    liveData: liveData,
                    // Antes esto quedaba vacío -- era exactamente
                    // el bug de "no me cierra, queda trabado".
                    // Ahora sí colapsa el panel de verdad.
                    onSwipeDown: () =>
                        _slidingPanelKey.currentState?.collapse(),
                  ),
                ),
              ),

              // Barra lateral tipo Waze/Maps -- independiente del
              // cockpit compacto/fullscreen (sigue visible sin
              // importar cuál de los dos esté abierto). Muestra
              // el dato que el usuario haya elegido (pendiente
              // por defecto); tocar el ícono de arriba abre el
              // selector.
              if (recordingState.isRecording)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: LateralDataBar(
                        liveData: liveData,
                        isApproximate:
                            recordingState.isApproximateElevation,
                      ),
                    ),
                  ),
                ),

              // Botón flotante "recentrar" -- reemplaza al ítem
              // "Ubicación" que antes vivía en la nav bar. Ya no es
              // una sección de la app a la que navegar, es una
              // acción contextual del mapa (mismo patrón que el botón
              // de recentrar de Google Maps/Waze). Se ubica arriba
              // del panel compacto para no quedar tapado por él.
              Positioned(
                right: 16,
                bottom: 170 + MediaQuery.of(context).padding.bottom,
                child: _RecenterButton(
                  isFollowingMe: _followMe,
                  onTap: () {
                    setState(() => _followMe = !_followMe);
                    if (_followMe) {
                      _mapController.move(
                        markerPosition,
                        _mapController.camera.zoom,
                      );
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
      powerSamples: List.of(_powerSamples),
      cadenceSamples: List.of(_cadenceSamples),
    );

    _heartRateSamples.clear();
    _powerSamples.clear();
    _cadenceSamples.clear();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaveActivityScreen(summary: summary),
      ),
    );
  }
}

/// Botón flotante circular para recentrar el mapa sobre la posición
/// actual. Se resalta en Páramo cuando el seguimiento automático está
/// activo -- mismo criterio de color que usaba el ítem "Ubicación" de
/// la nav bar antigua.
class _RecenterButton extends StatelessWidget {
  final bool isFollowingMe;
  final VoidCallback onTap;

  const _RecenterButton({required this.isFollowingMe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isFollowingMe
          ? CyclecorePalette.ubicacionActiva   
          : Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(
            isFollowingMe ? Icons.my_location : Icons.location_searching,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Píldora de estado -- lo único que queda flotando sobre el mapa
/// además del cockpit y el botón de recentrar.
class _StatusPill extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final bool isApproximate;

  const _StatusPill({
    required this.isRecording,
    required this.isPaused,
    required this.isApproximate,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRecording && !isPaused) ...[
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
            ] else if (isRecording && isPaused) ...[
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
            if (isRecording && isApproximate) ...[
              const SizedBox(width: 2),
              const ApproximateElevationBadge(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareLogButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareLogButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Icon(
            Icons.bug_report_outlined,
            size: 20,
            color: AppColors.textPrimaryOnPanel,
          ),
        ),
      ),
    );
  }
}

/// Contenido "compacto": panel de 3 campos fijos + botón(es) de
/// acción. Ya NO tiene su propio `GestureDetector` de swipe -- el
/// arrastre lo maneja `CockpitSlidingPanel` por encima.
class _CompactCockpitPanel extends StatelessWidget {
  final CockpitLiveData liveData;
  final bool isRecording;
  final bool isPaused;
  final VoidCallback onStartPressed;
  final VoidCallback onPauseResumePressed;
  final VoidCallback onFinishPressed;

  const _CompactCockpitPanel({
    required this.liveData,
    required this.isRecording,
    required this.isPaused,
    required this.onStartPressed,
    required this.onPauseResumePressed,
    required this.onFinishPressed,
  });

  static const _fields = [
    CockpitField.velocidad,
    CockpitField.tiempo,
    CockpitField.distancia,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
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
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: _fields.map((f) {
                        final d = f.display(liveData);
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: StatTile(
                              icon: d.icon,
                              accentColor: d.color,
                              value: d.value,
                              unit: d.unit,
                              label: d.label,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_up,
                          size: 14,
                          color: AppColors.textSecondaryOnPanel.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'Desliza para más datos',
                          style: TextStyle(
                            color: AppColors.textSecondaryOnPanel,
                            fontSize: 10.5,
                          ),
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
