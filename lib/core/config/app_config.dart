/// Configuración de infraestructura que cambia según el entorno. Se
/// centraliza aquí para no tener URLs sueltas por el código.
class AppConfig {
  AppConfig._();

  /// Base donde viven las teselas de elevación (.hgt) que TÚ subiste a tu
  /// cloud (bucket S3, R2, Backblaze, etc.) -- el celular NUNCA llama a
  /// NASA directamente, ni conoce que NASA existe. Solo habla con esta URL.
  ///
  /// TODO: reemplazar por la URL real de tu bucket cuando subas las
  /// teselas manualmente. Ej: 'https://tu-bucket.s3.amazonaws.com/elevation-tiles'
  static const String elevationTilesBaseUrl = 'http://localhost:8000';

  /// Base donde viven los grafos viales ya preprocesados (.roadgraph),
  /// uno por región -- ver `tools/preprocess_osm_to_roadgraph.py` y
  /// `RoadRegionRepository`. Mismo espíritu que `elevationTilesBaseUrl`:
  /// el celular solo habla con TU bucket, nunca con Geofabrik/OSM
  /// directamente en tiempo de ejecución.
  ///
  /// TODO: reemplazar por la URL real de tu bucket cuando subas los
  /// archivos .roadgraph generados por el script de preprocesamiento.
  /// Ej: 'https://tu-bucket.s3.amazonaws.com/road-regions'
  static const String roadRegionsBaseUrl = 'http://localhost:8000';

  /// Base donde viven los segmentos "nativos" de la app: un
  /// `catalog.json` con la lista y un `.gpx` por segmento (altitud
  /// barométrica de un ciclocomputador). Mismo espíritu que las dos
  /// URLs de arriba -- el celular solo habla con TU bucket. Ver
  /// `SegmentCatalogRepository`.
  ///
  /// TODO: reemplazar por la URL real de tu bucket.
  /// Ej: 'https://tu-bucket.s3.amazonaws.com/segments'
  static const String segmentCatalogBaseUrl = 'http://localhost:8000';
}
