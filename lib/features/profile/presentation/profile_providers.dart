import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import '../domain/cyclist_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Estado async del perfil: null significa "no hay perfil guardado todavía"
/// (dispara el onboarding), no un error.
class ProfileNotifier extends AsyncNotifier<CyclistProfile?> {
  @override
  Future<CyclistProfile?> build() async {
    return ref.read(profileRepositoryProvider).loadProfile();
  }

  Future<void> saveProfile(CyclistProfile profile) async {
    await ref.read(profileRepositoryProvider).saveProfile(profile);
    state = AsyncValue.data(profile);
  }

  Future<void> clearProfile() async {
    await ref.read(profileRepositoryProvider).clearProfile();
    state = const AsyncValue.data(null);
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, CyclistProfile?>(
  ProfileNotifier.new,
);
