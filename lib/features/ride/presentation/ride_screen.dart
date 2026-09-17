import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:share_plus/share_plus.dart';

import 'package:core_database/core_database.dart';
import '../../sensors/sensors.dart';
import 'package:core_ui/core_ui.dart';
import 'widgets/map_controls_cluster.dart';
import 'widgets/stat_tile.dart';
import '../../recording/recording.dart';
import '../../elevation/elevation.dart';
import '../../activities/activities.dart';
import '../../navigation/navigation.dart';
import '../../segments/segments.dart';
import '../../voice/voice.dart';
import '../../cockpit/cockpit.dart';
import 'package:core_platform/core_platform.dart';

class RideScreen extends ConsumerStatefulWidget {
  const RideScreen({super.key});

  @override
  ConsumerState<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends ConsumerState<RideScreen>
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

  /// true mientras el diálogo de recuperación está abierto -- evita
  /// mostrarlo dos veces (al abrir la pantalla y al tocar "grabar").
  bool _isOfferingRecovery = false;

  @override
  void initState() {
    super.initState();
    // Escucha todo movimiento/rotación del mapa -- tanto el que
    // provocamos nosotros (seguir posición, animar la brújula) como
    // el que hace el usuario con gestos (arrastrar, pellizcar,
    // girar con dos dedos).
    _mapEventSubscription = _mapController.mapEventStream.listen(_onMapEvent);

    // Si la app se cerró a mitad de una grabación, lo primero al volver
    // es ofrecer recuperarla (ver RecordingJournal).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _offerRecordingRecovery(),
    );
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
    _compassRotationAnim = Tween<double>(begin: current, end: current + delta)
        .animate(
          CurvedAnimation(
            parent: _compassAnimController,
            curve: Curves.easeOut,
          ),
        );
    _compassAnimController
      ..reset()
      ..forward();
  }

  /// Alterna entre "norte arriba" (mapa fijo) y "rumbo arriba" (el mapa
  /// rota para que la dirección en la que vas quede hacia arriba, como
  /// en navegación). Lo dispara el control unificado de mapa cuando ya
  /// estás siguiendo tu ubicación.
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

  /// El control unificado (estado `free`): recentra y empieza a seguir,
  /// conservando el modo de orientación actual.
  void _recenterAndFollow(latlng.LatLng markerPosition) {
    setState(() => _followMe = true);
    _mapController.move(markerPosition, _mapController.camera.zoom);
    if (_headingUp) {
      _mapController.rotate(
        -ref.read(routeRecordingProvider).currentBearingDegrees,
      );
    }
  }

  /// Long-press del control unificado: reset rápido a "norte arriba +
  /// siguiendo".
  void _resetNorthAndFollow(latlng.LatLng markerPosition) {
    setState(() {
      _followMe = true;
      _headingUp = false;
    });
    _animateMapRotationTo(0);
    _mapController.move(markerPosition, _mapController.camera.zoom);
  }

  MapFollowMode get _followMode => !_followMe
      ? MapFollowMode.free
      : (_headingUp
            ? MapFollowMode.followHeadingUp
            : MapFollowMode.followNorthUp);

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

    // --- Navegación (Waze) ---
    final hasNavigationData =
        ref.watch(hasNavigationDataProvider).valueOrNull ?? false;
    final activeNavigationRoute = ref.watch(activeNavigationRouteProvider);
    final activeNavigationTarget = ref.watch(activeNavigationTargetProvider);
    final routePreview = ref.watch(routePreviewProvider);
    final savedPlaces = ref.watch(savedPlacesProvider).valueOrNull ?? const [];

    // Coordenada del destino a marcar con montañita, si vamos hacia un
    // alto (en preview o ya navegando).
    final latlng.LatLng? climbDestination = routePreview != null
        ? (routePreview.isClimb
              ? latlng.LatLng(routePreview.target.lat, routePreview.target.lng)
              : null)
        : (activeNavigationTarget != null &&
                  looksLikeClimb(activeNavigationTarget.name)
              ? latlng.LatLng(
                  activeNavigationTarget.lat,
                  activeNavigationTarget.lng,
                )
              : null);

    // --- Segmento en vivo (Fase D) ---
    final segmentLive = ref.watch(segmentDetectionProvider).active;

    ref.watch(secondTickerProvider);

    // Al entrar a un segmento el panel se expande solo para mostrar la
    // pantalla de segmento; al salir, vuelve a colapsarse. Si el usuario
    // lo mueve a mano mientras tanto, no se le pelea (solo reacciona a
    // la transición entrar<->salir).
    ref.listen<SegmentLiveState>(segmentDetectionProvider, (previous, next) {
      final was = previous?.active != null;
      final now = next.active != null;
      if (!was && now) {
        _slidingPanelKey.currentState?.expand();
      } else if (was && !now) {
        _slidingPanelKey.currentState?.collapse();
      }
    });

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

    // Las muestras de sensores (FC/potencia/cadencia) se acumulan en
    // `rideSensorLogProvider` -- se `watch`ea acá para que su `ref.listen`
    // interno esté vivo desde el primer frame y para refrescar
    // max potencia/cadencia en el cockpit.
    final sensorLog = ref.watch(rideSensorLogProvider);

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
      altitudeMeters: recordingState.points.isEmpty
          ? null
          : recordingState.points.last.altitude,
      heartRateBpm: heartRate,
      powerWatts: powerWatts,
      maxPowerWattsSoFar: sensorLog.maxPowerSoFar,
      cadenceRpm: cadenceRpm,
      maxCadenceRpmSoFar: sensorLog.maxCadenceSoFar,
    );

    return NavigationVoiceBridge(
      child: Scaffold(
        backgroundColor: CcColors.bg,
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

            final markerPosition =
                _animatedPosition ??
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
                    // --- Segmento en vivo: su trazado en turquesa
                    // ("vas aquí") por encima del recorrido grabado. ---
                    if (segmentLive != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: segmentLive.profile.points
                                .map(
                                  (p) => latlng.LatLng(p.latitude, p.longitude),
                                )
                                .toList(),
                            strokeWidth: 6,
                            color: AppColors.segmentActiveTrack,
                          ),
                        ],
                      ),
                    // --- Ruta sugerida (verde) -- polilínea + marcadores
                    // de giro, por encima del trazado grabado. Si hay una
                    // ruta en preview (esperando confirmación) se dibuja
                    // esa, más tenue; si ya se activó, la activa.
                    if (activeNavigationRoute != null)
                      ...buildNavigationRouteLayers(activeNavigationRoute)
                    else if (routePreview != null)
                      ...buildNavigationRouteLayers(
                        routePreview.route,
                        preview: true,
                      ),
                    // --- Ubicaciones guardadas (estrella dorada / ícono
                    // de Casa). Tocar una la pone como destino y arranca
                    // la confirmación de ruta.
                    MarkerLayer(
                      markers: [
                        for (final place in savedPlaces)
                          Marker(
                            point: latlng.LatLng(
                              place.latitude,
                              place.longitude,
                            ),
                            width: 34,
                            height: 34,
                            child: _SavedPlaceMarker(
                              kind: place.kind,
                              onTap: () => _startPreviewTo(
                                NavigationTarget(
                                  name: place.name,
                                  lat: place.latitude,
                                  lng: place.longitude,
                                ),
                                markerPosition,
                              ),
                            ),
                          ),
                        // Montañita en el destino, cuando vamos hacia un alto.
                        if (climbDestination != null)
                          Marker(
                            point: climbDestination,
                            width: 40,
                            height: 46,
                            alignment: Alignment.topCenter,
                            child: const _PeakMarker(),
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
                              angle:
                                  recordingState.currentBearingDegrees *
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

                // Fila superior: píldora de estado + botón de compartir
                // log. La brújula ya no vive acá -- se unificó con el
                // control de ubicación (ver MapControlsCluster, abajo a
                // la derecha).
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _StatusPill(
                              isRecording: recordingState.isRecording,
                              isPaused: recordingState.isPaused,
                              isAutoPaused: recordingState.isAutoPaused,
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
                                  Share.shareXFiles([
                                    XFile(file.path),
                                  ], text: 'Log CycleCore');
                                },
                              ),
                          ],
                        ),
                        // --- Banner de próxima instrucción de giro --
                        // solo aparece mientras hay una navegación
                        // activa. Se oculta mientras estás dentro de un
                        // segmento: ahí la navegación no se usa y el
                        // espacio se aprovecha para la pantalla de
                        // segmento.
                        if (activeNavigationRoute != null &&
                            segmentLive == null) ...[
                          const SizedBox(height: 10),
                          const TurnInstructionBanner(),
                        ],
                        // --- Banner de segmento en vivo -- se auto-oculta
                        // si no estás dentro de un segmento vigilado (ver
                        // SegmentLiveBanner). Solo se ve cuando el panel
                        // de segmento está colapsado: si está expandido,
                        // esa pantalla ya muestra todo esto y más. ---
                        if (segmentLive != null && !_isCockpitExpanded) ...[
                          const SizedBox(height: 10),
                          const SegmentLiveBanner(),
                        ],
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
                        // La bitácora de sensores se limpia sola cuando
                        // `routeRecordingProvider` pasa a isRecording:true
                        // (ver rideSensorLogProvider).
                        //
                        // Una grabación nueva abre un diario nuevo y borra
                        // el anterior: si quedó una sin guardar (p. ej. se
                        // salió de "Guardar actividad" con atrás), primero
                        // se ofrece recuperarla.
                        if (await _offerRecordingRecovery()) return;
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
                      onFinishPressed: () =>
                          _confirmAndFinish(context, recordingController),
                    ),
                    // Dentro de un segmento, el panel expandido muestra la
                    // pantalla de segmento (perfil + polilínea + tus
                    // datos configurables) en vez del cockpit normal.
                    expanded: segmentLive != null
                        ? SegmentLiveScreen(
                            onCollapse: () =>
                                _slidingPanelKey.currentState?.collapse(),
                          )
                        : CockpitFullscreenView(
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
                // Se oculta también mientras estás dentro de un segmento
                // -- ahí la pantalla de segmento ya muestra velocidad y
                // demás, y el mapa se ve más limpio.
                if (recordingState.isRecording && segmentLive == null)
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

                // Botón flotante "Navegar" -- abre el buscador de
                // destino y traza la ruta más corta (ver
                // navigation_search_sheet.dart). Solo aparece si ya
                // tenés el grafo vial de tu zona descargado (ver
                // Ajustes > Navegación); si no, no tiene sentido
                // mostrarlo porque no hay con qué calcular la ruta.
                // Se ubica arriba del botón de recentrar, mismo margen
                // derecho para quedar alineados.
                if (hasNavigationData &&
                    segmentLive == null &&
                    routePreview == null)
                  Positioned(
                    right: _sideRightMargin,
                    bottom: 230 + MediaQuery.of(context).padding.bottom,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _isCockpitExpanded ? 0.0 : 1.0,
                      child: IgnorePointer(
                        ignoring: _isCockpitExpanded,
                        child: activeNavigationRoute == null
                            ? _NavigateButton(
                                onTap: () =>
                                    _openDestinationSearch(markerPosition),
                              )
                            : _CancelNavigationButton(
                                onTap: () => confirmEndNavigation(context, ref),
                              ),
                      ),
                    ),
                  ),

                // --- Tarjeta "Confirmar la ruta" -- aparece cuando hay
                // una ruta calculada esperando el "Empezar". Cubre el
                // cockpit compacto mientras decides.
                if (routePreview != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: RouteConfirmCard(
                      preview: routePreview,
                      onChange: () {
                        ref.read(navigationControllerProvider).clearPreview();
                        _openDestinationSearch(markerPosition);
                      },
                    ),
                  ),

                // Control unificado de mapa (recentrar + seguir +
                // brújula), estilo Google Maps/Waze -- un solo botón.
                // Se desvanece cuando el cockpit/segmento está en
                // pantalla completa, o mientras confirmas una ruta (la
                // tarjeta lo tapa).
                if (routePreview == null)
                  Positioned(
                    right: _sideRightMargin,
                    bottom: 170 + MediaQuery.of(context).padding.bottom,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _isCockpitExpanded ? 0.0 : 1.0,
                      child: IgnorePointer(
                        ignoring: _isCockpitExpanded,
                        child: MapControlsCluster(
                          mode: _followMode,
                          mapRotationDegrees: _currentMapRotationDegrees,
                          onRecenter: () => _recenterAndFollow(markerPosition),
                          onToggleHeading: _toggleHeadingUp,
                          onResetNorthFollow: () =>
                              _resetNorthAndFollow(markerPosition),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
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

    final sensorLog = ref.read(rideSensorLogProvider);
    final summary = await controller.finishRecording(
      heartRateSamples: List.of(sensorLog.heartRate),
      powerSamples: List.of(sensorLog.power),
      cadenceSamples: List.of(sensorLog.cadence),
    );

    // Voz: la actividad terminó y ya se generó el resumen.
    ref
        .read(voiceSettingsProvider.notifier)
        .speak(VoiceEventType.activityFinished);

    if (!context.mounted) return;

    _openSaveActivity(summary);
  }

  /// Abre "Guardar actividad" para una grabación ya terminada -- en vivo
  /// o recuperada del diario tras un cierre inesperado.
  void _openSaveActivity(ActivitySummary summary) {
    final journal = ref.read(recordingJournalProvider);
    final segmentDetection = ref.read(segmentDetectionProvider.notifier);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaveActivityScreen(
          summary: summary,
          // Los esfuerzos de segmento detectados durante la grabación
          // se bufferizan sin id de actividad (ver
          // SegmentDetectionController) -- acá se resuelven ya con el
          // id, o se tiran si el usuario descarta la grabación.
          //
          // Con la actividad ya en el historial se vacía el diario de
          // grabación. Va al final a propósito: si la app se cierra
          // justo antes, al reabrirla el diario reconoce que la
          // actividad ya existe y solo se limpia (ver
          // RecordingJournal.loadRecoverable).
          onActivitySaved: (activityId) async {
            await segmentDetection.flushPendingEfforts(activityId);
            await journal.clear();
          },
          onRecordingDiscarded: () {
            segmentDetection.discardPendingEfforts();
            unawaited(journal.clear());
          },
        ),
      ),
    );
  }

  /// Si el diario de grabación tiene una sesión que no llegó al historial
  /// (la app se cerró grabando, o ya en "Guardar actividad"), ofrece
  /// seguir grabando, guardarla o descartarla.
  ///
  /// Devuelve true si la sesión quedó en uso (se reanudó, se va a guardar
  /// o el usuario dejó la decisión para después) -- quien iba a empezar
  /// una grabación nueva no debe hacerlo.
  Future<bool> _offerRecordingRecovery() async {
    if (_isOfferingRecovery) return true;
    // Una grabación viva también escribe en el diario; esa no se ofrece.
    if (ref.read(routeRecordingProvider).isRecording) return false;

    _isOfferingRecovery = true;
    try {
      final journal = ref.read(recordingJournalProvider);
      final snapshot = await journal.loadRecoverable();
      if (snapshot == null || !mounted) return false;

      final choice = await showRecordingRecoveryDialog(context, snapshot);
      switch (choice) {
        case RecordingRecoveryChoice.resume:
          await _resumeRecovered(snapshot);
        case RecordingRecoveryChoice.save:
          await _saveRecovered(snapshot);
        case RecordingRecoveryChoice.discard:
          await journal.clear();
          return false;
        case null:
          break;
      }
      return true;
    } finally {
      _isOfferingRecovery = false;
    }
  }

  Future<void> _resumeRecovered(RecordingSnapshot snapshot) async {
    // La bitácora de sensores va primero: la detección de segmentos la
    // usa al ponerse al día con los puntos recuperados.
    ref.read(rideSensorLogProvider.notifier).restore(snapshot);
    try {
      await ref.read(routeRecordingProvider.notifier).resumeFrom(snapshot);
      ref
          .read(voiceSettingsProvider.notifier)
          .speak(VoiceEventType.activityResumed);
    } catch (e) {
      // El diario sigue intacto: se volverá a ofrecer.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _saveRecovered(RecordingSnapshot snapshot) async {
    try {
      final summary = await ref
          .read(routeRecordingProvider.notifier)
          .finishRecovered(snapshot);
      await ref
          .read(segmentDetectionProvider.notifier)
          .recoverEffortsFrom(
            points: snapshot.routePoints,
            log: RideSensorLog.fromSnapshot(snapshot),
          );
      if (!mounted) return;
      _openSaveActivity(summary);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// Abre el buscador de destino; si el usuario elige uno, calcula la
  /// ruta y la deja en preview (la tarjeta "Confirmar la ruta").
  Future<void> _openDestinationSearch(latlng.LatLng from) async {
    final target = await showNavigationSearchSheet(
      context,
      ref,
      fromLat: from.latitude,
      fromLng: from.longitude,
    );
    if (target == null || !mounted) return;
    await _startPreviewTo(target, from);
  }

  Future<void> _startPreviewTo(
    NavigationTarget target,
    latlng.LatLng from,
  ) async {
    try {
      await ref
          .read(navigationControllerProvider)
          .previewRoute(
            target: target,
            fromLat: from.latitude,
            fromLng: from.longitude,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

/// Botón flotante "Navegar" -- abre el buscador de destino (estilo
/// Waze). Mismo lenguaje visual que `MapControlsCluster`.
class _NavigateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NavigateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CcColors.glass,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Icon(Icons.directions, color: CcColors.blue, size: 22),
        ),
      ),
    );
  }
}

/// Estrella dorada (o ícono de Casa) sobre una ubicación guardada.
/// Tocarla la pone como destino.
class _SavedPlaceMarker extends StatelessWidget {
  final String kind;
  final VoidCallback onTap;

  const _SavedPlaceMarker({required this.kind, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isHome = kind == 'home';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CcColors.glass,
          shape: BoxShape.circle,
          border: Border.all(
            color: isHome ? CcColors.blue : CcColors.gold,
            width: 1.5,
          ),
        ),
        child: Icon(
          isHome ? Icons.home_rounded : Icons.star_rounded,
          color: isHome ? CcColors.blue : CcColors.gold,
          size: 16,
        ),
      ),
    );
  }
}

/// Montañita ámbar en el destino cuando la ruta va hacia un alto.
class _PeakMarker extends StatelessWidget {
  const _PeakMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -0.785398, // -45°
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: CcColors.glass,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(3),
              ),
              border: Border.all(color: CcColors.mSlope, width: 1.5),
            ),
            child: Transform.rotate(
              angle: 0.785398,
              child: const Icon(
                Icons.terrain,
                color: CcColors.mSlope,
                size: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reemplaza a `_NavigateButton` mientras hay una navegación activa --
/// mismo lugar en pantalla, ahora para cancelarla.
class _CancelNavigationButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CancelNavigationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CyclecorePalette.ubicacionActiva,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Icon(Icons.close, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Píldora de estado -- vive en la fila superior junto al botón de
/// compartir log.
class _StatusPill extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final bool isAutoPaused;
  final bool isApproximate;

  const _StatusPill({
    required this.isRecording,
    required this.isPaused,
    required this.isAutoPaused,
    required this.isApproximate,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CcColors.glass,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Detenido con la pausa automática: el tiempo está congelado,
            // pero se reanuda solo al volver a rodar.
            if (isRecording && isAutoPaused) ...[
              const Icon(
                Icons.pause_circle_outline,
                color: AppColors.accentSlope,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'PAUSA AUTOMÁTICA',
                style: TextStyle(
                  color: AppColors.textPrimaryOnPanel,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ] else if (isRecording && !isPaused) ...[
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
      color: CcColors.glass,
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
                            padding: const EdgeInsets.symmetric(horizontal: 4),
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
