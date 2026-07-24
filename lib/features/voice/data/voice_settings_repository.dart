import 'package:shared_preferences/shared_preferences.dart';

/// Guarda qué persona de voz eligió el usuario y si la voz está
/// activada, usando shared_preferences (ya está en el proyecto).
class VoiceSettingsRepository {
  static const _personaKey = 'voice_persona_id';
  static const _enabledKey = 'voice_enabled';

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
}
