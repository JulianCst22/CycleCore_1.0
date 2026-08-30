/// Estimación de calorías (kcal) quemadas en una actividad de ciclismo.
///
/// No se persiste: se calcula al vuelo en el detalle de actividad a
/// partir de los datos que ya están guardados (`Activity`) más el peso
/// del ciclista (`CyclistProfile`). Así no hace falta migración ni
/// recalcular actividades viejas.
///
/// Prioridad de método:
///  1. **Con potencia media** -- kcal ≈ trabajo mecánico en kJ
///     (`W · s / 1000`). La conversión kJ→kcal (÷4.184) se cancela
///     casi exactamente con la división por la eficiencia bruta humana
///     (~0.24), así que el factor neto es ≈ 1. Es el método que usan
///     Garmin y Strava cuando hay potenciómetro, y el más fiable para
///     este proyecto (que gira alrededor de la potencia).
///  2. **Sin potencia** -- modelo MET según velocidad media, más un
///     extra por el desnivel positivo (energía potencial ganada,
///     dividida por la eficiencia). Necesita el peso del ciclista.
///  3. **Sin peso** -- `null` (la UI muestra `--`).
int? estimateCalories({
  int? avgPowerWatts,
  required int durationSeconds,
  required double elevationGainMeters,
  required double avgSpeedKmh,
  double? weightKg,
}) {
  if (durationSeconds <= 0) return null;

  if (avgPowerWatts != null && avgPowerWatts > 0) {
    return (avgPowerWatts * durationSeconds / 1000).round();
  }

  if (weightKg == null || weightKg <= 0) return null;

  final hours = durationSeconds / 3600;
  final base = _cyclingMet(avgSpeedKmh) * weightKg * hours;

  // Energía para subir el desnivel: m·g·h (J) / eficiencia bruta /
  // 4184 J por kcal.
  final climbKcal =
      (elevationGainMeters.clamp(0, double.infinity) * weightKg * 9.81) /
          0.24 /
          4184;

  return (base + climbKcal).round();
}

/// Equivalente metabólico aproximado del ciclismo según la velocidad
/// media, siguiendo el Compendium of Physical Activities.
double _cyclingMet(double kmh) {
  if (kmh < 16) return 4.0;
  if (kmh < 19) return 6.0;
  if (kmh < 22) return 8.0;
  if (kmh < 25) return 10.0;
  if (kmh < 28) return 12.0;
  if (kmh < 32) return 14.0;
  return 16.0;
}
