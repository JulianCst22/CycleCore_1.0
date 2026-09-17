import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/zones_repository.dart';
import '../domain/training_zones.dart';

final zonesRepositoryProvider = Provider<ZonesRepository>((ref) {
  return ZonesRepository();
});

/// Estado async de las zonas: null significa "todavía no se han calculado
/// ni guardado zonas" (por ejemplo, antes del primer onboarding).
class ZonesNotifier extends AsyncNotifier<TrainingZones?> {
  @override
  Future<TrainingZones?> build() async {
    return ref.read(zonesRepositoryProvider).loadZones();
  }

  Future<void> saveZones(TrainingZones zones) async {
    await ref.read(zonesRepositoryProvider).saveZones(zones);
    state = AsyncValue.data(zones);
  }

  Future<void> clearZones() async {
    await ref.read(zonesRepositoryProvider).clearZones();
    state = const AsyncValue.data(null);
  }
}

final zonesProvider = AsyncNotifierProvider<ZonesNotifier, TrainingZones?>(
  ZonesNotifier.new,
);
