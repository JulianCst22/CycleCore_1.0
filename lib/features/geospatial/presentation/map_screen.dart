import 'dart:async';

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
import '../../voice/domain/voice_event.dart';
import '../../voice/presentation/voice_providers.dart';
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
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  /// Cuando está en true, el mapa recentra automáticamente la cámara
  /// sobre la posición actual a medida que llegan nuevos puntos GPS.
  bool _followMe = true;

  /// Modo de rotación del mapa, estilo Google Maps/Waze:
  /// - false (por defecto): "norte arriba" -- el mapa queda fijo y es
  ///   el MARCADOR el que rota según el rumbo real (comportamiento
  ///   original de esta pantalla).
  /// - true: "rumbo arriba" -- es el MAPA el que rota para que la
  ///   dirección en la que vas siempre apunte hacia arriba de la
  ///   pantalla, como en navegación.
  /// Se activa/desactiva con el botón de brújula.
  bool _headingUp = false;

  /// Rotación actual del mapa en grados, espejada desde
  /// `mapEventStream` -- se usa para que el ÍCONO de la brújula rote
  /// en sentido contrario y siempre señale el norte real, sin
  /// importar cómo esté girado el mapa en ese momento.
  double _currentMapRotationDegrees = 0;

  late final StreamSubscription<MapEvent> _mapEventSubscription;

  /// Margen derecho compartido entre la barra lateral de datos y el
  /// botón de recentrar, para que ambos queden alineados en la misma
  /// columna vertical. Cambiá este único valor para mover a los dos
  /// juntos más cerca/lejos del borde.
  static const double _sideRightMargin = 16;

  /// Cuántos píxeles subir la barra lateral desde el centro vertical
  /// exacto de la pantalla. 0 = centrada exacto. Un valor positivo la
  /// sube (queda "un poquito más arriba" del centro); negativo la
  /// bajaría. Ajustá solo este número para reposicionarla.
  static const double _lateralBarLiftPixels = 40;

  /// Referencia al panel deslizable -- se usa para poder colapsarlo
  /// desde afuera (p.ej. cuando el cockpit fullscreen pide cerrarse
  /// desde su propia manija de arriba).
  final GlobalKey<CockpitSlidingPanelState> _slidingPanelKey =
      GlobalKey<CockpitSlidingPanelState>();

  /// true cuando el cockpit está en pantalla completa -- se usa para
  /// desvanecer la barra lateral, el botón de recentrar y el de
  /// brújula mientras tanto (ver LateralDataBar): si el mismo dato
  /// que muestra la barra también aparece como campo en la grilla,
  /// ese tile ya adopta el estilo de gauge (ver CockpitGridLayout),
  /// así que mostrar la barra ADEMÁS sería redundante -- se "funden"
  /// en un solo lugar en vez de duplicarse. Los controles del mapa
  /// (recentrar, brújula) tampoco tienen sentido flotando sobre un
  /// panel que tapa el mapa por completo.
  bool _isCockpitExpanded = false;

  final List<HeartRateSample> _heartRateSamples = [];
  final List<PowerSample> _powerSamples = [];
  final List<CadenceSample> _cadenceSamples = [];

  // --- Animación del marcador entre puntos GPS reales ("efecto Waze") ---
  //
  // NOTA: esto es la animación de POSICIÓN del marcador (interpola
  // entre un punto GPS y el siguiente para que no salte de golpe).
  // Sigue igual que antes, e independiente de la rotación del mapa:
  // el marcador se sigue moviendo suave entre puntos GPS reales sin
  // importar si estás en modo "norte arriba" o "rumbo arriba".
  late final AnimationController _markerAnimController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..addListener(_onMarkerAnimationTick);

  static const Duration _minAnimDuration = Duration(milliseconds: 300);
  static const Duration _maxAnimDuration = Duration(seconds: 6);

  Animation<double>? _latAnim;
  Animation<double>? _lngAnim;
  latlng.LatLng? _animatedPosition;

  // --- Animación de la rotación del mapa (transición suave al tocar
  // el botón de brújula, en vez de un salto brusco de golpe). ---
  late final AnimationController _compassAnimController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..addListener(_onCompassAnimationTick);

  Animation<double>? _compassRotationAnim;

  @override
  void initState() {
    super.initState();
    // Escucha todo movimiento/rotación del mapa -- tanto el que
    // provocamos nosotros (seguir posición, animar la brújula) como
    // el que hace el usuario con gestos (arrastrar, pellizcar,
    // girar con dos dedos).
    _mapEventSubscription = _mapController.mapEventStream.listen(_onMapEvent);
  }

  @override
  void dispose() {
    _mapEventSubscription.cancel();
    _markerAnimController.dispose();
    _compassAnimController.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    if (!mounted) return;
    setState(() => _currentMapRotationDegrees = event.camera.rotation);

    // Si el usuario gira el mapa a mano (gesto de dos dedos) mientras
    // estamos en modo "rumbo arriba", soltamos el bloqueo automático
    // -- igual que Google Maps: el gesto manual tiene prioridad y el
    // ícono de brújula vuelve a su estado neutro.
    final isManualRotationGesture =
        event is MapEventRotate && event.source == MapEventSource.onMultiFinger;
    if (isManualRotationGesture && _headingUp) {
      setState(() => _headingUp = false);
    }
  }

  void _onMarkerAnimationTick() {
    if (_latAnim == null || _lngAnim == null) return;
    final next = latlng.LatLng(_latAnim!.value, _lngAnim!.value);
    setState(() => _animatedPosition = next);
    if (_followMe) {
      _mapController.move(next, _mapController.camera.zoom);
    }
  }

  void _onCompassAnimationTick() {
    if (_compassRotationAnim == null) return;
    _mapController.rotate(_compassRotationAnim!.value);
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

  /// Distancia angular más corta entre dos ángulos (en grados),
  /// para que la animación de rotación siempre gire por el camino
  /// más corto (p.ej. de 350° a 10° gira +20°, no -340°).
  double _shortestAngleDelta(double from, double to) {
    double delta = (to - from) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return delta;
  }

  /// Anima el mapa desde su rotación actual hasta [targetDegrees],
  /// por el camino más corto.
  void _animateMapRotationTo(double targetDegrees) {
    final current = _mapController.camera.rotation;
    final delta = _shortestAngleDelta(current, targetDegrees);
    _compassRotationAnim = Tween<double>(
      begin: current,
      end: current + delta,
    ).animate(
      CurvedAnimation(parent: _compassAnimController, curve: Curves.easeOut),
    );
    _compassAnimController
      ..reset()
      ..forward();
  }

  /// Botón de brújula: alterna entre "norte arriba" (mapa fijo, el
  /// marcador rota según el rumbo -- comportamiento original) y
  /// "rumbo arriba" (el mapa rota para que la dirección en la que
  /// vas siempre quede hacia arriba, como en navegación).
  void _toggleHeadingUp() {
    final goingHeadingUp = !_headingUp;
    setState(() => _headingUp = goingHeadingUp);
    if (goingHeadingUp) {
      final bearing = ref.read(routeRecordingProvider).currentBearingDegrees;
      _animateMapRotationTo(-bearing);
    } else {
      _animateMapRotationTo(0);
    }
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

      // En modo "rumbo arriba", cada vez que llega un rumbo nuevo el
      // mapa se re-orienta para que siga apuntando hacia arriba.
      if (_headingUp) {
        _mapController.rotate(-next.currentBearingDegrees);
      }
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

          return Stack(
            children: [
              // --- Mapa. En modo "norte arriba" queda plano y es el
              // marcador el que rota; en modo "rumbo arriba" es el
              // MAPA el que rota (ver _toggleHeadingUp / el listener
              // de arriba) y el marcador, al rotar solidario con el
              // mapa (no usa `Marker.rotate: true`), termina
              // mostrándose siempre apuntando hacia arriba en
              // pantalla sin necesidad de lógica extra. ---
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

              // Fila superior: brújula (izquierda) + píldora de estado
              // + botón de compartir log (derecha).
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: _isCockpitExpanded ? 0.0 : 1.0,
                        child: IgnorePointer(
                          ignoring: _isCockpitExpanded,
                          child: _CompassButton(
                            isHeadingUp: _headingUp,
                            rotationDegrees: _currentMapRotationDegrees,
                            onTap: _toggleHeadingUp,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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

              // --- Panel inferior: cockpit compacto/fullscreen, con
              // transición de desplazamiento real (arrastrar). Ocupa
              // TODO el alto disponible del mapa. ---
              Positioned.fill(
                child: CockpitSlidingPanel(
                  key: _slidingPanelKey,
                  // Se entera cuándo queda completamente expandido o
                  // completamente compacto -- de ahí se desprende si
                  // la barra lateral debe desvanecerse (ver más abajo).
                  onExpandedChanged: (expanded) {
                    if (expanded != _isCockpitExpanded) {
                      setState(() => _isCockpitExpanded = expanded);
                    }
                  },
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
                        // Voz: la actividad acaba de arrancar.
                        ref
                            .read(voiceSettingsProvider.notifier)
                            .speak(VoiceEventType.activityStarted);
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
                        // Voz: se reanudó tras una pausa.
                        ref
                            .read(voiceSettingsProvider.notifier)
                            .speak(VoiceEventType.activityResumed);
                      } else {
                        recordingController.pauseRecording();
                        // Voz: la actividad se puso en pausa.
                        ref
                            .read(voiceSettingsProvider.notifier)
                            .speak(VoiceEventType.activityPaused);
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
                    onSwipeDown: () =>
                        _slidingPanelKey.currentState?.collapse(),
                  ),
                ),
              ),

              // Barra lateral tipo Waze/Maps -- independiente del
              // cockpit compacto/fullscreen en cuanto a SU EXISTENCIA
              // (vive todo el tiempo que se está grabando), pero se
              // desvanece mientras el cockpit está en pantalla
              // completa (isCockpitExpanded) para no duplicar el dato
              // si ese mismo campo aparece como tile en la grilla.
              //
              // Se centra verticalmente en toda la pantalla (top: 0,
              // bottom: 0 + Center) y luego se sube un poco con
              // Transform.translate según _lateralBarLiftPixels -- así
              // queda "un poco arriba del centro" y es fácil de
              // ajustar tocando esa única constante. El right usa el
              // mismo margen que el botón de recentrar para que
              // ambos queden alineados en la misma columna.
              if (recordingState.isRecording)
                Positioned(
                  right: _sideRightMargin,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -_lateralBarLiftPixels),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: LateralDataBar(
                          liveData: liveData,
                          isApproximate:
                              recordingState.isApproximateElevation,
                          isCockpitExpanded: _isCockpitExpanded,
                        ),
                      ),
                    ),
                  ),
                ),

              // Botón flotante "recentrar" -- acción contextual del
              // mapa (mismo patrón que Google Maps/Waze), no una
              // sección a la que navegar. Se desvanece junto con la
              // barra lateral y la brújula cuando el cockpit está en
              // pantalla completa.
              Positioned(
                right: _sideRightMargin,
                bottom: 170 + MediaQuery.of(context).padding.bottom,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: _isCockpitExpanded ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: _isCockpitExpanded,
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

    // Voz: la actividad terminó y ya se generó el resumen.
    ref.read(voiceSettingsProvider.notifier).speak(
          VoiceEventType.activityFinished,
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
/// activo.
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

/// Botón flotante de brújula, estilo Google Maps/Waze:
/// - Un toque alterna entre "norte arriba" (mapa fijo) y "rumbo
///   arriba" (el mapa gira para que la dirección en la que vas
///   siempre apunte hacia arriba).
/// - El ícono rota en sentido contrario a la rotación actual del
///   mapa, así que SIEMPRE señala el norte real -- igual que la
///   brújula de cualquier app de navegación.
/// - Se resalta en Páramo cuando el modo "rumbo arriba" está activo,
///   mismo lenguaje visual que el botón de recentrar.
class _CompassButton extends StatelessWidget {
  final bool isHeadingUp;
  final double rotationDegrees;
  final VoidCallback onTap;

  const _CompassButton({
    required this.isHeadingUp,
    required this.rotationDegrees,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isHeadingUp
          ? CyclecorePalette.ubicacionActiva
          : Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Transform.rotate(
            angle: -rotationDegrees * (3.14159265 / 180),
            child: const Icon(
              Icons.explore,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Píldora de estado -- vive en la misma fila superior que la
/// brújula y el botón de compartir log.
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
