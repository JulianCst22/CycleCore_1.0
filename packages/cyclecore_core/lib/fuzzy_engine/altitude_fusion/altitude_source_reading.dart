/// Snapshot de las fuentes de altitud disponibles para un punto GPS,
/// ya recolectadas por RouteRecordingController -- este archivo no
/// sabe leer sensores, solo agrupa lo que ya se leyó.
class AltitudeSourceReading {
  /// Altitud del DEM (SRTM/NASA) para esta coordenada, o null si no hay
  /// tesela descargada.
  final double? demAltitude;

  /// Altitud en tiempo real ya fusionada por AltitudeFusionService
  /// (GPS+barómetro si el dispositivo tiene barómetro, o GPS puro si
  /// no lo tiene -- AltitudeFusionService ya resuelve esa diferencia
  /// internamente, aquí se trata como una sola fuente "caja negra").
  final double realtimeAltitude;

  /// Precisión horizontal reportada por el GPS en metros
  /// (`Position.accuracy`), o null si no está disponible.
  final double? gpsAccuracyMeters;

  /// Distancia GPS recorrida desde el punto anterior. Se usa para medir
  /// cuánta distancia lleva sostenida una discrepancia entre fuentes.
  final double stepDistanceMeters;

  const AltitudeSourceReading({
    required this.demAltitude,
    required this.realtimeAltitude,
    required this.gpsAccuracyMeters,
    required this.stepDistanceMeters,
  });

  bool get tileAvailable => demAltitude != null;
}
