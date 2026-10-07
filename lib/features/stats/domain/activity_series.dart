import '../../../core/database/database.dart';
import '../../../core/physiology/physiology.dart';

/// Series de 1 Hz de una actividad guardada, sobre el tiempo en
/// movimiento.
///
/// Cada punto de ruta trae su instante de reloj desde el inicio (con las
/// pausas adentro) y la última lectura de cada sensor. Durante una pausa
/// no se graban puntos, así que un hueco entre dos puntos más largo que
/// [pauseGapSeconds] es una pausa: cuenta como un intervalo típico entre
/// puntos, no como tiempo pedaleado. Entre puntos se sostiene la última
/// lectura (así se grabó).
///
/// Las series miden exactamente el tiempo en movimiento de la actividad;
/// los segundos que ningún punto alcanza a cubrir quedan sin lectura.
final class ActivitySeries {
  final List<double?> power;
  final List<double?> heartRate;

  ActivitySeries._(List<double?> power, List<double?> heartRate)
    : power = List.unmodifiable(power),
      heartRate = List.unmodifiable(heartRate);

  int get movingSeconds => power.length;

  /// Segundos con lectura de cada sensor.
  int get powerSeconds => _countReadings(power);
  int get heartRateSeconds => _countReadings(heartRate);

  factory ActivitySeries.fromRoutePoints(
    List<RoutePointSnapshot> points, {
    required int movingSeconds,
    int pauseGapSeconds = 10,
  }) {
    final length = movingSeconds < 0 ? 0 : movingSeconds;
    List<double?> empty() => List<double?>.filled(length, null);
    if (points.isEmpty || length == 0) {
      return ActivitySeries._(empty(), empty());
    }
    // Actividades muy viejas guardaban todos los puntos con t = 0: sin
    // tiempos no hay esfuerzos sostenidos que medir.
    if (points.length > 1 &&
        points.every(
          (p) => p.secondsFromStart == points.first.secondsFromStart,
        )) {
      return ActivitySeries._(empty(), empty());
    }

    final gaps = [
      for (var i = 1; i < points.length; i++)
        _nonNegative(
          points[i].secondsFromStart - points[i - 1].secondsFromStart,
        ),
    ];
    final typical = _typicalInterval(gaps, pauseGapSeconds);

    final power = <TimedSample>[];
    final heartRate = <TimedSample>[];
    var active = 0;
    for (var i = 0; i < points.length; i++) {
      if (i > 0) {
        final gap = gaps[i - 1];
        active += gap > pauseGapSeconds ? typical : gap;
      }
      final p = points[i];
      power.add((second: active, value: p.powerWatts?.toDouble()));
      heartRate.add((second: active, value: p.heartRateBpm?.toDouble()));
    }

    return ActivitySeries._(
      resampleToSeconds(
        power,
        maxHoldSeconds: pauseGapSeconds,
        duration: length,
      ),
      resampleToSeconds(
        heartRate,
        maxHoldSeconds: pauseGapSeconds,
        duration: length,
      ),
    );
  }

  static int _nonNegative(int x) => x < 0 ? 0 : x;

  /// Mediana de los intervalos normales (sin pausas); 1 s si no hay.
  static int _typicalInterval(List<int> gaps, int pauseGapSeconds) {
    final normal = [
      for (final g in gaps)
        if (g > 0 && g <= pauseGapSeconds) g,
    ]..sort();
    if (normal.isEmpty) return 1;
    return normal[normal.length ~/ 2];
  }

  static int _countReadings(List<double?> series) =>
      series.where((v) => v != null).length;
}

/// Segundos en cada zona y segundos sin lectura: juntos suman el largo de
/// la serie (el tiempo en movimiento).
typedef ZoneSeconds = ({List<int> seconds, int withoutReading});

/// Reparte [series] en las zonas que empiezan en [lowerBounds]. Una
/// lectura por debajo de la primera zona cuenta en ella. `null` si los
/// límites no crecen (zonas mal configuradas) o no hay zonas.
ZoneSeconds? secondsInZones(List<double?> series, List<num> lowerBounds) {
  if (lowerBounds.isEmpty) return null;
  for (var i = 1; i < lowerBounds.length; i++) {
    if (lowerBounds[i] <= lowerBounds[i - 1]) return null;
  }
  final seconds = timeInZones(series, [
    for (final b in lowerBounds) b.toDouble(),
  ]);
  final counted = seconds.fold(0, (s, x) => s + x);
  return (seconds: seconds, withoutReading: series.length - counted);
}
