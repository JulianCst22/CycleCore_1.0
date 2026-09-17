const List<String> _climbKeywords = [
  'alto ',
  'alto de',
  'paso ',
  'paso de',
  'puerto de',
  'cima',
  'cumbre',
  'páramo',
  'paramo',
  'mirador',
  'cerro ',
  'cuchilla',
];

/// Diferencia de altitud (m) por encima de la cual se considera que el
/// destino es "en alto" aunque el nombre no lo diga.
const double kClimbAltitudeDeltaMeters = 200;

/// ¿Este destino parece un alto / puerto de montaña? Se usa para
/// dibujarlo con una montañita en el mapa y en la tarjeta de confirmar
/// la ruta, y para sugerir el tipo "peak" al guardarlo.
///
/// Heurística deliberadamente simple (no hay una base de datos de altos
/// del país): el nombre menciona un término de montaña, O el destino
/// está bastante más alto que el punto de partida.
bool looksLikeClimb(
  String placeName, {
  double? destinationAltitudeMeters,
  double? originAltitudeMeters,
}) {
  final normalized = placeName.toLowerCase();
  if (_climbKeywords.any(normalized.contains)) return true;

  if (destinationAltitudeMeters != null && originAltitudeMeters != null) {
    return destinationAltitudeMeters - originAltitudeMeters >
        kClimbAltitudeDeltaMeters;
  }
  return false;
}
