/// Formatea la pendiente para mostrarla en pantalla al estilo de un
/// ciclocomputador profesional (Garmin/Wahoo): la agrupa en bandas de
/// [_bandWidth] y aplica histéresis por tiempo antes de saltar de una
/// banda a otra. Así un blip de medio segundo no hace que el número en
/// pantalla salte, aunque el valor de fondo (ya filtrado por
/// SlopePlausibilityFilter) sí varíe un poco.
///
/// Es PURAMENTE de presentación -- no toca el valor que se guarda en
/// RoutePointSnapshot ni el que alimenta ActivityChartsCard. Por eso
/// vive separado del filtro de plausibilidad: uno decide qué es real,
/// este decide cómo se ve.
class SlopePresentationFormatter {
  double? _displayedBand;
  DateTime? _pendingChangeSince;
  double? _pendingValue;

  static const double _bandWidth = 0.5;
  static const Duration _hysteresisDuration = Duration(milliseconds: 800);

  /// [now] es inyectable para poder probar el formateador sin depender
  /// del reloj real.
  double format(double filteredSlope, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final rounded = (filteredSlope / _bandWidth).round() * _bandWidth;

    if (_displayedBand == null) {
      _displayedBand = rounded;
      return _displayedBand!;
    }

    if (rounded == _displayedBand) {
      _pendingValue = null;
      _pendingChangeSince = null;
      return _displayedBand!;
    }

    if (_pendingValue != rounded) {
      // Primera vez que aparece este nuevo valor: empieza a contar,
      // pero todavía no cambiamos lo que se muestra.
      _pendingValue = rounded;
      _pendingChangeSince = currentTime;
      return _displayedBand!;
    }

    if (currentTime.difference(_pendingChangeSince!) >= _hysteresisDuration) {
      _displayedBand = rounded;
      _pendingValue = null;
      _pendingChangeSince = null;
    }

    return _displayedBand!;
  }

  void reset() {
    _displayedBand = null;
    _pendingChangeSince = null;
    _pendingValue = null;
  }
}
