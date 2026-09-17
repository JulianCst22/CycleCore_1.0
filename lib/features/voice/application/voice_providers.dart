import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../gamification/gamification.dart';
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

final voiceSettingsRepositoryProvider = Provider<VoiceSettingsRepository>((
  ref,
) {
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
    // `orElse` cubre la migración: un id guardado que ya no existe
    // (sargento / sarcástico / abuela, retiradas) cae a la voz estándar.
    final persona = kVoicePersonas.firstWhere(
      (p) => p.id == savedId,
      orElse: () => kVoicePersonas.first,
    );
    state = VoiceSettingsState(persona: persona, enabled: savedEnabled);
    await _engine.setPersona(persona);
  }

  /// El usuario eligió una nueva voz permanente. La UI sólo llama esto
  /// con voces disponibles; si aun así llega una bloqueada, se ignora.
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

/// Estado de una voz para este usuario ahora mismo.
enum VoicePersonaStatus {
  /// Es la voz seleccionada.
  activa,

  /// Disponible: se puede activar con un toque.
  disponible,

  /// Todavía bloqueada: falta cumplir [VoicePersona.unlock].
  bloqueada,
}

class VoiceRosterEntry {
  final VoicePersona persona;
  final VoicePersonaStatus status;

  const VoiceRosterEntry(this.persona, this.status);

  bool get isLocked => status == VoicePersonaStatus.bloqueada;
  bool get isActive => status == VoicePersonaStatus.activa;
}

/// La lista de voces con su estado real: cuál está activa, cuáles se
/// pueden usar y cuáles siguen bloqueadas. Cruza [kVoicePersonas] con el
/// contexto de logros del vestidor ([kitUnlockContextProvider]).
final voiceRosterProvider = Provider<List<VoiceRosterEntry>>((ref) {
  final selectedId = ref.watch(voiceSettingsProvider).persona.id;
  final ctx = ref.watch(kitUnlockContextProvider);
  return [
    for (final persona in kVoicePersonas)
      VoiceRosterEntry(
        persona,
        _statusFor(persona, ctx: ctx, selectedId: selectedId),
      ),
  ];
});

/// Si el usuario ya tiene desbloqueada esa voz (las gratis siempre lo
/// están; las de logro dependen del contexto).
bool isVoicePersonaUnlocked(VoicePersona persona, KitUnlockContext? ctx) {
  if (persona.tier == VoiceTier.gratis) return true;
  final condition = persona.unlock;
  if (condition == null) return true;
  if (ctx == null) return false;
  return isKitConditionMet(condition, ctx);
}

VoicePersonaStatus _statusFor(
  VoicePersona persona, {
  required KitUnlockContext? ctx,
  required String selectedId,
}) {
  if (!isVoicePersonaUnlocked(persona, ctx)) {
    return VoicePersonaStatus.bloqueada;
  }
  if (persona.id == selectedId) return VoicePersonaStatus.activa;
  return VoicePersonaStatus.disponible;
}

/// Ids de todas las voces desbloqueadas ahora mismo (las gratis siempre).
final unlockedVoicePersonaIdsProvider = Provider<Set<String>>((ref) {
  final ctx = ref.watch(kitUnlockContextProvider);
  return {
    for (final persona in kVoicePersonas)
      if (isVoicePersonaUnlocked(persona, ctx)) persona.id,
  };
});

/// Qué voces desbloqueadas ya se le "mostraron" al usuario -- para no
/// repetir el festejo de "¡Desbloqueaste una voz!". Mismo patrón que
/// `kitUnlocksSeenProvider`.
class VoiceUnlocksSeenNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  VoiceUnlocksSeenNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  final VoiceSettingsRepository _repo;
  bool _hadStored = false;

  Future<void> _load() async {
    try {
      final stored = await _repo.loadSeenUnlocks();
      _hadStored = stored != null;
      state = AsyncValue.data(stored ?? <String>{});
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Registra [currentlyUnlocked] como "visto" y devuelve los ids que
  /// eran NUEVOS. La primera vez (sin nada guardado) sólo inicializa:
  /// devuelve vacío, para no festejar el backlog de golpe.
  Future<Set<String>> reconcile(Set<String> currentlyUnlocked) async {
    final seen = state.valueOrNull ?? <String>{};
    final newOnes = _hadStored
        ? currentlyUnlocked.difference(seen)
        : const <String>{};
    _hadStored = true;
    final updated = {...seen, ...currentlyUnlocked};
    state = AsyncValue.data(updated);
    try {
      await _repo.saveSeenUnlocks(updated);
    } catch (_) {
      // El estado en memoria ya se actualizó; no rompemos la UX por un
      // fallo de escritura puntual (mismo criterio que el resto).
    }
    return newOnes;
  }
}

final voiceUnlocksSeenProvider =
    StateNotifierProvider<VoiceUnlocksSeenNotifier, AsyncValue<Set<String>>>(
      (ref) =>
          VoiceUnlocksSeenNotifier(ref.watch(voiceSettingsRepositoryProvider)),
    );

/// Voces desbloqueadas que el usuario aún no ha "visto" -- para el
/// puntito de aviso en la pestaña "Voz".
final unseenVoiceUnlocksProvider = Provider<Set<String>>((ref) {
  final unlocked = ref.watch(unlockedVoicePersonaIdsProvider);
  final seen =
      ref.watch(voiceUnlocksSeenProvider).valueOrNull ?? const <String>{};
  return unlocked.difference(seen);
});
