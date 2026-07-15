import 'cycling_speed_cadence_reading.dart';

/// Parsea el payload crudo de la característica estándar "CSC
/// Measurement" (Bluetooth SIG, UUID 0x2A5B). Función pura, mismo
/// criterio que los demás parsers del proyecto.
///
/// Estructura:
///   flags: uint8 (1 byte)
///   [wheelRevolutionData]: uint32 + uint16 (6 bytes) -- si flags bit 0
///   [crankRevolutionData]: uint16 + uint16 (4 bytes) -- si flags bit 1
///
/// A diferencia de Cycling Power, aquí SÍ nos interesan los datos de
/// rueda (es la única fuente de velocidad en todo este módulo).
CyclingSpeedCadenceReading parseCyclingSpeedCadenceMeasurement(
  List<int> data,
) {
  if (data.isEmpty) {
    throw ArgumentError('Payload de CSC Measurement vacío');
  }

  final flags = data[0];
  final hasWheelRevolutionData = (flags & 0x01) != 0;
  final hasCrankRevolutionData = (flags & 0x02) != 0;

  var cursor = 1;

  int? cumulativeWheelRevolutions;
  int? lastWheelEventTime;

  if (hasWheelRevolutionData) {
    if (data.length < cursor + 6) {
      throw ArgumentError(
        'Payload de CSC Measurement incompleto para datos de rueda',
      );
    }
    cumulativeWheelRevolutions =
        data[cursor] |
        (data[cursor + 1] << 8) |
        (data[cursor + 2] << 16) |
        (data[cursor + 3] << 24);
    lastWheelEventTime = data[cursor + 4] | (data[cursor + 5] << 8);
    cursor += 6;
  }

  int? cumulativeCrankRevolutions;
  int? lastCrankEventTime;

  if (hasCrankRevolutionData) {
    if (data.length < cursor + 4) {
      throw ArgumentError(
        'Payload de CSC Measurement incompleto para datos de manivela',
      );
    }
    cumulativeCrankRevolutions = data[cursor] | (data[cursor + 1] << 8);
    lastCrankEventTime = data[cursor + 2] | (data[cursor + 3] << 8);
  }

  return CyclingSpeedCadenceReading(
    cumulativeWheelRevolutions: cumulativeWheelRevolutions,
    lastWheelEventTime: lastWheelEventTime,
    cumulativeCrankRevolutions: cumulativeCrankRevolutions,
    lastCrankEventTime: lastCrankEventTime,
    timestamp: DateTime.now(),
  );
}
