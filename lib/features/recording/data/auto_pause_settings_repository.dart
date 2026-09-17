import 'package:shared_preferences/shared_preferences.dart';

/// Persiste si la pausa automática está encendida. Viene encendida por
/// defecto: quien no la quiera la apaga en Ajustes › En la salida.
class AutoPauseSettingsRepository {
  static const _key = 'auto_pause_enabled';

  Future<bool> loadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  Future<void> saveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}
