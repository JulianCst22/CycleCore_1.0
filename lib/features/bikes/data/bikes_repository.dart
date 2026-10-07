import 'package:drift/drift.dart' show Value;

import '../../../core/database/database.dart' as db;
import '../domain/bike.dart';

/// Las bicicletas del ciclista, guardadas en la base local.
///
/// Traduce entre la fila de Drift y el modelo del dominio: el dominio no
/// sabe de SQL y la base no sabe de rodadura ni de arrastre.
class BikesRepository {
  final db.AppDatabase database;

  BikesRepository(this.database);

  Stream<List<Bike>> watchBikes() =>
      database.watchBikes().map((rows) => rows.map(_toDomain).toList());

  Future<List<Bike>> allBikes() async =>
      (await database.allBikes()).map(_toDomain).toList();

  Future<Bike?> byId(int id) async {
    final row = await database.getBikeById(id);
    return row == null ? null : _toDomain(row);
  }

  /// La bicicleta con la que se rueda y con la que cuenta el coach.
  Future<Bike?> defaultBike() async {
    final row = await database.getDefaultBike();
    return row == null ? null : _toDomain(row);
  }

  Future<int> add({
    required String name,
    required BikeKind kind,
    String? brand,
    double? weightKg,
    int? color,
    String? photoPath,
    String? notes,
    int? lowestChainring,
    int? largestCog,
    int? largestChainring,
    int? smallestCog,
    int? wheelCircumferenceMm,
    bool isDefault = false,
  }) {
    return database.insertBike(
      db.BikesCompanion.insert(
        name: name,
        kind: Value(kind.name),
        brand: Value(brand),
        weightKg: Value(weightKg),
        color: Value(color),
        photoPath: Value(photoPath),
        notes: Value(notes),
        lowestChainring: Value(lowestChainring),
        largestCog: Value(largestCog),
        largestChainring: Value(largestChainring),
        smallestCog: Value(smallestCog),
        wheelCircumferenceMm: Value(wheelCircumferenceMm),
        isDefault: Value(isDefault),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> save(Bike bike) async {
    await database.updateBike(
      db.BikeRow(
        id: bike.id,
        name: bike.name,
        brand: bike.brand,
        kind: bike.kind.name,
        weightKg: bike.weightKg,
        color: bike.color,
        photoPath: bike.photoPath,
        notes: bike.notes,
        lowestChainring: bike.lowestChainring,
        largestCog: bike.largestCog,
        largestChainring: bike.largestChainring,
        smallestCog: bike.smallestCog,
        wheelCircumferenceMm: bike.wheelCircumferenceMm,
        isDefault: bike.isDefault,
        createdAt: bike.createdAt,
      ),
    );
  }

  Future<void> remove(int id) => database.deleteBike(id);

  Future<void> makeDefault(int id) => database.setDefaultBike(id);

  /// Cuánto lleva rodado cada bicicleta, sumando sus actividades, y se
  /// vuelve a sumar solo cuando alguna cambia.
  ///
  /// Se calcula al vuelo en vez de llevar contadores: si el ciclista
  /// borra o corrige una salida, el total queda bien solo.
  Stream<Map<int, BikeUsage>> watchUsage() =>
      database.watchAllActivities().map(totalsOf);

  /// Los mismos totales para una lista ya leída.
  static Map<int, BikeUsage> totalsOf(List<db.Activity> activities) {
    final totals = <int, BikeUsage>{};
    for (final activity in activities) {
      final id = activity.bikeId;
      if (id == null) continue;
      final current = totals[id] ?? emptyBikeUsage;
      final last = current.lastRide;
      totals[id] = (
        activities: current.activities + 1,
        distanceMeters: current.distanceMeters + activity.distanceMeters,
        time: current.time + Duration(seconds: activity.durationSeconds),
        elevationGainMeters:
            current.elevationGainMeters + activity.elevationGainMeters,
        lastRide: last == null || activity.startedAt.isAfter(last)
            ? activity.startedAt
            : last,
      );
    }
    return totals;
  }

  static Bike _toDomain(db.BikeRow row) => Bike(
    id: row.id,
    name: row.name,
    brand: row.brand,
    kind: BikeKind.byName(row.kind),
    weightKg: row.weightKg,
    color: row.color,
    photoPath: row.photoPath,
    notes: row.notes,
    lowestChainring: row.lowestChainring,
    largestCog: row.largestCog,
    largestChainring: row.largestChainring,
    smallestCog: row.smallestCog,
    wheelCircumferenceMm: row.wheelCircumferenceMm,
    isDefault: row.isDefault,
    createdAt: row.createdAt,
  );
}
