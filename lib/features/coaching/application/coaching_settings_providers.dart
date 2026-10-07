import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/coaching_settings_repository.dart';
import '../domain/coaching_preferences.dart';
import '../domain/variables/labels.dart';

final coachingSettingsRepositoryProvider = Provider<CoachingSettingsRepository>(
  (ref) => CoachingSettingsRepository(),
);

/// Ajustes del coach. Se leen de disco al arrancar; mientras tanto valen
/// los de fábrica (habla, con todo el detalle).
class CoachingPreferencesNotifier extends StateNotifier<CoachingPreferences> {
  CoachingPreferencesNotifier(this._repository)
    : super(const CoachingPreferences()) {
    _load();
  }

  final CoachingSettingsRepository _repository;

  /// El usuario ya cambió algo: lo que llegue del disco no lo pisa.
  bool _touched = false;

  Future<void> _load() async {
    final saved = await _repository.load();
    if (_touched) return;
    state = saved;
  }

  Future<void> setEnabled(bool enabled) async {
    _touched = true;
    state = state.copyWith(enabled: enabled);
    await _repository.saveEnabled(enabled);
  }

  Future<void> setDetail(CoachingDetail detail) async {
    _touched = true;
    state = state.copyWith(detail: detail);
    await _repository.saveDetail(detail);
  }

  Future<void> setPace(CoachingPace pace) async {
    _touched = true;
    state = state.copyWith(pace: pace);
    await _repository.savePace(pace);
  }

  Future<void> setGoal(Goal goal) async {
    _touched = true;
    state = state.copyWith(goal: goal);
    await _repository.saveGoal(goal);
  }

  Future<void> setAskBeforeRide(bool ask) async {
    _touched = true;
    state = state.copyWith(askBeforeRide: ask);
    await _repository.saveAskBeforeRide(ask);
  }
}

final coachingPreferencesProvider =
    StateNotifierProvider<CoachingPreferencesNotifier, CoachingPreferences>(
      (ref) => CoachingPreferencesNotifier(
        ref.watch(coachingSettingsRepositoryProvider),
      ),
    );
