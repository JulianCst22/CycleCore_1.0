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

  'zen': {
    VoiceEventType.activityStarted: [
      'Comenzamos. Ritmo suave y respiración tranquila.',
      'Actividad iniciada. Busca un ritmo cómodo y sostenlo.',
      'Iniciamos con calma. Sin prisa hoy.',
      'Empieza el recorrido. Rueda suelto y relajado.',
    ],
    VoiceEventType.activityPaused: [
      'Pausa. Respira hondo un momento.',
      'En pausa. Aprovecha para soltar los hombros.',
      'Paramos. Recupera con calma.',
      'Pausamos. Sin apuro.',
    ],
    VoiceEventType.activityResumed: [
      'Continuamos con calma.',
      'Retomamos el ritmo, tranquilo.',
      'Seguimos, sin forzar.',
      'De vuelta al camino. Suave.',
    ],
    VoiceEventType.activityFinished: [
      'Actividad terminada. Baja pulsaciones poco a poco.',
      'Hemos concluido. Afloja y recupera con calma.',
      'Fin del recorrido. Buen trabajo, sin desgaste.',
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
      'Has llegado. Tómate un momento.',
      'El camino termina aquí. Bien hecho.',
      'Destino alcanzado. A recuperar con calma.',
    ],
    VoiceEventType.segmentEntered: [
      'Comienza el segmento. A tu ritmo, sin agobios.',
      'Entraste al segmento. Constante y suelto.',
      'El segmento empieza. Un pedaleo a la vez.',
    ],
    VoiceEventType.segmentCompleted: [
      'Segmento completado. Buen ritmo.',
      'El segmento terminó. Suelta las piernas.',
      'Cerraste el segmento. Respira y sigue.',
    ],
    VoiceEventType.segmentPr: [
      'Nueva mejor marca, sin forzar. Muy bien.',
      'Récord personal con la cabeza fría. Buen trabajo.',
      'Superaste tu tiempo. Ibas muy suelto.',
    ],
    VoiceEventType.segmentAbandoned: [
      'Dejaste el segmento. No pasa nada, sigue.',
      'El segmento quedó atrás. Tranquilo.',
      'Perdiste el trazado. Continúa a tu ritmo.',
    ],
  },

  // "Director deportivo": el coche de equipo hablándote por radio.
  // Energía y decisión, pero profesional -- ni gritos ni estadio.
  'hype': {
    VoiceEventType.activityStarted: [
      'Salimos. Coche de equipo contigo, a rodar.',
      'Grabando. Encuentra tu ritmo y lo vamos gestionando.',
      'Arrancamos. Yo te doy referencias por radio.',
      'En marcha. Cabeza fría y piernas, que hoy sale bien.',
    ],
    VoiceEventType.activityPaused: [
      'Paramos un momento. Bebe y estira las piernas.',
      'Pausa. Aprovecha para comer algo.',
      'En pausa. Recupera, que luego seguimos.',
      'Alto breve. No te enfríes demasiado.',
    ],
    VoiceEventType.activityResumed: [
      'Volvemos a rodar. Retoma el ritmo poco a poco.',
      'Seguimos. Entra suave y ya subimos.',
      'De nuevo en carretera. Bien colocado.',
      'Reanudamos. Vamos a por lo que queda.',
    ],
    VoiceEventType.activityFinished: [
      'Cerramos por hoy. Buen trabajo ahí fuera.',
      'Actividad guardada. Has gestionado bien el esfuerzo.',
      'Fin de la jornada. A recuperar, mañana más.',
      'Listo. Ese es el trabajo que suma.',
    ],

    VoiceEventType.navigationStarted: [
      'Ruta cargada. Yo te canto los giros.',
      'Navegación activa. Sigue mis indicaciones.',
      'Tenemos recorrido. Vamos tramo a tramo.',
    ],
    VoiceEventType.navigationTurnLeft: [
      'A la izquierda.',
      'Giro a la izquierda, mantén el ritmo.',
      'Izquierda. Bien trazado.',
    ],
    VoiceEventType.navigationTurnRight: [
      'A la derecha.',
      'Giro a la derecha, mantén el ritmo.',
      'Derecha. Bien trazado.',
    ],
    VoiceEventType.navigationTurnSlightLeft: [
      'Abre ligeramente a la izquierda.',
      'Un poco a la izquierda, sin frenar.',
      'Suave a la izquierda.',
    ],
    VoiceEventType.navigationTurnSlightRight: [
      'Abre ligeramente a la derecha.',
      'Un poco a la derecha, sin frenar.',
      'Suave a la derecha.',
    ],
    VoiceEventType.navigationTurnSharpLeft: [
      'Curva cerrada a la izquierda, frena antes.',
      'Izquierda cerrada. Entra con cuidado.',
      'Giro fuerte a la izquierda, reduce.',
    ],
    VoiceEventType.navigationTurnSharpRight: [
      'Curva cerrada a la derecha, frena antes.',
      'Derecha cerrada. Entra con cuidado.',
      'Giro fuerte a la derecha, reduce.',
    ],
    VoiceEventType.navigationUTurn: [
      'Cambio de sentido cuando puedas.',
      'Da la vuelta, nos hemos pasado.',
      'Media vuelta y retomamos la ruta.',
    ],
    VoiceEventType.navigationArrived: [
      'Llegamos a meta. Bien hecho.',
      'Destino alcanzado. Buen recorrido.',
      'Fin de ruta. Trabajo completado.',
    ],
    VoiceEventType.segmentEntered: [
      'Empieza el segmento. A tope pero con cabeza.',
      'Entramos al segmento. Ritmo constante.',
      'Segmento en marcha. Ahora es el momento.',
    ],
    VoiceEventType.segmentCompleted: [
      'Segmento cerrado. Buen esfuerzo.',
      'Fin del segmento. Recupera y sigue.',
      'Completado. Has apretado bien ahí.',
    ],
    VoiceEventType.segmentPr: [
      'Mejor marca en el segmento. Excelente.',
      'Récord personal. Ese ritmo era muy bueno.',
      'Nuevo mejor tiempo. Así se hace.',
    ],
    VoiceEventType.segmentAbandoned: [
      'Fuera del segmento. Lo intentamos otro día.',
      'Segmento cancelado. Sigue rodando.',
      'Perdimos el trazado. No pasa nada, continúa.',
    ],
  },
};
