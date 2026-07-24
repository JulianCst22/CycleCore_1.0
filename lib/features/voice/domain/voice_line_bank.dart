import 'voice_event.dart';

/// Banco de frases: para cada persona y cada evento hay varias
/// variantes. El motor elige una al azar cada vez, así la voz no
/// repite siempre la misma línea (igual que hace Waze).
///
/// Para agregar más variedad a futuro, solo agrega strings a estas
/// listas — no hace falta tocar el motor ni la UI.
final Map<String, Map<VoiceEventType, List<String>>> kVoiceLineBank = {
  'coach': {
    VoiceEventType.activityStarted: [
      '¡Vamos con todo! Empieza el entrenamiento.',
      'Grabación iniciada. Hoy vamos a superarnos.',
      '¡Arriba esos pedales! Comenzamos ya.',
      'Actividad iniciada. Dale con toda la energía.',
    ],
    VoiceEventType.activityPaused: [
      'Pausa. Recupera el aire, enseguida seguimos.',
      'Descanso corto. No te acomodes mucho.',
      'Actividad en pausa. Aprovecha para hidratarte.',
      'Pausamos. Vuelve con más fuerza.',
    ],
    VoiceEventType.activityResumed: [
      '¡Otra vez en marcha! Dale con todo.',
      'Reanudamos. Vamos a terminar lo que empezamos.',
      'De vuelta al camino. ¡A por ello!',
      'Seguimos rodando. Tú puedes con esto.',
    ],
    VoiceEventType.activityFinished: [
      '¡Actividad terminada! Gran esfuerzo hoy.',
      'Lo lograste. Actividad finalizada, descansa bien.',
      'Terminamos. Ese fue un gran entrenamiento.',
      'Actividad guardada. Estoy orgulloso de tu esfuerzo.',
    ],
  },
  'chill': {
    VoiceEventType.activityStarted: [
      'Listo, empezamos a rodar tranquilo.',
      'Actividad iniciada. Disfruta el camino.',
      'Vamos dando pedal, sin apuros.',
      'Arrancamos. A tu ritmo, como siempre.',
    ],
    VoiceEventType.activityPaused: [
      'Pausa. Tómate tu tiempo.',
      'Descansando un rato. Todo bien.',
      'En pausa. Aquí te espero.',
      'Paramos un momento, relájate.',
    ],
    VoiceEventType.activityResumed: [
      'Seguimos rodando, sin prisa.',
      'De vuelta al pedaleo. Vamos con calma.',
      'Retomamos. Disfruta lo que queda.',
      'Otra vez en marcha, tranquilo.',
    ],
    VoiceEventType.activityFinished: [
      'Actividad terminada. Buen rato de pedal.',
      'Listo, ya está. Buen paseo.',
      'Terminamos por hoy. Descansa tranquilo.',
      'Actividad guardada. Nos vemos en la próxima.',
    ],
  },
  'sergeant': {
    VoiceEventType.activityStarted: [
      '¡Actividad iniciada! Nada de excusas.',
      'En marcha. Concéntrate y pedalea.',
      'Empezamos ya. Sin distracciones.',
      'Grabación activa. Disciplina desde el primer metro.',
    ],
    VoiceEventType.activityPaused: [
      'Pausa autorizada. Rápido, no te confíes.',
      'Alto. Recupera y prepárate para seguir.',
      'En pausa. El reloj no perdona.',
      'Descanso breve. Nada de flojera.',
    ],
    VoiceEventType.activityResumed: [
      '¡De vuelta! Sin perder el ritmo.',
      'Reanudamos. A por lo que falta.',
      'Continúa. No aflojes ahora.',
      'En marcha otra vez. Firmes.',
    ],
    VoiceEventType.activityFinished: [
      'Actividad finalizada. Buen trabajo, soldado.',
      'Terminamos. Cumpliste con la misión.',
      'Actividad guardada. Descanso merecido.',
      'Fin del entrenamiento. Bien hecho.',
    ],
  },
  'pro': {
    VoiceEventType.activityStarted: [
      'Actividad iniciada. Registrando datos.',
      'Grabación en curso desde este momento.',
      'Inicio de actividad confirmado.',
      'Comenzamos a registrar tu recorrido.',
    ],
    VoiceEventType.activityPaused: [
      'Actividad en pausa. Datos en espera.',
      'Registro pausado temporalmente.',
      'Pausa confirmada. Métricas detenidas.',
      'Actividad detenida momentáneamente.',
    ],
    VoiceEventType.activityResumed: [
      'Actividad reanudada. Registro activo.',
      'Continuando con el registro de datos.',
      'Reanudación confirmada.',
      'Registro de actividad reactivado.',
    ],
    VoiceEventType.activityFinished: [
      'Actividad finalizada. Datos guardados.',
      'Registro completado con éxito.',
      'Fin de la actividad. Resumen disponible.',
      'Actividad guardada correctamente.',
    ],
  },
  'sarcastic': {
    VoiceEventType.activityStarted: [
      'Ah, ya empezamos. Espero que hayas dormido.',
      'Actividad iniciada. Vamos a ver de qué estás hecho.',
      'Bueno, aquí vamos otra vez.',
      'Arrancamos. Intenta no rendirte en el primer kilómetro.',
    ],
    VoiceEventType.activityPaused: [
      '¿Ya cansado? Está bien, pausa concedida.',
      'En pausa. Tómate tu selfie y volvemos.',
      'Descansito. No te acostumbres.',
      'Pausamos. El sillín te va a extrañar.',
    ],
    VoiceEventType.activityResumed: [
      'Ah, decidiste volver. Qué generoso.',
      'Reanudamos. Veamos si aguantas más esta vez.',
      'De vuelta. No fue tan mala la pausa, ¿eh?',
      'Otra vez en marcha. A ver hasta dónde llegas.',
    ],
    VoiceEventType.activityFinished: [
      'Terminaste. No estuvo tan mal, admítelo.',
      'Actividad finalizada. Sobreviviste, felicidades.',
      'Listo. Ahora sí puedes presumir un poco.',
      'Fin de la actividad. Nada mal para hoy.',
    ],
  },
  'zen': {
    VoiceEventType.activityStarted: [
      'Comenzamos. Respira y siente cada pedalada.',
      'Actividad iniciada. Encuentra tu ritmo interior.',
      'Iniciamos con calma. Disfruta el presente.',
      'Empieza el recorrido. Conecta con tu respiración.',
    ],
    VoiceEventType.activityPaused: [
      'Pausa. Observa tu respiración un momento.',
      'En pausa. Permítete este instante de calma.',
      'Detente y agradece este momento.',
      'Pausamos. Solo respira.',
    ],
    VoiceEventType.activityResumed: [
      'Continuamos con serenidad.',
      'Retomamos el camino, en paz.',
      'Seguimos, con la mente tranquila.',
      'De vuelta al presente. Sigamos con calma.',
    ],
    VoiceEventType.activityFinished: [
      'Actividad terminada. Agradece este momento.',
      'Hemos concluido. Siente la calma en tu cuerpo.',
      'Fin del recorrido. Honra tu esfuerzo con calma.',
      'Actividad guardada. Respira y descansa.',
    ],
  },
  'hype': {
    VoiceEventType.activityStarted: [
      '¡Y ARRANCAMOS! ¡La actividad ha comenzado!',
      '¡Aquí vamos! ¡Todo el público de pie!',
      '¡Actividad iniciada! ¡Esto va a estar increíble!',
      '¡Comienza el show! ¡Dale con todo!',
    ],
    VoiceEventType.activityPaused: [
      '¡Pausa técnica! ¡Pero esto no ha terminado!',
      '¡Un descanso breve, la afición espera!',
      '¡En pausa! ¡Prepárate para el regreso!',
      '¡Tiempo fuera! ¡Vuelve con fuerza!',
    ],
    VoiceEventType.activityResumed: [
      '¡Y VOLVEMOS A LA ACCIÓN!',
      '¡De vuelta al ruedo! ¡Increíble!',
      '¡Reanudamos con toda la energía!',
      '¡Aquí viene otra vez, imparable!',
    ],
    VoiceEventType.activityFinished: [
      '¡Y SE ACABÓ! ¡Actividad finalizada, qué nivel!',
      '¡Terminaste como un campeón!',
      '¡Actividad guardada! ¡Qué actuación!',
      '¡Final de la actividad! ¡Una locura total!',
    ],
  },
  'grandma': {
    VoiceEventType.activityStarted: [
      'Ay, mi amor, empieza tu paseo. Cuídate mucho.',
      'Ya comenzamos, cariño. Ve con cuidado.',
      'Actividad iniciada, corazón. No te apures.',
      'Vamos, mi niño. Disfruta pero ten cuidado.',
    ],
    VoiceEventType.activityPaused: [
      'Descansa un poquito, mi amor.',
      'En pausa, cariño. Toma agüita.',
      'Ay qué bueno, un descansito.',
      'Pausamos, corazón. No te sobre esfuerces.',
    ],
    VoiceEventType.activityResumed: [
      'Ya seguimos, mi amor. Con cuidado siempre.',
      'De vuelta, cariño. Vamos despacito.',
      'Otra vez en camino, mi niño. Cuídate.',
      'Seguimos, corazón. Tú puedes.',
    ],
    VoiceEventType.activityFinished: [
      'Ay qué bien, ya terminaste. Estoy orgullosa.',
      'Actividad terminada, mi amor. Descansa ahora.',
      'Qué bueno que llegaste bien, cariño.',
      'Se acabó el paseo. Ve a tomar algo rico.',
    ],
  },
};
