/// Configuración de infraestructura que cambia según el entorno. Se
/// centraliza aquí para no tener URLs sueltas por el código.
class AppConfig {
  AppConfig._();

  /// Dónde viven los archivos que la app descarga: el release `mapas-v1`
  /// del repositorio público `cyclecore-mapas` en GitHub (ver
  /// https://github.com/JulianCst22/cyclecore-mapas/releases). Un release
  /// no tiene carpetas: teselas de elevación (`N04W074.hgt`), mapas por
  /// región (`regiones.json` + `<región>.roadgraph.gz`) y catálogo de
  /// segmentos (`catalog.json` + un `.gpx` por segmento) van todos
  /// sueltos en la misma dirección. Para publicar mapas nuevos se crea
  /// otro release (`mapas-v2`) y se cambia esta constante.
  ///
  /// El celular nunca habla con NASA ni con OpenStreetMap para esto: solo
  /// con esta dirección. Las descargas de GitHub redirigen a su CDN; el
  /// cliente `http` sigue esas redirecciones solo.
  static const String filesBaseUrl =
      'https://github.com/JulianCst22/cyclecore-mapas/releases/download/mapas-v1';

  /// Teselas de elevación (.hgt), en su propio release: Copernicus GLO-30
  /// (ESA / Unión Europea) convertido a `.hgt` con
  /// `herramientas/dem_a_hgt.py` de "Servidor CycleCore". Su licencia
  /// permite también el uso comercial, con aviso de origen. En la salida a
  /// La Calera del 28-oct-2026 dio 956 m de desnivel contra 911 del
  /// Garmin.
  static const String elevationTilesBaseUrl =
      'https://github.com/JulianCst22/cyclecore-mapas/releases/download/elevacion-copernicus-v1';

  /// Mapas de navegación por región: `regiones.json` y un
  /// `<región>.roadgraph.gz` por departamento. Los genera la carpeta
  /// "Servidor CycleCore" del escritorio (GENERAR MAPAS.bat).
  static const String roadRegionsBaseUrl = filesBaseUrl;

  /// Segmentos "nativos" de la app: un `catalog.json` con la lista y un
  /// `.gpx` por segmento. Ver `SegmentCatalogRepository`.
  static const String segmentCatalogBaseUrl = filesBaseUrl;
}
