import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// TEMPORAL -- herramienta de diagnóstico, no arquitectura permanente.
///
/// Escribe un CSV con los valores intermedios de cada punto (GPS
/// crudo, presión suavizada, altitud barométrica, delta antes/después
/// del recorte de outliers, altitud fusionada final) para poder
/// diagnosticar en campo real sin necesidad de cable ni consola.
///
/// Se guarda en almacenamiento externo específico de la app
/// (`Android/data/<paquete>/files/`) para poder compartirlo fácil con
/// share_plus al terminar la salida.
class AltitudeDebugLogger {
  IOSink? _sink;
  File? _currentFile;

  Future<void> start(String sessionId) async {
    final dir =
        await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();

    final file = File(p.join(dir.path, 'altitude_debug_$sessionId.csv'));
    _currentFile = file;
    _sink = file.openWrite();

    _sink!.writeln(
      'timestamp,gps_altitude,smoothed_pressure_hpa,barometric_altitude,'
      'delta_raw,delta_clamped,fused_altitude,slope_percent',
    );
  }

  void logSample({
    required DateTime timestamp,
    required double gpsAltitude,
    required double? smoothedPressureHpa,
    required double? barometricAltitude,
    required double barometricDeltaRaw,
    required double barometricDeltaClamped,
    required double fusedAltitude,
    required double slopePercent,
  }) {
    _sink?.writeln(
      '${timestamp.toIso8601String()},'
      '${gpsAltitude.toStringAsFixed(2)},'
      '${smoothedPressureHpa?.toStringAsFixed(2) ?? ''},'
      '${barometricAltitude?.toStringAsFixed(2) ?? ''},'
      '${barometricDeltaRaw.toStringAsFixed(3)},'
      '${barometricDeltaClamped.toStringAsFixed(3)},'
      '${fusedAltitude.toStringAsFixed(2)},'
      '${slopePercent.toStringAsFixed(2)}',
    );
  }

  Future<void> stop() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }

  /// Archivo del log de la sesión más reciente (o ya cerrada), para
  /// compartirlo con share_plus.
  File? get currentFile => _currentFile;
}
