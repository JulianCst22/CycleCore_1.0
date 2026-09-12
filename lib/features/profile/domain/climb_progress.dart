import 'climb_route.dart';
import 'package:cyclecore_core/gamification/level_info.dart';
import 'package:cyclecore_core/gamification/rank_tier.dart';

/// Dónde está el ciclista sobre la subida REAL del Alto de Patios,
/// derivado de su nivel + progreso dentro del nivel.
///
/// El [levelValue] es fraccionario a propósito: la pantalla de la
/// subida deja descansar al ciclista en `nivel + progresoEnNivel` (ej.
/// 12.62), no en enteros, para que tras cada actividad se note que
/// avanzó un poco aunque no haya subido de nivel. Toda la altitud /
/// distancia / pendiente sale de [ElevationProfile] (datos reales), no
/// de números inventados.
class ClimbProgress {
  /// Nivel + progreso dentro del nivel, 1.0 .. [ClimbRoute.maxLevel].
  final double levelValue;

  /// Fracción de la subida recorrida, 0.0 (Belisario) .. 1.0 (cima).
  final double fractionOfClimb;

  final double distanceKm;
  final double altitudeM;
  final double gradePercent;

  const ClimbProgress({
    required this.levelValue,
    required this.fractionOfClimb,
    required this.distanceKm,
    required this.altitudeM,
    required this.gradePercent,
  });

  /// Nivel entero en el que estás parado (el arco que ya cruzaste).
  int get currentLevel => levelValue.floor().clamp(1, ClimbRoute.maxLevel);

  /// El siguiente arco / nivel al que te diriges. `null` si ya estás en
  /// la cima.
  int? get nextLevel =>
      currentLevel >= ClimbRoute.maxLevel ? null : currentLevel + 1;

  /// Progreso hacia el próximo arco, 0.0 .. 1.0.
  double get fractionToNextLevel =>
      (levelValue - levelValue.floor()).clamp(0.0, 1.0);

  bool get isAtSummit => currentLevel >= ClimbRoute.maxLevel;

  /// El punto de interés / arco al que te diriges.
  ClimbPointOfInterest? get nextPoi =>
      nextLevel == null ? null : ClimbRoute.forLevel(nextLevel!);

  /// El punto de interés del tramo actual (el último que cruzaste).
  ClimbPointOfInterest get currentPoi => ClimbRoute.forLevel(currentLevel);

  RankTierInfo get rank => RankTier.forLevel(currentLevel);

  /// El rango del próximo arco, si es distinto al actual (cambio de
  /// rango inminente).
  RankTierInfo? get nextRank {
    if (nextLevel == null) return null;
    final next = RankTier.forLevel(nextLevel!);
    return next.rank == rank.rank ? null : next;
  }

  double get kmToSummit =>
      (ElevationProfile.totalDistanceKm - distanceKm).clamp(0, double.infinity);

  double get metersToSummit =>
      (ElevationProfile.summitAltitude - altitudeM).clamp(0, double.infinity);

  /// Metros de desnivel que faltan para llegar al próximo arco.
  double get metersToNextLevel {
    if (nextLevel == null) return 0;
    final nextAlt = ClimbRoute.forLevel(nextLevel!).altitudeM;
    return (nextAlt - altitudeM).clamp(0, double.infinity);
  }
}

/// Fracción de la subida (0..1) para un valor de nivel fraccionario --
/// misma fórmula lineal que usa `ClimbRoute` para ubicar cada punto.
double climbFractionForLevelValue(double levelValue) {
  if (ClimbRoute.maxLevel <= 1) return 0;
  final clamped = levelValue.clamp(1.0, ClimbRoute.maxLevel.toDouble());
  return ((clamped - 1) / (ClimbRoute.maxLevel - 1)).clamp(0.0, 1.0);
}

/// [ClimbProgress] para un valor de nivel fraccionario.
ClimbProgress climbProgressForLevelValue(double levelValue) {
  final fraction = climbFractionForLevelValue(levelValue);
  return ClimbProgress(
    levelValue: levelValue.clamp(1.0, ClimbRoute.maxLevel.toDouble()),
    fractionOfClimb: fraction,
    distanceKm: ElevationProfile.distanceKmForFraction(fraction),
    altitudeM: ElevationProfile.altitudeForFraction(fraction),
    gradePercent: ElevationProfile.gradeForFraction(fraction),
  );
}

/// [ClimbProgress] para el estado de nivel del usuario: el ciclista
/// descansa en `nivel + progreso dentro del nivel`.
ClimbProgress climbProgressFor(LevelInfo info) =>
    climbProgressForLevelValue(info.level + info.progress);
