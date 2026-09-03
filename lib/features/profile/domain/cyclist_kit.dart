import 'level_info.dart';

/// Lo que el ciclista de la subida puede llevar puesto / activo. Maillot
/// y bici son de una sola pieza equipada; los gestos pueden estar varios
/// activos a la vez. (La voz de guía se maneja aparte, en
/// `features/voice/` — ver [kVoicePersonas].)
enum KitSlot { maillot, bici, gesto }

/// Cómo se desbloquea una pieza. Todo por **hacer cosas de ciclismo de
/// verdad**, nunca por azar.
enum KitUnlockKind {
  always,
  rankReached,
  rankCompleted,
  totalKm,
  totalElevation,
  postales,
  rideSpeedKmh,
  longestRideKm,
}

class KitUnlockCondition {
  final KitUnlockKind kind;

  /// Umbral: nº de nivel, km, metros, cantidad de postales o km/h,
  /// según [kind]. Ignorado para [KitUnlockKind.always] y
  /// [KitUnlockKind.rankCompleted].
  final double value;

  /// Sólo para [KitUnlockKind.rankCompleted].
  final CyclistRank? rank;

  const KitUnlockCondition(this.kind, {this.value = 0, this.rank});

  static const always = KitUnlockCondition(KitUnlockKind.always);

  String get label {
    String grouped(double m) {
      final digits = m.round().abs().toString();
      final buffer = StringBuffer();
      for (var i = 0; i < digits.length; i++) {
        if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
        buffer.write(digits[i]);
      }
      return buffer.toString();
    }

    return switch (kind) {
      KitUnlockKind.always => 'Disponible',
      KitUnlockKind.rankReached => 'Nivel ${value.toInt()}',
      KitUnlockKind.rankCompleted => 'Corona el rango ${rank!.label}',
      KitUnlockKind.totalKm => '${grouped(value)} km en total',
      KitUnlockKind.totalElevation =>
        '${grouped(value)} m de desnivel en total',
      KitUnlockKind.postales => 'Descubre ${value.toInt()} postales',
      KitUnlockKind.rideSpeedKmh =>
        'Una salida a ${value.toStringAsFixed(0)} km/h de media',
      KitUnlockKind.longestRideKm => 'Una salida de ${value.toInt()} km',
    };
  }
}

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
