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

  Future<AuthSession> login({required String email, required String password});

  /// `true` si ya hay una cuenta con ese correo. Para validar el paso de
  /// registro antes de pedir el resto de los datos.
  Future<bool> emailTaken(String email);

  /// Cambia la contraseña de la cuenta [email]. Verifica primero
  /// [currentPassword] (lanza `WrongCurrentPasswordException` si no
  /// coincide) y exige que [newPassword] tenga al menos 6 caracteres.
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();
}
