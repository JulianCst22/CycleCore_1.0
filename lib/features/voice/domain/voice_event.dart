/// Momentos de la grabación de actividad en los que la voz de guía
/// debe hablar. Se amplía fácilmente más adelante (por ejemplo,
/// marcadores de distancia o récords personales) sin tocar el resto
/// del módulo: basta con agregar el caso aquí y sus líneas en
/// [voice_line_bank.dart].
enum VoiceEventType {
  activityStarted,
  activityPaused,
  activityResumed,
  activityFinished,
}
