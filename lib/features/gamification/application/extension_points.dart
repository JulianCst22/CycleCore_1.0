import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'unlock_celebration.dart';
import 'wardrobe_extra_tab.dart';

/// Puntos de extensión de la gamificación para features ajenas (hoy,
/// `voice`): vacíos/null por defecto, se completan una sola vez
/// desde la raíz de composición de la app (ver `main.dart`), que sí
/// conoce todas las features. La gamificación nunca importa esas features
/// directamente.

/// Festejos que `ClimbScreen` debe revisar además del suyo propio (el
/// vestidor) -- ver `UnlockCelebrationCheck`.
final unlockCelebrationSourcesProvider =
    Provider<List<UnlockCelebrationCheck>>((ref) => const []);

/// Pestañas que `WardrobeScreen` debe agregar a las suyas propias
/// (Maillot/Bici/Gestos/Sets) -- ver `WardrobeExtraTab`.
final wardrobeExtraTabsProvider =
    Provider<List<WardrobeExtraTab>>((ref) => const []);

/// Providers `bool` de otras features ("¿hay algo nuevo sin ver?") que
/// `ClimbScreen` debe sumar al puntito dorado del menú, junto con el
/// suyo propio (el vestidor).
final unseenUnlockIndicatorsProvider =
    Provider<List<ProviderListenable<bool>>>((ref) => const []);

/// Nombre del ciclista para pintarlo en la subida (la cinemática y el
/// cartel del camino). Lo aporta `profile`, que la gamificación no
/// conoce; `null` si no hay perfil o nadie lo registró.
final riderNameProvider = Provider<String?>((ref) => null);
