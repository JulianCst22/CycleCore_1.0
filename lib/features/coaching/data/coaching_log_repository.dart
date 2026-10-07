import 'package:drift/drift.dart' show Value;

import '../../../core/database/database.dart';
import '../domain/advice/physics_check.dart';
import '../domain/coaching_session.dart';

/// Registro de los avisos que dio el coach: sirve para revisar una salida
/// después y para medir si el ciclista siguió el consejo.
class CoachingLogRepository {
  final AppDatabase database;

  CoachingLogRepository(this.database);

  /// Guarda un aviso dado en la salida que empezó en [rideStartedAt].
  Future<int> record(
    Advice advice, {
    required DateTime rideStartedAt,
    required int segmentId,
    required double alongMeters,
    required DateTime recordedAt,
    String? message,
  }) {
    final situation = advice.situation;
    final adjustment = advice.decision.adjustment.centroid;
    final urgency = advice.urgency;
    final physics = advice.physics;
    return database.insertCoachingAdvice(
      CoachingAdvicesCompanion.insert(
        rideStartedAt: rideStartedAt,
        segmentId: segmentId,
        second: advice.second,
        alongMeters: alongMeters,
        recordedAt: recordedAt,
        mode: advice.decision.mode.name,
        register: advice.register.name,
        situation: Value(
          situation == null
              ? null
              : '${situation.state.name}/${situation.demand.name}/'
                    '${situation.phase.name}',
        ),
        diagnosis: Value(advice.diagnosis?.rule.id),
        adjustmentLo: Value(adjustment?.lo),
        adjustmentHi: Value(adjustment?.hi),
        urgencyLo: Value(urgency?.lo),
        urgencyHi: Value(urgency?.hi),
        targetPower: Value(advice.power?.spoken),
        targetCadence: Value(advice.cadence?.spoken),
        message: Value(message),
        requestedPower: Value(physics?.advised),
        sustainablePower: Value(physics?.sustainable),
        physicsGapPercent: Value(
          physics == null ? null : roundDifference(physics.difference),
        ),
      ),
    );
  }

  Future<List<CoachingAdvice>> adviceForRide(DateTime rideStartedAt) =>
      database.getCoachingAdvicesForRide(rideStartedAt);
}
