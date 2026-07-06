/// Una lectura de frecuencia cardíaca ya interpretada (no el byte crudo
/// de Bluetooth).
class HeartRateReading {
  final int bpm;

  /// Si el sensor reporta contacto con la piel. El Polar H7 sí soporta
  /// este campo -- útil para detectar si la banda se aflojó a mitad de
  /// un ascenso, algo que vale la pena mostrar en el piloto real.
  final bool sensorContactDetected;

  final DateTime timestamp;

  const HeartRateReading({
    required this.bpm,
    required this.sensorContactDetected,
    required this.timestamp,
  });
}
