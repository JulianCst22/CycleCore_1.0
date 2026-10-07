import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cadence_source.dart';

/// Recuerda de qué sensor quiere el ciclista la cadencia. Sin nada
/// guardado manda la prioridad automática (ver `CadenceSource`).
class CadenceSourceRepository {
  static const _prefsKey = 'cadence_source_v1';

  Future<CadenceSource?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return CadenceSourceInfo.byName(prefs.getString(_prefsKey));
  }

  Future<void> save(CadenceSource? source) async {
    final prefs = await SharedPreferences.getInstance();
    if (source == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, source.name);
    }
  }
}
