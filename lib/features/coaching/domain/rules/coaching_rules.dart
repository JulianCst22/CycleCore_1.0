import '../../../../core/fuzzy_type2/fuzzy_type2.dart';
import '../variables/coaching_variables.dart';
import '../variables/labels.dart';

/// Motor A · estado del ciclista. Se evalúa con el mínimo.
RuleBase effortRules(CoachingVariables v) => RuleBase([
  Rule(
    id: 'A1',
    when: Is(v.reserve, ReserveLevel.agotada),
    then: Consequent(v.effort, EffortState.fundido),
    rationale: 'La reserva anaeróbica se vació: ya reventó.',
  ),
  Rule(
    id: 'A2',
    when: All([
      Is(v.sufficiency, SufficiencyLevel.insuficiente),
      Is(v.reserve, ReserveLevel.sana),
    ]),
    then: Consequent(v.effort, EffortState.alLimite),
    rationale:
        'Ahora está bien, pero a este ritmo la reserva no alcanza para '
        'terminar.',
  ),
  Rule(
    id: 'A3',
    when: All([
      Is(v.heartRateReserve, HeartRateLevel.tope),
      Is(v.torque, TorqueLevel.pesado),
    ]),
    then: Consequent(v.effort, EffortState.alLimite),
    rationale: 'Pulso en el techo y mucha fuerza en cada pedalazo.',
  ),
  Rule(
    id: 'A4',
    when: All([
      Is(v.intensity, IntensityLevel.duro),
      Is(v.decoupling, DecouplingLevel.incipiente),
    ]),
    then: Consequent(v.effort, EffortState.alLimite),
    rationale: 'Por encima del umbral y el pulso ya se despega de la potencia.',
  ),
  Rule(
    id: 'A5',
    when: All([
      Is(v.intensity, IntensityLevel.umbral),
      Is(v.reserve, ReserveLevel.sana),
    ]),
    then: Consequent(v.effort, EffortState.justo),
    rationale: 'En el umbral y con reserva: esfuerzo sostenible.',
  ),
  Rule(
    id: 'A6',
    when: All([
      Is(v.heartRateReserve, HeartRateLevel.alta),
      Is(v.reserve, ReserveLevel.sana),
    ]),
    then: Consequent(v.effort, EffortState.justo),
    rationale: 'Pulso alto sin llegar al techo, con reserva.',
  ),
  Rule(
    id: 'A7',
    when: All([
      Is(v.variability, VariabilityLevel.pareja),
      Is(v.reserve, ReserveLevel.sana),
    ]),
    then: Consequent(v.effort, EffortState.comodo),
    certainty: 0.4,
    rationale: 'Está dosificando bien; eso cuenta a favor, con poco peso.',
  ),
  Rule(
    id: 'A8',
    when: All([
      Is(v.sufficiency, SufficiencyLevel.justa),
      Is(v.reserve, ReserveLevel.sana),
    ]),
    then: Consequent(v.effort, EffortState.justo),
    rationale: 'La reserva alcanza, pero justo.',
  ),
  Rule(
    id: 'A9',
    // La suficiencia compara la reserva con lo que va a gastar lo que
    // falta, y justo por debajo del umbral lo que falta casi no gasta:
    // sin pedir la reserva sana, con el tanque en cero salía «cómodo».
    when: All([
      Is(v.sufficiency, SufficiencyLevel.holgada),
      Is(v.intensity, IntensityLevel.umbral),
      Is(v.reserve, ReserveLevel.sana),
    ]),
    then: Consequent(v.effort, EffortState.comodo),
    rationale: 'Le sobra reserva a un ritmo de umbral.',
  ),

  // --- Reglas que cierran los huecos de cobertura ---
  //
  // Con las nueve anteriores había zonas del universo donde ninguna
  // regla hablaba y el motor se quedaba sin estado: media reserva sin
  // nada más marcado, ir muy por encima del umbral, ir atascado en el
  // pedal. Y «sobrado» no lo concluía ninguna, así que era una etiqueta
  // de salida inalcanzable.
  Rule(
    id: 'A10',
    when: Is(v.reserve, ReserveLevel.comprometida),
    then: Consequent(v.effort, EffortState.alLimite),
    certainty: 0.5,
    rationale: 'Medio tanque gastado: ya no está cómodo.',
  ),
  Rule(
    id: 'A11',
    when: All([
      Is(v.sufficiency, SufficiencyLevel.insuficiente),
      Is(v.reserve, ReserveLevel.comprometida),
    ]),
    then: Consequent(v.effort, EffortState.alLimite),
    rationale: 'Medio tanque y no alcanza para lo que falta.',
  ),
  Rule(
    id: 'A12',
    when: All([
      Is(v.intensity, IntensityLevel.suave),
      Is(v.sufficiency, SufficiencyLevel.holgada),
      Is(v.reserve, ReserveLevel.sana),
    ]),
    then: Consequent(v.effort, EffortState.sobrado),
    rationale: 'Por debajo del umbral y con reserva de sobra: puede más.',
  ),
  Rule(
    id: 'A13',
    when: All([
      Is(v.heartRateReserve, HeartRateLevel.baja),
      Is(v.sufficiency, SufficiencyLevel.holgada),
      Is(v.reserve, ReserveLevel.sana),
    ]),
    then: Consequent(v.effort, EffortState.sobrado),
    rationale: 'El corazón va tranquilo y el tanque está lleno.',
  ),
  Rule(
    id: 'A14',
    when: Is(v.intensity, IntensityLevel.insostenible),
    then: Consequent(v.effort, EffortState.alLimite),
    certainty: 0.8,
    rationale: 'Muy por encima del umbral: eso no se sostiene.',
  ),
  Rule(
    id: 'A15',
    when: Is(v.torque, TorqueLevel.atascado),
    then: Consequent(v.effort, EffortState.alLimite),
    certainty: 0.7,
    rationale: 'Va atascado en el pedal, a pura fuerza.',
  ),
]);

/// Motor B · demanda del terreno. Se evalúa con el mínimo.
RuleBase terrainRules(CoachingVariables v) => RuleBase([
  Rule(
    id: 'B1',
    when: All([
      Is(v.gradientAhead, GradientLevel.sostenida),
      Is(v.climbLeft, ClimbLevel.mucho),
    ]),
    then: Consequent(v.demand, Demand.sostenida),
    rationale: 'Pendiente sostenida con mucho desnivel por delante.',
  ),
  Rule(
    id: 'B2',
    when: Is(v.maxRamp, GradientLevel.muro),
    then: Consequent(v.demand, Demand.muro),
    rationale: 'Hay un muro en el tramo que viene.',
  ),
  Rule(
    id: 'B3',
    when: All([
      Is(v.climbLeft, ClimbLevel.mucho),
      Is(v.phase, PhaseLevel.primerTercio),
    ]),
    then: Consequent(v.demand, Demand.sostenida),
    rationale: 'Queda casi todo el trabajo por hacer.',
  ),
  Rule(
    id: 'B4',
    when: All([
      Is(v.maxRamp, GradientLevel.sostenida),
      Is(v.roughness, RoughnessLevel.regular),
    ]),
    then: Consequent(v.demand, Demand.sostenida),
    rationale: 'Subida pareja, sin escalones: se puede dosificar.',
  ),
  Rule(
    id: 'B5',
    when: Is(v.phase, PhaseLevel.arranque),
    then: Consequent(v.demand, Demand.repecho),
    certainty: 0.5,
    rationale: 'En el arranque la subida todavía no muerde.',
  ),

  // --- Reglas que cierran los huecos de cobertura ---
  //
  // Las cinco anteriores solo sabían de subida: con poco desnivel por
  // delante o con la pendiente aflojando, ninguna hablaba. «Llano» y
  // «recuperación» eran etiquetas inalcanzables, y son justo las que
  // describen los tramos donde se respira dentro de una subida.
  Rule(
    id: 'B6',
    when: All([
      Is(v.gradientAhead, GradientLevel.repecho),
      Is(v.climbLeft, ClimbLevel.poco),
    ]),
    then: Consequent(v.demand, Demand.repecho),
    rationale: 'Queda poco y la pendiente aflojó.',
  ),
  Rule(
    id: 'B7',
    when: All([
      Is(v.gradientAhead, GradientLevel.llano),
      Is(v.climbLeft, ClimbLevel.poco),
    ]),
    then: Consequent(v.demand, Demand.llano),
    rationale: 'Lo que falta es llano: ya no pide subida.',
  ),
  Rule(
    id: 'B8',
    when: All([
      Is(v.gradientAhead, GradientLevel.llano),
      Is(v.climbLeft, ClimbLevel.medio),
    ]),
    then: Consequent(v.demand, Demand.recuperacion),
    rationale: 'Tramo llano en mitad de la subida: acá se recupera.',
  ),
]);

/// Reglas de ajuste que salen del tanque (la reserva de W′). Cuando una
/// de ellas manda el consejo, el objetivo en vatios no baja de la potencia
/// que ese mismo modelo dice que se puede sostener hasta la cima: aflojar
/// más no guardaría reserva, solo perdería tiempo. Las demás razones
/// (pulso en el techo, deriva, un muro por delante) sí pueden pedir bajar
/// más.
const reserveDrivenAdjustmentRules = {'C2', 'C8'};

/// Motor C · decisión. Se evalúa con el producto: acumular condiciones
/// parciales se nota.
///
/// Recibe el estado y la demanda como puertos (activaciones de los motores
/// A y B) y produce tres salidas: ajuste de intensidad, cadencia y
/// urgencia.
RuleBase decisionRules(CoachingVariables v) => RuleBase([
  // --- Ajuste de intensidad ---
  Rule(
    id: 'C1',
    when: All([
      Is(v.effort, EffortState.alLimite),
      Is(v.demand, Demand.sostenida),
      Is(v.phase, PhaseLevel.primerTercio),
    ]),
    then: Consequent(v.adjustment, Adjustment.soltar),
    rationale: 'Al límite, en subida sostenida y apenas empezando.',
  ),
  Rule(
    id: 'C2',
    when: All([
      Is(v.sufficiency, SufficiencyLevel.insuficiente),
      Is(v.climbLeft, ClimbLevel.mucho),
    ]),
    then: Consequent(v.adjustment, Adjustment.soltarMucho),
    certainty: 0.9,
    rationale: 'No le alcanza el tanque para lo que falta.',
  ),
  Rule(
    id: 'C3',
    when: All([Is(v.effort, EffortState.alLimite), Is(v.demand, Demand.muro)]),
    then: Consequent(v.adjustment, Adjustment.soltarMucho),
    rationale: 'Al límite y viene un muro.',
  ),
  Rule(
    id: 'C4',
    when: All([Is(v.effort, EffortState.justo), Is(v.goal, Goal.pr)]),
    then: Consequent(v.adjustment, Adjustment.mantener),
    rationale: 'Buscando el récord y el esfuerzo es sostenible.',
  ),
  Rule(
    id: 'C5',
    when: All([
      Is(v.recordPace, RecordPaceLevel.enRitmo),
      Is(v.effort, EffortState.justo),
    ]),
    then: Consequent(v.adjustment, Adjustment.mantener),
    rationale: 'Va al ritmo del récord y el esfuerzo es sostenible.',
  ),
  Rule(
    id: 'C6',
    when: All([
      Is(v.effort, EffortState.comodo),
      Is(v.demand, Demand.sostenida),
    ]),
    then: Consequent(v.adjustment, Adjustment.mantener),
    rationale: 'Cómodo en una subida sostenida.',
  ),
  Rule(
    id: 'C7',
    when: All([Is(v.demand, Demand.muro), Is(v.effort, EffortState.alLimite)]),
    then: Consequent(v.adjustment, Adjustment.mantener),
    certainty: 0.6,
    rationale: 'Contrapeso: no soltar tanto que después no pueda con la rampa.',
  ),
  Rule(
    id: 'C8',
    when: All([
      Is(v.sufficiency, SufficiencyLevel.justa),
      Is(v.climbLeft, ClimbLevel.mucho),
    ]),
    then: Consequent(v.adjustment, Adjustment.soltar),
    rationale: 'La reserva va justa y queda mucho desnivel.',
  ),
  Rule(
    id: 'C9',
    when: All([
      Is(v.sufficiency, SufficiencyLevel.holgada),
      Is(v.recordPace, RecordPaceLevel.enRitmo),
      Is(v.goal, Goal.pr),
    ]),
    then: Consequent(v.adjustment, Adjustment.apretar),
    certainty: 0.6,
    rationale: 'Busca el récord, va en ritmo y le sobra reserva.',
  ),

  // --- Ajuste: reglas que cierran los huecos ---
  //
  // Las nueve anteriores nunca leían «fundido» ni «sobrado», y ninguna
  // concluía «apretar mucho»: el ciclista podía reventar sin que el
  // consejo lo tuviera en cuenta, y el modo «a tope» no tenía cómo
  // pedir el último esfuerzo.
  Rule(
    id: 'C10',
    when: Is(v.effort, EffortState.fundido),
    then: Consequent(v.adjustment, Adjustment.soltarMucho),
    rationale: 'Reventó: no hay consejo que valga sin bajar primero.',
  ),
  Rule(
    id: 'C11',
    when: All([Is(v.effort, EffortState.sobrado), Is(v.goal, Goal.pr)]),
    then: Consequent(v.adjustment, Adjustment.apretarMucho),
    rationale: 'Le sobra de todo y va a por el récord.',
  ),
  Rule(
    id: 'C12',
    when: All([
      Is(v.effort, EffortState.sobrado),
      Is(v.demand, Demand.sostenida),
    ]),
    then: Consequent(v.adjustment, Adjustment.apretar),
    rationale: 'Sobrado en subida sostenida: hay margen para apretar.',
  ),
  Rule(
    id: 'C13',
    when: All([
      Is(v.phase, PhaseLevel.remate),
      Is(v.sufficiency, SufficiencyLevel.holgada),
      Is(v.goal, Goal.pr),
    ]),
    then: Consequent(v.adjustment, Adjustment.apretarMucho),
    certainty: 0.8,
    rationale:
        'En el remate, con reserva y a tope: es el momento de '
        'vaciar el tanque.',
  ),

  // --- Cadencia ---
  Rule(
    id: 'K1',
    when: All([
      Is(v.torque, TorqueLevel.pesado),
      Is(v.demand, Demand.sostenida),
    ]),
    then: Consequent(v.cadence, CadenceLevel.media),
    rationale: 'Mucho torque en subida sostenida: pedalear más ágil.',
  ),
  Rule(
    id: 'K2',
    when: All([Is(v.torque, TorqueLevel.pesado), Is(v.demand, Demand.muro)]),
    then: Consequent(v.cadence, CadenceLevel.alta),
    rationale: 'Mucho torque y viene un muro: piñón suave antes de llegar.',
  ),
  Rule(
    id: 'K3',
    when: All([
      Is(v.effort, EffortState.alLimite),
      Is(v.demand, Demand.sostenida),
    ]),
    then: Consequent(v.cadence, CadenceLevel.media),
    rationale: 'Al límite en subida sostenida: cuidar las piernas.',
  ),
  Rule(
    id: 'K4',
    when: All([
      Is(v.torque, TorqueLevel.normal),
      Is(v.demand, Demand.sostenida),
    ]),
    then: Consequent(v.cadence, CadenceLevel.media),
    rationale: 'Torque normal en subida sostenida: mantener la cadencia.',
  ),
  Rule(
    id: 'K5',
    when: All([Is(v.torque, TorqueLevel.atascado), Is(v.demand, Demand.muro)]),
    then: Consequent(v.cadence, CadenceLevel.alta),
    rationale: 'Atascado con un muro por delante: piñón suave ya.',
  ),
  Rule(
    id: 'K6',
    when: All([
      Is(v.torque, TorqueLevel.ligero),
      Is(v.demand, Demand.sostenida),
    ]),
    then: Consequent(v.cadence, CadenceLevel.baja),
    rationale: 'Pedalea en el aire: con un piñón más duro rinde más.',
  ),

  // --- Urgencia ---
  Rule(
    id: 'U1',
    when: All([
      Is(v.sufficiency, SufficiencyLevel.insuficiente),
      Is(v.climbLeft, ClimbLevel.mucho),
    ]),
    then: Consequent(v.urgency, Urgency.alta),
    rationale: 'Va a reventar antes de la cima: hay que avisar ya.',
  ),
  Rule(
    id: 'U2',
    when: All([Is(v.demand, Demand.muro), Is(v.effort, EffortState.alLimite)]),
    then: Consequent(v.urgency, Urgency.media),
    rationale: 'Al límite con un muro por delante.',
  ),
  Rule(
    id: 'U3',
    when: Is(v.effort, EffortState.alLimite),
    then: Consequent(v.urgency, Urgency.media),
    certainty: 0.6,
    rationale: 'Estar al límite ya merece atención.',
  ),
  Rule(
    id: 'U4',
    when: All([
      Is(v.sufficiency, SufficiencyLevel.holgada),
      Is(v.recordPace, RecordPaceLevel.enRitmo),
    ]),
    then: Consequent(v.urgency, Urgency.media),
    certainty: 0.7,
    rationale: 'Hay margen para apretar: vale la pena avisar.',
  ),
  Rule(
    id: 'U5',
    when: Is(v.effort, EffortState.comodo),
    then: Consequent(v.urgency, Urgency.baja),
    certainty: 0.3,
    rationale: 'Regla de calma: cómodo, poco que decir.',
  ),
  Rule(
    id: 'U6',
    when: Is(v.effort, EffortState.justo),
    then: Consequent(v.urgency, Urgency.nula),
    certainty: 0.3,
    rationale: 'Regla de calma: esfuerzo sostenible, nada que decir.',
  ),

  // --- Urgencia: reglas que cierran los huecos ---
  //
  // Era la salida peor cubierta, y con el peor de los huecos: nada
  // hablaba cuando el ciclista reventaba, así que el coach se callaba
  // justo cuando más falta hacía.
  Rule(
    id: 'U7',
    when: Is(v.effort, EffortState.fundido),
    then: Consequent(v.urgency, Urgency.alta),
    rationale: 'Reventó: hay que decírselo ya.',
  ),
  Rule(
    id: 'U8',
    when: Is(v.effort, EffortState.sobrado),
    then: Consequent(v.urgency, Urgency.media),
    certainty: 0.5,
    rationale: 'Le está sobrando: vale la pena avisarle que puede más.',
  ),
  Rule(
    id: 'U9',
    when: Is(v.demand, Demand.muro),
    then: Consequent(v.urgency, Urgency.media),
    certainty: 0.6,
    rationale: 'Un muro por delante se avisa, vaya como vaya.',
  ),
]);
