import '../../../core/fuzzy_type2/fuzzy_type2.dart' show Implication, TNorm;

/// Cómo razona el motor: tipo-1 (valores exactos) o tipo-2 de intervalo
/// (cada valor con su banda de incertidumbre).
enum InferenceMode { type1, type2 }

/// Todos los parámetros ajustables del coach en un solo lugar.
///
/// Los valores por defecto son los de la especificación. Tenerlos juntos
/// permite el análisis de sensibilidad de la tesis sin tocar código.
final class CoachingParameters {
  // --- De la figura a vatios ---

  /// Cambio relativo máximo que puede pedir un consejo (±20 %).
  final double maxAdjustment;

  /// Paso con el que se recorre el perfil para repartir el esfuerzo (m).
  final double pacingStepMeters;

  /// Largo de la ventana que cuenta como «tramo duro» (m). Por debajo de
  /// esto es una rampa suelta, no una cuesta que decida la subida.
  final double pacingWindowMeters;

  /// Metros de adelante que no se miran al buscar ese tramo: son los que
  /// se están pedaleando ahora.
  final double pacingNowMeters;

  /// Cuántos puntos de pendiente tiene que empinar un tramo sobre el
  /// actual para que valga la pena guardar algo para él.
  final double harderAheadPoints;

  /// Parte del esfuerzo restante por debajo de la cual ya no hay dónde
  /// guardar: toca soltar lo que quede.
  final double finalShare;

  /// Separación máxima entre lo que piden las reglas y lo que dice la
  /// física antes de marcar el instante para revisar la base de reglas
  /// (F12 de la especificación).
  final double physicsTolerance;

  /// Urgencia desde la que un aviso no espera turno: se dice aunque la
  /// cadencia que eligió el ciclista todavía no lo permita.
  final double urgentUrgency;

  /// Reserva cardíaca desde la que el pulso ya está alto y conviene
  /// hablar de la respiración.
  final double highHeartRate;

  /// Torque relativo por debajo del cual el ciclista va pedaleando en
  /// el aire y le conviene un piñón más duro.
  final double lowTorque;

  /// Margen en rpm con el que se recorta la cadencia objetivo contra la
  /// que de verdad da la bicicleta: quedarse justo en el límite del
  /// desarrollo tampoco sirve.
  final double cadenceMargin;

  /// Torque relativo desde el que el ciclista va atascado en el pedal y
  /// un piñón más suave ayudaría.
  final double highTorque;

  /// Grado mínimo para declarar una limitante. Por debajo de esto lo
  /// que sea que esté más alto no está apretando de verdad.
  final double limiterFloor;

  /// Suficiencia por debajo de la cual el objetivo no puede pasarse de
  /// la potencia sostenible. Uno significa «la reserva alcanza justo
  /// para lo que falta»: por debajo de eso, no alcanza.
  final double sufficiencyCeiling;

  // --- Gobernador ---

  /// Urgencia mínima para hablar (se compara con el extremo inferior).
  final double urgencyThreshold;

  /// Sin potenciómetro la potencia sale de la velocidad y la pendiente,
  /// y su incertidumbre ensancha tanto el intervalo de la urgencia que el
  /// extremo inferior casi nunca pasa el umbral: en la subida simulada el
  /// coach hablaba 2 veces en 23 minutos, contra 7 con potenciómetro.
  /// Con esto, cuando la potencia es estimada se compara el centro del
  /// intervalo. Es una decisión de diseño: callar no ayuda al ciclista
  /// que tiene menos datos. Lo urgente que se salta el turno sigue
  /// exigiendo el extremo inferior, así que con datos estimados el coach
  /// nunca interrumpe antes del ritmo que eligió el ciclista.
  final bool urgencyAtMidpointWhenEstimated;

  /// Tiempo mínimo entre dos mensajes.
  final int minGapSeconds;

  /// Ventaja que necesita una situación nueva sobre la anterior para
  /// reemplazarla (histéresis).
  final double situationHysteresis;

  /// Una misma situación no se repite antes de este tiempo.
  final int repeatWindowSeconds;

  // --- Tono ---

  /// Ancho relativo del consejo a partir del cual el tono es cauto.
  final double cautiousWidth;

  /// Ancho relativo a partir del cual el tono es neutro.
  final double neutralWidth;

  /// Altura mínima de la figura para un tono asertivo.
  final double assertiveHeight;

  // --- Señales ---

  final int powerWindowSeconds;
  final int basePowerWindowSeconds;
  final int normalizedPowerWindowSeconds;
  final int heartRateWindowSeconds;
  final int cadenceWindowSeconds;

  /// Distancia hacia adelante que mira el motor de terreno.
  final double lookaheadMeters;

  // --- Incertidumbre de las mediciones (una desviación típica) ---

  /// Error relativo del potenciómetro.
  final double powerAccuracy;
  final double heartRateAccuracy;
  final double maxHeartRateAccuracy;
  final double cadenceAccuracy;
  final double gradientAccuracy;
  final double rampAccuracy;
  final double roughnessAccuracy;
  final double climbAccuracy;
  final double positionAccuracy;
  final double referenceAccuracy;

  /// Atletas posibles que se simulan para la reserva de W′.
  final int ensembleSize;
  final int seed;

  // --- Forma de razonar (para el análisis de sensibilidad) ---

  /// Factor que multiplica los quiebres de las variables de entrada.
  /// 1 son los del anexo; 0,9 y 1,1 son el barrido de ±10 %.
  final double breakpointScale;

  /// «Y» de cada motor. A y B usan el mínimo (una condición débil manda);
  /// C usa el producto (acumular evidencia parcial se nota).
  final TNorm effortAnd;
  final TNorm terrainAnd;
  final TNorm decisionAnd;

  /// Cómo se recorta el consecuente: Mamdani (recorte) o Larsen
  /// (escalado).
  final Implication implication;

  // --- Huellas de las etiquetas de salida ---

  final double effortFou;
  final double demandFou;
  final double adjustmentFou;
  final double cadenceFou;
  final double urgencyFou;

  const CoachingParameters({
    this.maxAdjustment = 0.20,
    this.sufficiencyCeiling = 1.0,
    this.physicsTolerance = 0.10,
    this.urgentUrgency = 0.80,
    this.highHeartRate = 0.85,
    this.highTorque = 1.25,
    this.lowTorque = 0.92,
    this.cadenceMargin = 3,
    this.limiterFloor = 0.35,
    this.pacingStepMeters = 100,
    this.pacingWindowMeters = 300,
    this.pacingNowMeters = 200,
    this.harderAheadPoints = 1.5,
    this.finalShare = 0.18,
    this.urgencyThreshold = 0.60,
    this.urgencyAtMidpointWhenEstimated = true,
    this.minGapSeconds = 45,
    this.situationHysteresis = 0.15,
    this.repeatWindowSeconds = 300,
    this.cautiousWidth = 0.15,
    this.neutralWidth = 0.30,
    this.assertiveHeight = 0.75,
    this.powerWindowSeconds = 3,
    this.basePowerWindowSeconds = 30,
    this.normalizedPowerWindowSeconds = 180,
    this.heartRateWindowSeconds = 10,
    this.cadenceWindowSeconds = 5,
    this.lookaheadMeters = 1000,
    this.powerAccuracy = 0.015,
    this.heartRateAccuracy = 1,
    this.maxHeartRateAccuracy = 2,
    this.cadenceAccuracy = 1,
    this.gradientAccuracy = 0.3,
    this.rampAccuracy = 0.5,
    this.roughnessAccuracy = 0.2,
    this.climbAccuracy = 5,
    this.positionAccuracy = 15,
    this.referenceAccuracy = 1,
    this.ensembleSize = 2000,
    this.seed = 1,
    this.breakpointScale = 1,
    this.effortAnd = TNorm.minimum,
    this.terrainAnd = TNorm.minimum,
    this.decisionAnd = TNorm.product,
    this.implication = Implication.clip,
    this.effortFou = 2,
    this.demandFou = 2,
    this.adjustmentFou = 3,
    this.cadenceFou = 1.5,
    this.urgencyFou = 0.02,
  });
}
