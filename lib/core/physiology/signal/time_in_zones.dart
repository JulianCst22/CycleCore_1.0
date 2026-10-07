/// Segundos pasados en cada zona.
///
/// [lowerBounds] son los límites inferiores de las zonas, en orden
/// creciente: la zona `i` va de `lowerBounds[i]` (incluido) a
/// `lowerBounds[i + 1]` (excluido) y la última no tiene techo. Un valor
/// por debajo del primer límite cuenta en la zona 0.
///
/// Los segundos sin lectura (`null`) no se cuentan; las pausas ya no
/// están en una serie de tiempo activo.
List<int> timeInZones(List<double?> series, List<double> lowerBounds) {
  assert(lowerBounds.isNotEmpty);
  for (var i = 1; i < lowerBounds.length; i++) {
    assert(lowerBounds[i] > lowerBounds[i - 1], 'Límites no crecientes');
  }
  final seconds = List<int>.filled(lowerBounds.length, 0);
  for (final v in series) {
    if (v == null) continue;
    seconds[_zoneOf(v, lowerBounds)]++;
  }
  return seconds;
}

int _zoneOf(double value, List<double> lowerBounds) {
  var low = 0, high = lowerBounds.length - 1;
  if (value < lowerBounds[0]) return 0;
  while (low < high) {
    final mid = (low + high + 1) >> 1;
    if (lowerBounds[mid] <= value) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  return low;
}
