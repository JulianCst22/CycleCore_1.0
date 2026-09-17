import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_database/core_database.dart';
import '../domain/level_info.dart';
import '../domain/xp_calculator.dart';
import 'xp_debug_provider.dart';

/// XP, nivel y rango del ciclista. La XP nunca se persiste: se recalcula
/// siempre desde las actividades guardadas (ver [XpCalculator]).

/// XP de cada actividad, indexado por su id -- para mostrar "+XX XP" en
/// el detalle del día y en cualquier otro lugar que lo necesite.
final activityXpProvider = Provider<AsyncValue<Map<int, ActivityXpBreakdown>>>((
  ref,
) {
  final activitiesAsync = ref.watch(allActivitiesProvider);
  return activitiesAsync.whenData((activities) {
    final breakdowns = XpCalculator.computeForActivities(activities);
    return {for (final b in breakdowns) b.activityId: b};
  });
});

/// XP total acumulado del usuario -- suma del XP de todas sus
/// actividades. Nunca se persiste aparte: se recalcula siempre desde
/// las actividades guardadas.
final totalXpProvider = Provider<AsyncValue<int>>((ref) {
  final activitiesAsync = ref.watch(allActivitiesProvider);
  return activitiesAsync.whenData(XpCalculator.totalXpFor);
});

/// XP "efectivo": el real, salvo que haya un override de testing activo
/// (ver `xp_debug_provider.dart`), en cuyo caso todo lo visual de nivel
/// usa ese valor en su lugar. `totalXpProvider` sigue siendo el XP real
/// sin tocar, por si en algún lugar necesitas mostrar el dato genuino.
final effectiveTotalXpProvider = Provider<AsyncValue<int>>((ref) {
  final debugOverride = ref.watch(xpDebugOverrideProvider);
  if (debugOverride != null) {
    return AsyncValue.data(debugOverride);
  }
  return ref.watch(totalXpProvider);
});

/// Nivel, rango y progreso actual, derivados del XP efectivo (real u
/// override de testing).
final levelInfoProvider = Provider<AsyncValue<LevelInfo>>((ref) {
  final totalXpAsync = ref.watch(effectiveTotalXpProvider);
  return totalXpAsync.whenData(LevelCalculator.fromTotalXp);
});

/// Recuerda el último nivel que la UI ya "reconoció", para detectar
/// subidas de nivel (nivel anterior vs nuevo) y disparar la animación
/// de celebración una sola vez por subida.
///
/// Vive solo en memoria: se resetea al reiniciar la app. Es una
/// simplificación intencional -- si más adelante quieres que sobreviva
/// a un reinicio, es cuestión de persistir `state` con
/// shared_preferences igual que hace `ProfileRepository`.
class LevelAcknowledgementNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  /// Compara [currentLevel] contra el último nivel reconocido y
  /// actualiza el estado. Devuelve `true` solo si es una subida real
  /// (no la primera vez que se consulta, para no disparar la animación
  /// apenas se abre la app).
  bool consumeLevelUp(int currentLevel) {
    final previous = state;
    state = currentLevel;
    if (previous == null) return false;
    return currentLevel > previous;
  }
}

final levelAcknowledgementProvider =
    NotifierProvider<LevelAcknowledgementNotifier, int?>(
      LevelAcknowledgementNotifier.new,
    );
