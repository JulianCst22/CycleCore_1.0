import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/physiology/physiology.dart';
import '../../profile/profile.dart';
import '../../stats/stats.dart';
import '../data/coaching_log_repository.dart';
import '../data/message_bank_repository.dart';
import '../data/ride_export_repository.dart';
import '../domain/calibration/athlete_calibration.dart';

final coachingLogRepositoryProvider = Provider<CoachingLogRepository>((ref) {
  return CoachingLogRepository(ref.watch(appDatabaseProvider));
});

/// Saca una salida guardada en el formato que reproduce el motor (las
/// herramientas de la tesis la leen tal cual).
final rideExportRepositoryProvider = Provider<RideExportRepository>(
  (ref) => RideExportRepository(ref.watch(appDatabaseProvider)),
);

/// Bancos de frases empaquetados con la app, uno por voz.
final messageBankRepositoryProvider = Provider<MessageBankRepository>(
  (ref) => MessageBankRepository(),
);

/// Potencia crítica y W′ calibradas con la curva de potencia de los
/// últimos 90 días; si no alcanza, con la potencia de 20 min o la FTP
/// del perfil. Se recalcula sola al guardar una salida nueva.
final athleteCalibrationProvider = Provider<AsyncValue<AthleteCalibration>>((
  ref,
) {
  final now = DateTime.now();
  final since = DateTime(
    now.year,
    now.month,
    now.day - AthleteCalibration.window.inDays,
  );
  final curve = ref.watch(
    bestCurveProvider((kind: CurveKind.power, since: since, until: null)),
  );
  final profile = ref.watch(profileProvider).valueOrNull;
  return curve.whenData(
    (c) => AthleteCalibration.from(
      recentPower: c,
      ftpWatts: profile?.ftpWatts,
      level: profile?.level,
      weightKg: profile?.weightKg,
    ),
  );
});

/// Resumen para mostrar fuera del coach: el modelo y de dónde sale.
final criticalPowerSummaryOfAthleteProvider =
    Provider<({CriticalPowerModel model, String basis})?>((ref) {
      final calibration = ref.watch(athleteCalibrationProvider).valueOrNull;
      final model = calibration?.model;
      if (calibration == null || model == null) return null;
      return (model: model, basis: calibration.explanation);
    });
