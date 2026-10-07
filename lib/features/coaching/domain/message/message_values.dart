import '../advice/targets.dart';
import '../coaching_session.dart';

/// Los huecos numéricos que una pieza puede pedir. Ningún número se
/// escribe en el banco de frases: todos salen del motor y se rellenan
/// acá, así una frase nunca puede mentir.
enum MessageValue {
  /// Objetivo de potencia, ya redondeado a múltiplo de 5 («290»).
  potencia,

  /// Cuánto hay que bajar o subir respecto a lo que lleva («25»).
  deltaPotencia,

  /// Potencia que lleva ahora, media de 30 s («316»).
  potenciaActual,

  /// Piso por debajo del cual no conviene aflojar («272»).
  piso,

  /// Objetivo de cadencia en rpm («80»).
  cadencia,

  /// Cadencia que lleva ahora («72»).
  cadenciaActual,

  /// Pendiente del tramo que viene, en % («8»).
  pendiente,

  /// Pendiente de la rampa más dura que viene, en % («9»).
  rampa,

  /// A cuántos metros está esa rampa («400»).
  metrosRampa,

  /// Desnivel que falta para la cima, en metros («421»).
  desnivel,

  /// Metros que faltan para terminar el segmento («4920»).
  metrosRestantes,

  /// Kilómetros que faltan para terminar («6», «1.5»). Es la distancia
  /// que el ciclista entiende cuando falta bastante: «quedan 285 metros
  /// de desnivel» no le dice nada, «quedan 6 kilómetros» sí.
  kmRestantes,

  /// Ventaja sobre el récord, en segundos y sin signo («4»).
  ventaja,

  /// Pulso actual en ppm («178»).
  pulso,

  /// Pulso al que conviene bajar cuando el corazón es la limitante
  /// («170»).
  pulsoObjetivo,
}

/// Cómo se llama en voz alta la unidad de cada número.
///
/// Un número suelto no se entiende pedaleando: «baja a 285» obliga al
/// ciclista a adivinar si son vatios, pulsaciones o metros, y eso es
/// exactamente lo que no puede pasar cuando va con el pulso arriba. Por
/// eso toda pieza que use un hueco tiene que decir su unidad, y el
/// validador lo revisa.
///
/// Se aceptan varias formas para que cada voz hable como habla: «80 de
/// cadencia» y «80 pedaladas» valen igual.
List<String> unitWordsOf(MessageValue value) => switch (value) {
  MessageValue.potencia ||
  MessageValue.potenciaActual ||
  MessageValue.deltaPotencia ||
  MessageValue.piso => const ['vatios', 'vatio'],
  MessageValue.cadencia ||
  MessageValue.cadenciaActual => const ['cadencia', 'pedaladas', 'rpm'],
  MessageValue.pulso ||
  MessageValue.pulsoObjetivo => const ['pulso', 'pulsaciones', 'pulsación'],
  MessageValue.pendiente || MessageValue.rampa => const ['por ciento', '%'],
  MessageValue.metrosRampa ||
  MessageValue.metrosRestantes ||
  MessageValue.desnivel => const ['metros', 'metro'],
  MessageValue.ventaja => const ['segundos', 'segundo'],
  MessageValue.kmRestantes => const ['kilómetros', 'kilómetro', 'kiló'],
};

/// Los números de un instante, ya redondeados como se dicen en voz alta.
/// Un valor ausente significa «este instante no lo tiene» (sin
/// potenciómetro no hay vatios, sin récord no hay ventaja), y ninguna
/// pieza que lo pida se puede usar.
typedef MessageNumbers = Map<MessageValue, num>;

/// Arma los números de un consejo. Todos vienen del motor o de los
/// sensores; acá solo se redondean.
MessageNumbers numbersOf(Advice advice) {
  final f = advice.features;
  final terrain = f.terrain;
  final power = advice.power;
  final cadence = advice.cadence;
  final numbers = <MessageValue, num>{};

  void put(MessageValue key, num? value) {
    if (value != null) numbers[key] = value;
  }

  // Sin potenciómetro la potencia se estima con la velocidad: sirve para
  // decidir, pero no para decirla en voz alta. Un «bájale a 290» que sale
  // de una estimación es un número inventado, y el ADR-8 dice que toda
  // cifra hablada viene del motor y es de fiar. Se habla igual: con las
  // piezas que no llevan vatios («afloja un poquito»), la cadencia y el
  // pulso.
  if (!f.powerIsEstimated) {
    put(MessageValue.potencia, power?.spoken.round());
    put(MessageValue.potenciaActual, f.basePower?.round());
    if (power != null && f.basePower != null) {
      final delta = (f.basePower! - power.spoken).abs().round();
      if (delta > 0) numbers[MessageValue.deltaPotencia] = delta;
    }
    put(MessageValue.piso, _floorOf(power));
  }
  // La cadencia objetivo solo se dice si hay con qué medirla (sensor de
  // cadencia o potenciómetro): «pedalea a 80» sin poder ver la cifra es
  // un número que el ciclista no puede comprobar. Sin sensor se habla
  // igual, con las piezas que no la llevan.
  if (f.cadence != null) {
    put(MessageValue.cadencia, cadence?.spoken.round());
    put(MessageValue.cadenciaActual, f.cadence?.round());
  }
  put(MessageValue.pendiente, f.gradientAhead.value.round());
  put(MessageValue.pulso, f.heartRate?.round());
  put(MessageValue.pulsoObjetivo, advice.targetHeartRate?.round());
  if (terrain != null) {
    put(MessageValue.rampa, terrain.maxRamp.round());
    put(MessageValue.metrosRampa, _toFifty(terrain.maxRampInMeters));
    put(MessageValue.desnivel, terrain.climbLeft.round());
    put(MessageValue.metrosRestantes, _toFifty(terrain.distanceLeft));
  }
  final left = advice.plan.metersLeft;
  if (left >= 1000) put(MessageValue.kmRestantes, _toKilometres(left));
  final pace = f.recordPace?.value;
  if (pace != null) put(MessageValue.ventaja, pace.abs().round());
  return numbers;
}

/// El piso solo se dice cuando de verdad limita: sin región segura no
/// hay número que decir.
int? _floorOf(Target? target) {
  final floor = target?.floor;
  if (floor == null || target == null) return null;
  return floor >= target.spoken ? null : floor.round();
}

/// Distancias habladas: múltiplos de 50 m, que es como las dice un
/// ciclista («en doscientos metros»).
int _toFifty(double meters) => (meters / 50).round() * 50;

/// Kilómetros con medio kilómetro de resolución, y sin decimal cuando
/// no hace falta: «6» y «1.5», nunca «6.0».
num _toKilometres(double meters) {
  final halves = (meters / 500).round() / 2;
  return halves == halves.roundToDouble() ? halves.round() : halves;
}
