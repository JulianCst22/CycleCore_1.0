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

  /// Base donde viven los mapas de navegación por región: el catálogo
  /// `regiones.json` y un `<región>.roadgraph.gz` por departamento. Los
  /// genera y los sirve la carpeta "Servidor CycleCore" del escritorio
  /// (GENERAR MAPAS.bat / INICIAR SERVIDOR.bat), en la ruta `/grafos`
  /// del mismo servidor que las teselas. Para pasarlos a la nube basta
  /// con subir esa carpeta `grafos` al bucket y cambiar esta dirección.
  static const String roadRegionsBaseUrl = 'http://localhost:8000/grafos';

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
