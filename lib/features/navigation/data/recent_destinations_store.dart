import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/navigation_target.dart';

/// Los últimos destinos a los que el usuario navegó -- se muestran en el
/// buscador de "Navegar" para no re-escribir siempre lo mismo.
///
/// Es un conveniencia efímera, no un dato del dominio: vive en
/// `SharedPreferences` como una lista JSON corta, no en la base de
/// datos. Se lee al abrir la hoja de búsqueda (no necesita reactividad).
class RecentDestinationsStore {
  static const _key = 'nav_recent_destinations';
  static const _max = 5;

  /// Dos destinos se consideran "el mismo sitio" si están a menos de
  /// esto -- evita llenar la lista con la misma esquina 3 veces.
  static const double _dedupeMeters = 120;

  Future<List<NavigationTarget>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .whereType<NavigationTarget>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(NavigationTarget target) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();

    final deduped = current
        .where((t) => !_sameSpot(t, target))
        .take(_max - 1)
        .toList();

    final updated = [target, ...deduped];
    await prefs.setString(_key, jsonEncode(updated.map(_toJson).toList()));
  }

  bool _sameSpot(NavigationTarget a, NavigationTarget b) {
    if (a.name.trim().toLowerCase() == b.name.trim().toLowerCase()) return true;
    // Distancia aproximada en metros (buena a estas escalas).
    final dLat = (a.lat - b.lat) * 111320;
    final dLng = (a.lng - b.lng) * 111320 * 0.9;
    return dLat * dLat + dLng * dLng < _dedupeMeters * _dedupeMeters;
  }

  Map<String, dynamic> _toJson(NavigationTarget t) => {
    'name': t.name,
    'lat': t.lat,
    'lng': t.lng,
    'kind': t.kind.wire,
  };

  NavigationTarget? _fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();
    if (name == null || lat == null || lng == null) return null;
    return NavigationTarget(
      name: name,
      lat: lat,
      lng: lng,
      kind: PlaceKind.fromWire(json['kind'] as String? ?? 'generic'),
    );
  }
}
