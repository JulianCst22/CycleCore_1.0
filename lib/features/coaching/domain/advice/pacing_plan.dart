import 'dart:math' as math;

import '../../../../core/geo/geo.dart';
import '../coaching_parameters.dart';

/// Qué le toca hacer al ciclista en este tramo mirando todo lo que le
/// falta, no solo lo que tiene delante.
enum PacingStance {
  /// Guardar acá porque lo duro viene después.
  regular,

  /// Ir parejo: lo que falta pide más o menos lo mismo que esto.
  sostener,

  /// Soltar lo que quede: ya no hay dónde guardarlo.
  apretar,
}

/// Reparto del esfuerzo por lo que queda del segmento.
///
/// La reserva anaeróbica es un presupuesto, no una alarma: sirve de
/// poco avisar «te queda poco» si no se dice dónde gastarlo. Acá lo que
/// falta se pesa por pendiente, siguiendo a Swain (1997): en subida
/// conviene poner más vatios donde más empina y menos donde afloja,
/// porque ahí la misma potencia rinde más tiempo de ventaja.
///
/// El plan no manda vatios; le dice al mensaje si toca regular o
/// apretar y dónde está el tramo que decide la subida.
final class PacingPlan {
  /// Pendiente del punto en el que va (%).
  final double gradientNow;

  /// Pendiente media del tramo más exigente que queda (%).
  final double hardestGradient;

  /// A cuántos metros empieza ese tramo.
  final double metersToHardest;

  /// Metros que faltan para terminar.
  final double metersLeft;

  /// Parte del esfuerzo total que todavía falta, pesada por pendiente.
  /// Uno al empezar, cero al coronar.
  final double shareAhead;

  final PacingStance stance;

  const PacingPlan({
    required this.gradientNow,
    required this.hardestGradient,
    required this.metersToHardest,
    required this.metersLeft,
    required this.shareAhead,
    required this.stance,
  });

  /// Segmento terminado o sin datos: no hay nada que repartir.
  static const PacingPlan finished = PacingPlan(
    gradientNow: 0,
    hardestGradient: 0,
    metersToHardest: 0,
    metersLeft: 0,
    shareAhead: 0,
    stance: PacingStance.apretar,
  );

  /// Hay un tramo claramente más duro adelante y vale la pena nombrarlo.
  bool get hasHarderAhead =>
      stance == PacingStance.regular && metersToHardest > 0;

  /// Reparte el presupuesto sobre el perfil que falta.
  ///
  /// Camina el perfil en pasos de [CoachingParameters.pacingStepMeters] y
  /// busca el tramo más exigente que queda, mirando tanto una rampa
  /// corta como una cuesta sostenida de
  /// [CoachingParameters.pacingWindowMeters]. Las dos cuestan reserva:
  /// un muro de cien metros se paga en veinte segundos y una cuesta
  /// larga, en varios minutos.
  factory PacingPlan.of(
    SegmentProfile profile,
    double alongMeters, {
    CoachingParameters parameters = const CoachingParameters(),
  }) {
    final total = profile.totalDistanceMeters;
    final step = parameters.pacingStepMeters;
    final from = alongMeters.clamp(0, total).toDouble();
    if (total - from < step) return finished;

    // Peso de cada paso: la pendiente positiva. Lo llano no consume
    // presupuesto porque ahí la reserva no es lo que decide.
    final weights = <({double at, double weight, double gradient})>[];
    for (var d = 0.0; d < total; d += step) {
      final g = profile.slopePercentAtDistance(d + step / 2) ?? 0;
      weights.add((at: d, weight: math.max(0, g), gradient: g));
    }
    // El paso que se está pedaleando es aquel cuyo tramo contiene la
    // posición; los de atrás ya no son presupuesto.
    final ahead = weights.where((w) => w.at + step > from).toList();
    if (ahead.isEmpty) return finished;

    final all = weights.fold(0.0, (a, w) => a + w.weight);
    final left = ahead.fold(0.0, (a, w) => a + w.weight);

    // Ventana más dura de las que faltan, saltándose la que se está
    // pedaleando: lo que interesa es a dónde hay que llegar con algo.
    final span = math.max(1, (parameters.pacingWindowMeters / step).round());
    final skip = math.max(1, (parameters.pacingNowMeters / step).round());
    var best = (mean: double.negativeInfinity, at: 0.0);
    for (final length in {1, span}) {
      for (var i = skip; i + length <= ahead.length; i++) {
        var sum = 0.0;
        for (var k = i; k < i + length; k++) {
          sum += ahead[k].gradient;
        }
        final mean = sum / length;
        if (mean > best.mean) best = (mean: mean, at: ahead[i].at);
      }
    }

    final now = ahead.first.gradient;
    final shareAhead = all > 0 ? (left / all).clamp(0.0, 1.0).toDouble() : 0.0;
    final harder =
        best.mean.isFinite && best.mean >= now + parameters.harderAheadPoints;

    final stance = switch (0) {
      _ when shareAhead <= parameters.finalShare => PacingStance.apretar,
      _ when harder => PacingStance.regular,
      _ => PacingStance.sostener,
    };

    return PacingPlan(
      gradientNow: now,
      hardestGradient: best.mean.isFinite ? best.mean : now,
      metersToHardest: best.mean.isFinite ? math.max(0, best.at - from) : 0,
      metersLeft: total - from,
      shareAhead: shareAhead,
      stance: stance,
    );
  }
}
