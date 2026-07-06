import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/training_zones.dart';

/// Persistencia de las zonas de entrenamiento, separada del perfil porque
/// el usuario puede editarlas manualmente y queremos respetar esa
/// personalización aunque luego actualice peso/FTP/FC en su perfil.
class ZonesRepository {
  static const _key = 'training_zones';

  Future<TrainingZones?> loadZones() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return TrainingZones.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveZones(TrainingZones zones) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(zones.toJson()));
  }

  Future<void> clearZones() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
