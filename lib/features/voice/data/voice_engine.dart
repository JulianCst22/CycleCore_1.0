import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

import '../domain/voice_event.dart';
import '../domain/voice_line_bank.dart';
import '../domain/voice_persona.dart';

/// Cuánto esperamos como máximo cualquier llamada al plugin de TTS
/// antes de darla por perdida. Sin esto, si el motor de voz del
/// teléfono se cuelga (p.ej. porque el paquete de idioma español no
/// está bien instalado), el `await` se queda esperando para siempre
/// y Android termina mostrando "la app no responde".
const _kTtsCallTimeout = Duration(seconds: 6);

/// Qué tan importante es lo que se va a decir. Lo que suena no se pisa
/// con algo menos importante: un consejo del coach espera a que termine
/// un giro de navegación, y un aviso urgente sí corta lo que esté
/// sonando.
enum VoicePriority {
  /// Comentarios de acompañamiento (seguimientos del coach).
  ambiente,

  /// Eventos normales: actividad, segmentos, consejos del coach.
  normal,

  /// No puede esperar: giros de navegación y avisos urgentes.
  urgente,
}

/// Motor de voz. Decide, para cada evento, si habla con el TTS del
/// sistema o si reproduce un audio pre-grabado — y si el audio no
/// existe todavía, cae automáticamente a TTS sin que se note un
/// error. Así puedes ir agregando audios pre-grabados persona por
/// persona sin romper nada mientras tanto.
class VoiceEngine {
  VoiceEngine();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();

  VoicePersona _current = kVoicePersonas.first;
  bool _initialized = false;

  /// Prioridad de lo que se está diciendo ahora; `null` si hay silencio.
  VoicePriority? _speaking;

  /// Voces reales del dispositivo en español, obtenidas una sola vez
  /// al iniciar. Se usa para repartir voces distintas entre
  /// personas en vez de que todas terminen sonando igual con la
  /// única voz por defecto del sistema.
  List<Map<String, String>> _availableSpanishVoices = [];

  /// Asignación automática persona → voz real del dispositivo,
  /// calculada en `_autoAssignVoices()`. Solo se usa cuando la
  /// persona no trae `preferredVoiceName` fijo desde código.
  final Map<String, Map<String, String>> _autoVoiceAssignments = {};

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _safeCall(() => _tts.awaitSpeakCompletion(true));
    await _loadAvailableVoices();
    _autoAssignVoices();
    await _applyPersonaTtsConfig(_current);
  }

  VoicePersona get currentPersona => _current;

  /// Ejecuta una llamada al plugin con timeout, para que nunca
  /// vuelva a trabar la UI si el motor TTS del sistema no responde.
  Future<T?> _safeCall<T>(
    Future<T> Function() call, {
    Duration timeout = _kTtsCallTimeout,
  }) async {
    try {
      return await call().timeout(timeout);
    } on TimeoutException {
      // El motor TTS del sistema no respondió a tiempo. Preferimos
      // seguir sin esa configuración/voz antes que congelar la app.
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Lee del dispositivo qué voces en español hay realmente
  /// instaladas (nombre + locale). Si el teléfono solo tiene una
  /// voz instalada para español, esta lista tendrá un solo elemento
  /// y no hay nada que el código pueda hacer para "inventar" más
  /// variedad — hace falta instalar más voces desde los ajustes del
  /// sistema (Ajustes > Accesibilidad > Conversión de texto a voz >
  /// motor de Google > Instalar datos de voz).
  Future<void> _loadAvailableVoices() async {
    final raw = await _safeCall(() => _tts.getVoices);
    if (raw is! List) return;

    final spanish = <Map<String, String>>[];
    for (final entry in raw) {
      if (entry is Map) {
        final name = entry['name']?.toString();
        final locale = entry['locale']?.toString();
        if (name == null || locale == null) continue;
        if (locale.toLowerCase().startsWith('es')) {
          spanish.add({'name': name, 'locale': locale});
        }
      }
    }
    _availableSpanishVoices = spanish;
  }

  /// Reparte las voces en español realmente disponibles en el
  /// dispositivo entre las 8 personas, en orden rotativo, para que
  /// no todas terminen usando la misma voz por defecto del sistema.
  /// Si una persona ya trae `preferredVoiceName` fijado en
  /// `voice_persona.dart`, esa asignación manual tiene prioridad y
  /// no se toca acá.
  void _autoAssignVoices() {
    if (_availableSpanishVoices.isEmpty) return;
    var index = 0;
    for (final persona in kVoicePersonas) {
      if (persona.preferredVoiceName != null) continue;
      final voice =
          _availableSpanishVoices[index % _availableSpanishVoices.length];
      _autoVoiceAssignments[persona.id] = voice;
      index++;
    }
  }

  /// Cambia la voz que se usará en los eventos reales de grabación
  /// (iniciar / pausar / reanudar / finalizar actividad).
  Future<void> setPersona(VoicePersona persona) async {
    _current = persona;
    await _applyPersonaTtsConfig(persona);
  }

  Future<void> _applyPersonaTtsConfig(VoicePersona persona) async {
    await _safeCall(() => _tts.setLanguage(persona.preferredLocale ?? 'es-ES'));
    await _safeCall(() => _tts.setPitch(persona.pitch));
    await _safeCall(() => _tts.setSpeechRate(persona.rate));

    final voice = persona.preferredVoiceName != null
        ? {
            'name': persona.preferredVoiceName!,
            'locale': persona.preferredLocale ?? 'es-ES',
          }
        : _autoVoiceAssignments[persona.id];

    if (voice != null) {
      await _safeCall(() => _tts.setVoice(voice));
    }
  }

  String? _randomLine(String personaId, VoiceEventType event) {
    final lines = kVoiceLineBank[personaId]?[event];
    if (lines == null || lines.isEmpty) return null;
    return lines[_random.nextInt(lines.length)];
  }

  /// Habla un evento real de grabación con la voz seleccionada
  /// actualmente (llamar esto desde donde inicias/pausas/reanudas/
  /// terminas la actividad).
  Future<void> speakEvent(VoiceEventType event) async {
    await init();
    final phrase = _randomLine(_current.id, event);
    if (phrase == null) return;

    if (_current.source == VoiceSourceType.audioPack) {
      final played = await _tryPlayAudioPack(_current.id, event);
      if (played) return;
      // No había audio disponible para este evento: seguimos con TTS.
    }
    await _safeCall(() => _tts.stop());
    await _safeCall(() => _tts.speak(phrase));
  }

  /// Dice un texto armado en el momento (los consejos del coach, que no
  /// son frases fijas del banco de eventos).
  ///
  /// [priority] decide si puede pisar lo que esté sonando. Con
  /// [chime] suena antes un toque corto, si el audio existe
  /// (`assets/voice_packs/chimes/<nombre>.mp3`): sirve para que el
  /// ciclista sepa que viene una indicación sin tener que entenderla
  /// toda.
  Future<void> speakText(
    String text, {
    VoicePriority priority = VoicePriority.normal,
    String? chime,
  }) async {
    if (text.trim().isEmpty) return;
    await init();
    final current = _speaking;
    if (current != null && current.index >= priority.index) return;
    _speaking = priority;
    try {
      if (chime != null) await _tryPlayChime(chime);
      await _safeCall(() => _tts.stop());
      // Con `awaitSpeakCompletion` el `speak` termina cuando termina la
      // frase, y un momento clave dura hasta ~15 s: con el tope general
      // de 6 s se daba por terminada a la mitad y cualquier otro aviso
      // la cortaba. El tope crece con el largo de la frase.
      await _safeCall(() => _tts.speak(text), timeout: _speakTimeoutFor(text));
    } finally {
      if (_speaking == priority) _speaking = null;
    }
  }

  /// Cuánto puede tardar en decirse [text]: unas 2,5 palabras por
  /// segundo a velocidad normal, con margen.
  static Duration _speakTimeoutFor(String text) {
    final words = text.trim().split(RegExp(r'\s+')).length;
    return Duration(seconds: (4 + words ~/ 2).clamp(6, 40));
  }

  /// Prioridad de lo que está sonando ahora, si algo suena.
  VoicePriority? get speakingPriority => _speaking;

  Future<bool> _tryPlayChime(String name) async {
    const path = 'assets/voice_packs/chimes/';
    try {
      await rootBundle.load('$path$name.mp3');
    } catch (_) {
      return false; // todavía no hay toques grabados: se habla y ya.
    }
    await _player.stop();
    await _player.play(AssetSource('voice_packs/chimes/$name.mp3'));
    return true;
  }

  /// Reproduce una muestra de [persona] sin cambiar la voz
  /// seleccionada de forma permanente. Pensado para el botón
  /// "Probar voz" en la pantalla de selección.
  Future<void> speakSample(VoicePersona persona, VoiceEventType event) async {
    await init();
    final phrase = _randomLine(persona.id, event);
    if (phrase == null) return;

    if (persona.source == VoiceSourceType.audioPack) {
      final played = await _tryPlayAudioPack(persona.id, event);
      if (played) return;
    }
    await _applyPersonaTtsConfig(persona);
    await _safeCall(() => _tts.stop());
    await _safeCall(() => _tts.speak(phrase));
    // Restauramos la configuración de la voz realmente seleccionada.
    await _applyPersonaTtsConfig(_current);
  }

  /// Busca un audio pre-grabado en
  /// `assets/voice_packs/<personaId>/<evento>/0.mp3`, `1.mp3`, etc.
  /// y reproduce uno al azar. Devuelve `false` si no encuentra
  /// ninguno, para que quien llama use TTS como respaldo.
  Future<bool> _tryPlayAudioPack(String personaId, VoiceEventType event) async {
    final folder = _eventFolder(event);
    final candidates = List.generate(
      5,
      (i) => 'assets/voice_packs/$personaId/$folder/$i.mp3',
    )..shuffle(_random);

    for (final path in candidates) {
      try {
        await rootBundle.load(path);
      } catch (_) {
        continue; // ese archivo no existe todavía, probamos el siguiente
      }
      await _player.stop();
      await _player.play(AssetSource(path.replaceFirst('assets/', '')));
      return true;
    }
    return false;
  }

  /// Nombre de carpeta de audio para cada evento -- los 4 originales
  /// (actividad) más los 8 nuevos (navegación). Si agregás otro
  /// VoiceEventType en el futuro, el compilador te va a obligar a
  /// agregarlo también acá (switch exhaustivo, sin `default`).
  String _eventFolder(VoiceEventType event) {
    switch (event) {
      case VoiceEventType.activityStarted:
        return 'start';
      case VoiceEventType.activityPaused:
        return 'paused';
      case VoiceEventType.activityResumed:
        return 'resumed';
      case VoiceEventType.activityFinished:
        return 'finished';
      case VoiceEventType.navigationStarted:
        return 'nav_started';
      case VoiceEventType.navigationTurnLeft:
        return 'turn_left';
      case VoiceEventType.navigationTurnRight:
        return 'turn_right';
      case VoiceEventType.navigationTurnSlightLeft:
        return 'turn_slight_left';
      case VoiceEventType.navigationTurnSlightRight:
        return 'turn_slight_right';
      case VoiceEventType.navigationTurnSharpLeft:
        return 'turn_sharp_left';
      case VoiceEventType.navigationTurnSharpRight:
        return 'turn_sharp_right';
      case VoiceEventType.navigationUTurn:
        return 'u_turn';
      case VoiceEventType.navigationArrived:
        return 'arrived';
      case VoiceEventType.segmentEntered:
        return 'segment_entered';
      case VoiceEventType.segmentCompleted:
        return 'segment_completed';
      case VoiceEventType.segmentPr:
        return 'segment_pr';
      case VoiceEventType.segmentAbandoned:
        return 'segment_abandoned';
    }
  }

  Future<void> stop() async {
    await _safeCall(() => _tts.stop());
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
