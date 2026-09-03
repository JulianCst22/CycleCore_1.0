/// Errores de dominio del módulo de autenticación. Se lanzan desde
/// cualquier implementación de `AuthRepository` (local o remota) para
/// que la UI pueda mostrar mensajes específicos sin acoplarse a los
/// detalles de la implementación concreta.
sealed class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
    : super('Correo o contraseña incorrectos.');
}

class EmailAlreadyRegisteredException extends AuthException {
  const EmailAlreadyRegisteredException()
    : super('Ya existe una cuenta con este correo en este dispositivo.');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException()
    : super('La contraseña debe tener al menos 6 caracteres.');
}

class WrongCurrentPasswordException extends AuthException {
  const WrongCurrentPasswordException()
    : super('La contraseña actual no es correcta.');
}

class SessionExpiredException extends AuthException {
  const SessionExpiredException()
    : super('Tu sesión expiró, inicia sesión de nuevo.');
}
