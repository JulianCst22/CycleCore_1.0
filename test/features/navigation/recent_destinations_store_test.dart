import 'package:cyclecore_app/features/navigation/data/recent_destinations_store.dart';
import 'package:cyclecore_app/features/navigation/domain/navigation_target.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('el más reciente queda primero y la lista se recorta a 5', () async {
    final store = RecentDestinationsStore();
    for (var i = 0; i < 7; i++) {
      await store.add(
        NavigationTarget(name: 'Destino $i', lat: 4.0 + i, lng: -74.0),
      );
    }
    final list = await store.load();
    expect(list.length, 5);
    expect(list.first.name, 'Destino 6');
    expect(list.last.name, 'Destino 2');
  });

  test('el mismo sitio (nombre) no se duplica, sube al tope', () async {
    final store = RecentDestinationsStore();
    await store.add(
      const NavigationTarget(name: 'Patios', lat: 4.7, lng: -74.0),
    );
    await store.add(const NavigationTarget(name: 'Sopó', lat: 4.9, lng: -73.9));
    await store.add(
      const NavigationTarget(name: 'patios', lat: 4.7, lng: -74.0),
    );

    final list = await store.load();
    expect(list.length, 2);
    expect(list.first.name, 'patios');
  });

  test('dos puntos muy cercanos se consideran el mismo sitio', () async {
    final store = RecentDestinationsStore();
    await store.add(
      const NavigationTarget(name: 'Esquina A', lat: 4.70000, lng: -74.00000),
    );
    await store.add(
      const NavigationTarget(name: 'Esquina B', lat: 4.70020, lng: -74.00020),
    );
    final list = await store.load();
    expect(list.length, 1);
  });

  test('lista vacía cuando no hay nada guardado', () async {
    expect(await RecentDestinationsStore().load(), isEmpty);
  });
}
