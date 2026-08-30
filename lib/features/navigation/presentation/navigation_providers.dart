import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/navigation/road_region_id.dart';
// currentPositionProvider y locationServiceProvider viven en
// geospatial/presentation/map_providers.dart -- mismo lugar de donde
// los importa elevation_providers.dart.
import '../../geospatial/presentation/map_providers.dart';
import '../data/geocoding_service.dart';
import '../data/road_region_repository.dart';
import '../domain/ch_router.dart';
import '../domain/navigation_route.dart';
import '../domain/route_snapper.dart';
import '../domain/turn_instruction_builder.dart';

final roadRegionRepositoryProvider = Provider<RoadRegionRepository>((ref) {
  return RoadRegionRepository(ref.read(appDatabaseProvider));
});

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});

/// Región del catálogo que cubre tu posición actual -- null si estás
/// fuera de todas las zonas ya preprocesadas.
final currentRoadRegionProvider = FutureProvider<RoadRegionId?>((ref) async {
  final position = await ref.watch(currentPositionProvider.future);
  return RoadRegionId.forPosition(position.latitude, position.longitude);
});

/// true si tu región actual ya tiene el grafo vial descargado -- esto
/// es lo que gatea el botón de "Navegar" en el mapa.
final hasNavigationDataProvider = FutureProvider<bool>((ref) async {
  final region = await ref.watch(currentRoadRegionProvider.future);
  if (region == null) return false;
  return ref.read(roadRegionRepositoryProvider).isRegionDownloaded(region.id);
});

/// Posición GPS en vivo mientras hay una navegación activa -- vive acá
/// (no en `currentPositionProvider`, que es un solo fix) porque la
/// navegación necesita saber tu posición continuamente para avanzar
/// las instrucciones, incluso si todavía no arrancaste a grabar una
/// actividad.
final liveNavigationPositionProvider = StreamProvider<Position>((ref) {
  final service = ref.read(locationServiceProvider);
  return service.watchPosition();
});

/// Ruta activa -- null si no hay ninguna navegación en curso.
final activeNavigationRouteProvider = StateProvider<NavigationRoute?>(
  (ref) => null,
);

/// Índice de la próxima instrucción a mostrar/anunciar dentro de
/// `activeNavigationRouteProvider.instructions`.
final nextInstructionIndexProvider = StateProvider<int>((ref) => 0);

class NavigationController {
  final Ref ref;
  const NavigationController(this.ref);

  /// Calcula la ruta más corta entre dos puntos usando el grafo de la
  /// región donde cae `fromLat/fromLng`, y la deja activa en
  /// `activeNavigationRouteProvider`.
  Future<NavigationRoute> calculateRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final region = RoadRegionId.forPosition(fromLat, fromLng);
    if (region == null) {
      throw Exception(
        'No hay datos de navegación para tu zona actual. Descargá tu '
        'región desde Ajustes > Navegación.',
      );
    }

    final repo = ref.read(roadRegionRepositoryProvider);
    final graph = await repo.loadGraph(region.id);
    if (graph == null) {
      throw Exception(
        'Descargá primero el mapa de "${region.displayName}" desde '
        'Ajustes > Navegación.',
      );
    }

    final snapper = RouteSnapper(graph);
    final startSnap = snapper.nearestNode(fromLat, fromLng);
    final endSnap = snapper.nearestNode(toLat, toLng);

    final router = ChRouter(graph);
    final path = router.findPath(
      startNodeIndex: startSnap.nodeIndex,
      endNodeIndex: endSnap.nodeIndex,
    );

    if (path == null) {
      throw Exception(
        'No se encontró una ruta hacia ese destino dentro de la '
        'región descargada.',
      );
    }

    final route = TurnInstructionBuilder(graph).build(path);

    ref.read(activeNavigationRouteProvider.notifier).state = route;
    ref.read(nextInstructionIndexProvider.notifier).state = 0;

    return route;
  }

  void cancelNavigation() {
    ref.read(activeNavigationRouteProvider.notifier).state = null;
    ref.read(nextInstructionIndexProvider.notifier).state = 0;
  }
}

final navigationControllerProvider = Provider<NavigationController>((ref) {
  return NavigationController(ref);
});