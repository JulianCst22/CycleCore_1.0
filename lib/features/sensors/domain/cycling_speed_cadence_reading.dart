/// Una lectura cruda del servicio "Cycling Speed and Cadence" (CSC,
/// 0x1816) ya interpretada de bytes, pero SIN convertir todavía a
/// km/h o RPM -- el estándar BLE nunca manda esos valores calculados,
/// solo contadores acumulados de revoluciones + marcas de tiempo. La
/// conversión real la hace `CadenceSpeedCalculator`, que necesita DOS
/// lecturas consecutivas para sacar una diferencia.
class CyclingSpeedCadenceReading {
  /// Contador acumulado de revoluciones de rueda (uint32, se reinicia
  /// solo al desbordar). Null si el sensor no reporta velocidad (ej. un
  /// sensor de cadencia puro, sin imán de rueda).
  final int? cumulativeWheelRevolutions;

  /// Marca del último evento de rueda, en unidades de 1/1024 de segundo
  /// (uint16, se reinicia solo).
  final int? lastWheelEventTime;

  /// Contador acumulado de revoluciones de manivela (uint16).
  final int? cumulativeCrankRevolutions;

  /// Marca del último evento de manivela, en unidades de 1/1024 s.
  final int? lastCrankEventTime;

  final DateTime timestamp;

  const CyclingSpeedCadenceReading({
    required this.timestamp,
    this.cumulativeWheelRevolutions,
    this.lastWheelEventTime,
    this.cumulativeCrankRevolutions,
    this.lastCrankEventTime,
  });

  bool get hasWheelData =>
      cumulativeWheelRevolutions != null && lastWheelEventTime != null;

  bool get hasCrankData =>
      cumulativeCrankRevolutions != null && lastCrankEventTime != null;
}
