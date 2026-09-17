import 'package:drift/drift.dart' show Value;

import 'package:core_database/core_database.dart';
import '../domain/navigation_target.dart';

/// CRUD de las ubicaciones guardadas del usuario (Casa, un alto que hace
/// seguido...). Persistencia mínima -- toda la lógica interesante
/// (detección de altos, ruta) vive en otra parte.
class SavedPlacesRepository {
  final AppDatabase _database;

  SavedPlacesRepository(this._database);

  Stream<List<SavedPlace>> watchAll() => _database.watchSavedPlaces();

  Future<int> add({
    required String name,
    required double lat,
    required double lng,
    PlaceKind kind = PlaceKind.generic,
  }) {
    return _database.insertSavedPlace(
      SavedPlacesCompanion.insert(
        name: name.trim(),
        latitude: lat,
        longitude: lng,
        kind: Value(kind.wire),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> rename(SavedPlace place, String name) {
    return _database.updateSavedPlace(
      place.toCompanion(true).copyWith(name: Value(name.trim())),
    );
  }

  Future<void> delete(int id) => _database.deleteSavedPlace(id);
}

extension SavedPlaceTarget on SavedPlace {
  NavigationTarget toTarget() => NavigationTarget(
    name: name,
    lat: latitude,
    lng: longitude,
    kind: PlaceKind.fromWire(kind),
  );
}
