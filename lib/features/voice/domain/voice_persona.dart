import '../../profile/domain/cyclist_kit.dart'
    show KitUnlockCondition, KitUnlockKind;
import '../../profile/domain/level_info.dart' show CyclistRank;

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

/// En qué "estante" del Vestidor aparece una voz.
enum VoiceTier {
  /// Disponible desde el primer día.
  gratis,

  /// Se gana cumpliendo un logro de ciclismo ([VoicePersona.unlock]).
  desbloqueable,
}

class VoicePersona {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final VoiceSourceType source;

  /// En qué estante del Vestidor va.
  final VoiceTier tier;

  /// Cómo se gana, si [tier] es [VoiceTier.desbloqueable]. `null` en las
  /// gratis. Reusa la misma condición que las piezas del vestidor, así
  /// que el texto ("Corona el rango Rodador") y la evaluación salen
  /// gratis de `kit_unlocks.dart`.
  final KitUnlockCondition? unlock;

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
    this.tier = VoiceTier.gratis,
    this.unlock,
    this.pitch = 1.0,
    this.rate = 0.5,
    this.preferredLocale = 'es-ES',
    this.preferredVoiceName,
  });
}

/// Las 5 voces de guía. Todas parten en modo [VoiceSourceType.systemTts]
/// (voz del sistema, con tono/ritmo propios); cuando consigas audios
/// pre-grabados para alguna, solo cambia su `source` a
/// [VoiceSourceType.audioPack] (ver README_VOZ.md). Los `id` son
/// estables: se guardan en `SharedPreferences` y son el nombre de la
/// carpeta de audios.
const List<VoicePersona> kVoicePersonas = [
  VoicePersona(
    id: 'pro',
    name: 'Estándar',
    description: 'Indicaciones claras y neutrales, como un copiloto técnico.',
    emoji: '🧭',
    pitch: 1.0,
    rate: 0.5,
  ),
  VoicePersona(
    id: 'chill',
    name: 'Compañero',
    description: 'Cercano y tranquilo, como salir a rodar con un amigo.',
    emoji: '🚴',
    pitch: 0.97,
    rate: 0.48,
  ),
  VoicePersona(
    id: 'coach',
    name: 'Entrenador',
    description: 'Te motiva y te marca el esfuerzo, como un preparador.',
    emoji: '💪',
    tier: VoiceTier.desbloqueable,
    unlock: KitUnlockCondition(
      KitUnlockKind.rankCompleted,
      rank: CyclistRank.rodador,
    ),
    pitch: 1.03,
    rate: 0.52,
  ),
  VoicePersona(
    id: 'hype',
    name: 'Director deportivo',
    description: 'Estilo radio de carrera y coche de equipo, con energía.',
    emoji: '📻',
    tier: VoiceTier.desbloqueable,
    unlock: KitUnlockCondition(KitUnlockKind.rideSpeedKmh, value: 30),
    pitch: 1.08,
    rate: 0.55,
  ),
  VoicePersona(
    id: 'zen',
    name: 'Ritmo suave',
    description: 'Voz calmada para rodar en fondo o en recuperación.',
    emoji: '🧘',
    tier: VoiceTier.desbloqueable,
    unlock: KitUnlockCondition(KitUnlockKind.totalElevation, value: 3000),
    pitch: 0.93,
    rate: 0.44,
  ),
];

/// Voz "premium" todavía no disponible: sólo pinta el estante en el
/// Vestidor para dejar claro que ahí irán voces de pago / de artista.
/// Cuando se implemente (Fase D: audio grabado en estudio o packs de
/// artista) pasará a ser una [VoicePersona] normal con `source`
/// [VoiceSourceType.audioPack].
class UpcomingVoice {
  final String name;
  final String tagline;
  final String emoji;

  const UpcomingVoice({
    required this.name,
    required this.tagline,
    required this.emoji,
  });
}

/// Busca una voz por su id. `null` si no existe (p.ej. un id guardado de
/// una versión anterior).
VoicePersona? voicePersonaById(String id) {
  for (final persona in kVoicePersonas) {
    if (persona.id == id) return persona;
  }
  return null;
}

const List<UpcomingVoice> kUpcomingVoices = [
  UpcomingVoice(
    name: 'Voces de artista',
    tagline: 'Grabadas por voces reales. Próximamente.',
    emoji: '🎤',
  ),
  UpcomingVoice(
    name: 'Pack narrador pro',
    tagline: 'Relato de carrera de estudio. Próximamente.',
    emoji: '🏆',
  ),
];
