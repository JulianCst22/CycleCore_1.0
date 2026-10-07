import '../../../core/physiology/physiology.dart';

/// Lo que el coach necesita saber del ciclista.
final class CoachAthlete {
  /// Potencia crítica y reserva anaeróbica, con su incertidumbre.
  final CriticalPowerModel power;
  final Bpm restingHeartRate;
  final Bpm maxHeartRate;

  /// Cadencia con la que suele pedalear (mediana de sus actividades).
  final Rpm preferredCadence;

  /// Peso, bicicleta y aire: con esto se estima la potencia a partir de
  /// la velocidad y la pendiente cuando no hay potenciómetro.
  final RidingResistance resistance;

  const CoachAthlete({
    required this.power,
    required this.restingHeartRate,
    required this.maxHeartRate,
    required this.preferredCadence,
    this.resistance = const RidingResistance(),
  });
}
