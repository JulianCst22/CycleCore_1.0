import '../../../core/database/app_database.dart';
import 'personal_records.dart';

/// Desglose de cuánta experiencia (XP) aportó una actividad concreta y
/// por qué -- se expone completo (no solo el total) para poder
/// mostrarlo en el detalle del día y que el usuario entienda de dónde
/// sale cada punto.
class ActivityXpBreakdown {
  final int activityId;
  final int distanceXp;
  final int durationXp;
  final int elevationXp;
  final int powerXp;
  final int streakXp;
  final int recordXp;
  final Set<RecordDimension> recordDimensions;

  const ActivityXpBreakdown({
    required this.activityId,
    required this.distanceXp,
    required this.durationXp,
    required this.elevationXp,
    required this.powerXp,
    required this.streakXp,
    required this.recordXp,
    required this.recordDimensions,
  });

  int get totalXp =>
      distanceXp + durationXp + elevationXp + powerXp + streakXp + recordXp;
}

/// Motor de experiencia (XP) de la gamificación.
///
/// Fórmula por actividad (documentada porque es una decisión de
/// producto, no un detalle interno):
/// - 12 XP por kilómetro recorrido.
/// - 2 XP por minuto de duración.
/// - 1 XP por cada 10 metros de desnivel positivo.
/// - Si hubo medidor de potencia: 0.4 XP por watt de potencia media
///   (premia la intensidad del esfuerzo, no solo el volumen).
/// - Bono de racha: 3 XP por cada día consecutivo que llevaba la racha
///   activa el día de esta actividad, con tope de 30 días (90 XP máx).
/// - Bono de récord: +40 XP por cada dimensión (distancia, duración,
///   desnivel, velocidad media, potencia media) en la que esta
///   actividad sea actualmente el récord personal de su tipo.
///
/// El XP nunca se guarda en la base de datos: se recalcula siempre a
/// partir de las actividades existentes, igual que las estadísticas y
/// la racha -- así nunca queda desincronizado si el usuario borra o
/// edita una actividad.
class XpCalculator {
  XpCalculator._();

  static const _xpPerKm = 12.0;
  static const _xpPerMinute = 2.0;
  static const _xpPerTenMetersElevation = 1.0;
  static const _xpPerWattAvgPower = 0.4;
  static const _xpPerStreakDay = 3;
  static const _maxStreakDaysCounted = 30;
  static const _xpPerRecordDimension = 40;

  static List<ActivityXpBreakdown> computeForActivities(
    List<Activity> activities,
  ) {
    if (activities.isEmpty) return [];

    final recordHolders = PersonalRecords.computeRecordHolders(activities);
    final streakLengthByDay = _streakLengthPerDay(
      activities.map((a) => a.startedAt).toList(),
    );

    return activities.map((a) {
      final day =
          DateTime(a.startedAt.year, a.startedAt.month, a.startedAt.day);
      final streakLengthThatDay =
          (streakLengthByDay[day] ?? 1).clamp(0, _maxStreakDaysCounted);

      final dimensions = recordHolders[a.id] ?? const <RecordDimension>{};

      return ActivityXpBreakdown(
        activityId: a.id,
        distanceXp: ((a.distanceMeters / 1000) * _xpPerKm).round(),
        durationXp: ((a.durationSeconds / 60) * _xpPerMinute).round(),
        elevationXp:
            (a.elevationGainMeters * _xpPerTenMetersElevation / 10).round(),
        powerXp: a.avgPower != null
            ? (a.avgPower! * _xpPerWattAvgPower).round()
            : 0,
        streakXp: streakLengthThatDay * _xpPerStreakDay,
        recordXp: dimensions.length * _xpPerRecordDimension,
        recordDimensions: dimensions,
      );
    }).toList();
  }

  static int totalXpFor(List<Activity> activities) {
    return computeForActivities(activities)
        .fold(0, (sum, b) => sum + b.totalXp);
  }

  /// Para cada día con actividad, calcula cuántos días consecutivos
  /// llevaba la racha en ESE momento (no la racha actual de hoy) --
  /// así una actividad grabada en medio de una racha larga de hace
  /// meses conserva su bono de XP aunque esa racha ya se haya roto.
  static Map<DateTime, int> _streakLengthPerDay(List<DateTime> dates) {
    final uniqueDays = <DateTime>{
      for (final d in dates) DateTime(d.year, d.month, d.day),
    }.toList()
      ..sort();

    final result = <DateTime, int>{};
    var streak = 0;
    DateTime? previous;
    for (final day in uniqueDays) {
      if (previous != null && day.difference(previous).inDays == 1) {
        streak++;
      } else {
        streak = 1;
      }
      result[day] = streak;
      previous = day;
    }
    return result;
  }
}
