import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/local/local_auth_repository.dart';
import '../domain/auth_exceptions.dart';
import '../domain/auth_session.dart';

/// Único punto de decisión de qué implementación usar. Cuando exista el
/// backend Kotlin, este es el ÚNICO lugar que cambia en todo el módulo:
/// `LocalAuthRepository()` -> `RemoteAuthRepository(dio: ...)`.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository();
});

/// Estado async de la sesión: null = modo invitado (no es un error).
/// Mismo patrón que `ProfileNotifier` en profile_providers.dart.
class AuthNotifier extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    return ref.read(authRepositoryProvider).currentSession();
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .register(email: email, password: password, displayName: displayName),
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .login(email: email, password: password),
    );
  }

  /// `true` si ya hay una cuenta con ese correo -- para validar el paso
  /// de registro antes de pedir el resto de los datos. No toca `state`.
  Future<bool> emailTaken(String email) =>
      ref.read(authRepositoryProvider).emailTaken(email);

  /// Cambia la contraseña de la sesión activa. Propaga
  /// `WrongCurrentPasswordException` / `WeakPasswordException`. No toca
  /// `state` (la sesión sigue siendo válida).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final session = state.valueOrNull;
    if (session == null) throw const SessionExpiredException();
    await ref
        .read(authRepositoryProvider)
        .changePassword(
          email: session.email,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthSession?>(
  AuthNotifier.new,
);

/// true mientras no haya sesión vinculada -- usado por la UI para
/// decidir si mostrar "Crear cuenta" o el email de la cuenta activa.
/// Nunca se usa para bloquear navegación: el gate real de la app es el
/// perfil local (ver core/navigation/app_gate.dart), no la sesión.
final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull == null;
});
