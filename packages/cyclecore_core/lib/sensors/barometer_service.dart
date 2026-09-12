import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

/// Única puerta de entrada al barómetro del dispositivo.
///
/// No todos los teléfonos Android tienen sensor de presión barométrica.
/// Si el dispositivo no lo tiene, el stream simplemente nunca emite
/// nada -- el resto del sistema (AltitudeFusionService) ya sabe hacer
/// fallback a GPS puro en ese caso, sin necesidad de detectarlo
/// explícitamente aquí.
class BarometerService {
  /// Stream de presión atmosférica en hectopascales (hPa).
  /// A nivel del mar, la presión estándar es ~1013.25 hPa.
  Stream<double> watchPressureHpa() {
    return barometerEventStream().map((event) => event.pressure);
  }
}
