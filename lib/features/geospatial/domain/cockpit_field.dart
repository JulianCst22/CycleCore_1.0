/// Snapshot de todos los valores en vivo que el cockpit configurable
/// puede necesitar mostrar, sin importar qué campos haya elegido el
/// usuario. Se arma una sola vez por frame en MapScreen y se le pasa a
/// cada CockpitField (ver cockpit_field_ui.dart) para que decida qué
/// mostrar -- así el widget de cada campo no necesita saber de dónde
/// viene cada dato (Riverpod, RouteRecordingState, listas locales de
/// muestras, etc).
class CockpitLiveData {
  final Duration elapsed;
  final double distanceMeters;
  final double currentSpeedKmh;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final double elevationGainMeters;
  final double slopePercent;

  /// Null si no hay sensor conectado -- cada campo decide mostrar '--'.
  final int? heartRateBpm;
  final int? powerWatts;

  /// Máximo visto EN ESTA SESIÓN de grabación (no el histórico de la
  /// actividad, que todavía no existe mientras se está grabando). Se
  /// calcula en MapScreen a partir de las mismas listas de muestras que
  /// alimentan `RouteRecordingController.finishRecording`.
  final int? maxPowerWattsSoFar;
  final double? cadenceRpm;
  final double? maxCadenceRpmSoFar;

  const CockpitLiveData({
    required this.elapsed,
    required this.distanceMeters,
    required this.currentSpeedKmh,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.elevationGainMeters,
    required this.slopePercent,
    this.heartRateBpm,
    this.powerWatts,
    this.maxPowerWattsSoFar,
    this.cadenceRpm,
    this.maxCadenceRpmSoFar,
  });
}

/// Un campo mostrable en el cockpit configurable (pantalla completa,
/// estilo Garmin). El panel compacto (velocidad/tiempo/distancia) NO
/// usa este enum -- ese es fijo a propósito, ver MapScreen.
///
/// La presentación de cada campo (ícono, color, cómo formatear su
/// valor) vive aparte, en `presentation/cockpit_field_ui.dart` -- este
/// archivo se queda puro (sin Flutter) para seguir la misma convención
/// que el resto de `domain/` en este feature.
enum CockpitField {
  tiempo,
  distancia,
  velocidad,
  velocidadProm,
  velocidadMax,
  desnivel,
  pendiente,
  frecuenciaCardiaca,
  potencia,
  potenciaMax,
  cadencia,
  cadenciaMax,
}
