import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart' show appDatabaseProvider;
import '../data/bikes_repository.dart';
import '../domain/bike.dart';

final bikesRepositoryProvider = Provider<BikesRepository>(
  (ref) => BikesRepository(ref.watch(appDatabaseProvider)),
);

/// Las bicicletas del ciclista, la predeterminada primero.
final bikesProvider = StreamProvider<List<Bike>>(
  (ref) => ref.watch(bikesRepositoryProvider).watchBikes(),
);

/// La bicicleta con la que se cuenta: la predeterminada. Es la que se
/// propone al guardar una salida y la que usa el coach para la masa.
final defaultBikeProvider = Provider<Bike?>((ref) {
  final bikes = ref.watch(bikesProvider).valueOrNull;
  if (bikes == null || bikes.isEmpty) return null;
  return bikes.firstWhere((b) => b.isDefault, orElse: () => bikes.first);
});

/// Cuánto lleva rodado cada bicicleta. Se vuelve a sumar solo cuando se
/// guarda, se corrige o se borra una salida.
final bikeUsageProvider = StreamProvider<Map<int, BikeUsage>>(
  (ref) => ref.watch(bikesRepositoryProvider).watchUsage(),
);
