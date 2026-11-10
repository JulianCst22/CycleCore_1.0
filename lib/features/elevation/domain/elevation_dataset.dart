/// Modelo de elevación del que salen las teselas `.hgt`. El ciclista elige
/// cuál usar en Ajustes › Elevación (y, para una salida ya guardada, en
/// "Ajustar altimetría"); los dos pueden estar descargados a la vez.
///
/// En la salida Bogotá - La Calera - Bogotá del 28-oct-2026, con la misma
/// receta de desnivel: Copernicus 956 m, FABDEM 925 m, Garmin 911 m.
enum ElevationDataset {
  /// Copernicus GLO-30 (ESA / Unión Europea; datos DLR y Airbus). Mide la
  /// superficie, con edificios y árboles. Libre también para uso
  /// comercial: es el modelo estándar.
  copernicus(
    id: 'copernicus-glo30',
    label: 'Copernicus GLO-30',
    summary: 'Estándar. Mide la superficie, con edificios y árboles.',
    isPremium: false,
  ),

  /// FABDEM V1-2 (Universidad de Bristol / Fathom): el mismo Copernicus
  /// sin edificios ni árboles. Licencia solo no comercial; en producción
  /// sería el plan pago.
  fabdem(
    id: 'fabdem-v1-2',
    label: 'FABDEM',
    summary: 'Alta precisión. El terreno sin edificios ni árboles.',
    isPremium: true,
  );

  /// Lo que se guarda en preferencias y en el registro de teselas.
  final String id;
  final String label;
  final String summary;

  /// Se muestra como plan pago.
  final bool isPremium;

  const ElevationDataset({
    required this.id,
    required this.label,
    required this.summary,
    required this.isPremium,
  });

  /// El modelo de [id], o `null` si no es ninguno de los actuales (las
  /// teselas SRTM de antes, por ejemplo).
  static ElevationDataset? byId(String? id) {
    for (final dataset in values) {
      if (dataset.id == id) return dataset;
    }
    return null;
  }

  /// El que se usa si el ciclista no ha elegido.
  static const standard = ElevationDataset.copernicus;
}
