import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/level_info.dart';

/// Override de XP **solo para pruebas** desde el perfil.
///
/// El XP real (`totalXpProvider` en `profile_providers.dart`) siempre
/// se recalcula desde las actividades guardadas y nunca se persiste --
/// eso no cambia. Este provider vive completamente aparte: cuando no es
/// `null`, la UI de nivel/roadmap/climb muestra este valor en vez del
/// real, pero no se guarda en la base de datos ni afecta el historial
/// de actividades. Vive solo en memoria (se resetea al reiniciar la
/// app), que es justo lo que quieres para "probar cómo se ve el nivel
/// 18" sin ensuciar datos reales.
class XpDebugOverrideNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  bool get isActive => state != null;

  void setLevel(int level) {
    state = LevelCalculator.cumulativeXpToReach(level);
  }

  void setTotalXp(int xp) {
    state = xp;
  }

  void clear() {
    state = null;
  }
}

final xpDebugOverrideProvider =
    NotifierProvider<XpDebugOverrideNotifier, int?>(
  XpDebugOverrideNotifier.new,
);
