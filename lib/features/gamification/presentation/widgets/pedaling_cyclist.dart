import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

/// Los gestos que el ciclista puede hacer -- lo que se equipa en el
/// Vestidor (slot `gesto`). `danzar` y `beber` van siempre; el resto se
/// desbloquean.
enum CyclistGesture { danzar, beber, wheelie, bandera, aero }

/// Traduce el id de una pieza de gesto del catálogo a [CyclistGesture].
CyclistGesture? cyclistGestureForKitId(String id) => switch (id) {
  'gesto_danzar' => CyclistGesture.danzar,
  'gesto_beber' => CyclistGesture.beber,
  'gesto_wheelie' => CyclistGesture.wheelie,
  'gesto_bandera' => CyclistGesture.bandera,
  'gesto_aero' => CyclistGesture.aero,
  _ => null,
};

/// Lo que se ve puesto: qué patrón de maillot, qué bici y qué gestos.
/// Lo resuelve quien llama (a partir del kit equipado) para que
/// [PedalingCyclist] no tenga que conocer el catálogo.
class CyclistKitVisual {
  /// 0..5 = maillot de rango; 6 = lunares, 7 = aero, 8 = lana.
  final int jerseyKind;

  /// 0..5 = bici de rango; 6 = ligera, 7 = contrarreloj, 8 = perfil,
  /// 9 = acero.
  final int bikeKind;

  /// Color del cuadro y las ruedas de la bici -- distinto del color del
  /// maillot ([PedalingCyclist.color]).
  final Color bikeColor;

  final Set<CyclistGesture> gestures;

  const CyclistKitVisual({
    this.jerseyKind = 0,
    this.bikeKind = 0,
    this.bikeColor = const Color(0xFF8C96A8),
    this.gestures = const {CyclistGesture.danzar, CyclistGesture.beber},
  });

  /// El kit "de rango": maillot + bici del tier, gestos base.
  const CyclistKitVisual.rank(int tier)
    : jerseyKind = tier,
      bikeKind = tier,
      bikeColor = const Color(0xFF8C96A8),
      gestures = const {CyclistGesture.danzar, CyclistGesture.beber};
}

/// Pose momentánea del ciclista, encima del pedaleo base -- corre todo
/// el tiempo (vista lateral en reposo o vista trasera subiendo), no
/// solo mientras sube de nivel.
enum _CyclistPose { seated, danzar, beber, wheelie, bandera, aero }

_CyclistPose _poseForGesture(CyclistGesture g) => switch (g) {
  CyclistGesture.danzar => _CyclistPose.danzar,
  CyclistGesture.beber => _CyclistPose.beber,
  CyclistGesture.wheelie => _CyclistPose.wheelie,
  CyclistGesture.bandera => _CyclistPose.bandera,
  CyclistGesture.aero => _CyclistPose.aero,
};

/// Dibuja un trazo con contorno oscuro por debajo y el color relleno
/// por encima -- efecto "sticker" usado en ambas vistas (lateral y
/// trasera) para que las líneas se lean bien sobre cualquier fondo.
void _outlinedStroke(Canvas canvas, Path path, double width, Color fillColor) {
  canvas.drawPath(
    path,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width * 1.7,
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width,
  );
}

/// Estrella de 5 puntas -- usada por el skin de Leyenda en ambas
/// vistas.
void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
  final path = Path();
  for (var i = 0; i < 5; i++) {
    final outerAngle = -math.pi / 2 + i * (2 * math.pi / 5);
    final innerAngle = outerAngle + math.pi / 5;
    final outer =
        center + Offset(math.cos(outerAngle), math.sin(outerAngle)) * radius;
    final inner =
        center +
        Offset(math.cos(innerAngle), math.sin(innerAngle)) * (radius * 0.42);
    if (i == 0) {
      path.moveTo(outer.dx, outer.dy);
    } else {
      path.lineTo(outer.dx, outer.dy);
    }
    path.lineTo(inner.dx, inner.dy);
  }
  path.close();
  canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.95));
}

/// Ciclista animado "pedaleando" de verdad, dibujado con
/// [CustomPainter], recoloreable según el rango actual.
///
/// Tiene dos vistas completas:
/// - Lateral (de perfil): la de siempre, usada en reposo.
/// - Trasera (de espaldas, cámara detrás del personaje): se activa
///   mientras [isClimbing] es true, con un giro de transición entre
///   una y otra -- ver [_flipController].
///
/// [cadence] controla qué tan rápido pedalea: 1 = ritmo normal en
/// reposo, valores mayores (ej. 2.6) dan una ráfaga de pedaleo rápido.
class PedalingCyclist extends StatefulWidget {
  final Color color;
  final double size;
  final double cadence;

  /// Índice del rango actual (0 = Novato ... 5 = Leyenda). Se usa como
  /// respaldo cuando no se pasa [kit] (color del casco/detalles).
  final int tierIndex;

  /// Lo que lleva puesto: patrón de maillot, bici y gestos. Si es nulo
  /// se deriva del rango ([CyclistKitVisual.rank]).
  final CyclistKitVisual? kit;

  /// Vestidor: recorre los gestos equipados en bucle corto para
  /// mostrarlos, en vez de dejarlos al azar.
  final bool demoGestures;

  /// Fuerza un gesto concreto y lo mantiene (sin ciclo aleatorio) --
  /// lo usa la cinemática de nivel para el wheelie de perfil.
  final CyclistGesture? forceGesture;

  /// True mientras el ciclista está en plena animación de subida de
  /// nivel -- dispara el giro hacia la vista trasera. False en reposo,
  /// gira de vuelta a la vista lateral.
  final bool isClimbing;

  const PedalingCyclist({
    super.key,
    required this.color,
    this.size = 64,
    this.cadence = 1,
    this.tierIndex = 0,
    this.kit,
    this.demoGestures = false,
    this.forceGesture,
    this.isClimbing = false,
  });

  CyclistKitVisual get effectiveKit => kit ?? CyclistKitVisual.rank(tierIndex);

  @override
  State<PedalingCyclist> createState() => _PedalingCyclistState();
}

class _PedalingCyclistState extends State<PedalingCyclist>
    with TickerProviderStateMixin {
  static const _baseDuration = Duration(milliseconds: 900);
  late final AnimationController _controller;

  /// Controla el ciclo completo (entrada + sostenida + salida) de la
  /// pose actual, ver [_poseAmount]. Se relanza con duración distinta
  /// según la pose elegida cada vez.
  late final AnimationController _poseController;
  _CyclistPose _pose = _CyclistPose.seated;
  Timer? _poseScheduleTimer;
  final math.Random _random = math.Random();

  /// 0 = vista lateral, 1 = vista trasera. Anima el giro entre las dos
  /// cada vez que [PedalingCyclist.isClimbing] cambia.
  late final AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.cadence),
    )..repeat();
    _poseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: widget.isClimbing ? 1 : 0,
    );

    final forced = widget.forceGesture;
    if (forced != null) {
      _pose = _poseForGesture(forced);
      _poseController
        ..duration = const Duration(milliseconds: 550)
        ..forward();
    } else {
      // Las poses corren todo el tiempo, tanto en la vista lateral de
      // reposo como en la trasera de subida.
      _schedulePose();
    }
  }

  Duration _durationFor(double cadence) => Duration(
    milliseconds: (_baseDuration.inMilliseconds / cadence.clamp(0.05, 4))
        .round(),
  );

  /// Progreso 0..1 de "qué tan metido" está en la pose actual, con
  /// entrada y salida suaves y un tramo sostenido en el medio.
  double get _poseAmount {
    if (_pose == _CyclistPose.seated) return 0;
    final t = _poseController.value;
    if (widget.forceGesture != null) {
      // Gesto forzado: entra y se queda.
      return t < 0.6 ? Curves.easeOut.transform(t / 0.6) : 1.0;
    }
    if (t < 0.22) return Curves.easeOut.transform(t / 0.22);
    if (t < 0.75) return 1.0;
    return 1.0 - Curves.easeIn.transform((t - 0.75) / 0.25);
  }

  int _demoIndex = 0;

  /// Poses disponibles = los gestos equipados. Puede quedar vacío: si el
  /// usuario apagó todos los gestos, el ciclista sólo pedalea sentado.
  List<_CyclistPose> get _posePool {
    final gestures = widget.effectiveKit.gestures;
    return [
      for (final g in CyclistGesture.values)
        if (gestures.contains(g)) _poseForGesture(g),
    ];
  }

  void _schedulePose() {
    _poseScheduleTimer?.cancel();
    _poseScheduleTimer = Timer(
      Duration(
        milliseconds: widget.demoGestures ? 700 : 1100 + _random.nextInt(1700),
      ),
      _startPose,
    );
  }

  void _startPose() {
    if (!mounted || widget.forceGesture != null) return;
    final pool = _posePool;
    if (pool.isEmpty) {
      // Sin gestos equipados: nada que hacer, se reintenta más tarde
      // por si el usuario activa alguno.
      _schedulePose();
      return;
    }
    final _CyclistPose pose;
    if (widget.demoGestures) {
      pose = pool[_demoIndex % pool.length];
      _demoIndex++;
    } else {
      pose = pool[_random.nextInt(pool.length)];
    }

    final duration = switch (pose) {
      _CyclistPose.beber => const Duration(milliseconds: 1800),
      _CyclistPose.bandera => const Duration(milliseconds: 2000),
      _CyclistPose.wheelie => const Duration(milliseconds: 1400),
      _ => const Duration(milliseconds: 1500),
    };

    setState(() => _pose = pose);
    _poseController
      ..duration = duration
      ..forward(from: 0).whenComplete(() {
        if (!mounted) return;
        setState(() => _pose = _CyclistPose.seated);
        _schedulePose();
      });
  }

  @override
  void didUpdateWidget(covariant PedalingCyclist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cadence != widget.cadence) {
      _controller.duration = _durationFor(widget.cadence);
      if (!_controller.isAnimating) _controller.repeat();
    }
    if (oldWidget.isClimbing != widget.isClimbing) {
      if (widget.isClimbing) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
    if (oldWidget.forceGesture != widget.forceGesture) {
      final forced = widget.forceGesture;
      _poseScheduleTimer?.cancel();
      if (forced != null) {
        setState(() => _pose = _poseForGesture(forced));
        _poseController
          ..duration = const Duration(milliseconds: 550)
          ..forward(from: 0);
      } else {
        setState(() => _pose = _CyclistPose.seated);
        _schedulePose();
      }
      return;
    }
    // Si cambian los gestos equipados (ej. desde el Vestidor), reinicia
    // el ciclo de poses para que se note enseguida.
    if (widget.forceGesture == null &&
        !setEquals(
          oldWidget.effectiveKit.gestures,
          widget.effectiveKit.gestures,
        )) {
      _demoIndex = 0;
      if (_pose == _CyclistPose.seated) _schedulePose();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _poseController.dispose();
    _flipController.dispose();
    _poseScheduleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _controller,
        _poseController,
        _flipController,
      ]),
      builder: (context, _) {
        final flip = _flipController.value;
        final angle = flip * math.pi;
        final showRear = angle > math.pi / 2;

        final kit = widget.effectiveKit;
        final painter = showRear
            ? _CyclistRearPainter(
                color: widget.color,
                phase: _controller.value * 2 * math.pi,
                jerseyKind: kit.jerseyKind,
                bikeKind: kit.bikeKind,
                bikeColor: kit.bikeColor,
                pose: _pose,
                poseAmount: _poseAmount,
              )
            : _CyclistPainter(
                color: widget.color,
                phase: _controller.value * 2 * math.pi,
                jerseyKind: kit.jerseyKind,
                bikeKind: kit.bikeKind,
                bikeColor: kit.bikeColor,
                pose: _pose,
                poseAmount: _poseAmount,
              );

        final content = CustomPaint(
          size: Size.square(widget.size),
          painter: painter,
        );

        // Giro tipo "tarjeta": el contenedor externo rota 0->pi según
        // el flip; el contenido interno se pre-rota pi cuando toca
        // mostrar la vista trasera, para que no se vea en espejo al
        // pasar de los 90 grados.
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angle),
          child: Transform(
            alignment: Alignment.center,
            transform: showRear
                ? (Matrix4.identity()..rotateY(math.pi))
                : Matrix4.identity(),
            child: content,
          ),
        );
      },
    );
  }
}

/// -------------------- Vista lateral (perfil, reposo) --------------------

class _CyclistPainter extends CustomPainter {
  final Color color;
  final double phase;
  final int jerseyKind;
  final int bikeKind;
  final Color bikeColor;
  final _CyclistPose pose;
  final double poseAmount;

  const _CyclistPainter({
    required this.color,
    required this.phase,
    this.jerseyKind = 0,
    this.bikeKind = 0,
    this.bikeColor = const Color(0xFF8C96A8),
    this.pose = _CyclistPose.seated,
    this.poseAmount = 0,
  });

  double _amt(_CyclistPose p) => pose == p ? poseAmount : 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    final standingAmount = _amt(_CyclistPose.danzar);
    final drinkingAmount = _amt(_CyclistPose.beber);
    final banderaAmount = _amt(_CyclistPose.bandera);
    final aeroAmount = _amt(_CyclistPose.aero);
    final wheelieAmount = _amt(_CyclistPose.wheelie);

    // -------- Anclas de la bici --------
    final rearAxle = Offset(s * 0.16, s * 0.76);
    final frontAxle = Offset(s * 0.80, s * 0.76);
    final wheelR = s * 0.175;
    final bb = Offset(s * 0.40, s * 0.64); // pedalier
    final seatTop = Offset(s * 0.32, s * 0.46);
    final headTop = Offset(s * 0.64, s * 0.34); // tope del tubo de dirección
    final headBottom = Offset(s * 0.68, s * 0.46); // corona de la horquilla
    final crankR = s * 0.085;

    // Sombra de contacto -- se dibuja antes del wheelie para que no
    // rote con la bici.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          (rearAxle.dx + frontAxle.dx) / 2,
          rearAxle.dy + wheelR * 0.6,
        ),
        width: s * (0.72 - wheelieAmount * 0.22),
        height: s * 0.05,
      ),
      Paint()
        ..color = Colors.black.withValues(
          alpha: 0.28 * (1 - wheelieAmount * 0.4),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Wheelie: toda la bici + ciclista gira un poco alrededor del eje
    // trasero y el frente se levanta.
    canvas.save();
    if (wheelieAmount > 0) {
      canvas.translate(rearAxle.dx, rearAxle.dy);
      canvas.rotate(-wheelieAmount * 0.42);
      canvas.translate(-rearAxle.dx, -rearAxle.dy);
    }

    // -------- Anclas del ciclista --------
    final crouch = aeroAmount * s * 0.05;
    final hip = seatTop
        .translate(0, -s * 0.02)
        .translate(standingAmount * s * 0.012, -standingAmount * s * 0.05);
    final shoulder = Offset(
      s * 0.52 + aeroAmount * s * 0.03,
      s * 0.20 - standingAmount * s * 0.018 + crouch,
    );
    final headCenter = Offset(
      s * 0.58 + aeroAmount * s * 0.04,
      s * 0.09 -
          standingAmount * s * 0.015 -
          drinkingAmount * s * 0.012 +
          crouch,
    );
    final headR = s * 0.09;

    // -------- Manubrio caído --------
    final stemTop = headTop.translate(s * 0.015, -s * 0.03);
    final barClamp = stemTop.translate(s * 0.03, -s * 0.005);
    final hoods = barClamp.translate(s * 0.05, s * 0.03);
    final dropEnd = hoods.translate(-s * 0.005, s * 0.09);

    // -------- Estilo de bici según lo equipado --------
    // El color del cuadro/ruedas viene de la BICI (no del maillot).
    final frameColor = bikeColor;
    final isRankBike = bikeKind <= 5;
    // Cuanto mejor la bici, llanta más profunda y menos radios visibles.
    final rimDepthT = isRankBike ? bikeKind / 5 : (bikeKind == 8 ? 1.0 : 0.55);
    final isDiscRear = bikeKind == 7;
    final spokeCount = rimDepthT > 0.72 ? 3 : 5;

    final tirePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * (0.056 - rimDepthT * 0.006);
    final rimPaint = Paint()
      ..color = Color.lerp(
        Colors.white.withValues(alpha: 0.95),
        frameColor,
        rimDepthT * 0.7,
      )!
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * (0.018 + rimDepthT * 0.032);
    final spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012;
    for (final (wheel, isRear) in [(rearAxle, true), (frontAxle, false)]) {
      if (isDiscRear && isRear) {
        // Rueda lenticular (disco sólido) de la de contrarreloj.
        canvas.drawCircle(
          wheel,
          wheelR,
          Paint()..color = const Color(0xFF1B1E26),
        );
        canvas.drawCircle(wheel, wheelR, tirePaint);
        canvas.drawCircle(
          wheel,
          wheelR * 0.5,
          Paint()..color = frameColor.withValues(alpha: 0.6),
        );
      } else {
        canvas.drawCircle(wheel, wheelR, tirePaint);
        canvas.drawCircle(wheel, wheelR, rimPaint);
        for (var i = 0; i < spokeCount; i++) {
          final angle = phase + i * (2 * math.pi / spokeCount);
          final dir = Offset(math.cos(angle), math.sin(angle));
          canvas.drawLine(
            wheel + dir * (wheelR * 0.16),
            wheel + dir * (wheelR * 0.9),
            spokePaint,
          );
        }
      }
      canvas.drawCircle(wheel, s * 0.018, Paint()..color = frameColor);
    }

    // Acero: portabultos + faro.
    if (bikeKind == 9) {
      _outlinedStroke(
        canvas,
        Path()
          ..moveTo(rearAxle.dx - wheelR * 0.6, rearAxle.dy - wheelR * 0.9)
          ..lineTo(rearAxle.dx + wheelR * 0.7, rearAxle.dy - wheelR * 1.0)
          ..moveTo(rearAxle.dx, rearAxle.dy)
          ..lineTo(rearAxle.dx + wheelR * 0.5, rearAxle.dy - wheelR * 1.0),
        s * 0.016,
        frameColor,
      );
      canvas.drawCircle(
        frontAxle.translate(-s * 0.02, -wheelR * 1.4),
        s * 0.022,
        Paint()..color = const Color(0xFFFFE082),
      );
    }

    // Cuadro: tubo superior inclinado + horquilla y vainas con curva.
    final framePath = Path()
      ..moveTo(seatTop.dx, seatTop.dy)
      ..lineTo(headTop.dx, headTop.dy)
      ..moveTo(headBottom.dx, headBottom.dy)
      ..lineTo(bb.dx, bb.dy)
      ..moveTo(seatTop.dx, seatTop.dy)
      ..lineTo(bb.dx, bb.dy)
      ..moveTo(bb.dx, bb.dy)
      ..lineTo(rearAxle.dx, rearAxle.dy)
      ..moveTo(headTop.dx, headTop.dy)
      ..lineTo(headBottom.dx, headBottom.dy)
      ..moveTo(seatTop.dx, seatTop.dy + s * 0.02)
      ..quadraticBezierTo(
        seatTop.dx - s * 0.02,
        (seatTop.dy + rearAxle.dy) / 2,
        rearAxle.dx,
        rearAxle.dy,
      )
      ..moveTo(headBottom.dx, headBottom.dy)
      ..quadraticBezierTo(
        headBottom.dx + s * 0.055,
        (headBottom.dy + frontAxle.dy) / 2,
        frontAxle.dx,
        frontAxle.dy,
      );
    _outlinedStroke(
      canvas,
      framePath,
      s * (bikeKind == 9 ? 0.036 : 0.03),
      frameColor,
    );

    // Cuadro premium: filete claro sobre el tubo diagonal (bicis de
    // rango alto y especiales aero).
    if (bikeKind >= 3) {
      canvas.drawLine(
        Offset.lerp(headBottom, bb, 0.15)!,
        Offset.lerp(headBottom, bb, 0.85)!,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = s * 0.008
          ..strokeCap = StrokeCap.round,
      );
    }

    // Manubrio caído (o de contrarreloj: prolongación aero hacia adelante).
    final barPath = Path()
      ..moveTo(headTop.dx, headTop.dy)
      ..lineTo(stemTop.dx, stemTop.dy)
      ..lineTo(barClamp.dx, barClamp.dy)
      ..lineTo(hoods.dx, hoods.dy)
      ..quadraticBezierTo(
        hoods.dx + s * 0.02,
        hoods.dy + s * 0.05,
        dropEnd.dx,
        dropEnd.dy,
      );
    if (bikeKind == 7) {
      barPath
        ..moveTo(barClamp.dx, barClamp.dy)
        ..lineTo(barClamp.dx + s * 0.13, barClamp.dy - s * 0.02);
    }
    _outlinedStroke(canvas, barPath, s * 0.024, const Color(0xFF2A2A2A));

    // Silla.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: seatTop.translate(-s * 0.01, -s * 0.01),
          width: s * 0.1,
          height: s * 0.032,
        ),
        Radius.circular(s * 0.015),
      ),
      Paint()..color = Colors.black87,
    );

    // Piernas pedaleando.
    final legsPath = Path();
    for (final offset in [0.0, math.pi]) {
      final pedalAngle = phase + offset;
      final pedal =
          bb + Offset(math.cos(pedalAngle), math.sin(pedalAngle)) * crankR;
      final knee = Offset(
        (hip.dx + pedal.dx) / 2 + math.sin(pedalAngle) * (s * 0.045),
        (hip.dy + pedal.dy) / 2 - s * 0.015,
      );
      legsPath
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(pedal.dx, pedal.dy);
    }
    _outlinedStroke(canvas, legsPath, s * 0.04, Colors.white);

    // Brazo con codo flexionado hasta las hoods -- salvo que esté
    // tomando agua (mano a la boca) o alzando la bandera (mano arriba).
    final mouthTarget = headCenter.translate(s * 0.025, s * 0.05);
    final flagHand = shoulder.translate(-s * 0.02, -s * 0.22);
    var handTarget = Offset.lerp(hoods, mouthTarget, drinkingAmount)!;
    handTarget = Offset.lerp(handTarget, flagHand, banderaAmount)!;
    final elbow = Offset(
      (shoulder.dx + handTarget.dx) / 2 + s * 0.01,
      (shoulder.dy + handTarget.dy) / 2 +
          s * 0.03 -
          drinkingAmount * s * 0.025 -
          banderaAmount * s * 0.05,
    );
    final armPath = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(handTarget.dx, handTarget.dy);
    _outlinedStroke(canvas, armPath, s * 0.034, Colors.white);

    if (banderaAmount > 0.12) {
      final a = banderaAmount.clamp(0.0, 1.0);
      final wave = math.sin(phase * 3) * s * 0.02 * a;
      final pole = handTarget.translate(0, -s * 0.11 * a);
      canvas.drawLine(
        handTarget,
        pole,
        Paint()
          ..color = const Color(0xFF3A3A3A)
          ..strokeWidth = s * 0.012,
      );
      final flag = Path()
        ..moveTo(pole.dx, pole.dy)
        ..lineTo(pole.dx + s * 0.11 * a, pole.dy + s * 0.02 + wave)
        ..lineTo(pole.dx, pole.dy + s * 0.06 * a)
        ..close();
      canvas.drawPath(flag, Paint()..color = color.withValues(alpha: 0.95 * a));
    }

    if (drinkingAmount > 0.12) {
      final bottleAlpha = drinkingAmount.clamp(0.0, 1.0);
      final bottleCenter = handTarget.translate(s * 0.012, -s * 0.01);
      final bottleBody = Rect.fromCenter(
        center: bottleCenter,
        width: s * 0.024,
        height: s * 0.07,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bottleBody, Radius.circular(s * 0.008)),
        Paint()..color = Colors.white.withValues(alpha: 0.92 * bottleAlpha),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: bottleCenter.translate(0, -bottleBody.height * 0.42),
          width: bottleBody.width * 0.5,
          height: bottleBody.height * 0.22,
        ),
        Paint()..color = color.withValues(alpha: 0.92 * bottleAlpha),
      );
    }

    // Torso (jersey) relleno.
    final torsoDir = shoulder - hip;
    final torsoLen = torsoDir.distance;
    final torsoPerp =
        Offset(-torsoDir.dy, torsoDir.dx) / (torsoLen == 0 ? 1 : torsoLen);
    const hipHalfWidth = 0.055;
    const shoulderHalfWidth = 0.05;
    final torsoPath = Path()
      ..moveTo(
        hip.dx + torsoPerp.dx * s * hipHalfWidth,
        hip.dy + torsoPerp.dy * s * hipHalfWidth,
      )
      ..lineTo(
        shoulder.dx + torsoPerp.dx * s * shoulderHalfWidth,
        shoulder.dy + torsoPerp.dy * s * shoulderHalfWidth,
      )
      ..lineTo(
        shoulder.dx - torsoPerp.dx * s * shoulderHalfWidth,
        shoulder.dy - torsoPerp.dy * s * shoulderHalfWidth,
      )
      ..lineTo(
        hip.dx - torsoPerp.dx * s * hipHalfWidth,
        hip.dy - torsoPerp.dy * s * hipHalfWidth,
      )
      ..close();
    canvas.drawPath(
      torsoPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018,
    );
    canvas.drawPath(torsoPath, Paint()..color = color);
    _paintJerseyPattern(canvas, torsoPath, hip, shoulder, torsoPerp, s);

    // Cabeza + casco.
    canvas.drawCircle(
      headCenter,
      headR,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      headCenter,
      headR * 0.84,
      Paint()..color = const Color(0xFFE8B98A),
    );

    final helmetRect = Rect.fromCircle(
      center: headCenter.translate(0, -headR * 0.16),
      radius: headR * 1.22,
    );
    canvas.drawArc(
      helmetRect,
      math.pi,
      math.pi,
      true,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
    canvas.drawArc(
      helmetRect.deflate(headR * 0.13),
      math.pi,
      math.pi,
      true,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    canvas.drawArc(
      helmetRect,
      math.pi * 1.05,
      math.pi * 0.9,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = headR * 0.24,
    );

    canvas.restore(); // cierra el wheelie
  }

  /// Skin del maillot, vista lateral. `jerseyKind` 0..5 = rango,
  /// 6 lunares, 7 aero, 8 lana.
  void _paintJerseyPattern(
    Canvas canvas,
    Path torsoPath,
    Offset hip,
    Offset shoulder,
    Offset torsoPerp,
    double s,
  ) {
    if (jerseyKind <= 0) return;

    canvas.save();
    canvas.clipPath(torsoPath);

    final white = Colors.white.withValues(alpha: 0.88);
    final mid = Offset.lerp(hip, shoulder, 0.5)!;

    // -------- Maillots especiales --------
    if (jerseyKind == 6) {
      // Lunares: base blanca + puntos rojos.
      canvas.drawPath(
        torsoPath,
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
      final dot = Paint()..color = const Color(0xFFE53935);
      for (var i = 0; i < 4; i++) {
        for (var j = 0; j < 2; j++) {
          final p = Offset.lerp(hip, shoulder, i / 3)!.translate(
            torsoPerp.dx * s * (j == 0 ? -0.03 : 0.03),
            torsoPerp.dy * s * (j == 0 ? -0.03 : 0.03),
          );
          canvas.drawCircle(p, s * 0.014, dot);
        }
      }
      canvas.restore();
      return;
    }
    if (jerseyKind == 7) {
      // Aero: costura lateral oscura + panel liso.
      canvas.drawLine(
        Offset.lerp(hip, shoulder, 0.05)! + torsoPerp * s * 0.03,
        Offset.lerp(hip, shoulder, 0.95)! + torsoPerp * s * 0.02,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.32)
          ..strokeWidth = s * 0.02,
      );
      canvas.restore();
      return;
    }
    if (jerseyKind == 8) {
      // Lana: dos bandas anchas retro.
      for (final t in [0.3, 0.62]) {
        final band = Offset.lerp(hip, shoulder, t)!;
        canvas.drawLine(
          band - torsoPerp * s * 0.08,
          band + torsoPerp * s * 0.08,
          Paint()
            ..color = const Color(0xFFF5E9C8).withValues(alpha: 0.9)
            ..strokeWidth = s * 0.03,
        );
      }
      canvas.restore();
      return;
    }

    switch (jerseyKind) {
      case 1: // Rodador -- una franja diagonal sencilla.
        canvas.drawLine(
          hip.translate(-s * 0.03, s * 0.01),
          shoulder.translate(s * 0.03, -s * 0.01),
          Paint()
            ..color = white
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.026,
        );
        break;

      case 2: // Escalador -- dos bandas horizontales.
        for (final t in [0.35, 0.65]) {
          final band = Offset.lerp(hip, shoulder, t)!;
          canvas.drawLine(
            band - torsoPerp * s * 0.07,
            band + torsoPerp * s * 0.07,
            Paint()
              ..color = white
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.02,
          );
        }
        break;

      case 3: // Fondista -- chevron.
        canvas.drawLine(
          hip - torsoPerp * s * 0.055,
          mid,
          Paint()
            ..color = white
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.022,
        );
        canvas.drawLine(
          hip + torsoPerp * s * 0.055,
          mid,
          Paint()
            ..color = white
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.022,
        );
        canvas.drawLine(
          mid,
          shoulder,
          Paint()
            ..color = white
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.022,
        );
        break;

      case 4: // Élite -- franja central + bloque de contraste.
        canvas.drawLine(
          hip,
          shoulder,
          Paint()
            ..color = white
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.018,
        );
        canvas.drawCircle(
          Offset.lerp(hip, shoulder, 0.3)!,
          s * 0.028,
          Paint()..color = Colors.black.withValues(alpha: 0.28),
        );
        break;

      case 5: // Leyenda -- ribete dorado + estrella.
      default:
        const gold = Color(0xFFFFD54F);
        canvas.drawPath(
          torsoPath,
          Paint()
            ..color = gold.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.016,
        );
        _drawStar(canvas, Offset.lerp(hip, shoulder, 0.45)!, s * 0.032, gold);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CyclistPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.color != color ||
      oldDelegate.jerseyKind != jerseyKind ||
      oldDelegate.bikeKind != bikeKind ||
      oldDelegate.bikeColor != bikeColor ||
      oldDelegate.pose != pose ||
      oldDelegate.poseAmount != poseAmount;
}

/// -------------------- Vista trasera (subiendo de nivel) --------------------

/// Ciclista visto desde atrás, cámara a media distancia (torso
/// dominando el cuadro, bici chica debajo) -- se activa mientras sube
/// de nivel. La rueda trasera se simplifica a una línea vertical
/// (así se ve una rueda real mirada de frente, de canto, no como un
/// círculo con rayos) y el manubrio es un drop bar real: sube al
/// centro y las puntas bajan por debajo de las manos.
class _CyclistRearPainter extends CustomPainter {
  final Color color;
  final double phase;
  final int jerseyKind;
  final int bikeKind;
  final Color bikeColor;
  final _CyclistPose pose;
  final double poseAmount;

  const _CyclistRearPainter({
    required this.color,
    required this.phase,
    this.jerseyKind = 0,
    this.bikeKind = 0,
    this.bikeColor = const Color(0xFF8C96A8),
    this.pose = _CyclistPose.seated,
    this.poseAmount = 0,
  });

  double _amt(_CyclistPose p) => pose == p ? poseAmount : 0.0;

  static Offset _lerpPt(Offset a, Offset b, double t) =>
      Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);

  /// Dibuja una pierna como un blob relleno (silueta, no trazo),
  /// interpolando entre una plantilla "flexionada" (compacta) y una
  /// "extendida" (larga) según [t] -- así una pierna se estira
  /// mientras la otra se recoge, el ritmo real de pedalear visto de
  /// espaldas.
  void _drawLeg(
    Canvas canvas,
    Offset hip,
    double mirror,
    double t,
    double scale,
  ) {
    const bentP1 = Offset(8, 55),
        bentP2 = Offset(-15, 100),
        bentP3 = Offset(-30, 35);
    const extP1 = Offset(8, 75),
        extP2 = Offset(-15, 115),
        extP3 = Offset(-30, 55);
    final p1 = _lerpPt(bentP1, extP1, t);
    final p2 = _lerpPt(bentP2, extP2, t);
    final p3 = _lerpPt(bentP3, extP3, t);

    Offset abs(Offset local) =>
        hip + Offset(local.dx * mirror * scale, local.dy * scale);
    final pp1 = abs(p1);
    final pp2 = abs(p2);
    final pp3 = abs(p3);

    final legPath = Path()
      ..moveTo(hip.dx, hip.dy)
      ..lineTo(pp1.dx, pp1.dy)
      ..lineTo(pp2.dx, pp2.dy)
      ..lineTo(pp3.dx, pp3.dy)
      ..close();
    canvas.drawPath(legPath, Paint()..color = const Color(0xFFE8B98A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pp2, width: 26 * scale, height: 24 * scale),
        Radius.circular(6 * scale),
      ),
      Paint()..color = const Color(0xFF1F2126),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final scale = s / 680;

    final standingAmount = _amt(_CyclistPose.danzar);
    final drinkingAmount = _amt(_CyclistPose.beber);
    final banderaAmount = _amt(_CyclistPose.bandera);
    final aeroAmount = _amt(_CyclistPose.aero);
    // De espaldas el wheelie no se aprecia tanto como de perfil (para
    // eso está la cinemática de nivel): aquí sólo se sugiere -- el cuerpo
    // se echa atrás/arriba y se ve más rueda trasera abajo.
    final wheelieAmount = _amt(_CyclistPose.wheelie);

    final bodyLift =
        standingAmount * s * 0.03 -
        aeroAmount * s * 0.02 +
        wheelieAmount * s * 0.05;

    final headCenter = Offset(
      s * 0.5,
      s * 0.162 - bodyLift - drinkingAmount * s * 0.012 + aeroAmount * s * 0.02,
    );
    final headR = s * 0.082;
    final torsoTopY = s * 0.257 - bodyLift;
    final torsoBottomY = s * 0.507 - bodyLift;
    final torsoHalfTop = s * 0.096;
    final torsoHalfBottom = s * 0.076;
    final torsoTopLeft = Offset(s * 0.5 - torsoHalfTop, torsoTopY);
    final torsoTopRight = Offset(s * 0.5 + torsoHalfTop, torsoTopY);
    final torsoBottomLeft = Offset(s * 0.5 - torsoHalfBottom, torsoBottomY);
    final torsoBottomRight = Offset(s * 0.5 + torsoHalfBottom, torsoBottomY);

    // Sombra de contacto con el piso.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.5, s * 0.95),
        width: s * 0.5,
        height: s * 0.04,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // -------- Grupo que se balancea: cuadro + silla + rueda --------
    // Al pararse en pedales, la bici se balancea de lado a lado bajo
    // el ciclista (el gesto real de "honkear" en una rampa), mientras
    // el cuerpo se mantiene relativamente estable arriba.
    final swayAngle = math.sin(phase * 2) * standingAmount * 0.16;
    final swayPivot = Offset(s * 0.5, s * 0.71);

    canvas.save();
    canvas.translate(swayPivot.dx, swayPivot.dy);
    canvas.rotate(swayAngle);
    canvas.translate(-swayPivot.dx, -swayPivot.dy);

    // Tubos del asiento (dos, divergiendo hacia la rueda).
    _outlinedStroke(
      canvas,
      Path()
        ..moveTo(s * 0.478, s * 0.507 - bodyLift)
        ..lineTo(s * 0.453, s * 0.706),
      s * 0.0125,
      const Color(0xFF2B2F36),
    );
    _outlinedStroke(
      canvas,
      Path()
        ..moveTo(s * 0.522, s * 0.507 - bodyLift)
        ..lineTo(s * 0.547, s * 0.706),
      s * 0.0125,
      const Color(0xFF2B2F36),
    );
    // Tubo de asiento central.
    canvas.drawLine(
      Offset(s * 0.5, s * 0.507 - bodyLift),
      Offset(s * 0.5, s * 0.735),
      Paint()
        ..color = const Color(0xFF2B2F36)
        ..strokeWidth = s * 0.0147
        ..strokeCap = StrokeCap.round,
    );
    // Silla.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.5, s * 0.5 - bodyLift),
          width: s * 0.053,
          height: s * 0.03,
        ),
        Radius.circular(s * 0.01),
      ),
      Paint()..color = const Color(0xFF1F2126),
    );
    // Rueda trasera: no un círculo con rayos (así se vería de lado),
    // sino la línea vertical con la que realmente se lee una rueda
    // mirada justo de frente/atrás. En wheelie se ve más rueda abajo
    // (el frente sube).
    final rearWheelTop = s * (0.706 - wheelieAmount * 0.05);
    canvas.drawLine(
      Offset(s * 0.5, rearWheelTop),
      Offset(s * 0.5, s * (0.926 + wheelieAmount * 0.03)),
      Paint()
        ..color = const Color(0xFF111318)
        ..strokeWidth = s * 0.044
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(s * 0.5, s * 0.706),
      Offset(s * 0.5, s * 0.926),
      Paint()
        ..color = Color.lerp(const Color(0xFFE5E7EB), bikeColor, 0.6)!
        ..strokeWidth = s * (bikeKind == 8 || bikeKind == 7 ? 0.02 : 0.006),
    );

    // Acero: guardabarros sobre la rueda trasera (+ salpicadera abajo).
    if (bikeKind == 9) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(s * 0.5, s * 0.74), radius: s * 0.062),
        math.pi * 1.12,
        math.pi * 0.76,
        false,
        Paint()
          ..color = bikeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.014
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(s * 0.5, s * 0.9),
            width: s * 0.05,
            height: s * 0.03,
          ),
          Radius.circular(s * 0.008),
        ),
        Paint()..color = const Color(0xFF15171C),
      );
    }

    canvas.restore();

    // -------- Piernas (no se balancean, van con el cuerpo) --------
    final legCycle = (math.sin(phase) + 1) / 2; // 0..1
    final rightHip = Offset(s * 0.559, torsoBottomY);
    final leftHip = Offset(s * 0.441, torsoBottomY);
    _drawLeg(canvas, rightHip, 1, legCycle, scale);
    _drawLeg(canvas, leftHip, -1, 1 - legCycle, scale);

    // -------- Manubrio de ruta (drop bar): sube al centro y las
    // puntas bajan por debajo de las manos --------
    final barPath = Path()
      ..moveTo(s * 0.360, s * 0.585)
      ..quadraticBezierTo(s * 0.324, s * 0.515, s * 0.340, s * 0.488)
      ..quadraticBezierTo(s * 0.419, s * 0.453, s * 0.5, s * 0.465)
      ..quadraticBezierTo(s * 0.581, s * 0.453, s * 0.660, s * 0.488)
      ..quadraticBezierTo(s * 0.676, s * 0.515, s * 0.640, s * 0.585);
    _outlinedStroke(canvas, barPath, s * 0.016, const Color(0xFF5A606B));

    // Contrarreloj: acoples aero saliendo del centro hacia adelante
    // (vistos de espaldas, escorzados hacia arriba) + reposabrazos.
    if (bikeKind == 7) {
      final aeroBar = Paint()
        ..color = const Color(0xFF3A3F47)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(s * 0.478, s * 0.47),
        Offset(s * 0.47, s * 0.40),
        aeroBar,
      );
      canvas.drawLine(
        Offset(s * 0.522, s * 0.47),
        Offset(s * 0.53, s * 0.40),
        aeroBar,
      );
      for (final dx in const [-0.03, 0.03]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(s * (0.5 + dx), s * 0.472),
              width: s * 0.03,
              height: s * 0.016,
            ),
            Radius.circular(s * 0.005),
          ),
          Paint()..color = const Color(0xFF1F2126),
        );
      }
    }

    // -------- Torso (jersey) --------
    final torsoPath = Path()
      ..moveTo(torsoTopLeft.dx, torsoTopLeft.dy)
      ..lineTo(torsoTopRight.dx, torsoTopRight.dy)
      ..lineTo(torsoBottomRight.dx, torsoBottomRight.dy)
      ..lineTo(torsoBottomLeft.dx, torsoBottomLeft.dy)
      ..close();
    canvas.drawPath(
      torsoPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016,
    );
    canvas.drawPath(torsoPath, Paint()..color = color);
    canvas.drawLine(
      Offset(torsoTopLeft.dx, torsoTopY + s * 0.06),
      Offset(torsoTopRight.dx, torsoTopY + s * 0.06),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = s * 0.017,
    );
    _paintJerseyPatternRear(
      canvas,
      torsoPath,
      torsoTopLeft,
      torsoTopRight,
      torsoBottomLeft,
      torsoBottomRight,
      s,
    );

    // -------- Brazos + manos (una va a la boca si toma agua, o al aire
    // con la bandera al coronar) --------
    final rightShoulder = Offset(
      torsoTopRight.dx - s * 0.01,
      torsoTopY + s * 0.015,
    );
    final leftShoulder = Offset(
      torsoTopLeft.dx + s * 0.01,
      torsoTopY + s * 0.015,
    );
    final rightGrip = Offset(s * 0.659, s * 0.491);
    final leftGrip = Offset(s * 0.338, s * 0.491);
    final mouthTarget = headCenter.translate(0, headR * 0.9);
    final flagTarget = Offset(s * 0.73, s * 0.06);
    var rightHandTarget = Offset.lerp(rightGrip, mouthTarget, drinkingAmount)!;
    rightHandTarget = Offset.lerp(rightHandTarget, flagTarget, banderaAmount)!;

    _outlinedStroke(
      canvas,
      Path()
        ..moveTo(leftShoulder.dx, leftShoulder.dy)
        ..quadraticBezierTo(s * 0.320, s * 0.368, leftGrip.dx, leftGrip.dy),
      s * 0.026,
      const Color(0xFFE8B98A),
    );
    final rightElbow = Offset.lerp(
      const Offset(0.679, 0.368),
      const Offset(0.70, 0.18),
      banderaAmount,
    )!;
    _outlinedStroke(
      canvas,
      Path()
        ..moveTo(rightShoulder.dx, rightShoulder.dy)
        ..quadraticBezierTo(
          rightElbow.dx * s,
          rightElbow.dy * s,
          rightHandTarget.dx,
          rightHandTarget.dy,
        ),
      s * 0.026,
      const Color(0xFFE8B98A),
    );

    if (banderaAmount > 0.12) {
      final a = banderaAmount.clamp(0.0, 1.0);
      final wave = math.sin(phase * 3) * s * 0.02 * a;
      final poleTop = rightHandTarget.translate(0, -s * 0.14 * a);
      canvas.drawLine(
        rightHandTarget,
        poleTop,
        Paint()
          ..color = const Color(0xFF3A3A3A)
          ..strokeWidth = s * 0.012,
      );
      final flag = Path()
        ..moveTo(poleTop.dx, poleTop.dy)
        ..lineTo(poleTop.dx + s * 0.14 * a, poleTop.dy + s * 0.03 + wave)
        ..lineTo(poleTop.dx, poleTop.dy + s * 0.08 * a)
        ..close();
      canvas.drawPath(flag, Paint()..color = color.withValues(alpha: 0.95 * a));
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: leftGrip, width: s * 0.076, height: s * 0.035),
        Radius.circular(s * 0.012),
      ),
      Paint()..color = const Color(0xFF1F2126),
    );
    if (drinkingAmount < 0.12 && banderaAmount < 0.12) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rightGrip,
            width: s * 0.076,
            height: s * 0.035,
          ),
          Radius.circular(s * 0.012),
        ),
        Paint()..color = const Color(0xFF1F2126),
      );
    } else if (drinkingAmount >= 0.12) {
      final bottleAlpha = drinkingAmount.clamp(0.0, 1.0);
      final bottleBody = Rect.fromCenter(
        center: rightHandTarget,
        width: s * 0.03,
        height: s * 0.08,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bottleBody, Radius.circular(s * 0.01)),
        Paint()..color = Colors.white.withValues(alpha: 0.92 * bottleAlpha),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: rightHandTarget.translate(0, -bottleBody.height * 0.42),
          width: bottleBody.width * 0.5,
          height: bottleBody.height * 0.2,
        ),
        Paint()..color = color.withValues(alpha: 0.92 * bottleAlpha),
      );
    }

    // -------- Cabeza + casco (visto de espaldas) --------
    canvas.drawCircle(
      headCenter,
      headR,
      Paint()..color = const Color(0xFF1F2126),
    );
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headR * 0.98),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = headR * 0.34,
    );
    final ventPaint = Paint()
      ..color = const Color(0xFF4A4F57)
      ..strokeWidth = headR * 0.1
      ..strokeCap = StrokeCap.round;
    for (final dx in [-0.42, 0.0, 0.42]) {
      canvas.drawLine(
        headCenter.translate(dx * headR, -headR * 0.7),
        headCenter.translate(dx * headR * 0.9, headR * 0.75),
        ventPaint,
      );
    }
  }

  /// Skin del maillot, vista trasera. `jerseyKind` 0..5 = rango,
  /// 6 lunares, 7 aero, 8 lana.
  void _paintJerseyPatternRear(
    Canvas canvas,
    Path torsoPath,
    Offset topLeft,
    Offset topRight,
    Offset bottomLeft,
    Offset bottomRight,
    double s,
  ) {
    if (jerseyKind <= 0) return;

    canvas.save();
    canvas.clipPath(torsoPath);

    final white = Colors.white.withValues(alpha: 0.88);
    final center = Offset.lerp(
      Offset.lerp(topLeft, topRight, 0.5)!,
      Offset.lerp(bottomLeft, bottomRight, 0.5)!,
      0.5,
    )!;

    if (jerseyKind == 6) {
      canvas.drawPath(
        torsoPath,
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
      final dot = Paint()..color = const Color(0xFFE53935);
      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 3; j++) {
          final p = Offset.lerp(
            Offset.lerp(topLeft, topRight, (j + 0.5) / 3)!,
            Offset.lerp(bottomLeft, bottomRight, (j + 0.5) / 3)!,
            (i + 0.5) / 3,
          )!;
          canvas.drawCircle(p, s * 0.016, dot);
        }
      }
      canvas.restore();
      return;
    }
    if (jerseyKind == 7) {
      canvas.drawLine(
        Offset.lerp(topLeft, topRight, 0.5)!,
        Offset.lerp(bottomLeft, bottomRight, 0.5)!,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.28)
          ..strokeWidth = s * 0.02,
      );
      canvas.restore();
      return;
    }
    if (jerseyKind == 8) {
      for (final t in [0.32, 0.62]) {
        canvas.drawLine(
          Offset.lerp(topLeft, bottomLeft, t)!,
          Offset.lerp(topRight, bottomRight, t)!,
          Paint()
            ..color = const Color(0xFFF5E9C8).withValues(alpha: 0.9)
            ..strokeWidth = s * 0.03,
        );
      }
      canvas.restore();
      return;
    }

    switch (jerseyKind) {
      case 1: // Rodador -- franja diagonal.
        canvas.drawLine(
          bottomLeft,
          topRight,
          Paint()
            ..color = white
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.024,
        );
        break;

      case 2: // Escalador -- dos bandas horizontales.
        for (final t in [0.4, 0.7]) {
          final left = Offset.lerp(topLeft, bottomLeft, t)!;
          final right = Offset.lerp(topRight, bottomRight, t)!;
          canvas.drawLine(
            left,
            right,
            Paint()
              ..color = white
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.018,
          );
        }
        break;

      case 3: // Fondista -- chevron.
        canvas.drawLine(
          bottomLeft,
          center,
          Paint()
            ..color = white
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.02,
        );
        canvas.drawLine(
          bottomRight,
          center,
          Paint()
            ..color = white
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.02,
        );
        canvas.drawLine(
          center,
          Offset.lerp(topLeft, topRight, 0.5)!,
          Paint()
            ..color = white
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.02,
        );
        break;

      case 4: // Élite -- franja central + bloque de contraste.
        canvas.drawLine(
          Offset.lerp(topLeft, topRight, 0.5)!,
          Offset.lerp(bottomLeft, bottomRight, 0.5)!,
          Paint()
            ..color = white
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.016,
        );
        canvas.drawCircle(
          center,
          s * 0.026,
          Paint()..color = Colors.black.withValues(alpha: 0.28),
        );
        break;

      case 5: // Leyenda -- ribete dorado + estrella.
      default:
        const gold = Color(0xFFFFD54F);
        canvas.drawPath(
          torsoPath,
          Paint()
            ..color = gold.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.015,
        );
        _drawStar(canvas, center, s * 0.03, gold);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CyclistRearPainter oldDelegate) =>
      oldDelegate.bikeColor != bikeColor ||
      oldDelegate.phase != phase ||
      oldDelegate.color != color ||
      oldDelegate.jerseyKind != jerseyKind ||
      oldDelegate.bikeKind != bikeKind ||
      oldDelegate.pose != pose ||
      oldDelegate.poseAmount != poseAmount;
}
