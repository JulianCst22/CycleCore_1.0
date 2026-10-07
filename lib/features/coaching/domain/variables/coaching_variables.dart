import '../../../../core/fuzzy_type2/fuzzy_type2.dart';
import '../coaching_parameters.dart';
import 'labels.dart';

/// De dónde sale el dato de una variable; su credibilidad decide cuánto
/// pesan las reglas que la usan.
enum DataSource { power, heartRate, cadence, terrain, reference }

/// Las variables lingüísticas del coach, con los parámetros del anexo de
/// la especificación.
///
/// Las de entrada forman particiones de Ruspini. Las de salida llevan la
/// huella de incertidumbre de [CoachingParameters] en tipo-2 y ninguna
/// en tipo-1.
final class CoachingVariables {
  // Motor A · estado del ciclista
  final LinguisticVariable<IntensityLevel> intensity;
  final LinguisticVariable<HeartRateLevel> heartRateReserve;
  final LinguisticVariable<TorqueLevel> torque;
  final LinguisticVariable<ReserveLevel> reserve;
  final LinguisticVariable<SufficiencyLevel> sufficiency;
  final LinguisticVariable<DecouplingLevel> decoupling;
  final LinguisticVariable<VariabilityLevel> variability;
  final LinguisticVariable<EffortState> effort;

  // Motor B · demanda del terreno
  final LinguisticVariable<GradientLevel> gradientAhead;
  final LinguisticVariable<GradientLevel> maxRamp;
  final LinguisticVariable<RoughnessLevel> roughness;
  final LinguisticVariable<ClimbLevel> climbLeft;
  final LinguisticVariable<PhaseLevel> phase;
  final LinguisticVariable<Demand> demand;

  // Motor C · decisión
  final LinguisticVariable<RecordPaceLevel> recordPace;
  final LinguisticVariable<Goal> goal;
  final LinguisticVariable<Adjustment> adjustment;
  final LinguisticVariable<CadenceLevel> cadence;
  final LinguisticVariable<Urgency> urgency;

  /// Fuentes de cada variable de entrada. Las que llegan como puerto de
  /// otro motor (estado y demanda) y el objetivo no tienen fuente: su
  /// credibilidad ya se aplicó o no aplica.
  late final Map<LinguisticVariable<Enum>, Set<DataSource>> sources =
      Map.identity()..addAll({
        intensity: {DataSource.power},
        heartRateReserve: {DataSource.heartRate},
        torque: {DataSource.power, DataSource.cadence},
        reserve: {DataSource.power},
        sufficiency: {DataSource.power},
        decoupling: {DataSource.power, DataSource.heartRate},
        variability: {DataSource.power},
        gradientAhead: {DataSource.terrain},
        maxRamp: {DataSource.terrain},
        roughness: {DataSource.terrain},
        climbLeft: {DataSource.terrain},
        phase: {DataSource.terrain},
        recordPace: {DataSource.reference},
      });

  CoachingVariables._({
    required this.intensity,
    required this.heartRateReserve,
    required this.torque,
    required this.reserve,
    required this.sufficiency,
    required this.decoupling,
    required this.variability,
    required this.effort,
    required this.gradientAhead,
    required this.maxRamp,
    required this.roughness,
    required this.climbLeft,
    required this.phase,
    required this.demand,
    required this.recordPace,
    required this.goal,
    required this.adjustment,
    required this.cadence,
    required this.urgency,
  });

  factory CoachingVariables({
    required InferenceMode mode,
    CoachingParameters parameters = const CoachingParameters(),
  }) {
    final t2 = mode == InferenceMode.type2;
    double fou(double width) => t2 ? width : 0;

    // Las variables que se miden llevan el factor de quiebres del
    // análisis de sensibilidad (1 = los valores del anexo). Las de
    // salida y las que llegan como puerto no se tocan: mover sus
    // quiebres cambiaría el significado de la recomendación, no la
    // frontera entre dos etiquetas medidas.
    LinguisticVariable<L> measured<L extends Enum>({
      required String name,
      required double min,
      required double max,
      required Map<L, Trapezoid> terms,
    }) => LinguisticVariable(
      name: name,
      min: min,
      max: max,
      terms: terms,
    ).withBreakpointsScaled(parameters.breakpointScale);
    const gradientTerms = {
      GradientLevel.llano: Trapezoid.leftShoulder(1.5, 3.5),
      GradientLevel.repecho: Trapezoid(1.5, 3.5, 5.5, 7.5),
      GradientLevel.sostenida: Trapezoid(5.5, 7.5, 9.0, 11.0),
      GradientLevel.muro: Trapezoid.rightShoulder(9, 11),
    };
    return CoachingVariables._(
      intensity: measured(
        name: 'intensidad',
        min: 0.4,
        max: 1.8,
        terms: const {
          IntensityLevel.suave: Trapezoid.leftShoulder(0.70, 0.88),
          IntensityLevel.umbral: Trapezoid(0.70, 0.88, 1.00, 1.15),
          IntensityLevel.duro: Trapezoid(1.00, 1.15, 1.25, 1.40),
          IntensityLevel.insostenible: Trapezoid.rightShoulder(1.25, 1.40),
        },
      ),
      heartRateReserve: measured(
        name: 'reserva cardíaca',
        min: 0,
        max: 1.1,
        terms: const {
          HeartRateLevel.baja: Trapezoid.leftShoulder(0.55, 0.70),
          HeartRateLevel.media: Trapezoid(0.55, 0.70, 0.74, 0.82),
          HeartRateLevel.alta: Trapezoid(0.74, 0.82, 0.86, 0.96),
          HeartRateLevel.tope: Trapezoid.rightShoulder(0.86, 0.96),
        },
      ),
      torque: measured(
        name: 'torque relativo',
        min: 0.5,
        max: 2.5,
        terms: const {
          TorqueLevel.ligero: Trapezoid.leftShoulder(0.75, 0.92),
          TorqueLevel.normal: Trapezoid(0.75, 0.92, 1.15, 1.42),
          TorqueLevel.pesado: Trapezoid(1.15, 1.42, 1.55, 1.75),
          TorqueLevel.atascado: Trapezoid.rightShoulder(1.55, 1.75),
        },
      ),
      reserve: measured(
        name: 'reserva de W′ (%)',
        min: 0,
        max: 100,
        terms: const {
          ReserveLevel.agotada: Trapezoid.leftShoulder(15, 35),
          ReserveLevel.comprometida: Trapezoid(15, 35, 50, 70),
          ReserveLevel.sana: Trapezoid.rightShoulder(50, 70),
        },
      ),
      sufficiency: measured(
        name: 'suficiencia de W′',
        min: 0,
        max: 2,
        terms: const {
          SufficiencyLevel.insuficiente: Trapezoid.leftShoulder(0.50, 0.85),
          SufficiencyLevel.justa: Trapezoid(0.50, 0.85, 1.05, 1.35),
          SufficiencyLevel.holgada: Trapezoid.rightShoulder(1.05, 1.35),
        },
      ),
      decoupling: measured(
        name: 'deriva pulso-potencia (%)',
        min: 0,
        max: 20,
        terms: const {
          DecouplingLevel.nula: Trapezoid.leftShoulder(3, 6),
          DecouplingLevel.incipiente: Trapezoid(3, 6, 9, 13),
          DecouplingLevel.marcada: Trapezoid.rightShoulder(9, 13),
        },
      ),
      variability: measured(
        name: 'variabilidad',
        min: 1,
        max: 1.5,
        terms: const {
          VariabilityLevel.pareja: Trapezoid.leftShoulder(1.03, 1.08),
          VariabilityLevel.irregular: Trapezoid.rightShoulder(1.03, 1.08),
        },
      ),
      effort: LinguisticVariable(
        name: 'estado',
        min: 0,
        max: 100,
        consequentFou: fou(parameters.effortFou),
        terms: const {
          EffortState.fundido: Trapezoid(0, 0, 12, 28),
          EffortState.alLimite: Trapezoid(14, 26, 34, 46),
          EffortState.justo: Trapezoid(34, 44, 56, 66),
          EffortState.comodo: Trapezoid(54, 66, 74, 86),
          EffortState.sobrado: Trapezoid(74, 88, 100, 100),
        },
      ),
      gradientAhead: measured(
        name: 'pendiente que viene (%)',
        min: -5,
        max: 20,
        terms: gradientTerms,
      ),
      maxRamp: measured(
        name: 'rampa máxima (%)',
        min: -5,
        max: 20,
        terms: gradientTerms,
      ),
      roughness: measured(
        name: 'rugosidad (%)',
        min: 0,
        max: 6,
        terms: const {
          RoughnessLevel.regular: Trapezoid.leftShoulder(1.5, 2.5),
          RoughnessLevel.escalonado: Trapezoid.rightShoulder(1.5, 2.5),
        },
      ),
      climbLeft: measured(
        name: 'desnivel restante (m)',
        min: 0,
        max: 1500,
        terms: const {
          ClimbLevel.poco: Trapezoid.leftShoulder(60, 140),
          ClimbLevel.medio: Trapezoid(60, 140, 240, 360),
          ClimbLevel.mucho: Trapezoid.rightShoulder(240, 360),
        },
      ),
      phase: measured(
        name: 'progreso (%)',
        min: 0,
        max: 100,
        terms: const {
          PhaseLevel.arranque: Trapezoid.leftShoulder(8, 20),
          PhaseLevel.primerTercio: Trapezoid(8, 20, 33, 45),
          PhaseLevel.medio: Trapezoid(33, 45, 62, 75),
          PhaseLevel.remate: Trapezoid.rightShoulder(62, 75),
        },
      ),
      demand: LinguisticVariable(
        name: 'demanda',
        min: 0,
        max: 100,
        consequentFou: fou(parameters.demandFou),
        terms: const {
          Demand.recuperacion: Trapezoid(0, 0, 10, 25),
          Demand.llano: Trapezoid(12, 22, 32, 42),
          Demand.repecho: Trapezoid(34, 44, 52, 62),
          Demand.sostenida: Trapezoid(54, 64, 74, 84),
          Demand.muro: Trapezoid(76, 88, 100, 100),
        },
      ),
      recordPace: measured(
        name: 'ventaja sobre el récord (s)',
        min: -120,
        max: 120,
        terms: const {
          RecordPaceLevel.retrasado: Trapezoid.leftShoulder(-12, -3),
          RecordPaceLevel.enRitmo: Trapezoid(-12, -3, 3, 12),
          RecordPaceLevel.adelante: Trapezoid.rightShoulder(3, 12),
        },
      ),
      // Categórica: cada objetivo es un índice y vale 1 exactamente ahí.
      goal: LinguisticVariable(
        name: 'objetivo',
        min: 0,
        max: 2,
        terms: const {
          Goal.recuperacion: Trapezoid.leftShoulder(0, 1),
          Goal.ritmo: Trapezoid(0, 1, 1, 2),
          Goal.pr: Trapezoid.rightShoulder(1, 2),
        },
      ),
      adjustment: LinguisticVariable(
        name: 'ajuste',
        min: -100,
        max: 100,
        consequentFou: fou(parameters.adjustmentFou),
        terms: const {
          Adjustment.soltarMucho: Trapezoid(-85, -70, -58, -45),
          Adjustment.soltar: Trapezoid(-72, -52, -32, -15),
          Adjustment.mantener: Trapezoid(-22, -8, 8, 22),
          Adjustment.apretar: Trapezoid(15, 32, 52, 72),
          Adjustment.apretarMucho: Trapezoid(45, 58, 70, 85),
        },
      ),
      cadence: LinguisticVariable(
        name: 'cadencia (rpm)',
        min: 50,
        max: 110,
        consequentFou: fou(parameters.cadenceFou),
        terms: const {
          CadenceLevel.baja: Trapezoid(50, 50, 62, 72),
          CadenceLevel.media: Trapezoid(66, 76, 84, 92),
          CadenceLevel.alta: Trapezoid(86, 94, 105, 110),
        },
      ),
      urgency: LinguisticVariable(
        name: 'urgencia',
        min: 0,
        max: 1,
        consequentFou: fou(parameters.urgencyFou),
        terms: const {
          Urgency.nula: Trapezoid(0, 0, 0.15, 0.30),
          Urgency.baja: Trapezoid(0.20, 0.32, 0.45, 0.58),
          Urgency.media: Trapezoid(0.48, 0.58, 0.70, 0.80),
          Urgency.alta: Trapezoid(0.72, 0.84, 1, 1),
        },
      ),
    );
  }

  /// Todas las variables del coach, en el orden de los motores. Sirve
  /// para recorrerlas sin nombrarlas una por una (dibujar sus
  /// particiones, verificarlas, documentarlas).
  List<LinguisticVariable<Enum>> get all => [
    intensity,
    heartRateReserve,
    torque,
    reserve,
    sufficiency,
    decoupling,
    variability,
    effort,
    gradientAhead,
    maxRamp,
    roughness,
    climbLeft,
    phase,
    demand,
    recordPace,
    goal,
    adjustment,
    cadence,
    urgency,
  ];

  /// Credibilidad de cada variable a partir de la de sus fuentes: la de la
  /// fuente menos creíble. Las variables sin fuente valen 1.
  Credibility credibilityFrom(double Function(DataSource source) ofSource) =>
      (variable) {
        final used = sources[variable];
        if (used == null || used.isEmpty) return 1;
        return used.map(ofSource).reduce((a, b) => a < b ? a : b);
      };
}
