import 'package:shared_preferences/shared_preferences.dart';

/// Guarda qué persona de voz eligió el usuario, si la voz está activada,
/// y qué voces desbloqueadas ya se le han festejado (para no repetir el
/// overlay de "¡Desbloqueaste una voz!"). Todo en shared_preferences.
class VoiceSettingsRepository {
  static const _personaKey = 'voice_persona_id';
  static const _enabledKey = 'voice_enabled';
  static const _seenUnlocksKey = 'voice_unlocks_seen_v1';

  Future<String?> getPersonaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_personaKey);
  }

  Future<void> savePersonaId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personaKey, id);
  }

  Future<bool> getEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Por defecto la voz viene activada.
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> saveEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  /// `null` = nunca se ha guardado (primera vez): quien llama debe
  /// inicializar sin festejar todo el backlog de voces ya desbloqueadas.
  Future<Set<String>?> loadSeenUnlocks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_seenUnlocksKey)?.toSet();
  }

  Future<void> saveSeenUnlocks(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_seenUnlocksKey, ids.toList());
  }
}
