import 'dart:convert';

/// Sesión de cuenta activa: la envoltura de datos que vive en memoria/
/// disco mientras el usuario está "vinculado" a una cuenta (local hoy,
/// remota cuando exista el backend Kotlin). Un [AuthSession] nulo en
/// `authProvider` significa modo invitado -- no un error.
class AuthSession {
  final String userId;
  final String email;
  final String? displayName;
  final String token;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const AuthSession({
    required this.userId,
    required this.email,
    required this.token,
    required this.issuedAt,
    required this.expiresAt,
    this.displayName,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'token': token,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        userId: json['userId'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        token: json['token'] as String,
        issuedAt: DateTime.parse(json['issuedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );

  String encode() => jsonEncode(toJson());

  factory AuthSession.decode(String raw) =>
      AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
