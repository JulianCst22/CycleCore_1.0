/// Una lectura de potencia ya interpretada (no el byte crudo de
/// Bluetooth). Refleja solo lo que este proyecto necesita del estándar
/// "Cycling Power Measurement" (0x2A63) -- el estándar trae muchos más
/// campos opcionales (balance de pedaleo, torque, ángulos extremos) que
/// están fuera del alcance actual.
class CyclingPowerReading {
  final int instantaneousPowerWatts;

  /// Datos de manivela, presentes solo si el sensor de potencia también
  /// reporta cadencia (muchos lo hacen). Null si el sensor no trae este
  /// campo -- en ese caso, la cadencia debe venir del sensor dedicado de
  /// velocidad/cadencia (CSC), si hay uno conectado.
  final int? cumulativeCrankRevolutions;

  /// Marca de tiempo del último evento de manivela, en unidades de
  /// 1/1024 de segundo (así lo define el estándar BLE) -- NO es un
  /// DateTime real, es un contador de 16 bits que se reinicia solo.
  final int? lastCrankEventTime;

  final DateTime timestamp;

  const CyclingPowerReading({
    required this.instantaneousPowerWatts,
    required this.timestamp,
    this.cumulativeCrankRevolutions,
    this.lastCrankEventTime,
  });

  bool get hasCrankData =>
      cumulativeCrankRevolutions != null && lastCrankEventTime != null;
}
