import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persistencia simple (un archivo JSON en el almacenamiento local del
/// dispositivo -- mismo patrón que ya usa el avatar del perfil) de qué
/// puntos de interés de la subida ya se "descubrieron": se tocaron al
/// menos una vez estando desbloqueados. Alimenta tanto el punto
/// "nuevo por descubrir" sobre el roadmap como la pantalla de
/// Colección.
class ClimbCollectiblesNotifier extends StateNotifier<AsyncValue<Set<int>>> {
  ClimbCollectiblesNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'climb_collectibles.json'));
  }

  Future<void> _load() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        state = const AsyncValue.data(<int>{});
        return;
      }
      final raw = await file.readAsString();
      final decoded = raw.trim().isEmpty ? const [] : jsonDecode(raw) as List;
      state = AsyncValue.data(decoded.map((e) => e as int).toSet());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Marca un nivel como descubierto. Devuelve `true` si era la
  /// primera vez que se descubría (para poder mostrar un pequeño
  /// festejo de "¡Nuevo!" solo esa primera vez).
  Future<bool> markDiscovered(int level) async {
    final current = state.valueOrNull ?? <int>{};
    if (current.contains(level)) return false;

    final updated = {...current, level};
    state = AsyncValue.data(updated);

    try {
      final file = await _file();
      final sorted = updated.toList()..sort();
      await file.writeAsString(jsonEncode(sorted));
    } catch (_) {
      // Si falla el guardado en disco, el estado en memoria ya quedó
      // actualizado para esta sesión -- no rompemos la UX por un
      // fallo de escritura puntual.
    }
    return true;
  }
}

final climbCollectiblesProvider =
    StateNotifierProvider<ClimbCollectiblesNotifier, AsyncValue<Set<int>>>(
  (ref) => ClimbCollectiblesNotifier(),
);
