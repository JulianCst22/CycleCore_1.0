/// Snapshot de todos los valores en vivo que la pantalla de segmento
/// puede mostrar mientras el ciclista recorre un segmento vigilado. Se
/// arma una vez por frame en la pantalla de segmento (Fase D) y se le
/// pasa a cada `SegmentCockpitField` para que decida qué pintar --
/// mismo patrón que `CockpitLiveData` en el mapa.
///
/// Los campos que dependen de la mejor marca / fantasma
/// (`deltaVsPr`, `projectedFinish`, `bestTime`) son `null` cuando no
/// hay un esfuerzo previo con splits -- cada campo muestra `--`.
class SegmentLiveData {
  /// Tu tiempo dentro del segmento, ahora.
  final Duration elapsedInSegment;

  /// Distancia recorrida dentro del segmento (m) y la que falta.
  final double alongMeters;
  final double remainingMeters;
  final double totalMeters;

  /// 0.0-1.0.
  final double progressFraction;

  /// Desnivel positivo que falta hasta la meta (m), del perfil congelado.
  final double remainingElevationGainMeters;

  /// Pendiente en tu posición actual, leída del perfil congelado (%).
  final double currentSlopePercent;

  /// Pendiente media de TODO el segmento (%).
  final double avgSegmentSlopePercent;

  final double currentSpeedKmh;

  /// Velocidad media DENTRO del segmento (distancia recorrida / tiempo).
  final double avgSpeedInSegmentKmh;

  final double currentAltitudeMeters;

  final int? heartRateBpm;
  final int? powerWatts;
  final double? cadenceRpm;

  /// Diferencia contra el fantasma en tu posición actual
  /// (+ = vas más lento). `null` si no hay fantasma.
  final Duration? deltaVsPr;

  /// Tiempo total proyectado si mantenés tu ritmo relativo al fantasma.
  /// `null` si no hay fantasma.
  final Duration? projectedFinish;

  /// Mejor marca previa del segmento. `null` si nunca se completó.
  final Duration? bestTime;

  const SegmentLiveData({
    required this.elapsedInSegment,
    required this.alongMeters,
    required this.remainingMeters,
    required this.totalMeters,
    required this.progressFraction,
    required this.remainingElevationGainMeters,
    required this.currentSlopePercent,
    required this.avgSegmentSlopePercent,
    required this.currentSpeedKmh,
    required this.avgSpeedInSegmentKmh,
    required this.currentAltitudeMeters,
    this.heartRateBpm,
    this.powerWatts,
    this.cadenceRpm,
    this.deltaVsPr,
    this.projectedFinish,
    this.bestTime,
  });
}

/// Un elemento mostrable en la pantalla de segmento en vivo. El usuario
/// elige cuáles, en qué orden y con qué tamaño desde
/// Perfil → Ajustes → "Datos del segmento" -- TODO es opcional,
/// incluidos el mapa, el perfil y la barra de progreso.
///
/// Hay dos tipos:
///  - **campos de dato** (la mayoría): un número con etiqueta y unidad.
///  - **bloques visuales** ([mapaSegmento], [perfilAltimetria],
///    [barraProgreso]): widgets completos que se renderizan dentro del
///    tile. Ver [isVisualBlock].
///
/// La presentación (ícono, color, formateo) vive en
/// `presentation/segment_cockpit_field_ui.dart` -- este archivo se
/// queda puro, igual que el resto de `domain/`.
enum SegmentCockpitField {
  // --- Bloques visuales ---
  mapaSegmento,
  perfilAltimetria,
  barraProgreso,

  // --- Campos de dato ---
  tiempoEnSegmento,
  deltaPr,
  proyeccionMeta,
  mejorTiempo,
  distanciaRecorrida,
  distanciaRestante,
  progreso,
  desnivelRestante,
  pendienteActual,
  pendienteMediaSegmento,
  velocidad,
  velocidadMediaSegmento,
  frecuenciaCardiaca,
  potencia,
  cadencia,
  altitud,
}

extension SegmentCockpitFieldKind on SegmentCockpitField {
  /// true para los que se renderizan como un widget completo (mapa,
  /// perfil, barra) en vez de un número.
  bool get isVisualBlock =>
      this == SegmentCockpitField.mapaSegmento ||
      this == SegmentCockpitField.perfilAltimetria ||
      this == SegmentCockpitField.barraProgreso;
}
