import 'package:flutter/services.dart' show rootBundle;

import '../domain/message/message_bank.dart';

/// Carga los bancos de frases empaquetados con la app
/// (`assets/coaching/messages/<voz>.json`).
///
/// Si una voz todavía no tiene banco propio, se usa el de la voz
/// estándar: el coach habla igual, solo que sin el color de esa persona.
class MessageBankRepository {
  static const fallbackPersona = 'pro';

  final Future<String> Function(String path) _load;
  final Map<String, MessageBank> _cache = {};

  MessageBankRepository({Future<String> Function(String path)? loadAsset})
    : _load = loadAsset ?? rootBundle.loadString;

  static String pathOf(String persona) =>
      'assets/coaching/messages/$persona.json';

  Future<MessageBank> load(String persona) async {
    final cached = _cache[persona];
    if (cached != null) return cached;
    MessageBank bank;
    try {
      bank = MessageBank.parse(await _load(pathOf(persona)));
    } on Exception {
      if (persona == fallbackPersona) rethrow;
      bank = await load(fallbackPersona);
    }
    return _cache[persona] = bank;
  }
}
