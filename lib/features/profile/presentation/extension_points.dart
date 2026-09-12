import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/unlock_celebration.dart';
import '../domain/wardrobe_extra_tab.dart';

/// Puntos de extensión de `profile` para features ajenas (hoy, `voice`
/// y `activities`): vacíos/null por defecto, se completan una sola vez
/// desde la raíz de composición de la app (ver `main.dart`), que sí
/// conoce todas las features. `profile` nunca importa esas features
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

/// Abre el detalle de una actividad guardada -- lo usan widgets de
/// profile (la hoja de detalle de un día del calendario, la grilla de
/// fotos destacadas) para saltar a la actividad de origen sin que
/// profile dependa de `activities`. `null` hasta que se registre.
typedef OpenActivityDetail = void Function(
  BuildContext context,
  int activityId,
);

final openActivityDetailProvider = Provider<OpenActivityDetail?>(
  (ref) => null,
);
