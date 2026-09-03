import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/navigation/road_region_id.dart';
// currentPositionProvider y locationServiceProvider viven en
// geospatial/presentation/map_providers.dart -- mismo lugar de donde
// los importa elevation_providers.dart.
import '../../elevation/data/elevation_resolver.dart';
import '../../elevation/presentation/elevation_providers.dart';
import '../../geospatial/presentation/map_providers.dart';
import '../data/geocoding_service.dart';
import '../data/recent_destinations_store.dart';
import '../data/road_region_repository.dart';
import '../data/saved_places_repository.dart';
import '../domain/ch_router.dart';
import '../domain/climb_detection.dart';
import '../domain/navigation_route.dart';
import '../domain/navigation_target.dart';
import '../domain/route_preview.dart';
import '../domain/route_snapper.dart';
import '../domain/turn_instruction_builder.dart';

final roadRegionRepositoryProvider = Provider<RoadRegionRepository>((ref) {
  return RoadRegionRepository(ref.read(appDatabaseProvider));
});

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});

// --- Ubicaciones guardadas -----------------------------------------

final savedPlacesRepositoryProvider = Provider<SavedPlacesRepository>((ref) {
  return SavedPlacesRepository(ref.read(appDatabaseProvider));
});

/// Ubicaciones guardadas del usuario -- alimentan los chips del buscador
/// de "Navegar", las estrellas del mapa y la pantalla de Ajustes.
final savedPlacesProvider = StreamProvider<List<SavedPlace>>((ref) {
  return ref.watch(savedPlacesRepositoryProvider).watchAll();
});

// --- Destinos recientes ------------------------------------------------

final recentDestinationsStoreProvider = Provider<RecentDestinationsStore>((
  ref,
) {
  return RecentDestinationsStore();
});

/// Últimos ~5 destinos usados -- se re-lee cada vez que se abre el
/// buscador (`autoDispose`), no necesita reactividad en vivo.
final recentDestinationsProvider =
    FutureProvider.autoDispose<List<NavigationTarget>>((ref) {
      return ref.read(recentDestinationsStoreProvider).load();
    });

// --- Región / grafo vial ---------------------------------------------

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

/// Destino de la navegación activa (nombre + coords + tipo) -- se usa
/// para dibujar la montañita en el destino si es un alto. `null` cuando
/// no hay navegación.
final activeNavigationTargetProvider = StateProvider<NavigationTarget?>(
  (ref) => null,
);

/// Ruta ya calculada pero pendiente de confirmar -- lo que muestra la
/// tarjeta "Confirmar la ruta". `null` cuando no hay ninguna esperando.
final routePreviewProvider = StateProvider<RoutePreview?>((ref) => null);

/// Índice de la próxima instrucción a mostrar/anunciar dentro de
/// `activeNavigationRouteProvider.instructions`.
final nextInstructionIndexProvider = StateProvider<int>((ref) => 0);

class NavigationController {
  final Ref ref;
  const NavigationController(this.ref);

  /// Calcula la ruta más corta entre dos puntos usando el grafo de la
  /// región donde cae `fromLat/fromLng`. No la activa ni la deja en
  /// preview -- solo la devuelve.
  Future<NavigationRoute> _computeRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final region = RoadRegionId.forPosition(fromLat, fromLng);
    if (region == null) {
      throw Exception(
        'No hay datos de navegación para tu zona actual. Descarga tu '
        'región desde Ajustes > Navegación.',
      );
    }

    final repo = ref.read(roadRegionRepositoryProvider);
    final graph = await repo.loadGraph(region.id);
    if (graph == null) {
      throw Exception(
        'Descarga primero el mapa de "${region.displayName}" desde '
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

    return TurnInstructionBuilder(graph).build(path);
  }

  /// Calcula la ruta hacia [target] y la deja en
  /// `routePreviewProvider` para que el usuario la confirme -- junto
  /// con el perfil de altimetría estimado y si el destino es un alto.
  Future<void> previewRoute({
    required NavigationTarget target,
    required double fromLat,
    required double fromLng,
  }) async {
    final route = await _computeRoute(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: target.lat,
      toLng: target.lng,
    );

    final resolver = ref.read(elevationResolverProvider);
    await resolver.preload();

    final samples = _sampleElevation(route, resolver);
    final gain = _positiveGain(samples);
    final originAlt = resolver.resolve(fromLat, fromLng).altitudeMeters;
    final destAlt = resolver.resolve(target.lat, target.lng).altitudeMeters;

    ref.read(routePreviewProvider.notifier).state = RoutePreview(
      target: target,
      route: route,
      elevationSamples: samples,
      elevationGainMeters: gain,
      destinationAltitudeMeters: destAlt,
      isClimb: looksLikeClimb(
        target.name,
        destinationAltitudeMeters: destAlt,
        originAltitudeMeters: originAlt,
      ),
    );
  }

  /// Activa la ruta que estaba en preview y la registra como destino
  /// reciente.
  void startPreviewedRoute() {
    final preview = ref.read(routePreviewProvider);
    if (preview == null) return;

    ref.read(activeNavigationRouteProvider.notifier).state = preview.route;
    ref.read(activeNavigationTargetProvider.notifier).state = preview.target;
    ref.read(nextInstructionIndexProvider.notifier).state = 0;
    ref.read(routePreviewProvider.notifier).state = null;

    // Guardar el reciente en segundo plano -- si falla, no pasa nada.
    ref.read(recentDestinationsStoreProvider).add(preview.target);
  }

  void clearPreview() {
    ref.read(routePreviewProvider.notifier).state = null;
  }

  void cancelNavigation() {
    ref.read(activeNavigationRouteProvider.notifier).state = null;
    ref.read(activeNavigationTargetProvider.notifier).state = null;
    ref.read(routePreviewProvider.notifier).state = null;
    ref.read(nextInstructionIndexProvider.notifier).state = 0;
  }

  /// Muestrea la altitud (msnm) a lo largo de la polilínea de la ruta,
  /// contra la cadena de elevación (GPX > HGT). Devuelve `null` en los
  /// tramos sin datos.
  List<double?> _sampleElevation(
    NavigationRoute route,
    ElevationResolver resolver, {
    int maxSamples = 48,
  }) {
    final nodes = route.polyline;
    if (nodes.isEmpty) return const [];
    final step = (nodes.length / maxSamples).ceil().clamp(1, nodes.length);
    final out = <double?>[];
    for (var i = 0; i < nodes.length; i += step) {
      out.add(resolver.resolve(nodes[i].lat, nodes[i].lng).altitudeMeters);
    }
    return out;
  }

  double? _positiveGain(List<double?> samples) {
    double? previous;
    var gain = 0.0;
    var counted = 0;
    for (final alt in samples) {
      if (alt == null) continue;
      if (previous != null) {
        final delta = alt - previous;
        if (delta > 0) gain += delta;
        counted++;
      }
      previous = alt;
    }
    return counted >= 3 ? gain : null;
  }
}

final navigationControllerProvider = Provider<NavigationController>((ref) {
  return NavigationController(ref);
});
