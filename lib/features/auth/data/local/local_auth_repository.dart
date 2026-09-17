import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/auth_exceptions.dart';
import '../../domain/auth_session.dart';
import '../auth_repository.dart';
import '../jwt_local_service.dart';

/// Implementación 100% local y provisional de `AuthRepository`.
///
/// TEMPORAL: el día que exista el backend en Kotlin + PostgreSQL, esta
/// clase se reemplaza por `RemoteAuthRepository` (HTTP), sin tocar la
/// interfaz ni la UI. "Local" no como en "tests" -- como en "vive en
/// este dispositivo, todavía no en la nube".
///
/// Guarda:
///  - `auth_users`: cuentas registradas en este dispositivo (email ->
///    hash+salt de password), simulando la tabla de usuarios del
///    backend real.
///  - `auth_session`: la sesión activa actual (si hay alguna).
class LocalAuthRepository implements AuthRepository {
  static const _usersKey = 'auth_users';
  static const _sessionKey = 'auth_session';

  final JwtLocalService _jwt;

  LocalAuthRepository({JwtLocalService? jwt}) : _jwt = jwt ?? JwtLocalService();

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  String _generateSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _generateUserId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  @override
  Future<AuthSession?> currentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;

    final session = AuthSession.decode(raw);
    final payload = await _jwt.verify(session.token);
    if (payload == null) {
      // Token corrupto o expirado -- limpiamos la sesión inválida en
      // vez de dejar que la UI la trate como buena.
      await prefs.remove(_sessionKey);
      return null;
    }
    return session;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (password.length < 6) throw const WeakPasswordException();

    final users = await _loadUsers();
    final exists = users.any((u) => u['email'] == normalizedEmail);
    if (exists) throw const EmailAlreadyRegisteredException();

    final salt = _generateSalt();
    final userId = _generateUserId();

    users.add({
      'userId': userId,
      'email': normalizedEmail,
      'displayName': displayName,
      'salt': salt,
      'passwordHash': _hashPassword(password, salt),
    });
    await _saveUsers(users);

    return _createSession(
      userId: userId,
      email: normalizedEmail,
      displayName: displayName,
    );
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = await _loadUsers();

    final match = users.cast<Map<String, dynamic>?>().firstWhere(
      (u) => u?['email'] == normalizedEmail,
      orElse: () => null,
    );
    if (match == null) throw const InvalidCredentialsException();

    final expectedHash = _hashPassword(password, match['salt'] as String);
    if (expectedHash != match['passwordHash']) {
      throw const InvalidCredentialsException();
    }

    return _createSession(
      userId: match['userId'] as String,
      email: normalizedEmail,
      displayName: match['displayName'] as String?,
    );
  }

  @override
  Future<bool> emailTaken(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = await _loadUsers();
    return users.any((u) => u['email'] == normalizedEmail);
  }

  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) throw const WeakPasswordException();

    final normalizedEmail = email.trim().toLowerCase();
    final users = await _loadUsers();
    final index = users.indexWhere((u) => u['email'] == normalizedEmail);
    if (index == -1) throw const InvalidCredentialsException();

    final user = users[index];
    final currentHash = _hashPassword(currentPassword, user['salt'] as String);
    if (currentHash != user['passwordHash']) {
      throw const WrongCurrentPasswordException();
    }

    final newSalt = _generateSalt();
    users[index] = {
      ...user,
      'salt': newSalt,
      'passwordHash': _hashPassword(newPassword, newSalt),
    };
    await _saveUsers(users);
  }

  Future<AuthSession> _createSession({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    const validFor = Duration(days: 30);
    final token = await _jwt.issue(
      userId: userId,
      email: email,
      validFor: validFor,
    );
    final now = DateTime.now();

    final session = AuthSession(
      userId: userId,
      email: email,
      displayName: displayName,
      token: token,
      issuedAt: now,
      expiresAt: now.add(validFor),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, session.encode());
    return session;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
