import '../../../../core/physiology/physiology.dart' show RidingResistance;
import '../coaching_parameters.dart';
import '../variables/labels.dart';
import 'pacing_plan.dart';

/// Lo que el mensaje puede añadir además del objetivo.
///
/// El motor difuso decide vatios y cadencia; estos son los consejos de
/// al lado, los que un compañero de ruta diría sin mirar el ciclómetro.
/// No salen de reglas difusas sino de condiciones duras, porque son
/// cosas que o se pueden hacer o no: no tiene sentido «respira profundo»
/// con el pulso bajo, ni «sube un piñón» cuando ya no queda piñón.
enum AdviceHint {
  /// Queda desarrollo para pedalear más redondo.
  pinon,

  /// Va pedaleando en el aire y queda piñón más duro que poner.
  pinonDuro,

  /// El corazón está arriba: aflojar la respiración ayuda a bajarlo.
  respirar,

  /// Guardar acá porque lo duro viene después.
  regular,

  /// Ir parejo.
  sostener,

  /// Soltar lo que quede: ya no hay dónde guardarlo.
  apretar,
}

/// Qué avisos secundarios caben en este instante.
///
/// Devuelve solo los que son verdad ahora mismo. Una pieza del banco
/// etiquetada con uno de estos no se puede usar si el aviso no está en
/// el conjunto, y así una frase nunca sugiere algo imposible.
Set<AdviceHint> hintsOf({
  required PacingStance stance,
  required RidingResistance resistance,
  EffortState? state,
  double? heartRateReserve,
  double? torque,
  double? cadenceTarget,
  double? speed,
  CoachingParameters parameters = const CoachingParameters(),
}) => {
  // No hace falta que el pulso sea *la* limitante: si está arriba,
  // respirar más lento ayuda. Pero a alguien que va cómodo o sobrado no
  // se le dice que baje el pulso: suena a contradicción y no lo es —el
  // corazón deriva hacia arriba en una subida larga aunque el esfuerzo
  // esté controlado—, así que mejor no decirlo.
  if (heartRateReserve != null &&
      heartRateReserve >= parameters.highHeartRate &&
      state != EffortState.comodo &&
      state != EffortState.sobrado)
    AdviceHint.respirar,
  // El piñón, en cambio, se dice solo si existe: pedirlo en una rampa
  // donde ya se acabó el desarrollo no es un consejo.
  if (torque != null &&
      torque >= parameters.highTorque &&
      cadenceTarget != null &&
      speed != null &&
      resistance.canReachCadence(cadenceTarget, speed))
    AdviceHint.pinon,
  // Y al revés: a 110 rpm lo que sobra es cadencia, y el consejo es
  // poner un piñón más duro —si queda alguno.
  if (torque != null &&
      torque <= parameters.lowTorque &&
      cadenceTarget != null &&
      speed != null &&
      resistance.canLowerCadence(cadenceTarget, speed))
    AdviceHint.pinonDuro,
  switch (stance) {
    PacingStance.regular => AdviceHint.regular,
    PacingStance.sostener => AdviceHint.sostener,
    PacingStance.apretar => AdviceHint.apretar,
  },
};
