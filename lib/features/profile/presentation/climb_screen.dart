import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/level_info.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/climb_route.dart';
import '../domain/rank_tier.dart';
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
  static const double _levelSpacing = 150;
  static const double _horizontalAmplitude = 80;
  static const double _topPadding = 220;
  static const double _bottomPadding = 160;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);
  late final AnimationController _climbController;
  double _displayedLevel = 1;

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

  double get _contentHeight =>
      (ClimbRoute.maxLevel - 1) * _levelSpacing + _topPadding + _bottomPadding;

  double _xForLevel(num level) =>
      _horizontalAmplitude * math.sin(level * 0.9);

  double _yFromTopForLevel(num level) =>
      (ClimbRoute.maxLevel - level) * _levelSpacing + _topPadding;

  /// Progreso 0..1 sobre la subida real (0 = nivel 1, 1 = nivel máximo)
  /// -- es lo que alimenta el mini-perfil de altimetría y el degradado
  /// de cielo, para que ambos avancen en sincronía con el ciclista.
  double get _progressFraction =>
      ClimbRoute.maxLevel <= 1 ? 0 : (_displayedLevel - 1) / (ClimbRoute.maxLevel - 1);

  void _onFirstFrame() {
    final currentLevel = ref.read(levelInfoProvider).valueOrNull?.level ?? 1;

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
    _scrollToLevel(startLevel);

    if (startLevel >= currentLevel) {
      // Nada que animar (primera vez que se abre, o ya está al día):
      // solo confirmamos el nivel actual como "reconocido".
      ref.read(levelAcknowledgementProvider.notifier).consumeLevelUp(currentLevel);
      return;
    }

    final tween = Tween<double>(begin: startLevel, end: currentLevel.toDouble());
    _climbController
      ..reset()
      ..addListener(() {
        setState(() => _displayedLevel = tween.evaluate(_climbController));
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
        actions: const [
          Padding(
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

  const _ClimbBody({
    required this.currentLevel,
    required this.displayedLevel,
    required this.contentHeight,
    required this.scrollController,
    required this.scrollOffset,
    required this.xForLevel,
    required this.yFromTopForLevel,
    required this.isClimbing,
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
            // cuando está quieto en su nivel actual.
            _CyclistMarker(
              x: width / 2 + xForLevel(displayedLevel),
              y: yFromTopForLevel(displayedLevel),
              color: RankTier.forLevel(displayedLevel.round()).color,
              cadence: isClimbing ? 2.6 : 1.0,
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

    final centerLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(
      _dashPath(path, dashLength: 14, gapLength: 12),
      centerLine,
    );
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
class _PoiMarker extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final color = _isLocked ? AppColors.textSecondaryOnPanel : poi.tier.color;

    return Positioned(
      left: x - 22,
      top: y - 22,
      child: GestureDetector(
        onTap: () => _showPoiSheet(context),
        child: Container(
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
      ),
    );
  }

  void _showPoiSheet(BuildContext context) {
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

  const _CyclistMarker({
    required this.x,
    required this.y,
    required this.color,
    required this.cadence,
  });

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    return Positioned(
      left: x - size / 2,
      top: y - size * 0.95,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.18),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20)],
        ),
        child: PedalingCyclist(color: color, size: size, cadence: cadence),
      ),
    );
  }
}
