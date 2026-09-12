import 'dart:math' as math;

/// Identifica una tesela SRTM por su esquina suroeste (el estándar real
/// que usan NASA/USGS y todo el ecosistema GIS) -- ej. lat=4.6, lng=-74.08
/// vive en la tesela "N04W075.hgt" (cubre de lat 4 a 5, lng -75 a -74).
class SrtmTileId {
  final int latFloor;
  final int lngFloor;

  const SrtmTileId({required this.latFloor, required this.lngFloor});

  String get fileName {
    final ns = latFloor >= 0 ? 'N' : 'S';
    final ew = lngFloor >= 0 ? 'E' : 'W';
    final latStr = latFloor.abs().toString().padLeft(2, '0');
    final lngStr = lngFloor.abs().toString().padLeft(3, '0');
    return '$ns$latStr$ew$lngStr.hgt';
  }

  static SrtmTileId fromLatLng(double lat, double lng) {
    return SrtmTileId(latFloor: lat.floor(), lngFloor: lng.floor());
  }

  @override
  bool operator ==(Object other) =>
      other is SrtmTileId &&
      other.latFloor == latFloor &&
      other.lngFloor == lngFloor;

  @override
  int get hashCode => Object.hash(latFloor, lngFloor);

  @override
  String toString() => fileName;
}

/// Calcula todas las teselas que cubren un radio (en km) alrededor de una
/// posición. Cada tesela SRTM es de 1°×1° (~111 km de lado), así que esto
/// se traduce naturalmente en "la tesela donde estás + las vecinas que
/// toque el radio" -- sin necesitar fronteras departamentales/políticas.
List<SrtmTileId> tilesForRadius({
  required double centerLat,
  required double centerLng,
  required double radiusKm,
}) {
  const kmPerDegreeLat = 111.0;
  final kmPerDegreeLng = 111.0 * math.cos(centerLat * math.pi / 180).abs();

  final latDelta = radiusKm / kmPerDegreeLat;
  final lngDelta = kmPerDegreeLng < 1 ? 180.0 : radiusKm / kmPerDegreeLng;

  final minLat = (centerLat - latDelta).floor();
  final maxLat = (centerLat + latDelta).floor();
  final minLng = (centerLng - lngDelta).floor();
  final maxLng = (centerLng + lngDelta).floor();

  final tiles = <SrtmTileId>[];
  for (int lat = minLat; lat <= maxLat; lat++) {
    for (int lng = minLng; lng <= maxLng; lng++) {
      tiles.add(SrtmTileId(latFloor: lat, lngFloor: lng));
    }
  }
  return tiles;
}
