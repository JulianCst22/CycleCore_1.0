import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/voice_engine.dart';
import '../data/voice_settings_repository.dart';
import '../domain/voice_event.dart';
import '../domain/voice_persona.dart';

final voiceEngineProvider = Provider<VoiceEngine>((ref) {
  final engine = VoiceEngine();
  engine.init();
  ref.onDispose(engine.dispose);
  return engine;
});

final voiceSettingsRepositoryProvider = Provider<VoiceSettingsRepository>((ref) {
  return VoiceSettingsRepository();
});

class VoiceSettingsState {
  final VoicePersona persona;
  final bool enabled;

  const VoiceSettingsState({required this.persona, required this.enabled});

  VoiceSettingsState copyWith({VoicePersona? persona, bool? enabled}) {
    return VoiceSettingsState(
      persona: persona ?? this.persona,
      enabled: enabled ?? this.enabled,
    );
  }
}

class VoiceSettingsNotifier extends StateNotifier<VoiceSettingsState> {
  VoiceSettingsNotifier(this._repo, this._engine)
      : super(VoiceSettingsState(persona: kVoicePersonas.first, enabled: true)) {
    _load();
  }

  final VoiceSettingsRepository _repo;
  final VoiceEngine _engine;

  Future<void> _load() async {
    final savedId = await _repo.getPersonaId();
    final savedEnabled = await _repo.getEnabled();
    final persona = kVoicePersonas.firstWhere(
      (p) => p.id == savedId,
      orElse: () => kVoicePersonas.first,
    );
    state = VoiceSettingsState(persona: persona, enabled: savedEnabled);
    await _engine.setPersona(persona);
  }

  /// El usuario eligió una nueva voz permanente en la pantalla de
  /// selección.
  Future<void> selectPersona(VoicePersona persona) async {
    state = state.copyWith(persona: persona);
    await _repo.savePersonaId(persona.id);
    await _engine.setPersona(persona);
  }

  /// Prende/apaga la voz de guía por completo.
  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await _repo.saveEnabled(value);
  }

  /// Llamar esto desde donde se inicia/pausa/reanuda/termina la
  /// grabación de actividad. No hace nada si la voz está apagada.
  Future<void> speak(VoiceEventType event) async {
    if (!state.enabled) return;
    await _engine.speakEvent(event);
  }

  /// Reproduce una muestra de [persona] sin cambiar la selección
  /// actual — para el botón "Probar voz".
  Future<void> previewPersona(VoicePersona persona) async {
    await _engine.speakSample(persona, VoiceEventType.activityStarted);
  }
}

final voiceSettingsProvider =
    StateNotifierProvider<VoiceSettingsNotifier, VoiceSettingsState>((ref) {
  final repo = ref.watch(voiceSettingsRepositoryProvider);
  final engine = ref.watch(voiceEngineProvider);
  return VoiceSettingsNotifier(repo, engine);
});
