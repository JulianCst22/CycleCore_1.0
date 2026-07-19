import '../core/fuzzy_inference_engine.dart';
import '../core/fuzzy_membership.dart';
import '../core/fuzzy_rule.dart';

/// CAPA 2 del modelo geoespacial: decide cuánto pesar una nueva lectura
/// de pendiente cruda (ya calculada por SlopeWindowCalculator sobre una
/// ventana corta) frente a la que se está mostrando, usando un motor
/// difuso Sugeno de orden cero. Reemplaza tanto la ventana ancha fija
/// como el suavizado exponencial de coeficiente fijo que se habían
/// probado antes y descartado.
///
/// Por qué esto y no una ventana más ancha: una ventana ancha diluye
/// por igual el ruido de grilla del DEM (~30m) Y las rampas/puentes
/// cortos reales (30-40m, muy comunes en Bogotá) -- no existe un
/// tamaño de ventana que sirva bien para ambos casos a la vez. Este
/// filtro, en cambio, desconfía de un salto que aparece en pocos
/// metros (jitter de semáforo, ruido de grilla), y confía en el MISMO
/// salto si se sostiene por suficiente distancia y es consistente
/// consigo mismo (evidencia de que es real).
class SlopePlausibilityFilter {
  double? _displayedSlope;
  final List<double> _recentRawSlopes = [];
  double _persistenceDistance = 0;
  double _lastDeltaSign = 0;

  static const int _spreadWindowSize = 5;

  /// Muestras crudas que se acumulan antes de anclar `_displayedSlope`
  /// por primera vez -- ver la nota en [filter].
  static const int _warmupSamples = 3;
  final List<double> _warmupBuffer = [];

  late final FuzzyInferenceEngine _engine = FuzzyInferenceEngine(
    fallbackOutput: 0.3,
    rules: [
      // El salto es pequeño respecto a lo mostrado -> se acepta siempre,
      // sin importar el resto de condiciones.
      FuzzyRule(
        name: 'salto_pequeno',
        firingStrength: (d) => d['deltaSmall']!,
        outputValue: 0.9,
      ),
      // Puntos muy juntos (jitter de semáforo o velocidad muy baja) ->
      // desconfiar aunque el salto parezca grande: es la firma clásica
      // del ruido de grilla del DEM amplificado por poca distancia
      // horizontal (dividir una diferencia de altitud pequeña entre
      // una distancia diminuta da un porcentaje absurdo).
      FuzzyRule(
        name: 'puntos_juntos_desconfia',
        firingStrength: (d) =>
            FuzzyRule.and([d['deltaLarge']!, d['stepClose']!]),
        outputValue: 0.05,
      ),
      // Salto grande, sostenido por suficiente distancia, con lecturas
      // crudas recientes consistentes entre sí -> es una rampa o
      // puente real, no ruido puntual.
      FuzzyRule(
        name: 'cambio_real_sostenido',
        firingStrength: (d) => FuzzyRule.and([
          d['deltaLarge']!,
          d['persistenceSustained']!,
          d['spreadLow']!,
        ]),
        outputValue: 0.95,
      ),
      // Salto grande pero las lecturas recientes son erráticas entre sí
      // (mucha dispersión) -> ruido, no una señal real.
      FuzzyRule(
        name: 'erratico_desconfia',
        firingStrength: (d) =>
            FuzzyRule.and([d['deltaLarge']!, d['spreadHigh']!]),
        outputValue: 0.1,
      ),
      // Agregada tras confirmar en campo (Alto del Águila, 2026-07-16,
      // comparado tramo a tramo contra el GPX de un Garmin) que bajadas
      // cortas y reales (7-13%, 8-24m) se mostraban casi planas: exigir
      // 20-35m de persistencia sostenida (regla 'cambio_real_sostenido')
      // penaliza por igual una bajada corta real y un blip de ruido, y
      // la mayoría de descensos cortos de montaña no llegan a esa
      // distancia. `spreadLow` (consistencia entre las últimas lecturas
      // crudas) es evidencia de señal real que NO depende de cuánto dure
      // -- el ruido no es consistente consigo mismo aunque sea puntual.
      // Con esta regla, un salto grande y consistente se confía rápido
      // aunque sea corto; si además se sostiene, 'cambio_real_sostenido'
      // sigue dando la confianza más alta (0.95 vs 0.75 acá). No debilita
      // la protección contra jitter de semáforo: esa se basa en
      // `stepClose` (otra señal), no en persistencia, y sigue intacta.
      FuzzyRule(
        name: 'consistente_confia_aunque_corto',
        firingStrength: (d) =>
            FuzzyRule.and([d['deltaLarge']!, d['spreadLow']!]),
        outputValue: 0.75,
      ),
      // Zona gris: el salto es grande, pero ni la persistencia ni la
      // dispersión están claramente definidas todavía (por ejemplo,
      // apenas empieza a acumularse evidencia de un cambio real). Sin
      // esta regla, esos casos caían en el `fallbackOutput` fijo del
      // motor -- una red de seguridad genérica, no una decisión
      // razonada. Con ella, el motor da una confianza moderada (ni
      // "acéptalo" ni "ignóralo") mientras se termina de acumular
      // evidencia en los siguientes puntos. Misma idea que
      // `zona_gris_mezcla` en la Capa 1.
      FuzzyRule(
        name: 'zona_gris_pendiente',
        firingStrength: (d) => d['deltaLarge']!,
        outputValue: 0.4,
      ),
    ],
  );

  /// [rawSlope] es la salida cruda de SlopeWindowCalculator.
  /// [stepDistanceMeters] es la distancia GPS desde el punto anterior
  /// (la misma que ya se calcula en RouteRecordingController).
  /// Devuelve la pendiente "de confianza" a usar -- tanto para mostrar
  /// en vivo como para guardar en RoutePointSnapshot.
  double filter({
    required double rawSlope,
    required double stepDistanceMeters,
  }) {
    if (_displayedSlope == null) {
      // --- Calentamiento -- agregado tras confirmar en campo (Alto del
      // Águila, 2026-07-16) que el primerísimo fix GPS puede llegar
      // hasta ~19m desviado en altitud mientras el GPS termina de
      // estabilizar (cold start). Antes, esa primera muestra cruda se
      // volvía el ancla de TODA la actividad sin pasar por el motor
      // difuso. Ahora se acumulan unas pocas muestras y se ancla con
      // la MEDIANA (no el promedio: un solo outlier extremo no debe
      // arrastrar el ancla). Mientras se completa el buffer, se
      // devuelve el promedio corrido -- ya diluye algo el ruido y
      // evita mostrar un "0%" fijo en la UI durante el arranque.
      _warmupBuffer.add(rawSlope);
      _recentRawSlopes.add(rawSlope);

      if (_warmupBuffer.length < _warmupSamples) {
        return _warmupBuffer.reduce((a, b) => a + b) / _warmupBuffer.length;
      }

      final sorted = [..._warmupBuffer]..sort();
      _displayedSlope = sorted[sorted.length ~/ 2];
      return _displayedSlope!;
    }

    final delta = (rawSlope - _displayedSlope!).abs();

    final deltaSign = (rawSlope - _displayedSlope!).sign;
    _persistenceDistance = (deltaSign == _lastDeltaSign && deltaSign != 0)
        ? _persistenceDistance + stepDistanceMeters
        : stepDistanceMeters;
    _lastDeltaSign = deltaSign;

    _recentRawSlopes.add(rawSlope);
    if (_recentRawSlopes.length > _spreadWindowSize) {
      _recentRawSlopes.removeAt(0);
    }
    final spread = _spread(_recentRawSlopes);

    final degrees = <String, double>{
      'deltaSmall': rampDown(delta, 1, 3),
      'deltaLarge': rampUp(delta, 2, 5),
      'stepClose': rampDown(stepDistanceMeters, 3, 8),
      'persistenceSustained': rampUp(_persistenceDistance, 20, 35),
      'spreadLow': rampDown(spread, 1, 3),
      'spreadHigh': rampUp(spread, 2, 5),
    };

    final trust = _engine.infer(degrees).clamp(0.0, 1.0);

    _displayedSlope = (trust * rawSlope) + ((1 - trust) * _displayedSlope!);
    return _displayedSlope!;
  }

  /// Dispersión (rango, máximo - mínimo) de las últimas lecturas
  /// crudas -- una señal consistente consigo misma, aunque distinta a
  /// lo mostrado, es evidencia de un cambio real; una errática es
  /// ruido.
  double _spread(List<double> values) {
    if (values.length < 2) return 0;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    return maxV - minV;
  }

  void reset() {
    _displayedSlope = null;
    _recentRawSlopes.clear();
    _persistenceDistance = 0;
    _lastDeltaSign = 0;
    _warmupBuffer.clear();
  }
}
