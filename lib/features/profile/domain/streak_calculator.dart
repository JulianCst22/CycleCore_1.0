/// Cálculo de racha de días consecutivos con actividad.
///
/// Reglas (documentadas explícitamente porque son una decisión de
/// producto, no un detalle de implementación):
/// - Cualquier actividad guardada ese día cuenta, sin importar el tipo.
/// - La racha se rompe estrictamente si hay más de 1 día calendario sin
///   ninguna actividad -- no hay "día de descanso gratis".
/// - Se considera vigente si la última actividad fue hoy o ayer, para no
///   penalizar al usuario antes de que termine su día actual.
class StreakCalculator {
  StreakCalculator._();

  static int currentStreak(List<DateTime> activityDates, {DateTime? now}) {
    final days = _uniqueSortedDays(activityDates);
    if (days.isEmpty) return 0;

    final today = _dateOnly(now ?? DateTime.now());
    final mostRecent = days.last;
    final gapFromToday = today.difference(mostRecent).inDays;
    if (gapFromToday > 1) return 0;

    var streak = 1;
    for (var i = days.length - 1; i > 0; i--) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static int longestStreak(List<DateTime> activityDates) {
    final days = _uniqueSortedDays(activityDates);
    if (days.isEmpty) return 0;

    var longest = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (diff > 1) {
        current = 1;
      }
    }
    return longest;
  }

  /// Días concretos (fecha sin hora) que forman la racha activa ahora
  /// mismo -- usado por el calendario para superponer el ícono de fuego
  /// solo sobre esos días, no sobre cualquier día con actividad.
  /// Devuelve un set vacío si no hay racha vigente.
  static Set<DateTime> currentStreakDays(
    List<DateTime> activityDates, {
    DateTime? now,
  }) {
    final days = _uniqueSortedDays(activityDates);
    if (days.isEmpty) return {};

    final today = _dateOnly(now ?? DateTime.now());
    final mostRecent = days.last;
    if (today.difference(mostRecent).inDays > 1) return {};

    final streakDays = <DateTime>{mostRecent};
    for (var i = days.length - 1; i > 0; i--) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        streakDays.add(days[i - 1]);
      } else {
        break;
      }
    }
    return streakDays;
  }

  static List<DateTime> _uniqueSortedDays(List<DateTime> dates) {
    final unique = <DateTime>{for (final d in dates) _dateOnly(d)};
    return unique.toList()..sort();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
