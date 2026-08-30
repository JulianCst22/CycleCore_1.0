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

    VoiceEventType.navigationStarted: [
      'Ruta iniciada. Vamos a por ella.',
      'Navegación activa. Sigue las indicaciones.',
      'Tenemos ruta. Pedalea y yo te guío.',
    ],
    VoiceEventType.navigationTurnLeft: [
      'Gira a la izquierda.',
      'Próximo giro a la izquierda.',
      'Izquierda. Mantén el ritmo.',
    ],
    VoiceEventType.navigationTurnRight: [
      'Gira a la derecha.',
      'Próximo giro a la derecha.',
      'Derecha. Vamos bien.',
    ],
    VoiceEventType.navigationTurnSlightLeft: [
      'Giro suave a la izquierda.',
      'Mantente hacia la izquierda.',
      'Toma la salida ligeramente a la izquierda.',
    ],
    VoiceEventType.navigationTurnSlightRight: [
      'Giro suave a la derecha.',
      'Mantente hacia la derecha.',
      'Toma la salida ligeramente a la derecha.',
    ],
    VoiceEventType.navigationTurnSharpLeft: [
      'Giro cerrado a la izquierda.',
      'Izquierda cerrada. Reduce un poco.',
      'Giro fuerte a la izquierda. Prepárate.',
    ],
    VoiceEventType.navigationTurnSharpRight: [
      'Giro cerrado a la derecha.',
      'Derecha cerrada. Reduce un poco.',
      'Giro fuerte a la derecha. Prepárate.',
    ],
    VoiceEventType.navigationUTurn: [
      'Haz un giro de ciento ochenta grados.',
      'Da la vuelta y regresa por el camino.',
      'Cambio de sentido. Volvemos.',
    ],
    VoiceEventType.navigationArrived: [
      '¡Llegamos! Buen trabajo.',
      'Destino alcanzado. Excelente recorrido.',
      'Has llegado. ¡Ruta completada!',
    ],
    VoiceEventType.segmentEntered: [
      'Entraste al segmento. Dale con todo.',
      'Segmento en marcha. Ahora es cuando.',
      'Arrancó el segmento. A darlo todo.',
    ],
    VoiceEventType.segmentCompleted: [
      'Segmento completado. Buen esfuerzo.',
      'Cerraste el segmento. Bien ahí.',
      'Fin del segmento. Recupera y sigue.',
    ],
    VoiceEventType.segmentPr: [
      '¡Nueva mejor marca en el segmento!',
      '¡Récord personal! Lo bajaste.',
      '¡PR! Ese segmento es tuyo.',
    ],
    VoiceEventType.segmentAbandoned: [
      'Te saliste del segmento. No pasa nada, sigue.',
      'Segmento cancelado. La próxima va.',
      'Perdiste el trazado del segmento. Seguimos.',
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

    VoiceEventType.navigationStarted: [
      'Listo, seguimos la ruta con calma.',
      'Navegación activa. Disfruta el camino.',
      'Ya tenemos la ruta. Vamos tranquilos.',
    ],
    VoiceEventType.navigationTurnLeft: [
      'Gira a la izquierda, tranquilo.',
      'Vamos hacia la izquierda.',
      'Toma la izquierda y seguimos.',
    ],
    VoiceEventType.navigationTurnRight: [
      'Gira a la derecha, sin prisa.',
      'Vamos hacia la derecha.',
      'Toma la derecha y seguimos.',
    ],
    VoiceEventType.navigationTurnSlightLeft: [
      'Un poquito hacia la izquierda.',
      'Mantente ligeramente a la izquierda.',
      'Suave hacia la izquierda.',
    ],
    VoiceEventType.navigationTurnSlightRight: [
      'Un poquito hacia la derecha.',
      'Mantente ligeramente a la derecha.',
      'Suave hacia la derecha.',
    ],
    VoiceEventType.navigationTurnSharpLeft: [
      'Giro cerrado a la izquierda. Con calma.',
      'Izquierda cerrada, reduce un poquito.',
      'Gira fuerte a la izquierda, tranquilo.',
    ],
    VoiceEventType.navigationTurnSharpRight: [
      'Giro cerrado a la derecha. Con calma.',
      'Derecha cerrada, reduce un poquito.',
      'Gira fuerte a la derecha, tranquilo.',
    ],
    VoiceEventType.navigationUTurn: [
      'Vamos a dar la vuelta.',
      'Cambio de sentido, regresamos.',
      'Da la vuelta y seguimos por el otro lado.',
    ],
    VoiceEventType.navigationArrived: [
      'Llegamos. Disfruta el momento.',
      'Destino alcanzado. Buen recorrido.',
      'Ya llegamos. Todo tranquilo.',
    ],
    VoiceEventType.segmentEntered: [
      'Empezó el segmento. A tu ritmo.',
      'Entraste al segmento, sin apuros.',
      'Segmento en marcha. Tranquilo y constante.',
    ],
    VoiceEventType.segmentCompleted: [
      'Segmento terminado. Bien hecho.',
      'Listo el segmento. Afloja un poco.',
      'Cerraste el segmento. Buen trabajo.',
    ],
    VoiceEventType.segmentPr: [
      'Nueva mejor marca. Qué bueno.',
      'Bajaste tu tiempo en el segmento.',
      'Récord personal, sin forzar. Genial.',
    ],
    VoiceEventType.segmentAbandoned: [
      'Te saliste del segmento. Todo bien.',
      'Segmento cancelado. Seguimos rodando.',
      'Perdimos el trazado. No importa.',
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

    VoiceEventType.navigationStarted: [
      'Ruta iniciada. Mantente atento.',
      'Navegación activa. Sigue las órdenes.',
      'En marcha. Yo marco el camino.',
    ],
    VoiceEventType.navigationTurnLeft: [
      'Giro a la izquierda.',
      'Izquierda. Ahora.',
      'Toma la izquierda. Mantén el rumbo.',
    ],
    VoiceEventType.navigationTurnRight: [
      'Giro a la derecha.',
      'Derecha. Ahora.',
      'Toma la derecha. Mantén el rumbo.',
    ],
    VoiceEventType.navigationTurnSlightLeft: [
      'Ligeramente a la izquierda.',
      'Desvío suave a la izquierda.',
      'Mantente a la izquierda.',
    ],
    VoiceEventType.navigationTurnSlightRight: [
      'Ligeramente a la derecha.',
      'Desvío suave a la derecha.',
      'Mantente a la derecha.',
    ],
    VoiceEventType.navigationTurnSharpLeft: [
      '¡Giro cerrado a la izquierda!',
      'Izquierda cerrada. Reduce.',
      '¡Giro fuerte a la izquierda! Atención.',
    ],
    VoiceEventType.navigationTurnSharpRight: [
      '¡Giro cerrado a la derecha!',
      'Derecha cerrada. Reduce.',
      '¡Giro fuerte a la derecha! Atención.',
    ],
    VoiceEventType.navigationUTurn: [
      '¡Cambio de sentido!',
      'Da la vuelta. Rumbo contrario.',
      '¡Giro de ciento ochenta grados!',
    ],
    VoiceEventType.navigationArrived: [
      'Destino alcanzado. Misión cumplida.',
      'Llegamos. Buen trabajo.',
      'Ruta completada. Descansa.',
    ],
    VoiceEventType.segmentEntered: [
      'Segmento iniciado. Sin aflojar.',
      'Entraste al segmento. A darlo todo.',
      'Empieza el segmento. Concéntrate.',
    ],
    VoiceEventType.segmentCompleted: [
      'Segmento completado. Buen trabajo, soldado.',
      'Cerraste el segmento. Cumpliste.',
      'Fin del segmento. Recupera y sigue.',
    ],
    VoiceEventType.segmentPr: [
      '¡Nueva marca! Así se hace.',
      '¡Récord personal! Superaste tu tiempo.',
      '¡PR! Ese segmento cayó.',
    ],
    VoiceEventType.segmentAbandoned: [
      'Perdiste el segmento. Recupéralo la próxima.',
      'Segmento cancelado. Sin excusas la próxima.',
      'Te saliste del trazado. Seguimos.',
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

    VoiceEventType.navigationStarted: [
      'Navegación iniciada. Ruta activa.',
      'Ruta calculada. Navegación en curso.',
      'Navegación activa. Siguiendo el recorrido.',
    ],
    VoiceEventType.navigationTurnLeft: [
      'Giro a la izquierda.',
      'Próxima maniobra: izquierda.',
      'Tome la izquierda.',
    ],
    VoiceEventType.navigationTurnRight: [
      'Giro a la derecha.',
      'Próxima maniobra: derecha.',
      'Tome la derecha.',
    ],
    VoiceEventType.navigationTurnSlightLeft: [
      'Giro leve a la izquierda.',
      'Manténgase ligeramente a la izquierda.',
      'Desvío leve a la izquierda.',
    ],
    VoiceEventType.navigationTurnSlightRight: [
      'Giro leve a la derecha.',
      'Manténgase ligeramente a la derecha.',
      'Desvío leve a la derecha.',
    ],
    VoiceEventType.navigationTurnSharpLeft: [
      'Giro pronunciado a la izquierda.',
      'Giro cerrado a la izquierda.',
      'Maniobra cerrada hacia la izquierda.',
    ],
    VoiceEventType.navigationTurnSharpRight: [
      'Giro pronunciado a la derecha.',
      'Giro cerrado a la derecha.',
      'Maniobra cerrada hacia la derecha.',
    ],
    VoiceEventType.navigationUTurn: [
      'Cambio de sentido.',
      'Realice un giro de ciento ochenta grados.',
      'Regrese por el sentido contrario.',
    ],
    VoiceEventType.navigationArrived: [
      'Destino alcanzado.',
      'Ha llegado al destino.',
      'Navegación finalizada. Destino alcanzado.',
    ],
    VoiceEventType.segmentEntered: [
      'Segmento iniciado. Registrando tiempo.',
      'Entrada al segmento confirmada.',
      'Comienza el segmento.',
    ],
    VoiceEventType.segmentCompleted: [
      'Segmento completado. Tiempo registrado.',
      'Fin del segmento.',
      'Esfuerzo de segmento guardado.',
    ],
    VoiceEventType.segmentPr: [
      'Nueva mejor marca en el segmento.',
      'Récord personal registrado.',
      'Mejor tiempo del segmento superado.',
    ],
    VoiceEventType.segmentAbandoned: [
      'Segmento no completado.',
      'Esfuerzo de segmento cancelado.',
      'Se abandonó el segmento antes de la meta.',
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

    VoiceEventType.navigationStarted: [
      'Ruta lista. Intentemos no perdernos.',
      'Navegación iniciada. Porque aparentemente necesitas ayuda.',
      'Bueno, yo te digo por dónde. Tú intenta seguirme.',
    ],
    VoiceEventType.navigationTurnLeft: [
      'Gira a la izquierda. Sí, esa izquierda.',
      'Izquierda. No te preocupes, no es tan difícil.',
      'Toma la izquierda. Intenta no pasártela.',
    ],
    VoiceEventType.navigationTurnRight: [
      'Gira a la derecha. Esta vez sí.',
      'Derecha. Vamos, tú puedes.',
      'Toma la derecha. No me hagas repetirlo.',
    ],
    VoiceEventType.navigationTurnSlightLeft: [
      'Un poquito a la izquierda. No hace falta dramatizar.',
      'Suave hacia la izquierda.',
      'Ligeramente a la izquierda. Sí, eso mismo.',
    ],
    VoiceEventType.navigationTurnSlightRight: [
      'Un poquito a la derecha. Fácil.',
      'Suave hacia la derecha.',
      'Ligeramente a la derecha. No te emociones.',
    ],
    VoiceEventType.navigationTurnSharpLeft: [
      'Giro cerrado a la izquierda. Ahora viene lo divertido.',
      'Izquierda cerrada. Frena antes de descubrir la gravedad.',
      'Giro fuerte a la izquierda. Suerte.',
    ],
    VoiceEventType.navigationTurnSharpRight: [
      'Giro cerrado a la derecha. Sujétate bien.',
      'Derecha cerrada. Intenta mantenerte sobre la bici.',
      'Giro fuerte a la derecha. Qué emoción.',
    ],
    VoiceEventType.navigationUTurn: [
      'Da la vuelta. Sí, nos equivocamos.',
      'Cambio de sentido. Excelente trabajo perdiéndonos.',
      'Giro de ciento ochenta grados. Volvemos.',
    ],
    VoiceEventType.navigationArrived: [
      'Llegaste. Milagrosamente.',
      'Destino alcanzado. Puedes celebrar.',
      'Llegamos. Al menos esta vez.',
    ],
    VoiceEventType.segmentEntered: [
      'Segmento iniciado. Veamos qué tienes hoy.',
      'Entraste al segmento. No lo arruines.',
      'Empieza el segmento. Suerte con eso.',
    ],
    VoiceEventType.segmentCompleted: [
      'Segmento terminado. No estuvo tan mal.',
      'Cerraste el segmento. Sobreviviste.',
      'Fin del segmento. Respira, campeón.',
    ],
    VoiceEventType.segmentPr: [
      'Nueva mejor marca. ¿Quién lo diría?',
      'Récord personal. Hasta yo estoy impresionado.',
      'Bajaste tu tiempo. Aprovecha para presumir.',
    ],
    VoiceEventType.segmentAbandoned: [
      'Te saliste del segmento. Clásico.',
      'Segmento cancelado. Otra vez será.',
      'Perdiste el trazado. Sin comentarios.',
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

    VoiceEventType.navigationStarted: [
      'Comienza el camino. Sigue las indicaciones con calma.',
      'La ruta está lista. Disfruta cada momento.',
      'Navegación iniciada. Fluye con el recorrido.',
    ],
    VoiceEventType.navigationTurnLeft: [
      'Gira suavemente a la izquierda.',
      'El camino continúa hacia la izquierda.',
      'Toma la izquierda y continúa en calma.',
    ],
    VoiceEventType.navigationTurnRight: [
      'Gira suavemente a la derecha.',
      'El camino continúa hacia la derecha.',
      'Toma la derecha y continúa en calma.',
    ],
    VoiceEventType.navigationTurnSlightLeft: [
      'Acércate suavemente hacia la izquierda.',
      'Continúa ligeramente hacia la izquierda.',
      'Deja que el camino te lleve hacia la izquierda.',
    ],
    VoiceEventType.navigationTurnSlightRight: [
      'Acércate suavemente hacia la derecha.',
      'Continúa ligeramente hacia la derecha.',
      'Deja que el camino te lleve hacia la derecha.',
    ],
    VoiceEventType.navigationTurnSharpLeft: [
      'Un giro cerrado hacia la izquierda. Respira.',
      'Gira con calma hacia la izquierda.',
      'El camino cambia hacia la izquierda. Suavemente.',
    ],
    VoiceEventType.navigationTurnSharpRight: [
      'Un giro cerrado hacia la derecha. Respira.',
      'Gira con calma hacia la derecha.',
      'El camino cambia hacia la derecha. Suavemente.',
    ],
    VoiceEventType.navigationUTurn: [
      'El camino nos invita a regresar.',
      'Cambiamos de sentido con calma.',
      'Volvemos sobre nuestros pasos.',
    ],
    VoiceEventType.navigationArrived: [
      'Has llegado. Permanece presente.',
      'El camino termina aquí. Respira.',
      'Destino alcanzado. Disfruta este momento.',
    ],
    VoiceEventType.segmentEntered: [
      'Comienza el segmento. Respira y fluye.',
      'Entraste al segmento. Encuentra tu ritmo.',
      'El segmento empieza. Un pedaleo a la vez.',
    ],
    VoiceEventType.segmentCompleted: [
      'Segmento completado. Honra tu esfuerzo.',
      'El segmento terminó. Suelta la tensión.',
      'Cerraste el segmento. Respira y sigue.',
    ],
    VoiceEventType.segmentPr: [
      'Nueva mejor marca. Fluiste bien hoy.',
      'Récord personal, sin forzar. Buen trabajo.',
      'Superaste tu tiempo. Estabas presente.',
    ],
    VoiceEventType.segmentAbandoned: [
      'Dejaste el segmento. Está bien, sigue.',
      'El segmento quedó atrás. Sin apego.',
      'Perdiste el trazado. Vuelve a tu respiración.',
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

    VoiceEventType.navigationStarted: [
      '¡RUTA LISTA! ¡Vamos a por el recorrido!',
      '¡Navegación activada! ¡Sigue la línea!',
      '¡Tenemos camino! ¡Dale, que arrancamos!',
    ],
    VoiceEventType.navigationTurnLeft: [
      '¡IZQUIERDA! ¡Vamos por ahí!',
      '¡Giro a la izquierda! ¡Dale!',
      '¡IZQUIERDA! ¡Mantén la velocidad!',
    ],
    VoiceEventType.navigationTurnRight: [
      '¡DERECHA! ¡Vamos por ahí!',
      '¡Giro a la derecha! ¡Dale!',
      '¡DERECHA! ¡Seguimos con todo!',
    ],
    VoiceEventType.navigationTurnSlightLeft: [
      '¡Suave a la izquierda!',
      '¡Ligeramente a la izquierda! ¡Vamos!',
      '¡Izquierda suave! ¡Seguimos!',
    ],
    VoiceEventType.navigationTurnSlightRight: [
      '¡Suave a la derecha!',
      '¡Ligeramente a la derecha! ¡Vamos!',
      '¡Derecha suave! ¡Seguimos!',
    ],
    VoiceEventType.navigationTurnSharpLeft: [
      '¡GIRO CERRADO A LA IZQUIERDA!',
      '¡IZQUIERDA FUERTE! ¡Prepárate!',
      '¡Giro cerrado! ¡A la izquierda!',
    ],
    VoiceEventType.navigationTurnSharpRight: [
      '¡GIRO CERRADO A LA DERECHA!',
      '¡DERECHA FUERTE! ¡Prepárate!',
      '¡Giro cerrado! ¡A la derecha!',
    ],
    VoiceEventType.navigationUTurn: [
      '¡CAMBIO DE SENTIDO!',
      '¡DA LA VUELTA! ¡Regresamos!',
      '¡GIRO DE CIENTO OCHENTA! ¡Vamos!',
    ],
    VoiceEventType.navigationArrived: [
      '¡LLEGAMOS! ¡QUÉ GRAN RECORRIDO!',
      '¡DESTINO ALCANZADO! ¡LO LOGRAMOS!',
      '¡Y LLEGAMOS! ¡RUTA COMPLETADA!',
    ],
    VoiceEventType.segmentEntered: [
      '¡ARRANCA EL SEGMENTO! ¡Dale, dale!',
      '¡Entramos al segmento! ¡Todo el gas!',
      '¡EMPIEZA EL SEGMENTO! ¡A romperla!',
    ],
    VoiceEventType.segmentCompleted: [
      '¡SEGMENTO COMPLETADO! ¡Qué nivel!',
      '¡Y cerraste el segmento! ¡Grande!',
      '¡FIN DEL SEGMENTO! ¡Increíble esfuerzo!',
    ],
    VoiceEventType.segmentPr: [
      '¡RÉCORD PERSONAL! ¡LO BAJASTE!',
      '¡NUEVA MEJOR MARCA! ¡IMPARABLE!',
      '¡PR EN EL SEGMENTO! ¡ESO ES!',
    ],
    VoiceEventType.segmentAbandoned: [
      '¡Te saliste del segmento! ¡La próxima cae!',
      '¡Segmento cancelado! ¡Vamos por la revancha!',
      '¡Perdimos el trazado! ¡Seguimos con todo!',
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

    VoiceEventType.navigationStarted: [
      'Ya tenemos el camino, mi amor. Ve con cuidado.',
      'La ruta está lista, cariño. Yo te voy guiando.',
      'Empezamos el camino, corazón. Sin apurarte.',
    ],
    VoiceEventType.navigationTurnLeft: [
      'Gira a la izquierda, mi amor.',
      'Vamos por la izquierda, cariño.',
      'A la izquierda, corazón. Con cuidadito.',
    ],
    VoiceEventType.navigationTurnRight: [
      'Gira a la derecha, mi amor.',
      'Vamos por la derecha, cariño.',
      'A la derecha, corazón. Con cuidadito.',
    ],
    VoiceEventType.navigationTurnSlightLeft: [
      'Un poquito hacia la izquierda, cariño.',
      'Suavecito hacia la izquierda, mi amor.',
      'Mantente un poquito a la izquierda, corazón.',
    ],
    VoiceEventType.navigationTurnSlightRight: [
      'Un poquito hacia la derecha, cariño.',
      'Suavecito hacia la derecha, mi amor.',
      'Mantente un poquito a la derecha, corazón.',
    ],
    VoiceEventType.navigationTurnSharpLeft: [
      'Giro cerrado a la izquierda, mi amor. Despacito.',
      'Cuidado con ese giro a la izquierda, cariño.',
      'A la izquierda, corazón. Ve con mucho cuidado.',
    ],
    VoiceEventType.navigationTurnSharpRight: [
      'Giro cerrado a la derecha, mi amor. Despacito.',
      'Cuidado con ese giro a la derecha, cariño.',
      'A la derecha, corazón. Ve con mucho cuidado.',
    ],
    VoiceEventType.navigationUTurn: [
      'Vamos a dar la vueltica, mi amor.',
      'Hay que regresar, cariño. Damos la vuelta.',
      'Cambio de sentido, corazón. Con cuidadito.',
    ],
    VoiceEventType.navigationArrived: [
      'Ay, mi amor, ya llegamos. Qué bueno.',
      'Llegaste bien, cariño. Estoy orgullosa.',
      'Ya estamos en el destino, corazón. Descansa.',
    ],
    VoiceEventType.segmentEntered: [
      'Empezó el segmento, mi amor. Ve a tu ritmo.',
      'Entraste al segmento, cariño. Con cuidadito.',
      'Ya arrancó el segmento, corazón. Tú puedes.',
    ],
    VoiceEventType.segmentCompleted: [
      'Terminaste el segmento, mi amor. Muy bien.',
      'Ya cerraste el segmento, cariño. Descansa.',
      'Listo el segmento, corazón. Estoy orgullosa.',
    ],
    VoiceEventType.segmentPr: [
      '¡Ay, tu mejor marca, mi amor! Qué orgullo.',
      'Bajaste tu tiempo, cariño. ¡Qué bien!',
      'Nuevo récord, corazón. Estoy feliz por ti.',
    ],
    VoiceEventType.segmentAbandoned: [
      'Te saliste del segmento, mi amor. No te preocupes.',
      'Se canceló el segmento, cariño. La próxima.',
      'Perdimos el caminito, corazón. No pasa nada.',
    ],
  },
};