import 'package:shared_preferences/shared_preferences.dart';

import '../domain/coaching_preferences.dart';
import '../domain/variables/labels.dart';

/// Guarda lo que el ciclista elige del coach: si habla y cuánto.
class CoachingSettingsRepository {
  static const _enabledKey = 'coaching_enabled';
  static const _detailKey = 'coaching_detail';
  static const _paceKey = 'coaching_pace';
  static const _goalKey = 'coaching_goal';
  static const _askBeforeRideKey = 'coaching_ask_before_ride';

  Future<CoachingPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return CoachingPreferences(
      enabled: prefs.getBool(_enabledKey) ?? true,
      detail: CoachingDetail.byName(prefs.getString(_detailKey)),
      pace: CoachingPace.byName(prefs.getString(_paceKey)),
      goal: Goal.byName(prefs.getString(_goalKey)),
      askBeforeRide: prefs.getBool(_askBeforeRideKey) ?? true,
    );
  }

  Future<void> saveAskBeforeRide(bool ask) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askBeforeRideKey, ask);
  }

  Future<void> saveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<void> saveDetail(CoachingDetail detail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_detailKey, detail.name);
  }

  Future<void> savePace(CoachingPace pace) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paceKey, pace.name);
  }

  Future<void> saveGoal(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalKey, goal.name);
  }
}
