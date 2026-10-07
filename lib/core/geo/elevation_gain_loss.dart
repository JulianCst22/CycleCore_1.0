/// Desnivel positivo y negativo de una serie de altitudes, con
/// **histéresis**: solo se "cuenta" un cambio de dirección cuando la
/// altitud se aleja más de [minChangeMeters] del último pivote. Es el
/// método que usan Garmin/Strava y evita que el ruido de la serie
/// (jitter de GPS, costuras de HGT, barómetro indoor durante un test)
/// infle el desnivel -- el problema clásico de "hice solo una subida
/// pero me marca desnivel negativo".
///
/// Sumar cada delta > un piso fijo (lo que hacía antes el aplanador y
/// `_DerivedStats`) falla justo en ese caso: una serie que oscila
/// ±1 m mil veces acumula cientos de metros falsos en ambos sentidos.
class GainLoss {
  final double gainMeters;
  final double lossMeters;

  const GainLoss(this.gainMeters, this.lossMeters);

  static const zero = GainLoss(0, 0);
}

GainLoss computeGainLoss(
  List<double> altitudes, {
  double minChangeMeters = 3,
}) {
  if (altitudes.length < 2) return GainLoss.zero;

  double gain = 0;
  double loss = 0;

  // Pivote: última altitud "confirmada". `direction` = hacia dónde
  // veníamos (1 subiendo, -1 bajando, 0 sin definir).
  double pivot = altitudes.first;
  double extreme = altitudes.first; // el punto más lejos del pivote en
  // la dirección actual (candidato a nuevo pivote)
  int direction = 0;

  for (int i = 1; i < altitudes.length; i++) {
    final alt = altitudes[i];

    if (direction >= 0 && alt > extreme) {
      // Seguimos (o empezamos) a subir -- el extremo sube con nosotros.
      extreme = alt;
      if (direction == 0) direction = 1;
    } else if (direction <= 0 && alt < extreme) {
      extreme = alt;
      if (direction == 0) direction = -1;
    }

    // ¿Retrocedimos lo suficiente respecto al extremo como para
    // confirmar un cambio de dirección?
    if (direction == 1 && (extreme - alt) >= minChangeMeters) {
      gain += extreme - pivot;
      pivot = extreme;
      extreme = alt;
      direction = -1;
    } else if (direction == -1 && (alt - extreme) >= minChangeMeters) {
      loss += pivot - extreme;
      pivot = extreme;
      extreme = alt;
      direction = 1;
    }
  }

  // Cerrar el tramo abierto al final.
  if (direction == 1 && extreme > pivot) {
    gain += extreme - pivot;
  } else if (direction == -1 && extreme < pivot) {
    loss += pivot - extreme;
  }

  return GainLoss(gain, loss);
}
