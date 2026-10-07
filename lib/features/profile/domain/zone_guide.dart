/// Para qué sirve cada zona, en palabras de ciclista: lo que se lee al
/// tocar una zona en la pantalla de zonas.
///
/// Va por posición, no por nombre: las zonas guardadas pueden venir con
/// el nombre de una versión anterior, pero la Z4 sigue siendo la Z4.
class ZoneGuide {
  /// Etiqueta corta para la fila de la lista.
  final String hint;

  /// Para qué sirve.
  final String purpose;

  /// Cómo se siente por dentro (la prueba del habla).
  final String feel;

  /// Cuánto se aguanta o cómo se suele entrenar.
  final String duration;

  /// Esfuerzo percibido, de 1 a 10.
  final String effort;

  /// De dónde sale la energía.
  final String fuel;

  const ZoneGuide({
    required this.hint,
    required this.purpose,
    required this.feel,
    required this.duration,
    required this.effort,
    required this.fuel,
  });

  /// La guía de la zona [index] de potencia (modelo de 7 zonas sobre el
  /// FTP), o `null` si las zonas no siguen ese modelo.
  static ZoneGuide? power(int index, int count) =>
      count == _power.length && index < count ? _power[index] : null;

  /// La guía de la zona [index] de pulso (modelo de 5 zonas sobre la FC
  /// máxima), o `null` si las zonas no siguen ese modelo.
  static ZoneGuide? heartRate(int index, int count) =>
      count == _heartRate.length && index < count ? _heartRate[index] : null;

  static const _power = [
    ZoneGuide(
      hint: 'Rodar suave',
      purpose:
          'Soltar las piernas y recuperarte de los días duros. No entrena '
          'nada nuevo: ayuda a que lo demás se asiente.',
      feel: 'Hablas sin ningún esfuerzo, como si fueras de paseo.',
      duration: 'Para calentar, enfriar y los días de descanso activo.',
      effort: '1–2/10',
      fuel: 'Grasas',
    ),
    ZoneGuide(
      hint: 'Base aeróbica',
      purpose:
          'La base de todo: corazón más fuerte y un cuerpo que aprende a '
          'gastar grasa y guardar azúcar para cuando la necesita.',
      feel: 'Puedes conversar en frases completas.',
      duration: 'Es donde pasan las salidas largas, de 2 a 4 horas o más.',
      effort: '3/10',
      fuel: 'Grasas',
    ),
    ZoneGuide(
      hint: 'Ritmo sostenido',
      purpose:
          'Aguantar un ritmo firme mucho tiempo: el de una subida larga '
          'llevada con cabeza o el de ir tirando de un grupo.',
      feel: 'Exigente pero controlado. Hablas en frases cortas.',
      duration: 'Bloques de 20 a 60 minutos.',
      effort: '4–5/10',
      fuel: 'Grasas y azúcar',
    ),
    ZoneGuide(
      hint: 'Subidas largas',
      purpose:
          'Subir el umbral: lo más fuerte que puedes sostener cerca de una '
          'hora. Es el ritmo de un puerto a tope.',
      feel: 'Respiración profunda y constante; solo palabras sueltas.',
      duration: 'Intervalos de 8 a 20 minutos, hasta una hora en total.',
      effort: '6–7/10',
      fuel: 'Azúcar (glucógeno)',
    ),
    ZoneGuide(
      hint: '3 a 8 minutos',
      purpose:
          'Llevar el consumo de oxígeno al máximo. Sirve para las rampas '
          'duras y para no quedarte cuando el grupo acelera.',
      feel: 'Muy duro. No puedes hablar y las piernas empiezan a arder.',
      duration: 'Series de 3 a 8 minutos con descansos parecidos.',
      effort: '8–9/10',
      fuel: 'Azúcar (glucógeno)',
    ),
    ZoneGuide(
      hint: '30 s a 2 min',
      purpose:
          'Esfuerzos por encima de lo que el oxígeno alcanza a cubrir: '
          'ataques, cambios de ritmo y repechos cortos.',
      feel: 'Arde y se acaba rápido. Después necesitas varios minutos.',
      duration: 'De 30 segundos a 2 minutos.',
      effort: '9/10',
      fuel: 'Azúcar, sin oxígeno',
    ),
    ZoneGuide(
      hint: 'Sprints',
      purpose:
          'Potencia pura: arrancadas, sprints y saltar a una rueda. Es más '
          'fuerza que respiración.',
      feel: 'Todo lo que tienes, de pie sobre los pedales.',
      duration: 'Menos de 30 segundos.',
      effort: '10/10',
      fuel: 'Reservas inmediatas del músculo',
    ),
  ];

  static const _heartRate = [
    ZoneGuide(
      hint: 'Recuperar',
      purpose: 'Calentar, enfriar y recuperarte entre días duros.',
      feel: 'Respiras por la nariz y hablas sin pensarlo.',
      duration: 'Tanto como quieras.',
      effort: '1–2/10',
      fuel: 'Grasas',
    ),
    ZoneGuide(
      hint: 'Base aeróbica',
      purpose:
          'Fortalece el corazón y enseña al cuerpo a gastar grasa. Es la '
          'zona que más tiempo deberías pasar.',
      feel: 'Conversas sin problema.',
      duration: 'Salidas largas, de 1 a 4 horas.',
      effort: '3/10',
      fuel: 'Grasas',
    ),
    ZoneGuide(
      hint: 'Ritmo de crucero',
      purpose: 'Un ritmo firme de fondo, el de rodar en grupo a buen paso.',
      feel: 'Hablas en frases cortas.',
      duration: 'De 20 a 90 minutos.',
      effort: '5/10',
      fuel: 'Grasas y azúcar',
    ),
    ZoneGuide(
      hint: 'Cerca del umbral',
      purpose:
          'Aguantar ritmos altos más tiempo. Es donde suele quedar el '
          'pulso subiendo un puerto fuerte.',
      feel: 'Respiración fuerte; cuesta hablar.',
      duration: 'Intervalos de 5 a 20 minutos.',
      effort: '7/10',
      fuel: 'Azúcar (glucógeno)',
    ),
    ZoneGuide(
      hint: 'Al límite',
      purpose:
          'Esfuerzos máximos. El pulso tarda en subir, así que en '
          'arrancadas cortas va por detrás de las piernas: ahí manda la '
          'potencia.',
      feel: 'No puedes hablar.',
      duration: 'Pocos minutos.',
      effort: '9–10/10',
      fuel: 'Azúcar (glucógeno)',
    ),
  ];
}
