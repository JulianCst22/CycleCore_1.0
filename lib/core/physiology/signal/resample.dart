/// Una lectura con su instante, en segundos de tiempo activo.
typedef TimedSample = ({int second, double? value});

/// Serie de un valor por segundo a partir de lecturas irregulares, con
/// retención de orden cero: cada segundo toma la última lectura conocida.
///
/// Un segundo queda en `null` si todavía no había lecturas o si la última
/// tiene más de [maxHoldSeconds] de antigüedad (el sensor se cayó). Las
/// lecturas con valor `null` cortan la retención.
///
/// [duration] fija el largo de la serie (por defecto, hasta la última
/// lectura, inclusive).
List<double?> resampleToSeconds(
  Iterable<TimedSample> samples, {
  int maxHoldSeconds = 5,
  int? duration,
}) {
  assert(maxHoldSeconds >= 0);
  final sorted = samples.where((s) => s.second >= 0).toList()
    ..sort((a, b) => a.second.compareTo(b.second));
  if (sorted.isEmpty) return List.filled(duration ?? 0, null);

  final length = duration ?? sorted.last.second + 1;
  final out = List<double?>.filled(length, null);
  var next = 0;
  int? heldSince;
  double? held;
  for (var k = 0; k < length; k++) {
    while (next < sorted.length && sorted[next].second <= k) {
      held = sorted[next].value;
      heldSince = sorted[next].second;
      next++;
    }
    if (held != null && heldSince != null && k - heldSince <= maxHoldSeconds) {
      out[k] = held;
    }
  }
  return out;
}
