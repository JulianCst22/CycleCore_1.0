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

  /// Precisión GPS por debajo de la cual se considera segura para
  /// anclar la PRIMERA lectura de pendiente de la sesión (calentamiento
  /// no bloqueante -- síntoma 1 del informe de campo: pico falso al
  /// inicio de cada actividad por cold start del GPS). No bloquea la
  /// grabación: distancia, puntos y tiempo siguen corriendo desde el
  /// primer punto; lo único que se retiene es cuál lectura ancla la
  /// pendiente MOSTRADA. Coincide con el extremo alto del rampUp de
  /// 'gpsInaccurate' que ya usa la Capa 1 (15-30m), para que ambas
  /// capas compartan el mismo criterio de "el GPS todavía no está
  /// listo".
  static const double _warmupAccuracyThresholdMeters = 20.0;

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
      // GPS con precisión mala (cold start, túnel, arboleda densa) ->
      // desconfiar de la lectura cruda y quedarse más cerca de lo
      // último mostrado, sin importar qué tan grande sea el salto.
      // Vota igual que las demás reglas (promedio ponderado), no
      // reemplaza la decisión -- así un salto real y sostenido con GPS
      // algo impreciso todavía puede colarse si el resto de señales lo
      // respalda con fuerza.
      FuzzyRule(
        name: 'gps_impreciso_desconfia',
        firingStrength: (d) => d['gpsInaccurate']!,
        outputValue: 0.05,
      ),
    ],
  );

  /// [rawSlope] es la salida cruda de SlopeWindowCalculator.
  /// [stepDistanceMeters] es la distancia GPS desde el punto anterior
  /// (la misma que ya se calcula en RouteRecordingController).
  /// [gpsAccuracyMeters] es `Position.accuracy` (en vivo) o
  /// `RoutePoint.accuracyMeters` (reconstrucción histórica) del punto
  /// que originó [rawSlope] -- mismo dato que ya usa la Capa 1, null
  /// si no está disponible.
  /// Devuelve la pendiente "de confianza" a usar -- tanto para mostrar
  /// en vivo como para guardar en RoutePointSnapshot.
  double filter({
    required double rawSlope,
    required double stepDistanceMeters,
    required double? gpsAccuracyMeters,
  }) {
    if (_displayedSlope == null) {
      // Calentamiento no bloqueante: si el primer punto de la sesión
      // todavía trae un GPS impreciso (cold start típico), no se ancla
      // todavía -- se muestra 0 en vez de la lectura cruda (que podría
      // ser el pico falso del síntoma 1). La grabación sigue su curso
      // normal; en cuanto llegue una lectura con precisión aceptable,
      // ancla ahí y el filtro sigue de ahí en adelante como siempre.
      if (gpsAccuracyMeters != null &&
          gpsAccuracyMeters > _warmupAccuracyThresholdMeters) {
        return 0;
      }
      _displayedSlope = rawSlope;
      _recentRawSlopes.add(rawSlope);
      return rawSlope;
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
      'gpsInaccurate': gpsAccuracyMeters == null
          ? 0.0
          : rampUp(gpsAccuracyMeters, 15, 30),
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
  }
}
