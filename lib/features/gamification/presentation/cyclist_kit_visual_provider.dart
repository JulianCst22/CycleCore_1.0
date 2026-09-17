import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/rank_tier.dart';
import '../domain/kit_catalog.dart';
import '../application/cyclist_kit_providers.dart';
import 'rank_tier_style.dart';
import 'widgets/pedaling_cyclist.dart';
import '../application/xp_providers.dart';

// Modelo visual del ciclista (lo que dibuja `PedalingCyclist`) derivado
// del kit equipado. Vive en presentación, junto al widget que lo
// consume: es una traducción de estado a colores y poses, no estado.

int _jerseyKindFor(String maillotId) => switch (maillotId) {
  'maillot_lunares' => 6,
  'maillot_aero' => 7,
  'maillot_lana' => 8,
  _ => KitCatalog.byId[maillotId]?.rankTierIndex ?? 0,
};

int _bikeKindFor(String biciId) => switch (biciId) {
  'bici_ligera' => 6,
  'bici_aero' => 7,
  'bici_perfil' => 8,
  'bici_acero' => 9,
  _ => KitCatalog.byId[biciId]?.rankTierIndex ?? 0,
};

Color _bikeColorFor(int bikeKind) => switch (bikeKind) {
  6 => const Color(0xFFF0F0F0), // ligera -- blanco
  7 => const Color(0xFF16B8F3), // contrarreloj -- cian
  8 => const Color(0xFF7E9BFF), // perfil -- azul
  9 => const Color(0xFF9AA0AA), // acero -- gris
  _ => RankTier.all[bikeKind.clamp(0, 5)].color, // rango
};

/// Lo que se le ve puesto al `PedalingCyclist`: patrón de maillot, bici
/// y gestos, resuelto desde el kit equipado. El maillot/bici por
/// defecto "siguen el rango"; una pieza elegida a mano manda.
final cyclistKitVisualProvider = Provider<CyclistKitVisual>((ref) {
  final kit =
      ref.watch(cyclistKitProvider).valueOrNull ?? KitCatalog.defaultKit;
  final level = ref.watch(levelInfoProvider).valueOrNull;
  final rankTier = level == null ? 0 : RankTier.indexOfRank(level.rank);

  final jersey = kit.maillotId == KitCatalog.defaultKit.maillotId
      ? rankTier
      : _jerseyKindFor(kit.maillotId);
  final bike = kit.biciId == KitCatalog.defaultKit.biciId
      ? rankTier
      : _bikeKindFor(kit.biciId);

  final gestures = <CyclistGesture>{
    for (final id in kit.gestoIds) ?cyclistGestureForKitId(id),
  };

  return CyclistKitVisual(
    jerseyKind: jersey,
    bikeKind: bike,
    bikeColor: _bikeColorFor(bike),
    // Puede quedar vacío a propósito: si apagas todos los gestos, el
    // ciclista sólo pedalea.
    gestures: gestures,
  );
});
