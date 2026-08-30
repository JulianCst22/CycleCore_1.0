/// De dónde nació un segmento. Se guarda como string en
/// `Segments.source` (ver `app_database.dart`) -- este enum es el
/// espejo tipado que usa el código.
enum SegmentSource {
  /// Recortado de una actividad propia, ya aplanada contra HGT.
  activity('activity'),

  /// Importado de un archivo GPX que subió el usuario (altitud
  /// barométrica de un ciclocomputador -- prioridad 1 sobre HGT).
  gpxImport('gpxImport'),

  /// Descargado del catálogo remoto de segmentos "nativos" de la app.
  nativeCatalog('nativeCatalog');

  final String wire;
  const SegmentSource(this.wire);

  static SegmentSource fromWire(String raw) {
    return SegmentSource.values.firstWhere(
      (s) => s.wire == raw,
      orElse: () => SegmentSource.activity,
    );
  }
}
