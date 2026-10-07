import 'dart:math' as math;

import '../../../../core/geo/geo.dart';

/// Esfuerzo de referencia contra el que se compara (el récord): tiempo
/// acumulado en cada distancia del segmento.
final class ReferenceEffort {
  /// Pares (metros, segundos), ordenados por distancia.
  final List<({double meters, double seconds})> splits;

  ReferenceEffort(List<({double meters, double seconds})> splits)
    : splits = List.unmodifiable(
        [...splits]..sort((a, b) => a.meters.compareTo(b.meters)),
      ) {
    if (this.splits.length < 2) {
      throw ArgumentError('Una referencia necesita al menos dos puntos.');
    }
  }

  /// Tiempo total del esfuerzo de referencia.
  double get totalSeconds => splits.last.seconds;

  /// Tiempo de la referencia al pasar por [meters] (interpolado).
  double secondsAt(double meters) {
    if (meters <= splits.first.meters) return splits.first.seconds;
    for (var i = 1; i < splits.length; i++) {
      final a = splits[i - 1], b = splits[i];
      if (meters <= b.meters) {
        final span = b.meters - a.meters;
        if (span <= 0) return b.seconds;
        return a.seconds + (b.seconds - a.seconds) * (meters - a.meters) / span;
      }
    }
    return splits.last.seconds;
  }
}

/// Lo que el perfil del segmento dice del tramo que viene.
final class TerrainWindow {
  /// Pendiente media de los próximos metros (%).
  final double gradientAhead;

  /// Pendiente máxima del tramo que viene (%) y a cuántos metros está.
  final double maxRamp;
  final double maxRampInMeters;

  /// Dispersión de la pendiente en el tramo (%): subida pareja o a saltos.
  final double roughness;

  /// Desnivel positivo que falta hasta el final (m).
  final double climbLeft;

  /// Desnivel positivo ya hecho dentro del segmento (m).
  final double climbDone;

  /// Avance en el segmento (%).
  final double progress;
  final double distanceLeft;
  final double gradientNow;

  const TerrainWindow({
    required this.gradientAhead,
    required this.maxRamp,
    required this.maxRampInMeters,
    required this.roughness,
    required this.climbLeft,
    required this.climbDone,
    required this.progress,
    required this.distanceLeft,
    required this.gradientNow,
  });

  /// Lee el tramo `[along, along + lookahead]` del [profile] (recortado
  /// al final del segmento). Integra la pendiente por tramos lineales:
  ///
  ///     media = 100·(h(fin) − h(inicio)) / largo
  ///     σ²    = (1/largo)·∫ g² − ((1/largo)·∫ g)²
  factory TerrainWindow.read(
    SegmentProfile profile,
    double along, {
    double lookahead = 1000,
  }) {
    final total = profile.totalDistanceMeters;
    final start = along.clamp(0, total).toDouble();
    final end = math.min(total, start + lookahead);
    final gradientNow = profile.slopePercentAtDistance(start) ?? 0;

    // Pendiente en los puntos del perfil dentro del tramo y en sus bordes.
    final samples = <({double d, double g})>[
      (d: start, g: gradientNow),
      for (final p in profile.points)
        if (p.distanceFromStartMeters > start &&
            p.distanceFromStartMeters < end)
          (d: p.distanceFromStartMeters, g: p.slopePercent),
      if (end > start) (d: end, g: profile.slopePercentAtDistance(end) ?? 0),
    ];

    var maxRamp = gradientNow, maxAt = start;
    var sumG = 0.0, sumG2 = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      if (s.g > maxRamp) {
        maxRamp = s.g;
        maxAt = s.d;
      }
      if (i == 0) continue;
      final a = samples[i - 1];
      final h = s.d - a.d;
      sumG += h * (a.g + s.g) / 2;
      sumG2 += h * (a.g * a.g + a.g * s.g + s.g * s.g) / 3;
    }
    final length = end - start;
    final hStart = profile.altitudeAtDistance(start) ?? 0;
    final hEnd = profile.altitudeAtDistance(end) ?? hStart;
    final meanFromIntegral = length > 0 ? sumG / length : gradientNow;
    final variance = length > 0
        ? sumG2 / length - meanFromIntegral * meanFromIntegral
        : 0.0;

    return TerrainWindow(
      gradientAhead: length > 0 ? 100 * (hEnd - hStart) / length : gradientNow,
      maxRamp: maxRamp,
      maxRampInMeters: maxAt - start,
      roughness: math.sqrt(math.max(0, variance)),
      climbLeft: profile.elevationGainBetween(start, total),
      climbDone: profile.elevationGainBetween(0, start),
      progress: total > 0 ? 100 * start / total : 0,
      distanceLeft: total - start,
      gradientNow: gradientNow,
    );
  }
}
