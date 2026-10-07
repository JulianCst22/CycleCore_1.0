import 'dart:math' as math;
import 'dart:typed_data';

import '../../../../core/physiology/physiology.dart';
import '../athlete.dart';
import '../coaching_parameters.dart';

/// Lo que llega cada segundo de tiempo activo dentro del segmento.
final class RideTick {
  /// Segundos activos desde que empezó el segmento (0, 1, 2…).
  final int second;

  /// Avance dentro del segmento, en metros.
  final double alongMeters;
  final double? power;
  final double? heartRate;
  final double? cadence;

  /// Velocidad en metros por segundo. Con la pendiente alcanza para
  /// estimar la potencia cuando no hay potenciómetro.
  final double? speed;

  /// Pendiente del punto donde va, en %.
  final double? slopePercent;

  const RideTick({
    required this.second,
    required this.alongMeters,
    this.power,
    this.heartRate,
    this.cadence,
    this.speed,
    this.slopePercent,
  });

  /// El mismo segundo con la pendiente del terreno puesta: la sabe quien
  /// tiene el perfil, no quien lee los sensores.
  RideTick withSlope(double slope) => RideTick(
    second: second,
    alongMeters: alongMeters,
    power: power,
    heartRate: heartRate,
    cadence: cadence,
    speed: speed,
    slopePercent: slope,
  );
}

/// Percentiles ±1σ del conjunto de atletas posibles.
typedef EnsembleBands = ({
  ({double lo, double hi}) reservePercent,
  ({double lo, double hi}) sufficiency,
  ({double lo, double hi}) sustainablePower,
});

/// Un atleta posible, compatible con la calibración: su sesgo de
/// potenciómetro, su CP, su W′ y su propio balance de W′.
final class _PossibleAthlete {
  final double beta;
  final WPrimeBalance balance;

  _PossibleAthlete(this.beta, this.balance);
}

/// Historia del esfuerzo dentro del segmento, segundo a segundo.
///
/// Lleva el balance de W′ del atleta nominal y, en paralelo, el de un
/// conjunto de atletas posibles muestreados de la incertidumbre de la
/// calibración (CP, W′ y su covarianza) y del potenciómetro. La banda de
/// la reserva sale de ese conjunto y respeta toda la historia: los
/// tramos sobre CP y las recuperaciones.
final class EffortTracker {
  final CoachAthlete athlete;
  final CoachingParameters parameters;

  final _power = <double?>[];

  /// Incertidumbre relativa de cada lectura de potencia: la del
  /// potenciómetro cuando lo hay, la de la estimación cuando no.
  final _powerSigma = <double?>[];

  /// Si esa lectura salió de la velocidad en vez de un potenciómetro.
  final _powerEstimated = <bool>[];
  final _heartRate = <double?>[];
  final _cadence = <double?>[];
  final _speed = <double?>[];
  late final WPrimeBalance _nominal;
  late final List<_PossibleAthlete> _ensemble;

  // Buffers del conjunto: se crean una vez y se reescriben en cada
  // inferencia (la selección de percentiles los reordena).
  Float64List? _reserveBuffer;
  Float64List? _sufficiencyBuffer;
  Float64List? _sustainableBuffer;

  EffortTracker({
    required this.athlete,
    this.parameters = const CoachingParameters(),
  }) {
    final model = athlete.power;
    _nominal = WPrimeBalance(cp: model.cp, wPrime: model.wPrime);
    final covariance = Covariance.diagonal([
      parameters.powerAccuracy,
      model.seCp,
      model.seWPrime,
    ]).withCovariance(1, 2, model.covariance);
    _ensemble = [
      for (final x in sampleMultivariateNormal(
        [1, model.cp, model.wPrime],
        covariance,
        samples: parameters.ensembleSize,
        seed: parameters.seed,
      ))
        _PossibleAthlete(
          math.max(0.5, x[0]),
          WPrimeBalance(
            cp: Watts(math.max(1.0, x[1])),
            wPrime: Joules(math.max(1.0, x[2])),
          ),
        ),
    ];
  }

  /// Agrega el segundo [tick].
  ///
  /// Si no hay potenciómetro se estima la potencia con la velocidad y la
  /// pendiente (ver [virtualPower]): en subida esa estimación es buena y
  /// permite seguir llevando el balance de W′. Lo que se adivina queda
  /// registrado en la banda y en la credibilidad, no escondido. Sin
  /// potencia y sin velocidad no se actualiza el balance: no hay forma de
  /// saber si fue esfuerzo o recuperación.
  void add(RideTick tick) {
    assert(tick.second == _power.length, 'Los segundos deben ser seguidos');
    final measured = tick.power;
    final estimated = measured == null ? _estimate(tick) : null;
    final p = measured ?? estimated?.value;
    _power.add(p);
    _powerEstimated.add(measured == null && estimated != null);
    _powerSigma.add(
      measured != null
          ? parameters.powerAccuracy
          : estimated == null
          ? null
          : estimated.standardUncertainty / math.max(1.0, estimated.value),
    );
    _heartRate.add(tick.heartRate);
    _cadence.add(tick.cadence);
    _speed.add(tick.speed);
    if (p == null) return;
    _nominal.update(Watts(p));
    for (final a in _ensemble) {
      a.balance.update(Watts(a.beta * p));
    }
  }

  /// Segundos registrados.
  int get seconds => _power.length;

  /// Potencia estimada a partir de la velocidad de este segundo; `null`
  /// si tampoco hay velocidad.
  UncertainValue? _estimate(RideTick tick) {
    final speed = tick.speed;
    if (speed == null || speed <= 0) return null;
    return virtualPower(
      speedMetersPerSecond: speed,
      slopePercent: tick.slopePercent ?? 0,
      resistance: athlete.resistance,
    );
  }

  /// La potencia con la que se está trabajando viene de la velocidad, no
  /// de un potenciómetro. Se mira la ventana del objetivo, que es la que
  /// alimenta los consejos.
  bool get powerIsEstimated {
    final window = math.max(
      0,
      _powerEstimated.length - parameters.basePowerWindowSeconds,
    );
    var estimated = 0, total = 0;
    for (var i = window; i < _powerEstimated.length; i++) {
      if (_power[i] == null) continue;
      total++;
      if (_powerEstimated[i]) estimated++;
    }
    return total > 0 && estimated * 2 > total;
  }

  /// Incertidumbre relativa típica de la potencia de la ventana: 1,5 %
  /// con potenciómetro, bastante más si viene de la velocidad.
  double get powerRelativeUncertainty {
    final window = math.max(
      0,
      _powerSigma.length - parameters.basePowerWindowSeconds,
    );
    var sum = 0.0, count = 0;
    for (var i = window; i < _powerSigma.length; i++) {
      final sigma = _powerSigma[i];
      if (sigma == null) continue;
      sum += sigma;
      count++;
    }
    return count == 0 ? parameters.powerAccuracy : sum / count;
  }

  double? get power => _meanOfLast(_power, parameters.powerWindowSeconds);
  double? get basePower =>
      _meanOfLast(_power, parameters.basePowerWindowSeconds);
  double? get heartRate =>
      _meanOfLast(_heartRate, parameters.heartRateWindowSeconds);

  /// Cadencia media de los segundos recientes en que se pedaleó. Los
  /// sensores dicen 0 rpm al dejar de pedalear; si esos ceros entraran
  /// al promedio, retomar el pedaleo después de un respiro bajaría la
  /// cadencia a la mitad por unos segundos y el torque parecería
  /// «atascado» sin estarlo. `null` si en la ventana no se pedaleó.
  double? get cadence {
    final pedalling = [
      for (final c in _lastValues(_cadence, parameters.cadenceWindowSeconds))
        if (c > 0) c,
    ];
    if (pedalling.isEmpty) return null;
    return pedalling.reduce((a, b) => a + b) / pedalling.length;
  }

  /// Velocidad media reciente en m/s. En subida no sirve para juzgar el
  /// esfuerzo, pero sí para saber si al ciclista le queda piñón.
  double? get speed => _meanOfLast(_speed, parameters.cadenceWindowSeconds);

  /// Índice de variabilidad (potencia normalizada / media) de la ventana
  /// reciente; `null` si todavía no alcanza para la potencia normalizada.
  double? get variability {
    final window = _lastValues(_power, parameters.normalizedPowerWindowSeconds);
    final np = normalizedPower(window);
    final mean = meanPower(window);
    if (np == null || mean == null || mean <= 0) return null;
    return np / mean;
  }

  /// Medias de potencia y pulso de la primera y la segunda mitad del
  /// esfuerzo, contando solo los segundos con ambas lecturas.
  ({double firstPower, double firstHr, double secondPower, double secondHr})?
  get halves {
    final n = _power.length;
    if (n < 2) return null;
    ({double p, double hr})? mean(int from, int to) {
      var p = 0.0, hr = 0.0, count = 0;
      for (var i = from; i < to; i++) {
        final w = _power[i], h = _heartRate[i];
        if (w == null || h == null) continue;
        p += w;
        hr += h;
        count++;
      }
      return count == 0 ? null : (p: p / count, hr: hr / count);
    }

    final a = mean(0, n ~/ 2), b = mean(n ~/ 2, n);
    if (a == null || b == null || a.p <= 0 || a.hr <= 0 || b.hr <= 0) {
      return null;
    }
    return (firstPower: a.p, firstHr: a.hr, secondPower: b.p, secondHr: b.hr);
  }

  /// Reserva del atleta nominal.
  Joules get balance => _nominal.balance;

  /// Reserva nominal como % de W′.
  double get reservePercent => 100 * _nominal.fraction;

  /// Reserva de cada atleta posible, en % de su propio W′.
  Iterable<double> get ensembleReservePercent =>
      _ensemble.map((a) => 100 * a.balance.fraction);

  /// Suficiencia de cada atleta posible a la potencia [power] (medida por
  /// el potenciómetro, que cada uno corrige con su sesgo).
  Iterable<double> ensembleSufficiency(double power, double remainingSeconds) =>
      _ensemble.map(
        (a) => sufficiency(
          balance: a.balance.balance,
          power: Watts(a.beta * power),
          cp: a.balance.cp,
          remainingSeconds: remainingSeconds,
        ),
      );

  /// Potencia que cada atleta posible podría sostener hasta el final,
  /// expresada como la marcaría el potenciómetro (se deshace su sesgo).
  Iterable<double> ensembleSustainablePower(double remainingSeconds) =>
      _ensemble.map(
        (a) =>
            sustainablePower(
              balance: a.balance.balance,
              cp: a.balance.cp,
              remainingSeconds: remainingSeconds,
            ) /
            a.beta,
      );

  /// Las tres bandas del conjunto (percentiles ±1σ) en una sola pasada,
  /// reutilizando los mismos buffers.
  ///
  /// Es el camino que se usa en carretera: recorrer el conjunto una vez
  /// y sacar los percentiles por selección cuesta bastante menos que
  /// armar y ordenar tres listas en cada inferencia.
  EnsembleBands ensembleBands({
    required double power,
    required double remainingSeconds,
    double spendable = 1,
  }) {
    final n = _ensemble.length;
    final reserve = _reserveBuffer ??= Float64List(n);
    final enough = _sufficiencyBuffer ??= Float64List(n);
    final sustainable = _sustainableBuffer ??= Float64List(n);
    for (var i = 0; i < n; i++) {
      final a = _ensemble[i];
      final balance = a.balance.balance;
      reserve[i] = 100 * a.balance.fraction;
      enough[i] = sufficiency(
        balance: balance,
        power: Watts(a.beta * power),
        cp: a.balance.cp,
        remainingSeconds: remainingSeconds,
        spendable: spendable,
      );
      sustainable[i] =
          sustainablePower(
            balance: balance,
            cp: a.balance.cp,
            remainingSeconds: remainingSeconds,
            spendable: spendable,
          ) /
          a.beta;
    }
    return (
      reservePercent: _band(reserve),
      sufficiency: _band(enough),
      sustainablePower: _band(sustainable),
    );
  }

  static ({double lo, double hi}) _band(Float64List values) => (
    lo: percentileInPlace(values, 0.158655),
    hi: percentileInPlace(values, 0.841345),
  );

  static List<double> _lastValues(List<double?> series, int window) => [
    for (var i = math.max(0, series.length - window); i < series.length; i++)
      ?series[i],
  ];

  static double? _meanOfLast(List<double?> series, int window) {
    final values = _lastValues(series, window);
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
