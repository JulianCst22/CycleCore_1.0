import '../domain/auth_session.dart';

/// Contrato de autenticación. La UI y los providers de Riverpod SOLO
/// conocen esta interfaz -- nunca la implementación concreta. Esto es
/// lo que permite reemplazar `LocalAuthRepository` por una versión que
/// hable HTTP con el backend Kotlin sin tocar ni una línea de UI.
abstract class AuthRepository {
  /// Sesión guardada localmente, si existe y sigue vigente. Null =
  /// modo invitado.
  Future<AuthSession?> currentSession();

  Future<AuthSession> register({
    required String email,
    required String password,
    String? displayName,
  });

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<void> logout();
}
