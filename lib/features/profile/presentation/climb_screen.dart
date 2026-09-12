import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import '../../voice/domain/voice_persona.dart';
import '../../voice/presentation/voice_providers.dart';
import '../../voice/presentation/widgets/voice_unlock_overlay.dart';
import '../domain/activity_climb_result.dart';
import '../domain/climb_progress.dart';
import '../domain/climb_route.dart';
import '../domain/cyclist_kit.dart';
import '../domain/kit_catalog.dart';
import '../domain/kit_unlocks.dart';
import 'package:cyclecore_core/gamification/level_info.dart';
import 'package:cyclecore_core/gamification/rank_tier.dart';
import 'climb_collectibles_provider.dart';
import 'climb_collection_screen.dart';
import 'cyclist_kit_providers.dart';
import 'profile_providers.dart';
import 'wardrobe_screen.dart';
import 'widgets/climb_arch.dart';
import 'widgets/climb_progress_sheet.dart';
import 'widgets/climb_road.dart';
import 'widgets/climb_scenery.dart';
import 'widgets/dawn_climb_backdrop.dart';
import 'widgets/kit_unlock_overlay.dart';
import 'widgets/level_cinematic.dart';
import 'widgets/level_up_overlay.dart';
import 'widgets/pedaling_cyclist.dart';
import 'widgets/rank_up_overlay.dart';
import 'widgets/xp_debug_panel.dart';

/// La pantalla de "la subida": una vista tipo videojuego con la cámara
/// justo detrás del ciclista, subiendo el Alto de Patios real. La
/// carretera se pierde en el horizonte con el amanecer de Welcome/Login
/// de fondo; el ciclista va SIEMPRE centrado y es el mundo el que se
/// mueve. Cada cambio de rango (niveles 5/10/15/20/25) tiene su arco
/// sobre la vía, del color y la grandeza de ese rango.
///
/// El ciclista descansa en `nivel + progreso dentro del nivel` (ej.
/// 12.62), no en enteros: tras cada actividad se nota que avanzó un
/// poco aunque no haya subido de nivel.
///
/// Tres formas de entrar:
/// - **Post-actividad** ([activityResult] no nulo): el ciclista sube
///   animado de `before` a `after`, festeja cada arco cruzado y, al
///   final, encadena el festejo de subida de nivel o de cambio de rango.
///   El panel inferior muestra "+XP / avanzaste X km / Seguir".
/// - Desde el roadmap del perfil, tocando un rango -> [focusRank] no
///   nulo: la cámara se planta en ese tramo, sin animar.
/// - Desde cualquier otro lugar sin ninguno de los dos: sube animado
///   desde el último nivel reconocido hasta donde está ahora.
class ClimbScreen extends ConsumerStatefulWidget {
  final CyclistRank? focusRank;
  final ActivityClimbResult? activityResult;

  const ClimbScreen({super.key, this.focusRank, this.activityResult});

  @override
  ConsumerState<ClimbScreen> createState() => _ClimbScreenState();
}

class _ClimbScreenState extends ConsumerState<ClimbScreen>
    with TickerProviderStateMixin {
  late final AnimationController _climbController;
  Tween<double>? _climbTween;

  /// Corta a vista de perfil (bici + maillot) al cruzar un arco de rango
  /// o al tocar el ciclista -- ver [_playCinematic].
  late final AnimationController _cinematicController;

  /// Nivel del arco de la cinemática en curso; `null` = modo
  /// "inspeccionar" (tocar el ciclista); si `_cinematicController` no
  /// está animando, no hay cinemática.
  int? _cinematicLevel;
  final Set<int> _cinematicsShown = {};
  final List<int> _pendingCinematics = [];

  /// El festejo que va al terminar la subida (subir de nivel / cambio de
  /// rango / desbloqueo) -- se guarda aquí si hay una cinemática de nivel
  /// en curso, para que el modal NO se solape con la cinemática.
  VoidCallback? _pendingClimbFinish;

  bool get _cinematicActive => _cinematicController.isAnimating;

  /// Nivel fraccionario que la cámara está mostrando ahora mismo.
  double _displayedLevel = 1;

  /// Último nivel entero que ya disparó su vibración durante la
  /// animación en curso -- evita repetir el toque en el mismo arco.
  int _lastHapticFloor = 1;

  /// Último nivel de [levelInfoProvider] ya visto -- distingue, dentro
  /// de `ref.listen`, un cambio real de nivel de la primera
  /// notificación al empezar a escuchar.
  int? _lastKnownProviderLevel;

  bool get _isPostActivity => widget.activityResult != null;

  @override
  void initState() {
    super.initState();
    _climbController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2000),
        )..addListener(() {
          final tween = _climbTween;
          if (tween == null) return;
          final value = tween.evaluate(_climbController);
          final floor = value.floor();
          if (floor > _lastHapticFloor) {
            for (var l = _lastHapticFloor + 1; l <= floor; l++) {
              if (ClimbArchesPainter.isArchLevel(l) &&
                  _cinematicsShown.add(l)) {
                _pendingCinematics.add(l);
              }
            }
            _lastHapticFloor = floor;
            HapticFeedback.lightImpact();
            if (_pendingCinematics.isNotEmpty && !_cinematicActive) {
              _playCinematic(_pendingCinematics.removeAt(0));
            }
          }
          setState(() => _displayedLevel = value);
        });

    _cinematicController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3200),
        )..addStatusListener((status) {
          if (status != AnimationStatus.completed) return;
          setState(() => _cinematicLevel = null);
          if (_pendingCinematics.isNotEmpty) {
            _playCinematic(_pendingCinematics.removeAt(0));
            return;
          }
          if (_climbTween != null && !_climbController.isCompleted) {
            // Reanuda la subida que quedó a medias, y al terminar corre
            // el festejo que estaba esperando.
            _climbController.forward().whenComplete(_runPendingClimbFinish);
            return;
          }
          _runPendingClimbFinish();
        });

    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  /// Pausa la subida y corta a la cinemática de perfil.
  void _playCinematic(int? level) {
    if (_cinematicActive) return;
    _climbController.stop();
    setState(() => _cinematicLevel = level);
    _cinematicController.forward(from: 0);
  }

  /// Corre el festejo de fin de subida -- ya, o guardado si hay una
  /// cinemática por delante.
  void _finishClimb(VoidCallback celebrate) {
    if (!mounted) return;
    if (_cinematicActive || _pendingCinematics.isNotEmpty) {
      _pendingClimbFinish = celebrate;
    } else {
      celebrate();
    }
  }

  void _runPendingClimbFinish() {
    if (!mounted || _cinematicActive || _pendingCinematics.isNotEmpty) return;
    final cb = _pendingClimbFinish;
    if (cb != null) {
      _pendingClimbFinish = null;
      cb();
    }
  }

  @override
  void dispose() {
    _climbController.dispose();
    _cinematicController.dispose();
    super.dispose();
  }

  double _restLevelFor(LevelInfo? info, int currentLevel) =>
      (currentLevel + (info?.progress ?? 0.0)).clamp(
        1.0,
        ClimbRoute.maxLevel.toDouble(),
      );

  void _onFirstFrame() {
    final info = ref.read(levelInfoProvider).valueOrNull;
    final currentLevel = info?.level ?? 1;
    _lastKnownProviderLevel = currentLevel;

    final result = widget.activityResult;
    if (result != null) {
      _runPostActivity(result);
      return;
    }

    if (widget.focusRank != null) {
      final tierPoints = ClimbRoute.forTier(
        RankTier.forRank(widget.focusRank!),
      );
      final mid = tierPoints[tierPoints.length ~/ 2].level;
      setState(() => _displayedLevel = mid.toDouble());
      return;
    }

    _runClimbAnimation(currentLevel);
  }

  void _runPostActivity(ActivityClimbResult result) {
    final start = result.before.levelValue;
    final end = result.after.levelValue;
    _lastHapticFloor = start.floor();

    if ((end - start).abs() < 0.002) {
      setState(() => _displayedLevel = end);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finishClimb(() => _celebrate(result));
      });
      return;
    }

    _climbController.duration = Duration(
      milliseconds: (2400 + (end - start) * 850).clamp(2400, 6200).round(),
    );
    _climbTween = Tween<double>(begin: start, end: end);
    setState(() => _displayedLevel = start);

    _climbController
      ..reset()
      ..forward().whenComplete(() {
        if (mounted) _finishClimb(() => _celebrate(result));
      });
  }

  Future<void> _celebrate(ActivityClimbResult result) async {
    ref
        .read(levelAcknowledgementProvider.notifier)
        .consumeLevelUp(result.after.currentLevel);
    if (!mounted) return;

    if (result.newRank != null) {
      await RankUpFlow.showRankUp(
        context,
        newRank: result.newRank!,
        previousRank: result.before.rank,
        totalXp: ref.read(effectiveTotalXpProvider).valueOrNull,
      );
    } else if (result.leveledUp) {
      final info = ref.read(levelInfoProvider).valueOrNull;
      if (info != null) await LevelUpFlow.showLevelUpOverlay(context, info);
    }

    if (!mounted) return;
    await _maybeShowKitUnlock();
    if (!mounted) return;
    await _maybeShowVoiceUnlock();
  }

  /// Encadena el festejo de "¡Desbloqueaste una pieza!" si esta
  /// actividad cruzó el umbral de alguna del vestidor.
  Future<void> _maybeShowKitUnlock() async {
    final newIds = await ref
        .read(kitUnlocksSeenProvider.notifier)
        .reconcile(ref.read(unlockedKitIdsProvider));
    if (!mounted) return;

    KitItem? chosen;
    for (final id in newIds) {
      final item = KitCatalog.byId[id];
      if (item != null && item.unlock.kind != KitUnlockKind.always) {
        chosen = item;
        break;
      }
    }
    if (chosen == null) return;
    final item = chosen;

    final set = KitCatalog.setById(item.setId);
    await KitUnlockFlow.showUnlock(
      context,
      item,
      setName: set?.name,
      setProgress: set == null
          ? null
          : kitSetProgress(set, ref.read(unlockedKitIdsProvider)),
      onEquip: () => ref.read(cyclistKitProvider.notifier).equip(item),
    );
  }

  /// Encadena el festejo de "¡Desbloqueaste una voz!" si esta actividad
  /// desbloqueó alguna voz de guía nueva.
  Future<void> _maybeShowVoiceUnlock() async {
    final newIds = await ref
        .read(voiceUnlocksSeenProvider.notifier)
        .reconcile(ref.read(unlockedVoicePersonaIdsProvider));
    if (!mounted) return;

    VoicePersona? chosen;
    for (final id in newIds) {
      final persona = voicePersonaById(id);
      if (persona != null && persona.tier == VoiceTier.desbloqueable) {
        chosen = persona;
        break;
      }
    }
    if (chosen == null) return;
    final persona = chosen;

    await VoiceUnlockFlow.showUnlock(
      context,
      persona,
      onEquip: () =>
          ref.read(voiceSettingsProvider.notifier).selectPersona(persona),
      onPreview: () =>
          ref.read(voiceSettingsProvider.notifier).previewPersona(persona),
    );
  }

  void _runClimbAnimation(int currentLevel) {
    final info = ref.read(levelInfoProvider).valueOrNull;
    final acknowledged = ref.read(levelAcknowledgementProvider);
    final restLevel = _restLevelFor(info, currentLevel);
    final startLevel = (acknowledged ?? currentLevel)
        .clamp(1, ClimbRoute.maxLevel)
        .toDouble();
    _lastHapticFloor = startLevel.floor();

    if (startLevel >= currentLevel) {
      // Nada que animar (primera vez, o ya está al día): solo
      // confirmamos el nivel actual como "reconocido" y descansamos.
      _climbController.stop();
      _climbTween = null;
      setState(() => _displayedLevel = restLevel);
      ref
          .read(levelAcknowledgementProvider.notifier)
          .consumeLevelUp(currentLevel);
      return;
    }

    final levelsToClimb = (currentLevel - startLevel).clamp(
      1,
      ClimbRoute.maxLevel,
    );
    _climbController.duration = Duration(
      milliseconds: (1900 + levelsToClimb * 340).clamp(1900, 5400).round(),
    );
    _climbTween = Tween<double>(begin: startLevel, end: restLevel);
    setState(() => _displayedLevel = startLevel);

    _climbController
      ..reset()
      ..forward().whenComplete(() {
        if (!mounted) return;
        _finishClimb(() {
          final leveledUp = ref
              .read(levelAcknowledgementProvider.notifier)
              .consumeLevelUp(currentLevel);
          if (leveledUp && mounted) {
            final latest = ref.read(levelInfoProvider).valueOrNull;
            if (latest != null) {
              LevelUpFlow.showLevelUpOverlay(context, latest);
            }
          }
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    final levelAsync = ref.watch(levelInfoProvider);

    // Si el XP cambia con la pantalla abierta (ej. panel de debug),
    // relanzamos la subida hacia el nuevo nivel -- salvo en modo
    // post-actividad, donde la animación de `activityResult` manda.
    ref.listen<AsyncValue<LevelInfo>>(levelInfoProvider, (previous, next) {
      if (_isPostActivity) return;
      final newLevel = next.valueOrNull?.level;
      if (newLevel == null) return;
      if (_lastKnownProviderLevel != null &&
          newLevel != _lastKnownProviderLevel) {
        _runClimbAnimation(newLevel);
      }
      _lastKnownProviderLevel = newLevel;
    });

    final progress = climbProgressForLevelValue(_displayedLevel);
    final accent = RankTier.forLevel(
      _displayedLevel.round().clamp(1, ClimbRoute.maxLevel),
    ).color;
    final kitVisual = ref.watch(cyclistKitVisualProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: CcColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('La subida'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Center(child: XpDebugEntryButton()),
          ),
          _ClimbMenuButton(levelValue: _displayedLevel),
        ],
      ),
      body: levelAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CcColors.orange),
        ),
        error: (_, _) => const Center(
          child: Text(
            'No se pudo cargar tu progreso.',
            style: TextStyle(color: CcColors.inkDim),
          ),
        ),
        data: (_) => Stack(
          children: [
            _ClimbView(
              displayedLevel: _displayedLevel,
              progress: progress,
              accent: accent,
              climbing: _climbController.isAnimating,
              activityResult: widget.activityResult,
              kitVisual: kitVisual,
              onInspect: () => _playCinematic(null),
            ),
            if (_cinematicActive)
              Positioned.fill(
                child: LevelCinematic(
                  progress: _cinematicController,
                  level: _cinematicLevel,
                  rank: RankTier.forLevel(
                    (_cinematicLevel ?? _displayedLevel.round()).clamp(
                      1,
                      ClimbRoute.maxLevel,
                    ),
                  ),
                  kit: kitVisual,
                  jerseyColor:
                      RankTier.all[kitVisual.jerseyKind.clamp(0, 5)].color,
                  riderName: ref.watch(profileProvider).valueOrNull?.name,
                  onSkip: () => _cinematicController.animateTo(
                    1,
                    duration: const Duration(milliseconds: 220),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Menú de 3 puntos del app bar: recoge Vestidor / colección / progreso
/// y el interruptor de testing, para no llenar la barra de botones.
/// Lleva un puntito dorado si hay piezas nuevas en el Vestidor.
class _ClimbMenuButton extends ConsumerWidget {
  final double levelValue;

  const _ClimbMenuButton({required this.levelValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNew =
        ref.watch(unseenKitUnlocksProvider).isNotEmpty ||
        ref.watch(unseenVoiceUnlocksProvider).isNotEmpty;
    final debugAll = ref.watch(kitDebugUnlockAllProvider);

    PopupMenuItem<String> row(
      String value,
      IconData icon,
      String label, {
      bool dot = false,
      bool checked = false,
    }) {
      return PopupMenuItem<String>(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 18, color: CcColors.inkDim),
            const SizedBox(width: 12),
            Text(label),
            if (dot) ...[
              const SizedBox(width: 8),
              const Icon(Icons.circle, size: 8, color: CcColors.gold),
            ],
            if (checked) ...[
              const Spacer(),
              const Icon(Icons.check, size: 16, color: CcColors.gold),
            ],
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PopupMenuButton<String>(
          tooltip: 'Más',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'vestidor':
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WardrobeScreen()),
                );
              case 'coleccion':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ClimbCollectionScreen(),
                  ),
                );
              case 'progreso':
                showClimbProgressSheet(context, levelValue: levelValue);
              case 'skins':
                ref.read(kitDebugUnlockAllProvider.notifier).state = !debugAll;
            }
          },
          itemBuilder: (context) => [
            row('vestidor', Icons.checkroom_outlined, 'Vestidor', dot: hasNew),
            row(
              'coleccion',
              Icons.collections_bookmark_outlined,
              'Tu colección',
            ),
            row('progreso', Icons.insights_outlined, 'Mi progreso'),
            const PopupMenuDivider(),
            row(
              'skins',
              debugAll ? Icons.lock_open : Icons.lock_outline,
              'Desbloquear skins (test)',
              checked: debugAll,
            ),
          ],
        ),
        if (hasNew)
          const Positioned(
            top: 10,
            right: 8,
            child: Icon(Icons.circle, size: 8, color: CcColors.gold),
          ),
      ],
    );
  }
}

/// La escena en sí: fondo de amanecer + carretera + arcos + ciclista +
/// HUD. Sin estado propio -- todo lo que se mueve viene de arriba.
class _ClimbView extends StatelessWidget {
  final double displayedLevel;
  final ClimbProgress progress;
  final Color accent;
  final bool climbing;
  final ActivityClimbResult? activityResult;
  final CyclistKitVisual kitVisual;
  final VoidCallback onInspect;

  const _ClimbView({
    required this.displayedLevel,
    required this.progress,
    required this.accent,
    required this.climbing,
    required this.activityResult,
    required this.kitVisual,
    required this.onInspect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final camera = ClimbCamera(size: size, displayedLevel: displayedLevel);
        final cyclistPos = camera.roadPoint(0);
        final cyclistSize = (size.height * 0.2).clamp(110.0, 168.0);

        // Banderines-postal de los niveles normales que se acercan (los
        // que no estrenan rango); el primero es "hacia donde vas".
        final floor = displayedLevel.floor();
        final poiLevels = <int>[
          for (
            var l = floor + 1;
            l <= floor + 5 && l <= ClimbRoute.maxLevel;
            l++
          )
            if (!ClimbArchesPainter.isArchLevel(l)) l,
        ];
        final nextArch = ClimbArchesPainter.nextArchLevel(displayedLevel);

        return Stack(
          children: [
            Positioned.fill(
              child: DawnClimbBackdrop(progress: progress.fractionOfClimb),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: ClimbRoadPainter(camera: camera, accent: accent),
              ),
            ),
            ClimbRoadName(camera: camera),
            Positioned.fill(
              child: CustomPaint(painter: ClimbArchesPainter(camera: camera)),
            ),
            ClimbCrowd(camera: camera),
            for (final l in poiLevels)
              ClimbPoiPennant(
                key: ValueKey('poi-pennant-$l'),
                camera: camera,
                level: l,
                onLeft: l.isEven,
                highlighted: l == poiLevels.first,
                onTap: () => showClimbPoiSheet(
                  context,
                  ClimbRoute.forLevel(l),
                  isNew: false,
                  locked: true,
                ),
              ),
            if (nextArch != null)
              ClimbArchLabel(camera: camera, level: nextArch),
            Positioned(
              left: cyclistPos.dx - cyclistSize / 2,
              top: cyclistPos.dy - cyclistSize * 0.76,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Tocar el ciclista corta a vista de perfil para ver el
                // equipo de cerca.
                onTap: climbing ? null : onInspect,
                child: PedalingCyclist(
                  color: accent,
                  size: cyclistSize,
                  cadence: climbing ? 2.6 : 1.15,
                  kit: kitVisual,
                  // En la subida la cámara va SIEMPRE detrás del ciclista.
                  isClimbing: true,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: kToolbarHeight,
                    left: 12,
                    right: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _AltitudePill(
                            progress: progress,
                            accent: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: _DistancePill(progress: progress),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: activityResult != null
                  ? _PostActivityPanel(
                      result: activityResult!,
                      displayedLevel: displayedLevel,
                      progress: progress,
                      accent: accent,
                    )
                  : _ClimbPanel(
                      displayedLevel: displayedLevel,
                      progress: progress,
                      accent: accent,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AltitudePill extends StatelessWidget {
  final ClimbProgress progress;
  final Color accent;

  const _AltitudePill({required this.progress, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: CcColors.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CcColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.terrain, size: 14, color: CcColors.inkDim),
          const SizedBox(width: 6),
          Text(
            '${progress.altitudeM.round()} msnm',
            style: CcType.displayStyle(size: 15),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${progress.gradePercent.toStringAsFixed(1)}%',
              style: CcType.label(size: 11, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistancePill extends StatelessWidget {
  final ClimbProgress progress;

  const _DistancePill({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CcColors.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CcColors.line),
      ),
      child: Text(
        'km ${progress.distanceKm.toStringAsFixed(1)} '
        '/ ${ElevationProfile.totalDistanceKm.toStringAsFixed(1)}',
        style: CcType.label(size: 11, color: CcColors.inkDim),
      ),
    );
  }
}

/// Contenedor "glass" del panel inferior -- compartido por el panel de
/// reposo y el de post-actividad.
class _PanelShell extends StatelessWidget {
  final Widget child;

  const _PanelShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: CcColors.glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CcColors.line),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Panel inferior de reposo: dónde vas (rango, nivel, punto de interés),
/// barra de XP al próximo arco, y accesos a la postal y al progreso.
class _ClimbPanel extends ConsumerWidget {
  final double displayedLevel;
  final ClimbProgress progress;
  final Color accent;

  const _ClimbPanel({
    required this.displayedLevel,
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = progress.currentLevel;
    final tier = RankTier.forLevel(level);
    final currentPoi = ClimbRoute.forLevel(level);
    final nextLevel = progress.nextLevel;
    final collected = ref.watch(climbCollectiblesProvider).valueOrNull ?? {};
    final undiscovered = !collected.contains(level);

    return _PanelShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RankRibbon(currentRank: tier.rank),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(tier.icon, size: 16, color: tier.color),
              const SizedBox(width: 6),
              Text(
                tier.label.toUpperCase(),
                style: CcType.label(
                  size: 12,
                  color: tier.color,
                ).copyWith(letterSpacing: 1.2),
              ),
              const Spacer(),
              Text('NIVEL $level', style: CcType.displayStyle(size: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text(
                  currentPoi.name,
                  style: CcType.displayStyle(size: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (undiscovered) ...[
                const SizedBox(width: 8),
                _Chip(label: 'postal nueva', color: CcColors.gold),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _XpBar(fraction: progress.fractionToNextLevel, color: accent),
          const SizedBox(height: 8),
          Text(
            nextLevel == null
                ? 'Estás en la cima del Alto de Patios'
                : 'Próximo arco · Nivel $nextLevel · '
                      '${ClimbRoute.forLevel(nextLevel).name}',
            style: CcType.label(size: 11, color: CcColors.inkDim),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _openPostal(context, ref, currentPoi, level),
                  icon: const Icon(Icons.image_outlined, size: 16),
                  label: const Text('Ver postal'),
                  style: TextButton.styleFrom(foregroundColor: CcColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => showClimbProgressSheet(
                    context,
                    levelValue: displayedLevel,
                  ),
                  icon: const Icon(Icons.insights_outlined, size: 16),
                  label: const Text('Mi progreso'),
                  style: TextButton.styleFrom(foregroundColor: CcColors.ink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openPostal(
    BuildContext context,
    WidgetRef ref,
    ClimbPointOfInterest poi,
    int level,
  ) async {
    final isNew = await ref
        .read(climbCollectiblesProvider.notifier)
        .markDiscovered(level);
    if (!context.mounted) return;
    showClimbPoiSheet(context, poi, isNew: isNew, locked: false);
  }
}

/// Panel inferior tras guardar una actividad: cuánta XP y cuánto camino
/// ganaste, y el botón para seguir.
class _PostActivityPanel extends StatelessWidget {
  final ActivityClimbResult result;
  final double displayedLevel;
  final ClimbProgress progress;
  final Color accent;

  const _PostActivityPanel({
    required this.result,
    required this.displayedLevel,
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final nextLevel = progress.nextLevel;
    final km = result.kmAdvanced;
    final meters = result.metersClimbed;

    return _PanelShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(label: '+${result.xpGained} XP', color: CcColors.gold),
              const Spacer(),
              if (result.leveledUp)
                Row(
                  children: [
                    Icon(
                      result.after.rank.icon,
                      size: 15,
                      color: result.after.rank.color,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Nivel ${result.after.currentLevel}',
                      style: CcType.label(
                        size: 12,
                        color: result.after.rank.color,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            km >= 0.05
                ? 'Avanzaste ${km.toStringAsFixed(1)} km en el Alto de Patios'
                : 'Avanzaste un tramo del Alto de Patios',
            style: CcType.displayStyle(size: 17),
          ),
          if (meters >= 1) ...[
            const SizedBox(height: 2),
            Text(
              'y ganaste ${meters.round()} m de altura',
              style: CcType.label(size: 11, color: CcColors.inkDim),
            ),
          ],
          const SizedBox(height: 12),
          _XpBar(fraction: progress.fractionToNextLevel, color: accent),
          const SizedBox(height: 8),
          Text(
            nextLevel == null
                ? 'Estás en la cima del Alto de Patios'
                : 'Próximo arco · Nivel $nextLevel · '
                      '${ClimbRoute.forLevel(nextLevel).name}',
            style: CcType.label(size: 11, color: CcColors.inkDim),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => showClimbProgressSheet(
                    context,
                    levelValue: displayedLevel,
                  ),
                  icon: const Icon(Icons.insights_outlined, size: 16),
                  label: const Text('Mi progreso'),
                  style: TextButton.styleFrom(foregroundColor: CcColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  child: const Text('Seguir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(label, style: CcType.label(size: 11, color: color)),
    );
  }
}

/// Cinta de los 6 rangos (los mismos del home) con el rango actual
/// resaltado -- referencia rápida de "en qué parte del camino estoy".
class _RankRibbon extends StatelessWidget {
  final CyclistRank currentRank;

  const _RankRibbon({required this.currentRank});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tier in RankTier.all)
          Expanded(
            flex: tier.rank == currentRank ? 3 : 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 6,
              decoration: BoxDecoration(
                color: tier.color.withValues(
                  alpha: tier.rank == currentRank ? 1 : 0.28,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

class _XpBar extends StatelessWidget {
  final double fraction;
  final Color color;

  const _XpBar({required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Container(height: 7, color: CcColors.surfaceInset),
          FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(height: 7, color: color),
          ),
        ],
      ),
    );
  }
}

/// Hoja con la postal / micro-historia de un punto de interés. Portada
/// del diseño anterior (mapa scrollable) -- el contenido no cambió, solo
/// el resto de la pantalla.
void showClimbPoiSheet(
  BuildContext context,
  ClimbPointOfInterest poi, {
  required bool isNew,
  required bool locked,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: CcColors.surfaceHi,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                locked ? Icons.lock_outline : poi.tier.icon,
                color: locked ? CcColors.inkDim : poi.tier.color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(poi.name, style: CcType.displayStyle(size: 18)),
              ),
              if (isNew) _Chip(label: '¡Nuevo!', color: CcColors.gold),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Nivel ${poi.level} · ${poi.tier.label} · '
            'km ${poi.distanceKm.toStringAsFixed(1)}',
            style: CcType.label(size: 12, color: poi.tier.color),
          ),
          const SizedBox(height: 12),
          Text(
            locked ? 'Todavía no llegas aquí. ${poi.stat}' : poi.stat,
            style: const TextStyle(color: CcColors.inkDim, fontSize: 13),
          ),
          if (!locked) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CcColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: poi.tier.color.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    color: poi.tier.color.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      poi.discoveryText,
                      style: const TextStyle(
                        color: CcColors.inkDim,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
