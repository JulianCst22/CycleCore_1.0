/// De dónde saca el motor las frases habladas para esta persona.
///
/// - [systemTts]: usa la voz nativa del teléfono (flutter_tts), con
///   tono/velocidad/idioma ajustados para que cada persona "suene"
///   distinta aunque sea el mismo motor de voz del sistema.
/// - [audioPack]: reproduce clips de audio pre-grabados guardados en
///   `assets/voice_packs/<id>/<evento>/0.mp3`, `1.mp3`, etc. Si un
///   archivo no existe, el motor cae automáticamente a TTS para ese
///   evento, así que puedes migrar personas de a poco.
enum VoiceSourceType { systemTts, audioPack }

class VoicePersona {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final VoiceSourceType source;

  /// Tono de la voz TTS. 1.0 es el tono normal del dispositivo.
  final double pitch;

  /// Velocidad de habla TTS (escala 0.0–1.0 en Android/iOS vía
  /// flutter_tts). 0.5 es aproximadamente el ritmo normal.
  final double rate;

  /// Locale preferido, ej. 'es-ES', 'es-MX', 'es-US'. Si el
  /// dispositivo no lo tiene instalado, flutter_tts usa el más
  /// parecido disponible.
  final String? preferredLocale;

  /// Nombre exacto de una voz del dispositivo (obtenido vía
  /// `FlutterTts.getVoices()`), opcional. Si no existe en el
  /// dispositivo del usuario, se ignora sin romper nada.
  final String? preferredVoiceName;

  const VoicePersona({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    this.source = VoiceSourceType.systemTts,
    this.pitch = 1.0,
    this.rate = 0.5,
    this.preferredLocale = 'es-ES',
    this.preferredVoiceName,
  });
}

/// Las 8 personalidades de voz disponibles, al estilo de las voces
/// de Waze. Todas parten en modo [VoiceSourceType.systemTts]; cuando
/// consigas audios pre-grabados para alguna, solo cambia su `source`
/// a [VoiceSourceType.audioPack] (ver README_VOZ.md).
const List<VoicePersona> kVoicePersonas = [
  VoicePersona(
    id: 'coach',
    name: 'Entrenador Motivador',
    description: 'Te empuja a dar el máximo en cada pedalada.',
    emoji: '💪',
    pitch: 1.05,
    rate: 0.52,
  ),
  VoicePersona(
    id: 'chill',
    name: 'Compa Relajado',
    description: 'Tranquilo, como pedalear con un amigo sin prisa.',
    emoji: '😎',
    pitch: 0.95,
    rate: 0.48,
  ),
  VoicePersona(
    id: 'sergeant',
    name: 'Sargento',
    description: 'Disciplina y órdenes directas, sin excusas.',
    emoji: '🎖️',
    pitch: 0.85,
    rate: 0.58,
  ),
  VoicePersona(
    id: 'pro',
    name: 'Profesional',
    description: 'Reportes claros y neutrales, como un copiloto técnico.',
    emoji: '📊',
    pitch: 1.0,
    rate: 0.5,
  ),
  VoicePersona(
    id: 'sarcastic',
    name: 'Copiloto Sarcástico',
    description: 'Humor filoso y comentarios pícaros en cada aviso.',
    emoji: '😏',
    pitch: 1.1,
    rate: 0.5,
  ),
  VoicePersona(
    id: 'zen',
    name: 'Modo Zen',
    description: 'Voz calmada, ideal para pedalear con plena consciencia.',
    emoji: '🧘',
    pitch: 0.9,
    rate: 0.42,
  ),
  VoicePersona(
    id: 'hype',
    name: 'Fan a Tope',
    description: 'Como un comentarista deportivo, siempre a mil.',
    emoji: '📣',
    pitch: 1.2,
    rate: 0.6,
  ),
  VoicePersona(
    id: 'grandma',
    name: 'Abuela Cariñosa',
    description: 'Cariñosa y protectora, preocupada por tu bienestar.',
    emoji: '🧶',
    pitch: 1.15,
    rate: 0.46,
  ),
];
