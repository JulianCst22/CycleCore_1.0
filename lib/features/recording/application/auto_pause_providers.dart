import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auto_pause_settings_repository.dart';

final autoPauseSettingsRepositoryProvider =
    Provider<AutoPauseSettingsRepository>((ref) {
      return AutoPauseSettingsRepository();
    });

class AutoPauseEnabledNotifier extends StateNotifier<bool> {
  AutoPauseEnabledNotifier(this._repo) : super(true) {
    _load();
  }

  final AutoPauseSettingsRepository _repo;

  Future<void> _load() async {
    final enabled = await _repo.loadEnabled();
    if (mounted) state = enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _repo.saveEnabled(enabled);
  }
}

/// Si la actividad se pausa sola al detenerse (ver `AutoPauseDetector`).
/// Lo consulta `RouteRecordingController` en cada revisión, así que
/// apagarlo a mitad de una salida surte efecto de inmediato.
final autoPauseEnabledProvider =
    StateNotifierProvider<AutoPauseEnabledNotifier, bool>((ref) {
      return AutoPauseEnabledNotifier(
        ref.watch(autoPauseSettingsRepositoryProvider),
      );
    });
