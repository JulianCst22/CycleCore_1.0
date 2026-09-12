import 'package:cyclecore_core/database/app_database.dart';
import 'package:cyclecore_core/theme/app_theme.dart';
import 'package:cyclecore_app/features/navigation/domain/navigation_route.dart';
import 'package:cyclecore_app/features/navigation/domain/navigation_target.dart';
import 'package:cyclecore_app/features/navigation/domain/road_graph.dart';
import 'package:cyclecore_app/features/navigation/domain/route_preview.dart';
import 'package:cyclecore_app/features/navigation/presentation/navigation_providers.dart';
import 'package:cyclecore_app/features/navigation/presentation/route_confirm_card.dart';
import 'package:cyclecore_app/features/navigation/presentation/saved_places_screen.dart';
import 'package:cyclecore_app/features/recording/presentation/route_recording_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

SavedPlace _place(int id, String name, {String kind = 'generic'}) => SavedPlace(
  id: id,
  name: name,
  latitude: 4.7,
  longitude: -74.0,
  kind: kind,
  createdAt: DateTime(2026, 1, 1),
);

RoutePreview _preview() {
  const route = NavigationRoute(
    polyline: [
      RoadNode(lat: 4.70, lng: -74.00),
      RoadNode(lat: 4.71, lng: -74.01),
      RoadNode(lat: 4.72, lng: -74.02),
    ],
    instructions: [],
    totalDistanceMeters: 12400,
  );
  return const RoutePreview(
    target: NavigationTarget(name: 'Alto de Patios', lat: 4.72, lng: -74.02),
    route: route,
    elevationSamples: [2550, 2600, 2700, 2900, 3001],
    elevationGainMeters: 480,
    destinationAltitudeMeters: 3001,
    isClimb: true,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('RouteConfirmCard pinta destino, stats y perfil sin excepción', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedPlacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: RouteConfirmCard(preview: _preview(), onChange: () {}),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Alto de Patios'), findsOneWidget);
    expect(find.text('3001 msnm'), findsOneWidget);
    expect(find.text('Empezar'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SavedPlacesScreen lista las ubicaciones guardadas', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedPlacesProvider.overrideWith(
            (ref) => Stream.value([
              _place(1, 'Casa', kind: 'home'),
              _place(2, 'Alto de Patios', kind: 'peak'),
            ]),
          ),
          currentPositionProvider.overrideWith(
            (ref) async => Position(
              latitude: 4.7,
              longitude: -74.0,
              timestamp: DateTime(2026, 1, 1),
              accuracy: 5,
              altitude: 2600,
              altitudeAccuracy: 5,
              heading: 0,
              headingAccuracy: 5,
              speed: 0,
              speedAccuracy: 1,
            ),
          ),
        ],
        child: const MaterialApp(home: SavedPlacesScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Ubicaciones'), findsOneWidget);
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Alto de Patios'), findsOneWidget);
    expect(find.text('Añadir ubicación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SavedPlacesScreen: estado vacío', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedPlacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: SavedPlacesScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Todavía no tienes ninguna.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
