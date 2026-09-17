import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cyclist_kit_repository.dart';
import '../domain/cyclist_kit.dart';
import '../domain/kit_catalog.dart';
import '../domain/kit_unlocks.dart';
import '../domain/rank_tier.dart';
import 'climb_collectibles_provider.dart';
import '../../stats/stats.dart';
import 'xp_providers.dart';

final cyclistKitRepositoryProvider = Provider<CyclistKitRepository>(
  (ref) => CyclistKitRepository(),
);

/// Lo que el ciclista lleva puesto ahora mismo.
class CyclistKitNotifier extends StateNotifier<AsyncValue<CyclistKit>> {
  CyclistKitNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  final CyclistKitRepository _repo;

  Future<void> _load() async {
    try {
      state = AsyncValue.data(await _repo.loadKit());
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Equipa una pieza. Para los gestos alterna (pueden ir varios a la
  /// vez); para el resto reemplaza.
  Future<void> equip(KitItem item) async {
    final current = state.valueOrNull ?? KitCatalog.defaultKit;
    final CyclistKit updated = switch (item.slot) {
      KitSlot.maillot => current.copyWith(maillotId: item.id),
      KitSlot.bici => current.copyWith(biciId: item.id),
      KitSlot.gesto => current.copyWith(
        gestoIds: current.gestoIds.contains(item.id)
            ? (current.gestoIds.toSet()..remove(item.id))
            : (current.gestoIds.toSet()..add(item.id)),
      ),
    };
    state = AsyncValue.data(updated);
    try {
      await _repo.saveKit(updated);
    } catch (_) {
      // El estado en memoria ya se actualizó; no rompemos la UX por un
      // fallo de escritura puntual (mismo criterio que los coleccionables).
    }
  }
}

final cyclistKitProvider =
    StateNotifierProvider<CyclistKitNotifier, AsyncValue<CyclistKit>>(
      (ref) => CyclistKitNotifier(ref.watch(cyclistKitRepositoryProvider)),
    );

/// El contexto de desbloqueos, derivado del estado REAL del usuario
/// (nivel + estadísticas totales + postales descubiertas).
final kitUnlockContextProvider = Provider<KitUnlockContext?>((ref) {
  final level = ref.watch(levelInfoProvider).valueOrNull;
  final stats = ref.watch(profileStatsProvider).valueOrNull;
  if (level == null || stats == null) return null;
  final postales =
      ref.watch(climbCollectiblesProvider).valueOrNull?.length ?? 0;
  return kitUnlockContextFrom(
    levelInfo: level,
    allTimeStats: stats,
    postalesCount: postales,
  );
});

/// Interruptor de testing: desbloquea TODO el vestidor. Se activa desde
/// el botón "🔓" del Vestidor. Temporal -- se quita antes de entregar.
final kitDebugUnlockAllProvider = StateProvider<bool>((ref) => false);

/// Ids de todas las piezas desbloqueadas ahora mismo.
final unlockedKitIdsProvider = Provider<Set<String>>((ref) {
  if (ref.watch(kitDebugUnlockAllProvider)) {
    return {for (final item in KitCatalog.items) item.id};
  }
  final ctx = ref.watch(kitUnlockContextProvider);
  return ctx == null ? const <String>{} : unlockedKitItemIds(ctx);
});

/// Índice de rango (0..5) del maillot equipado -- lo usa
/// `PedalingCyclist` para el patrón del maillot. El maillot por defecto
/// "sigue tu rango"; uno elegido a mano manda (las piezas especiales sin
/// rango caen al patrón del rango actual).
final equippedMaillotTierProvider = Provider<int>((ref) {
  final kit =
      ref.watch(cyclistKitProvider).valueOrNull ?? KitCatalog.defaultKit;
  final level = ref.watch(levelInfoProvider).valueOrNull;
  final rankTier = level == null ? 0 : RankTier.indexOfRank(level.rank);
  if (kit.maillotId == KitCatalog.defaultKit.maillotId) return rankTier;
  return KitCatalog.byId[kit.maillotId]?.rankTierIndex ?? rankTier;
});

/// Qué desbloqueos ya se le mostraron al usuario -- para no repetir el
/// festejo. Mismo patrón que `climbCollectiblesProvider`.
class KitUnlocksSeenNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  KitUnlocksSeenNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  final CyclistKitRepository _repo;
  bool _hadStored = false;

  Future<void> _load() async {
    try {
      final stored = await _repo.loadSeenUnlocks();
      _hadStored = stored != null;
      state = AsyncValue.data(stored ?? <String>{});
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Registra [currentlyUnlocked] como "visto" y devuelve los ids que
  /// eran NUEVOS. La primera vez (sin nada guardado) sólo inicializa:
  /// devuelve vacío, para no festejar todo el backlog de golpe.
  Future<Set<String>> reconcile(Set<String> currentlyUnlocked) async {
    final seen = state.valueOrNull ?? <String>{};
    final newOnes = _hadStored
        ? currentlyUnlocked.difference(seen)
        : const <String>{};
    _hadStored = true;
    final updated = {...seen, ...currentlyUnlocked};
    state = AsyncValue.data(updated);
    try {
      await _repo.saveSeenUnlocks(updated);
    } catch (_) {
      // Ver nota en CyclistKitNotifier.equip.
    }
    return newOnes;
  }
}

final kitUnlocksSeenProvider =
    StateNotifierProvider<KitUnlocksSeenNotifier, AsyncValue<Set<String>>>(
      (ref) => KitUnlocksSeenNotifier(ref.watch(cyclistKitRepositoryProvider)),
    );

/// Ids desbloqueados que el usuario aún no ha "visto" -- para el
/// puntito de aviso en el Vestidor.
final unseenKitUnlocksProvider = Provider<Set<String>>((ref) {
  final unlocked = ref.watch(unlockedKitIdsProvider);
  final seen =
      ref.watch(kitUnlocksSeenProvider).valueOrNull ?? const <String>{};
  return unlocked.difference(seen);
});
