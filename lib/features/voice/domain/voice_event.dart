/// Momentos de la grabación de actividad en los que la voz de guía
/// debe hablar. Se amplía fácilmente más adelante (por ejemplo,
/// marcadores de distancia o récords personales) sin tocar el resto
/// del módulo: basta con agregar el caso aquí y sus líneas en
/// [voice_line_bank.dart].
///
/// Los valores `navigation*` son nuevos (módulo de Navegación /
/// "Waze"): cada uno tiene una frase FIJA por diseño (igual que el
/// resto del enum) -- no llevan la distancia dentro del texto hablado
/// ("gira a la derecha", sin "en 200 metros"), porque `speak()` no
/// acepta texto dinámico. La distancia sí se ve en el banner visual
/// (`TurnInstructionBanner`), que se actualiza en tiempo real.
enum VoiceEventType {
  activityStarted,
  activityPaused,
  activityResumed,
  activityFinished,

  // --- Navegación ---
  navigationStarted,
  navigationTurnLeft,
  navigationTurnRight,
  navigationTurnSlightLeft,
  navigationTurnSlightRight,
  navigationTurnSharpLeft,
  navigationTurnSharpRight,
  navigationUTurn,
  navigationArrived,

  // --- Segmentos en vivo (Fase C). Frase FIJA por diseño, igual que
  // el resto del enum: los números ("vas +12 s") van en la pantalla
  // del segmento, no en la voz. ---
  segmentEntered,
  segmentCompleted,

  /// Se completó y además es nueva mejor marca personal.
  segmentPr,

  /// Se salió del trazado o fue en contravía antes de terminar.
  segmentAbandoned,
}
