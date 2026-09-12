import 'package:cyclecore_core/gamification/kit_unlock_condition.dart';

// `KitUnlockCondition`/`KitUnlockKind` viven en cyclecore_core: son el
// motor de desbloqueos genérico que también usa `voice/` para sus
// personas (ver voice_persona.dart) -- no son específicos del vestidor.
// Se re-exportan acá para no romper al resto de este feature, que ya
// las usaba vía este import.
export 'package:cyclecore_core/gamification/kit_unlock_condition.dart';

/// Lo que el ciclista de la subida puede llevar puesto / activo. Maillot
/// y bici son de una sola pieza equipada; los gestos pueden estar varios
/// activos a la vez. (La voz de guía se maneja aparte, en
/// `features/voice/` — ver [kVoicePersonas].)
enum KitSlot { maillot, bici, gesto }

/// Una pieza del vestidor.
class KitItem {
  final String id;
  final KitSlot slot;
  final String name;
  final String description;
  final KitUnlockCondition unlock;

  /// Si es una pieza de rango (maillot/bici que cambia de color con el
  /// rango): índice 0..5 en `RankTier.all`. `null` = pieza especial.
  final int? rankTierIndex;

  /// El set al que pertenece, si pertenece a uno.
  final String? setId;

  const KitItem({
    required this.id,
    required this.slot,
    required this.name,
    required this.description,
    required this.unlock,
    this.rankTierIndex,
    this.setId,
  });

  bool get isRankPiece => rankTierIndex != null;
}

/// Un set temático: un maillot + una bici + un gesto + una voz que van
/// juntos. Completarlo da una insignia.
class KitSet {
  final String id;
  final String name;
  final String description;
  final List<String> itemIds;

  const KitSet({
    required this.id,
    required this.name,
    required this.description,
    required this.itemIds,
  });
}

/// Lo que el ciclista lleva puesto ahora mismo. Se persiste en
/// `SharedPreferences` (igual que la voz de guía y los coleccionables).
class CyclistKit {
  final String maillotId;
  final String biciId;
  final Set<String> gestoIds;

  const CyclistKit({
    required this.maillotId,
    required this.biciId,
    required this.gestoIds,
  });

  CyclistKit copyWith({
    String? maillotId,
    String? biciId,
    Set<String>? gestoIds,
  }) {
    return CyclistKit(
      maillotId: maillotId ?? this.maillotId,
      biciId: biciId ?? this.biciId,
      gestoIds: gestoIds ?? this.gestoIds,
    );
  }

  bool isEquipped(KitItem item) => switch (item.slot) {
    KitSlot.maillot => item.id == maillotId,
    KitSlot.bici => item.id == biciId,
    KitSlot.gesto => gestoIds.contains(item.id),
  };
}
