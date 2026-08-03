import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/level_info.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/climb_route.dart';
import '../domain/rank_tier.dart';
import 'climb_collectibles_provider.dart';
import 'climb_collection_screen.dart';
import 'profile_providers.dart';
import 'widgets/elevation_profile_overlay.dart';
import 'widgets/level_up_overlay.dart';
import 'widgets/pedaling_cyclist.dart';
import 'widgets/xp_debug_panel.dart';

/// La pantalla de "la subida": un camino serpenteante tipo mapa de
/// niveles de videojuego, dibujado con varias capas de parallax +
/// una carretera en perspectiva (más angosta arriba), un punto de
/// interés real por nivel (altitud/pendiente reales del Alto de
/// Patios, ver [ElevationProfile]), y el ciclista pedaleando de verdad
/// mientras se anima entre niveles.
///
/// Dos formas de entrar:
/// - Desde el roadmap del perfil, tocando un rango -> [focusRank] no
///   nulo, la pantalla solo hace scroll hasta ese tramo, sin animar.
/// - Desde cualquier otro lugar (ej. después de subir de nivel) sin
///   [focusRank] -> anima al ciclista subiendo desde el último nivel
///   reconocido hasta el nivel actual, y si hubo una subida real,
///   muestra el festejo al llegar arriba.
class ClimbScreen extends ConsumerStatefulWidget {
  final CyclistRank? focusRank;
  const ClimbScreen({super.key, this.focusRank});

  @override
  ConsumerState<ClimbScreen> createState() => _ClimbScreenState();
}

class _ClimbScreenState extends ConsumerState<ClimbScreen>
    with SingleTickerProviderStateMixin {
  static const double _horizontalAmplitude = 80;
  static const double _topPadding = 220;
  static const double _bottomPadding = 160;

  /// Pendiente real (%) interpolada en la fracción de subida que le
  /// corresponde a [level] -- sale del mismo perfil real
  /// ([ElevationProfile]) que ya alimenta el mini-perfil de
  /// altimetría, así todo el mapa de niveles queda consistente con
  /// los mismos datos.
  static double _gradeAtLevel(num level) {
    final maxLevel = ClimbRoute.maxLevel.toDouble();
    final fraction = maxLevel <= 1 ? 0.0 : (level - 1) / (maxLevel - 1);
    return ElevationProfile.gradeForFraction(fraction);
  }

  /// Cuánto "sube" visualmente cada nivel, en píxeles, según la
  /// pendiente real del tramo. Antes cada nivel ocupaba siempre el
  /// mismo espacio (`_levelSpacing` fijo), sin relación con dónde
  /// están las rampas reales de Patios -- ahora una rampa del 11-14%
  /// se siente más larga de subir en pantalla que un tramo del 2-3%.
  static double _baseSpacingForLevel(int level) {
    final grade = _gradeAtLevel(level).clamp(0.0, 16.0);
    return 90 + (grade / 16) * 140;
  }

  /// Suma acumulada de [_baseSpacingForLevel] desde el nivel 1 --
  /// se calcula una sola vez (son 30 niveles fijos) y de ahí se
  /// deriva tanto el alto total del contenido como la posición Y de
  /// cada nivel.
  static final List<double> _riseFromBase = _buildRiseFromBase();

  static List<double> _buildRiseFromBase() {
    final list = <double>[0];
    for (var level = 2; level <= ClimbRoute.maxLevel; level++) {
      list.add(list.last + _baseSpacingForLevel(level));
    }
    return list;
  }

  static double get _totalRise => _riseFromBase.last;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);
  late final AnimationController _climbController;
  double _displayedLevel = 1;

  /// Último nivel entero que ya disparó su micro-celebración durante la
  /// animación de subida en curso -- evita festejar el mismo nivel dos
  /// veces si el tween pasa varias veces cerca del mismo punto.
  int _lastCelebratedFloorLevel = 1;

  /// Pulsos de "crucé este POI" activos ahora mismo (Fase 4): cada uno
  /// se dibuja como un anillo que se expande y se desvanece sobre el
  /// punto de interés correspondiente, y se retira solo cuando termina
  /// su propia animación.
  final List<_PulseEvent> _activePulses = [];
  int _pulseIdCounter = 0;

  /// Último nivel reconocido de [levelInfoProvider] -- para distinguir,
  /// dentro de `ref.listen`, un cambio real de nivel (ej. el XP subió
  /// mientras la pantalla ya estaba abierta) de la primera notificación
  /// que llega apenas se empieza a escuchar el provider.
  int? _lastKnownProviderLevel;

  @override
  void initState() {
    super.initState();
    _climbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  @override
  void dispose() {
    _climbController.dispose();
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  double get _contentHeight => _totalRise + _topPadding + _bottomPadding;

  /// Amplitud del serpenteo horizontal: los tramos con más pendiente
  /// real "ondulan" un poco más, los suaves quedan casi rectos --
  /// mismo criterio de [_baseSpacingForLevel] pero en el eje X.
  double _xForLevel(num level) {
    final grade = _gradeAtLevel(level).clamp(0.0, 16.0);
    final amplitude = _horizontalAmplitude * (0.55 + (grade / 16) * 0.85);
    return amplitude * math.sin(level * 0.9);
  }

  double _yFromTopForLevel(num level) {
    final clamped = level.clamp(1, ClimbRoute.maxLevel).toDouble();
    final lowIndex = clamped.floor();
    final frac = clamped - lowIndex;
    final lowRise = _riseFromBase[lowIndex - 1];
    final highRise =
        lowIndex < ClimbRoute.maxLevel ? _riseFromBase[lowIndex] : lowRise;
    final rise = lowRise + (highRise - lowRise) * frac;
    return _topPadding + (_totalRise - rise);
  }

  /// Progreso 0..1 sobre la subida real (0 = nivel 1, 1 = nivel máximo)
  /// -- es lo que alimenta el mini-perfil de altimetría y el degradado
  /// de cielo, para que ambos avancen en sincronía con el ciclista.
  double get _progressFraction =>
      ClimbRoute.maxLevel <= 1 ? 0 : (_displayedLevel - 1) / (ClimbRoute.maxLevel - 1);

  void _onFirstFrame() {
    final currentLevel = ref.read(levelInfoProvider).valueOrNull?.level ?? 1;
    _lastKnownProviderLevel = currentLevel;

    if (widget.focusRank != null) {
      _displayedLevel = currentLevel.toDouble();
      final tierPoints = ClimbRoute.forTier(RankTier.forRank(widget.focusRank!));
      final midLevel = tierPoints[tierPoints.length ~/ 2].level;
      _scrollToLevel(midLevel, animate: true);
      setState(() {});
      return;
    }

    _runClimbAnimation(currentLevel);
  }

  /// Retira un pulso de "crucé este POI" de la lista una vez que su
  /// propia animación (ver [_PoiPulse]) ya terminó de dibujarse.
  void _onPulseDone(int id) {
    if (!mounted) return;
    setState(() => _activePulses.removeWhere((p) => p.id == id));
  }

  void _scrollToLevel(num level, {bool animate = false}) {
    if (!_scrollController.hasClients) return;
    final target = (_yFromTopForLevel(level) - 320)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _runClimbAnimation(int currentLevel) {
    final acknowledged = ref.read(levelAcknowledgementProvider);
    final startLevel =
        (acknowledged ?? currentLevel).clamp(1, ClimbRoute.maxLevel).toDouble();

    setState(() => _displayedLevel = startLevel);
    _lastCelebratedFloorLevel = startLevel.floor();
    _scrollToLevel(startLevel);

    if (startLevel >= currentLevel) {
      // Nada que animar (primera vez que se abre, o ya está al día):
      // solo confirmamos el nivel actual como "reconocido".
      ref.read(levelAcknowledgementProvider.notifier).consumeLevelUp(currentLevel);
      return;
    }

    final tween = Tween<double>(begin: startLevel, end: currentLevel.toDouble());

    // Antes la subida siempre duraba 1600ms fijos, sin importar si era
    // un solo nivel o diez de golpe -- se sentía apurada, sobre todo
    // en un salto de un solo nivel. Ahora la duración depende de
    // cuántos niveles hay que recorrer: más lenta en general, y más
    // larga todavía cuanto más grande sea el salto, para que la
    // "paseada" (out of saddle, tomar agua) tenga tiempo real de
    // notarse en pantalla.
    final levelsToClimb = (currentLevel - startLevel).clamp(1, ClimbRoute.maxLevel);
    _climbController.duration = Duration(
      milliseconds: (1900 + levelsToClimb * 340).clamp(1900, 5400).round(),
    );

    _climbController
      ..reset()
      ..addListener(() {
        final newDisplayed = tween.evaluate(_climbController);
        final newFloor = newDisplayed.floor().clamp(1, ClimbRoute.maxLevel).toInt();

        // Fase 4: cada punto de interés real que se cruza durante el
        // trayecto (no solo al llegar arriba) dispara su propia
        // micro-celebración -- si el salto de XP es grande y se
        // cruzan varios niveles en un mismo frame, festejamos cada uno.
        final crossedLevels = <int>[];
        if (newFloor > _lastCelebratedFloorLevel) {
          for (var lvl = _lastCelebratedFloorLevel + 1; lvl <= newFloor; lvl++) {
            crossedLevels.add(lvl);
          }
          _lastCelebratedFloorLevel = newFloor;
        }

        setState(() {
          _displayedLevel = newDisplayed;
          for (final lvl in crossedLevels) {
            _activePulses.add(_PulseEvent(id: _pulseIdCounter++, level: lvl));
          }
        });
        if (crossedLevels.isNotEmpty) HapticFeedback.lightImpact();
        _scrollToLevel(_displayedLevel);
      });

    _climbController.forward().whenComplete(() {
      final leveledUp = ref
          .read(levelAcknowledgementProvider.notifier)
          .consumeLevelUp(currentLevel);
      if (leveledUp && mounted) {
        final info = ref.read(levelInfoProvider).valueOrNull;
        if (info != null) {
          LevelUpFlow.showLevelUpOverlay(context, info);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final levelAsync = ref.watch(levelInfoProvider);
    final accentColor = RankTier.forLevel(_displayedLevel.round()).color;

    // FIX: antes `_runClimbAnimation` solo se llamaba una vez, desde
    // `_onFirstFrame` en `initState`. Si el XP cambiaba con la pantalla
    // ya abierta (ej. panel de debug), `info.level` sí se actualizaba
    // pero `_displayedLevel` -- lo que realmente posiciona al ciclista
    // y al camino -- se quedaba clavado, y solo se corregía al salir y
    // volver a entrar (lo que reinicia el estado). Con este listener,
    // cualquier cambio real de nivel mientras la pantalla está abierta
    // relanza la animación de subida (o bajada, si el debug resta XP).
    ref.listen<AsyncValue<LevelInfo>>(levelInfoProvider, (previous, next) {
      final newLevel = next.valueOrNull?.level;
      if (newLevel == null) return;
      if (_lastKnownProviderLevel != null && newLevel != _lastKnownProviderLevel) {
        _runClimbAnimation(newLevel);
      }
      _lastKnownProviderLevel = newLevel;
    });

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: levelAsync.maybeWhen(
          data: (info) => Text('Tu subida · Nivel ${info.level}'),
          orElse: () => const Text('Tu subida'),
        ),
        actions: [
          IconButton(
            tooltip: 'Tu colección',
            icon: const Icon(Icons.collections_bookmark_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClimbCollectionScreen()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: XpDebugEntryButton()),
          ),
        ],
      ),
      body: levelAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(
          child: Text(
            'No se pudo cargar tu progreso.',
            style: TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ),
        data: (info) => Stack(
          children: [
            // Cielo fijo (no hace scroll): cambia de tono con la
            // altitud real a medida que el ciclista avanza -- verde de
            // valle abajo, dorado/gris de páramo arriba.
            Positioned.fill(child: _SkyBackdrop(progressFraction: _progressFraction)),
            _ClimbBody(
              currentLevel: info.level,
              displayedLevel: _displayedLevel,
              contentHeight: _contentHeight,
              scrollController: _scrollController,
              scrollOffset: _scrollOffset,
              xForLevel: _xForLevel,
              yFromTopForLevel: _yFromTopForLevel,
              isClimbing: _climbController.isAnimating,
              activePulses: _activePulses,
              onPulseDone: _onPulseDone,
            ),
            // HUD de altimetría real, siempre visible arriba a la
            // izquierda (no se va con el scroll).
            Positioned(
              top: 0,
              left: 12,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevationProfileOverlay(
                    progressFraction: _progressFraction,
                    accentColor: accentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClimbBody extends StatelessWidget {
  final int currentLevel;
  final double displayedLevel;
  final double contentHeight;
  final ScrollController scrollController;
  final ValueNotifier<double> scrollOffset;
  final double Function(num level) xForLevel;
  final double Function(num level) yFromTopForLevel;
  final bool isClimbing;
  final List<_PulseEvent> activePulses;
  final void Function(int id) onPulseDone;

  const _ClimbBody({
    required this.currentLevel,
    required this.displayedLevel,
    required this.contentHeight,
    required this.scrollController,
    required this.scrollOffset,
    required this.xForLevel,
    required this.yFromTopForLevel,
    required this.isClimbing,
    required this.activePulses,
    required this.onPulseDone,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      controller: scrollController,
      child: SizedBox(
        height: contentHeight,
        width: width,
        child: Stack(
          children: [
            // Fondo en capas (parallax), cada una a distinta velocidad
            // y con una leve inclinación 3D para dar sensación real de
            // profundidad, no solo de imágenes planas apiladas.
            ValueListenableBuilder<double>(
              valueListenable: scrollOffset,
              builder: (context, offset, _) => _ParallaxBackground(
                width: width,
                height: contentHeight,
                scrollOffset: offset,
                currentLevel: currentLevel,
              ),
            ),
            // Carretera + puntos de interés.
            CustomPaint(
              size: Size(width, contentHeight),
              painter: _RoadPainter(
                width: width,
                currentLevel: currentLevel,
                xForLevel: xForLevel,
                yFromTopForLevel: yFromTopForLevel,
              ),
            ),
            for (final poi in ClimbRoute.points)
              _PoiMarker(
                poi: poi,
                x: width / 2 + xForLevel(poi.level),
                y: yFromTopForLevel(poi.level),
                isCurrent: poi.level == currentLevel,
                isCompleted: poi.level < currentLevel,
              ),
            // El ciclista, pedaleando de verdad e interpolado
            // suavemente entre niveles. Pedalea más rápido mientras
            // avanza de un nivel a otro (ráfaga), y a ritmo normal
            // cuando está quieto en su nivel actual. El tierIndex
            // define el skin del maillot (Fase 3).
            _CyclistMarker(
              x: width / 2 + xForLevel(displayedLevel),
              y: yFromTopForLevel(displayedLevel),
              color: RankTier.forLevel(displayedLevel.round()).color,
              cadence: isClimbing ? 2.6 : 1.0,
              tierIndex: RankTier.indexOfRank(
                RankTier.forLevel(displayedLevel.round()).rank,
              ),
              isClimbing: isClimbing,
            ),
            // Fase 4: un anillo que se expande y se desvanece por cada
            // POI real que se acaba de cruzar -- feedback constante a
            // lo largo de todo el trayecto, no solo al final.
            for (final pulse in activePulses)
              _PoiPulse(
                key: ValueKey('poi-pulse-${pulse.id}'),
                center: Offset(
                  width / 2 + xForLevel(pulse.level),
                  yFromTopForLevel(pulse.level),
                ),
                color: RankTier.forLevel(pulse.level).color,
                onDone: () => onPulseDone(pulse.id),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cielo fijo respecto a la pantalla (no se mueve con el scroll de la
/// subida) que interpola tono según [progressFraction]: verde-dorado
/// de valle bajo cerca de la base, azul/gris frío de páramo con niebla
/// cerca de la cima -- el mismo tipo de recurso que usan los juegos de
/// "endless runner" para vender sensación de altura sin geometría 3D
/// real.
class _SkyBackdrop extends StatelessWidget {
  final double progressFraction;
  const _SkyBackdrop({required this.progressFraction});

  @override
  Widget build(BuildContext context) {
    final t = progressFraction.clamp(0.0, 1.0);

    const valleyTop = Color(0xFF16241C);
    const valleyBottom = Color(0xFF223A2A);
    const paramoTop = Color(0xFF0E1A26);
    const paramoBottom = Color(0xFF2B3B45);

    final topColor = Color.lerp(valleyTop, paramoTop, t)!;
    final bottomColor = Color.lerp(valleyBottom, paramoBottom, t)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor, AppColors.panelBackground],
          stops: const [0, 0.6, 1],
        ),
      ),
    );
  }
}

/// Fondo con 4 capas a distinta velocidad de scroll (parallax) más una
/// leve inclinación en perspectiva (`Transform` con matriz 3D) para
/// que las montañas se sientan como un plano visto en ángulo y no como
/// una imagen plana pegada a la pantalla. La niebla de la capa
/// delantera aumenta con la altura del contenido para simular el
/// páramo cerca de la cima.
class _ParallaxBackground extends StatelessWidget {
  final double width;
  final double height;
  final double scrollOffset;
  final int currentLevel;

  const _ParallaxBackground({
    required this.width,
    required this.height,
    required this.scrollOffset,
    required this.currentLevel,
  });

  /// Inclina una capa levemente hacia "atrás" en el eje X, como si la
  /// cámara mirara la montaña un poco desde abajo -- truco barato de
  /// pseudo-3D que no requiere motor de render aparte.
  Widget _tilted({required Widget child, double angle = 0.045}) {
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0016)
        ..rotateX(angle),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Capa 1 (más lejana, más grande): cordillera de fondo.
        Positioned(
          top: -scrollOffset * 0.15,
          left: 0,
          right: 0,
          child: _tilted(
            angle: 0.03,
            child: CustomPaint(
              size: Size(width, height),
              painter: _MountainLayerPainter(
                amplitude: 130,
                baseline: 0.22,
                color: Colors.white.withValues(alpha: 0.045),
                wavelength: 340,
              ),
            ),
          ),
        ),
        // Capa 2: cordillera media.
        Positioned(
          top: -scrollOffset * 0.30,
          left: 0,
          right: 0,
          child: _tilted(
            angle: 0.045,
            child: CustomPaint(
              size: Size(width, height),
              painter: _MountainLayerPainter(
                amplitude: 170,
                baseline: 0.32,
                color: Colors.white.withValues(alpha: 0.07),
                wavelength: 240,
              ),
            ),
          ),
        ),
        // Capa 3: cerros cercanos, más grandes y con más contraste.
        Positioned(
          top: -scrollOffset * 0.55,
          left: 0,
          right: 0,
          child: _tilted(
            angle: 0.06,
            child: CustomPaint(
              size: Size(width, height),
              painter: _MountainLayerPainter(
                amplitude: 210,
                baseline: 0.44,
                color: Colors.white.withValues(alpha: 0.11),
                wavelength: 160,
              ),
            ),
          ),
        ),
        // Capa 4 (más cercana, se mueve más rápido que el scroll para
        // dar sensación de estar "al lado" de la carretera): línea de
        // árboles / vegetación de páramo.
        Positioned(
          top: -scrollOffset * 0.8,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: Size(width, height),
            painter: _MountainLayerPainter(
              amplitude: 46,
              baseline: 0.55,
              color: Colors.black.withValues(alpha: 0.22),
              wavelength: 70,
              jagged: true,
            ),
          ),
        ),
        // Niebla / neblina de páramo: aparece hacia la parte alta del
        // contenido (independiente del scroll), donde ya toca la
        // altitud real de frailejones y niebla frecuente.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height * 0.5,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MountainLayerPainter extends CustomPainter {
  final double amplitude;
  final double baseline;
  final Color color;
  final double wavelength;
  final bool jagged;

  const _MountainLayerPainter({
    required this.amplitude,
    required this.baseline,
    required this.color,
    required this.wavelength,
    this.jagged = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()..moveTo(0, size.height);

    final step = jagged ? size.width / 40 : 8.0;
    for (var x = 0.0; x <= size.width; x += step) {
      final noise = jagged
          ? amplitude * 0.35 * math.sin((x / (wavelength * 0.3)) * 2 * math.pi)
          : 0.0;
      final y = size.height * baseline +
          amplitude * math.sin((x / wavelength) * 2 * math.pi) +
          noise;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MountainLayerPainter oldDelegate) => false;
}

/// La carretera: una curva serpenteante de nivel 1 (abajo) a
/// [ClimbRoute.maxLevel] (arriba), más angosta cuanto más "lejos" (más
/// arriba) para dar sensación de perspectiva, con una línea central
/// discontinua tipo carretera real.
class _RoadPainter extends CustomPainter {
  final double width;
  final int currentLevel;
  final double Function(num level) xForLevel;
  final double Function(num level) yFromTopForLevel;

  const _RoadPainter({
    required this.width,
    required this.currentLevel,
    required this.xForLevel,
    required this.yFromTopForLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const steps = 400;
    final maxLevel = ClimbRoute.maxLevel.toDouble();

    for (var i = 0; i <= steps; i++) {
      final level = 1 + (maxLevel - 1) * (i / steps);
      final x = size.width / 2 + xForLevel(level);
      final y = yFromTopForLevel(level);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Sombra de la carretera (vende que está "elevada" sobre el
    // terreno, no pintada plana encima del fondo).
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 62
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path.shift(const Offset(0, 6)), shadow);

    // Angosta la carretera hacia arriba (perspectiva): más ancha abajo.
    for (var pass = 0; pass < 2; pass++) {
      final asphalt = Paint()
        ..color = Colors.white.withValues(alpha: pass == 0 ? 0.10 : 0.05)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = pass == 0 ? 46 : 58;
      canvas.drawPath(path, asphalt);
    }

    // Fase 3 -- "asfalto más cuidado" por rango: en vez de una sola
    // línea central pareja de punta a punta, cada tramo se dibuja con
    // el estilo de su propio rango (RankTier.minLevel/maxLevel). En
    // rangos bajos la línea es más tenue y los guiones más cortos e
    // irregulares (asfalto de trocha); en rangos altos los guiones son
    // más largos, más definidos, y se le suma un filo sutil con el
    // color del rango pegado al borde de la vía -- la sensación de una
    // carretera cada vez mejor pavimentada a medida que se sube.
    for (final tier in RankTier.all) {
      final segStart = tier.minLevel.toDouble().clamp(1, maxLevel).toDouble();
      final segEnd = tier.maxLevel.toDouble().clamp(1, maxLevel).toDouble();
      if (segEnd <= segStart) continue;
      final tierIndex = RankTier.indexOfRank(tier.rank);
      final segmentPath = _segmentPath(size, segStart, segEnd);

      if (tierIndex >= 2) {
        final edgeTint = Paint()
          ..color = tier.color.withValues(alpha: 0.04 + tierIndex * 0.022)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 50;
        canvas.drawPath(segmentPath, edgeTint);
      }

      final dashLength = 12.0 + tierIndex * 2.2;
      final gapLength = (13.0 - tierIndex * 1.6).clamp(4.0, 13.0);
      final centerLine = Paint()
        ..color = Color.lerp(Colors.white, tier.color, tierIndex * 0.09)!
            .withValues(alpha: 0.14 + tierIndex * 0.035)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + tierIndex * 0.18;
      canvas.drawPath(
        _dashPath(segmentPath, dashLength: dashLength, gapLength: gapLength),
        centerLine,
      );
    }
  }

  /// Sub-tramo de la carretera entre dos niveles (en vez de toda la
  /// subida) -- usado por el estilo "por rango" de la línea central y
  /// el filo de asfalto (Fase 3).
  Path _segmentPath(Size size, double fromLevel, double toLevel) {
    final segmentPath = Path();
    const steps = 120;
    for (var i = 0; i <= steps; i++) {
      final level = fromLevel + (toLevel - fromLevel) * (i / steps);
      final x = size.width / 2 + xForLevel(level);
      final y = yFromTopForLevel(level);
      if (i == 0) {
        segmentPath.moveTo(x, y);
      } else {
        segmentPath.lineTo(x, y);
      }
    }
    return segmentPath;
  }

  Path _dashPath(Path source, {required double dashLength, required double gapLength}) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        final next = math.min(distance + length, metric.length);
        if (draw) {
          dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        }
        distance = next;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) =>
      oldDelegate.currentLevel != currentLevel;
}

/// Un punto de interés sobre la carretera: bloqueado (gris + candado),
/// completado (color del rango + check) o el actual (resplandor).
/// Ahora también (Fase 2) marca el POI como "descubierto" la primera
/// vez que se toca estando desbloqueado, y muestra un punto de aviso
/// mientras no se haya descubierto todavía.
class _PoiMarker extends ConsumerWidget {
  final ClimbPointOfInterest poi;
  final double x;
  final double y;
  final bool isCurrent;
  final bool isCompleted;

  const _PoiMarker({
    required this.poi,
    required this.x,
    required this.y,
    required this.isCurrent,
    required this.isCompleted,
  });

  bool get _isLocked => !isCurrent && !isCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _isLocked ? AppColors.textSecondaryOnPanel : poi.tier.color;
    final collected = ref.watch(climbCollectiblesProvider).valueOrNull ?? {};
    final isUndiscovered = !_isLocked && !collected.contains(poi.level);

    return Positioned(
      left: x - 22,
      top: y - 22,
      child: GestureDetector(
        onTap: () => _openPoi(context, ref),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLocked
                    ? Colors.black.withValues(alpha: 0.35)
                    : color.withValues(alpha: 0.2),
                border: Border.all(
                  color: color.withValues(alpha: _isLocked ? 0.4 : 1),
                  width: isCurrent ? 3 : 1.5,
                ),
                boxShadow: isCurrent
                    ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 16)]
                    : null,
              ),
              child: Icon(
                _isLocked ? Icons.lock_outline : poi.tier.icon,
                color: color,
                size: 18,
              ),
            ),
            // Punto de aviso "nuevo por descubrir" -- un POI ya
            // alcanzado que todavía no se ha tocado ni una vez.
            if (isUndiscovered)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentSlope,
                    border: Border.all(color: AppColors.panelBackground, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPoi(BuildContext context, WidgetRef ref) async {
    var isNew = false;
    if (!_isLocked) {
      isNew = await ref
          .read(climbCollectiblesProvider.notifier)
          .markDiscovered(poi.level);
    }
    if (!context.mounted) return;
    _showPoiSheet(context, isNew: isNew);
  }

  void _showPoiSheet(BuildContext context, {required bool isNew}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.panelBackground,
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
                  _isLocked ? Icons.lock_outline : poi.tier.icon,
                  color: _isLocked ? AppColors.textSecondaryOnPanel : poi.tier.color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    poi.name,
                    style: const TextStyle(
                      color: AppColors.textPrimaryOnPanel,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentSlope.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '¡Nuevo!',
                      style: TextStyle(
                        color: AppColors.accentSlope,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Nivel ${poi.level} · ${poi.tier.label} · km ${poi.distanceKm.toStringAsFixed(1)}',
              style: TextStyle(color: poi.tier.color, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              _isLocked ? 'Todavía no llegas aquí. ${poi.stat}' : poi.stat,
              style: const TextStyle(
                color: AppColors.textSecondaryOnPanel,
                fontSize: 13,
              ),
            ),
            if (!_isLocked) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: poi.tier.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_stories_outlined,
                        color: poi.tier.color.withValues(alpha: 0.8), size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        poi.discoveryText,
                        style: const TextStyle(
                          color: AppColors.textSecondaryOnPanel,
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
}

class _CyclistMarker extends StatelessWidget {
  final double x;
  final double y;
  final Color color;
  final double cadence;
  final int tierIndex;
  final bool isClimbing;

  const _CyclistMarker({
    required this.x,
    required this.y,
    required this.color,
    required this.cadence,
    required this.tierIndex,
    required this.isClimbing,
  });

  @override
  Widget build(BuildContext context) {
    // Antes: un Container circular con halo de color rodeando al
    // ciclista, dando sensación de "burbuja" genérica flotando sobre
    // el camino. Ahora el propio PedalingCyclist dibuja su sombra de
    // contacto con el piso, así que el ciclista se apoya en la
    // carretera en vez de flotar sobre una burbuja de color.
    const size = 70.0;
    return Positioned(
      left: x - size / 2,
      top: y - size * 0.92,
      child: PedalingCyclist(
        color: color,
        size: size,
        cadence: cadence,
        tierIndex: tierIndex,
        // Fase de vista trasera: mientras sube de nivel, el ciclista
        // gira y se ve de espaldas (estilo cámara detrás del
        // personaje); en reposo vuelve a la vista lateral de siempre.
        isClimbing: isClimbing,
      ),
    );
  }
}

/// Un evento de "acabo de cruzar este POI" (Fase 4) -- vive en memoria
/// solo mientras dura su propia animación en [_PoiPulse]; [id] es único
/// por instancia para poder tener varios pulsos simultáneos (ej. si un
/// salto grande de XP cruza varios niveles en el mismo frame) sin que
/// se pisen entre sí.
class _PulseEvent {
  final int id;
  final int level;
  const _PulseEvent({required this.id, required this.level});
}

/// Anillo que se expande y se desvanece una sola vez sobre un punto de
/// interés real recién cruzado -- el "feedback constante" de la Fase 4,
/// distinto del chip "¡Nuevo!" de la Fase 2 (que solo aparece la
/// primera vez que se descubre un punto). Se retira solo del árbol al
/// terminar, vía [onDone].
class _PoiPulse extends StatefulWidget {
  final Offset center;
  final Color color;
  final VoidCallback onDone;

  const _PoiPulse({
    required this.center,
    required this.color,
    required this.onDone,
    super.key,
  });

  @override
  State<_PoiPulse> createState() => _PoiPulseState();
}

class _PoiPulseState extends State<_PoiPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward().whenComplete(() {
        if (mounted) widget.onDone();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value);
        final radius = 22 + t * 34;
        final ringOpacity = (1 - t).clamp(0.0, 1.0);
        return Positioned(
          left: widget.center.dx - radius,
          top: widget.center.dy - radius,
          child: IgnorePointer(
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(alpha: ringOpacity * 0.9),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: ringOpacity * 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
