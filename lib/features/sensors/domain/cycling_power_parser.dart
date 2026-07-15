import 'cycling_power_reading.dart';

/// Parsea el payload crudo de la característica estándar "Cycling Power
/// Measurement" (Bluetooth SIG, UUID 0x2A63).
///
/// Es una función PURA a propósito -- no importa nada de
/// flutter_blue_plus. Mismo criterio que `heart_rate_parser.dart`:
/// permite un test unitario con bytes fijos, sin hardware real.
///
/// Estructura (todos los campos multi-byte son little-endian, como todo
/// en BLE):
///   flags: uint16 (2 bytes) -- qué campos opcionales vienen después
///   instantaneousPower: sint16 (2 bytes) -- SIEMPRE presente
///   [pedalPowerBalance]: uint8 (1 byte) -- si flags bit 0
///   [accumulatedTorque]: uint16 (2 bytes) -- si flags bit 2
///   [wheelRevolutionData]: uint32 + uint16 (6 bytes) -- si flags bit 4
///   [crankRevolutionData]: uint16 + uint16 (4 bytes) -- si flags bit 5
///   (el resto de campos opcionales del estándar no se usan en este
///   proyecto, pero SÍ hay que respetar su orden si algún día se
///   necesitan -- por eso el cursor de bytes avanza campo por campo en
///   vez de asumir offsets fijos).
///
/// Bits de flags relevantes aquí:
///   bit 0 = viene balance de pedaleo
///   bit 2 = viene torque acumulado
///   bit 4 = vienen datos de rueda (fuera de alcance: la velocidad se
///           obtiene del sensor CSC dedicado, no de un medidor de
///           potencia)
///   bit 5 = vienen datos de manivela (esto SÍ nos interesa: cadencia)
CyclingPowerReading parseCyclingPowerMeasurement(List<int> data) {
  if (data.length < 4) {
    throw ArgumentError('Payload de Cycling Power Measurement muy corto');
  }

  final flags = data[0] | (data[1] << 8);
  final hasPedalBalance = (flags & 0x0001) != 0;
  final hasAccumulatedTorque = (flags & 0x0004) != 0;
  final hasWheelRevolutionData = (flags & 0x0010) != 0;
  final hasCrankRevolutionData = (flags & 0x0020) != 0;

  // sint16: si el bit más significativo está encendido, es negativo
  // (complemento a dos) -- en la práctica la potencia nunca es negativa
  // en un pedaleo normal, pero respetamos el formato del estándar.
  final rawPower = data[2] | (data[3] << 8);
  final instantaneousPower = rawPower >= 0x8000
      ? rawPower - 0x10000
      : rawPower;

  var cursor = 4;

  if (hasPedalBalance) cursor += 1;
  if (hasAccumulatedTorque) cursor += 2;
  if (hasWheelRevolutionData) cursor += 6;

  int? cumulativeCrankRevolutions;
  int? lastCrankEventTime;

  if (hasCrankRevolutionData) {
    if (data.length < cursor + 4) {
      throw ArgumentError(
        'Payload de Cycling Power Measurement incompleto para datos de '
        'manivela',
      );
    }
    cumulativeCrankRevolutions = data[cursor] | (data[cursor + 1] << 8);
    lastCrankEventTime = data[cursor + 2] | (data[cursor + 3] << 8);
  }

  return CyclingPowerReading(
    instantaneousPowerWatts: instantaneousPower,
    cumulativeCrankRevolutions: cumulativeCrankRevolutions,
    lastCrankEventTime: lastCrankEventTime,
    timestamp: DateTime.now(),
  );
}
