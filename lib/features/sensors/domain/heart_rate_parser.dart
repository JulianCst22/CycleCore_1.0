import 'heart_rate_reading.dart';

/// Parsea el payload crudo de la característica estándar
/// "Heart Rate Measurement" (Bluetooth SIG, UUID 0x2A37).
///
/// Es una función PURA a propósito -- no importa nada de flutter_blue_plus.
/// Eso permite escribir un test unitario con bytes fijos (ver ejemplo más
/// abajo en los comentarios) sin necesitar hardware real ni mockear todo
/// el stack de BLE. Cualquier sensor que cumpla el estándar (Polar,
/// Garmin, Wahoo, Magene, etc) envía el dato en este mismo formato.
///
/// Estructura del primer byte (flags), según la especificación oficial:
///   bit 0 = formato del valor de FC (0 = UINT8, 1 = UINT16)
///   bit 1 = estado de contacto con la piel (solo válido si bit 2 = 1)
///   bit 2 = si el sensor soporta reportar el contacto con la piel
///   (bits 3 y 4 se refieren a energía expendida e intervalos RR,
///    que no se usan en el alcance de este proyecto)
///
/// Ejemplo para test unitario: bytes [0x00, 75] representa FC=75 en
/// formato UINT8, sin soporte de detección de contacto.
HeartRateReading parseHeartRateMeasurement(List<int> data) {
  if (data.isEmpty) {
    throw ArgumentError('Payload de Heart Rate Measurement vacío');
  }

  final flags = data[0];
  final isUint16Format = (flags & 0x01) != 0;
  final contactStatusSupported = (flags & 0x04) != 0;
  final contactDetected = (flags & 0x02) != 0;

  final int bpm;
  if (isUint16Format) {
    if (data.length < 3) {
      throw ArgumentError(
        'Payload incompleto para formato UINT16 de frecuencia cardíaca',
      );
    }
    bpm = data[1] | (data[2] << 8);
  } else {
    bpm = data[1];
  }

  return HeartRateReading(
    bpm: bpm,
    // Si el sensor no reporta contacto (algunos modelos no lo soportan),
    // asumimos que sí hay contacto en vez de mostrar una falsa alarma.
    sensorContactDetected: contactStatusSupported ? contactDetected : true,
    timestamp: DateTime.now(),
  );
}
