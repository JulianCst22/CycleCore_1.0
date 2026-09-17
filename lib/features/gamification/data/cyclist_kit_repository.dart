import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cyclist_kit.dart';
import '../domain/kit_catalog.dart';

/// Persistencia del vestidor en `SharedPreferences` (igual que la voz de
/// guía y los coleccionables -- es estado de UI/producto, no del
/// dominio, y no necesita reactividad entre pantallas más allá de los
/// providers).
///
/// Guarda dos cosas:
/// - El kit equipado ([CyclistKit]) como un JSON pequeño.
/// - Qué desbloqueos ya se le han mostrado al usuario, para no repetir
///   el festejo de "¡Desbloqueaste...!" cada vez.
class CyclistKitRepository {
  static const _kitKey = 'cyclist_kit_v1';
  static const _seenKey = 'cyclist_kit_unlocks_seen_v1';

  Future<CyclistKit> loadKit() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kitKey);
    if (raw == null) return KitCatalog.defaultKit;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      // Una clave `voz` de versiones anteriores se ignora sin más.
      return _sanitized(
        CyclistKit(
          maillotId:
              map['maillot'] as String? ?? KitCatalog.defaultKit.maillotId,
          biciId: map['bici'] as String? ?? KitCatalog.defaultKit.biciId,
          gestoIds: {
            for (final g in (map['gestos'] as List? ?? const [])) g as String,
          },
        ),
      );
    } catch (_) {
      return KitCatalog.defaultKit;
    }
  }

  /// Descarta ids que ya no existan en el catálogo (por si cambió el
  /// contenido entre versiones).
  CyclistKit _sanitized(CyclistKit kit) {
    String pick(String id, String fallback) =>
        KitCatalog.byId.containsKey(id) ? id : fallback;
    final gestos = kit.gestoIds.where(KitCatalog.byId.containsKey).toSet();
    return CyclistKit(
      maillotId: pick(kit.maillotId, KitCatalog.defaultKit.maillotId),
      biciId: pick(kit.biciId, KitCatalog.defaultKit.biciId),
      gestoIds: gestos.isEmpty ? KitCatalog.defaultKit.gestoIds : gestos,
    );
  }

  Future<void> saveKit(CyclistKit kit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kitKey,
      jsonEncode({
        'maillot': kit.maillotId,
        'bici': kit.biciId,
        'gestos': kit.gestoIds.toList(),
      }),
    );
  }

  /// `null` = nunca se ha guardado (primera vez): quien llama debe
  /// inicializar sin festejar el backlog.
  Future<Set<String>?> loadSeenUnlocks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_seenKey);
    return list?.toSet();
  }

  Future<void> saveSeenUnlocks(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_seenKey, ids.toList());
  }
}
