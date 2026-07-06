import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cyclist_profile.dart';

/// Persistencia simple del perfil del ciclista en disco local.
///
/// Usa SharedPreferences porque es un único objeto pequeño que se lee una
/// vez al arrancar la app; no justifica Drift/SQLite (eso se reserva para
/// rutas, segmentos y sesiones históricas).
class ProfileRepository {
  static const _key = 'cyclist_profile';

  Future<CyclistProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return CyclistProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(CyclistProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
