import 'package:cyclecore_app/features/auth/data/local/local_auth_repository.dart';
import 'package:cyclecore_app/features/auth/domain/auth_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  LocalAuthRepository repo() => LocalAuthRepository();

  group('emailTaken', () {
    test('falso si no hay cuenta, verdadero tras registrar', () async {
      final r = repo();
      expect(await r.emailTaken('nuevo@correo.com'), isFalse);
      await r.register(email: 'Nuevo@Correo.com', password: 'secreta1');
      expect(await r.emailTaken('nuevo@correo.com'), isTrue);
      // Normaliza mayúsculas/espacios.
      expect(await r.emailTaken('  NUEVO@correo.com '), isTrue);
    });
  });

  group('changePassword', () {
    test(
      'cambia la contraseña y permite iniciar sesión con la nueva',
      () async {
        final r = repo();
        await r.register(email: 'a@a.com', password: 'vieja123');

        await r.changePassword(
          email: 'a@a.com',
          currentPassword: 'vieja123',
          newPassword: 'nueva456',
        );

        await expectLater(
          r.login(email: 'a@a.com', password: 'vieja123'),
          throwsA(isA<InvalidCredentialsException>()),
        );
        final session = await r.login(email: 'a@a.com', password: 'nueva456');
        expect(session.email, 'a@a.com');
      },
    );

    test('rechaza si la contraseña actual es incorrecta', () async {
      final r = repo();
      await r.register(email: 'a@a.com', password: 'vieja123');
      await expectLater(
        r.changePassword(
          email: 'a@a.com',
          currentPassword: 'incorrecta',
          newPassword: 'nueva456',
        ),
        throwsA(isA<WrongCurrentPasswordException>()),
      );
    });

    test('rechaza contraseñas nuevas débiles', () async {
      final r = repo();
      await r.register(email: 'a@a.com', password: 'vieja123');
      await expectLater(
        r.changePassword(
          email: 'a@a.com',
          currentPassword: 'vieja123',
          newPassword: '123',
        ),
        throwsA(isA<WeakPasswordException>()),
      );
    });
  });
}
