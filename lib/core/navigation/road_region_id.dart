/// Identifica una región descargable del grafo vial (equivalente a
/// `SrtmTileId` pero para calles en vez de elevación).
///
/// A diferencia de SRTM, que es una grilla uniforme de 1°x1° y se
/// puede calcular matemáticamente a partir de lat/lng, las regiones de
/// OSM vienen de extractos de Geofabrik con límites irregulares
/// (departamentos, países) -- por eso acá SÍ hace falta un catálogo
/// estático con la caja delimitadora (bounding box) de cada una.
class RoadRegionId {
  final String id;
  final String displayName;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final String fileName;

  const RoadRegionId({
    required this.id,
    required this.displayName,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.fileName,
  });

  bool contains(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  /// Catálogo de regiones disponibles.
  static const List<RoadRegionId> catalog = [
    // ---------------------------------------------------------
    // ZONA DE TESTING ACTIVA
    // ---------------------------------------------------------
    RoadRegionId(
      id: 'bogota_cundinamarca',
      displayName: 'Bogotá y Cundinamarca',
      minLat: 3.70,
      maxLat: 5.90,
      minLng: -74.90,
      maxLng: -73.00,
      fileName: 'bogota_cundinamarca.roadgraph',
    ),
    
    // ---------------------------------------------------------
    // VERSIÓN FINAL NACIONAL (Comentada para fase de pruebas)
    // ---------------------------------------------------------
    // Cuando el proyecto escale para producción y proceses el archivo 
    // colombia-260823.osm.pbf completo sin recortarlo, descomenta esto 
    // y elimina/comenta el de Cundinamarca.
    /*
    RoadRegionId(
      id: 'colombia_nacional',
      displayName: 'Colombia Completa',
      minLat: -4.23, // Sur (Amazonas)
      maxLat: 13.40, // Norte (San Andrés y Providencia / Guajira)
      minLng: -81.85, // Occidente (San Andrés)
      maxLng: -66.85, // Oriente (Guainía)
      fileName: 'colombia.roadgraph',
    ),
    */
  ];

  /// Devuelve la región del catálogo que cubre esa posición, o null si
  /// no hay ninguna (todavía no preprocesaste esa zona).
  static RoadRegionId? forPosition(double lat, double lng) {
    for (final region in catalog) {
      if (region.contains(lat, lng)) return region;
    }
    return null;
  }

  static RoadRegionId? byId(String id) {
    for (final region in catalog) {
      if (region.id == id) return region;
    }
    return null;
  }
}