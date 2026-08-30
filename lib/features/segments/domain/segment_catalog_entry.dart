/// Una fila del `catalog.json` remoto de segmentos "nativos" de la app.
///
/// El JSON esperado (misma idea que el catálogo de teselas de
/// elevación / regiones de grafo vial):
/// ```json
/// {
///   "segments": [
///     {
///       "id": "patios_belisario",
///       "name": "Alto de Patios (Belisario)",
///       "region": "Cundinamarca",
///       "gpx": "patios_belisario.gpx",
///       "distanceM": 5920,
///       "gainM": 499,
///       "avgSlope": 6.9
///     }
///   ]
/// }
/// ```
class SegmentCatalogEntry {
  final String id;
  final String name;
  final String? region;

  /// Nombre del archivo GPX dentro del mismo bucket
  /// (`AppConfig.segmentCatalogBaseUrl/<gpxFileName>`).
  final String gpxFileName;

  /// Metadatos solo para mostrar en la lista antes de descargar -- las
  /// stats reales se recalculan del GPX al importarlo.
  final double? distanceMeters;
  final double? elevationGainMeters;
  final double? avgSlopePercent;

  const SegmentCatalogEntry({
    required this.id,
    required this.name,
    required this.gpxFileName,
    this.region,
    this.distanceMeters,
    this.elevationGainMeters,
    this.avgSlopePercent,
  });

  factory SegmentCatalogEntry.fromJson(Map<String, dynamic> json) {
    return SegmentCatalogEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      gpxFileName: (json['gpx'] ?? json['gpxFileName']) as String,
      region: json['region'] as String?,
      distanceMeters: (json['distanceM'] as num?)?.toDouble(),
      elevationGainMeters: (json['gainM'] as num?)?.toDouble(),
      avgSlopePercent: (json['avgSlope'] as num?)?.toDouble(),
    );
  }
}
