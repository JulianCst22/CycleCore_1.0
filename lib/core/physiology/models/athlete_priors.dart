import '../units.dart' show Joules, Watts;
import 'critical_power.dart';

/// Qué tan rodado está el ciclista.
///
/// No es una etiqueta de vanidad: es el punto de partida de la potencia
/// crítica y de la reserva anaeróbica mientras no haya salidas con
/// datos suficientes para calcularlas. Un aficionado de fin de semana y
/// un competidor no tienen la misma reserva, y suponerles la misma —que
/// es lo que hacía el motor— hace que el coach le hable igual a los dos.
enum RiderLevel {
  /// Empezando: sale de vez en cuando, sin plan.
  empezando,

  /// Intermedio: rueda casi todas las semanas.
  intermedio,

  /// Avanzado: entrena con constancia y ya conoce sus números.
  avanzado,

  /// Competidor: compite o entrena como si lo hiciera.
  competidor;

  String get label => switch (this) {
    RiderLevel.empezando => 'Empezando',
    RiderLevel.intermedio => 'Intermedio',
    RiderLevel.avanzado => 'Avanzado',
    RiderLevel.competidor => 'Competidor',
  };

  String get description => switch (this) {
    RiderLevel.empezando => 'Salgo de vez en cuando',
    RiderLevel.intermedio => 'Ruedo casi todas las semanas',
    RiderLevel.avanzado => 'Entreno con constancia',
    RiderLevel.competidor => 'Compito o entreno para competir',
  };

  static RiderLevel byName(String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return RiderLevel.intermedio;
  }
}

/// Punto de partida de un nivel: cuántos vatios por kilo sostiene en el
/// umbral y cuántos julios por kilo tiene de reserva anaeróbica.
///
/// Los rangos siguen las categorías de perfil de potencia que se usan en
/// ciclismo (de recreativo a competidor) y los valores de W′ que reporta
/// la literatura, entre 150 y 400 J/kg. Son **anchos a propósito**: el
/// motor tipo-2 trabaja con la banda, no con el punto, y prefiere decir
/// «no sé bien» a inventar precisión.
typedef LevelPrior = ({
  double cpPerKg,
  double cpPerKgLow,
  double cpPerKgHigh,
  double wPrimePerKg,
  double wPrimePerKgLow,
  double wPrimePerKgHigh,
});

LevelPrior priorOf(RiderLevel level) => switch (level) {
  RiderLevel.empezando => (
    cpPerKg: 2.4,
    cpPerKgLow: 2.0,
    cpPerKgHigh: 2.9,
    wPrimePerKg: 180,
    wPrimePerKgLow: 150,
    wPrimePerKgHigh: 220,
  ),
  RiderLevel.intermedio => (
    cpPerKg: 3.1,
    cpPerKgLow: 2.7,
    cpPerKgHigh: 3.6,
    wPrimePerKg: 220,
    wPrimePerKgLow: 180,
    wPrimePerKgHigh: 270,
  ),
  RiderLevel.avanzado => (
    cpPerKg: 3.9,
    cpPerKgLow: 3.4,
    cpPerKgHigh: 4.5,
    wPrimePerKg: 270,
    wPrimePerKgLow: 220,
    wPrimePerKgHigh: 330,
  ),
  RiderLevel.competidor => (
    cpPerKg: 4.7,
    cpPerKgLow: 4.2,
    cpPerKgHigh: 5.4,
    wPrimePerKg: 320,
    wPrimePerKgLow: 260,
    wPrimePerKgHigh: 390,
  ),
};

/// Modelo de potencia crítica de partida para alguien de [level] que
/// pesa [weightKg], con la incertidumbre que corresponde a estar
/// suponiendo.
///
/// La desviación típica sale del ancho del rango del nivel (un rango de
/// cuatro sigmas), así que el motor arranca con una banda del orden del
/// 10 % en CP y del 20 % en W′. Es mucho, y está bien que lo sea: es lo
/// que se sabe de alguien a quien todavía no se le ha medido nada.
CriticalPowerModel priorModel(RiderLevel level, {required double weightKg}) {
  final prior = priorOf(level);
  final cp = prior.cpPerKg * weightKg;
  final wPrime = prior.wPrimePerKg * weightKg;
  return CriticalPowerModel.manual(
    cp: Watts(cp),
    wPrime: Joules(wPrime),
    seCp: (prior.cpPerKgHigh - prior.cpPerKgLow) * weightKg / 4,
    seWPrime: (prior.wPrimePerKgHigh - prior.wPrimePerKgLow) * weightKg / 4,
  );
}

/// Nivel deducido de cuánto y desde hace cuánto rueda.
///
/// Se pregunta así, y no «¿qué tan bueno eres?», porque la gente se
/// califica mal a sí misma pero sí sabe cuántas horas sale a la semana.
/// Las horas pesan más que los años: alguien que lleva diez años
/// saliendo un domingo al mes no está entrenado.
///
/// En horas a la semana, la escala queda más o menos así:
///
///     menos de 3,5      empezando
///     de 3,5 a 7,5      intermedio
///     de 7,5 a 11       avanzado
///     más de 11         competidor
///
/// y los años corren esa frontera medio nivel como mucho.
///
/// Ante la duda se elige el nivel de abajo: suponerle de menos al
/// ciclista hace que el coach sea prudente, y suponerle de más lo
/// empuja a un ritmo que quizá no aguante.
///
/// Sin ninguno de los dos datos devuelve `null`: mejor preguntar que
/// suponer.
RiderLevel? riderLevelFrom({int? yearsRiding, double? weeklyHours}) {
  if (yearsRiding == null && weeklyHours == null) return null;
  final hours = (weeklyHours ?? 0).clamp(0.0, 16.0);
  final years = (yearsRiding ?? 0).clamp(0, 12).toDouble();
  final score = hours / 3.5 + years / 16;
  if (score < 1.0) return RiderLevel.empezando;
  if (score < 2.2) return RiderLevel.intermedio;
  if (score < 3.4) return RiderLevel.avanzado;
  return RiderLevel.competidor;
}
