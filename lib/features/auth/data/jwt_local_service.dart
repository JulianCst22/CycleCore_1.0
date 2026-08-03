import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Emisor y verificador de JWT 100% local.
///
/// Genera tokens con la MISMA estructura que emitiría un backend real
/// (header.payload.signature, HS256, claims estándar `sub`, `email`,
/// `iat`, `exp`), para que el día que exista el backend en Kotlin toda
/// la lógica de decodificación/expiración de la UI se reutilice sin
/// cambios -- solo cambia quién firma el token.
///
/// IMPORTANTE: la clave de firma vive en el propio dispositivo, así
/// que este JWT NO tiene valor como prueba de identidad ante terceros
/// (cualquiera con acceso al dispositivo podría re-firmar uno). Solo
/// sirve para el propósito actual: verificar consistencia interna y
/// expiración de la sesión -- no autenticación real de servidor.
class JwtLocalService {
  static const _secretKey = 'jwt_local_secret';
  static const _algHeader = {'alg': 'HS256', 'typ': 'JWT'};

  Future<String> _getOrCreateSecret() async {
    final prefs = await SharedPreferences.getInstance();
    var secret = prefs.getString(_secretKey);
    if (secret == null) {
      final rnd = Random.secure();
      final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
      secret = base64UrlEncode(bytes);
      await prefs.setString(_secretKey, secret);
    }
    return secret;
  }

  String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

  Future<String> issue({
    required String userId,
    required String email,
    Duration validFor = const Duration(days: 30),
  }) async {
    final secret = await _getOrCreateSecret();
    final now = DateTime.now();
    final payload = {
      'sub': userId,
      'email': email,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(validFor).millisecondsSinceEpoch ~/ 1000,
    };
    final headerEncoded = _b64(utf8.encode(jsonEncode(_algHeader)));
    final payloadEncoded = _b64(utf8.encode(jsonEncode(payload)));
    final signingInput = '$headerEncoded.$payloadEncoded';
    final signature =
        Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(signingInput));
    final signatureEncoded = _b64(signature.bytes);
    return '$signingInput.$signatureEncoded';
  }

  /// Verifica firma y expiración. Devuelve el payload decodificado si
  /// es válido, o null si la firma no coincide o el token expiró.
  Future<Map<String, dynamic>?> verify(String token) async {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final secret = await _getOrCreateSecret();
    final signingInput = '${parts[0]}.${parts[1]}';
    final expectedSig =
        Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(signingInput));
    final expectedSigEncoded = _b64(expectedSig.bytes);
    if (expectedSigEncoded != parts[2]) return null;
    final payloadJson =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
    final exp = payload['exp'] as int?;
    if (exp != null &&
        DateTime.now()
            .isAfter(DateTime.fromMillisecondsSinceEpoch(exp * 1000))) {
      return null;
    }
    return payload;
  }
}
