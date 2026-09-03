/// Qué tipo de lugar es una ubicación guardada -- decide el ícono en el
/// mapa y en el buscador.
enum PlaceKind {
  home('home'),
  peak('peak'),
  generic('generic');

  final String wire;
  const PlaceKind(this.wire);

  static PlaceKind fromWire(String raw) => PlaceKind.values.firstWhere(
    (k) => k.wire == raw,
    orElse: () => PlaceKind.generic,
  );
}

/// Un destino de navegación ya resuelto a coordenadas -- lo que el
/// buscador ("¿A dónde vamos?") le devuelve al mapa. NO es todavía una
/// ruta: el mapa lo usa para calcular la ruta y pedir confirmación
/// antes de activarla.
///
/// Sale de tres sitios: un resultado de búsqueda (Nominatim), una
/// ubicación guardada, o un destino reciente.
class NavigationTarget {
  final String name;
  final double lat;
  final double lng;
  final PlaceKind kind;

  const NavigationTarget({
    required this.name,
    required this.lat,
    required this.lng,
    this.kind = PlaceKind.generic,
  });
}
