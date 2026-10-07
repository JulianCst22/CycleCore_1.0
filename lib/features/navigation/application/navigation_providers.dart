import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/database/database.dart';
import '../../../core/platform/platform.dart';
import '../../elevation/elevation.dart';
import '../data/geocoding_service.dart';
import '../data/recent_destinations_store.dart';
import '../data/route_worker.dart' show OutsideMapException;
import '../data/saved_places_repository.dart';
import '../domain/climb_detection.dart';
import '../domain/navigation_route.dart';
import '../domain/navigation_target.dart';
import '../domain/route_preview.dart';
import 'road_region_providers.dart';

export 'road_region_providers.dart';

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

/// true si hay un mapa descargado que cubre tu posición -- esto es lo
/// que muestra el botón de "Navegar" en el mapa. Un mapa que ya no está
/// en el catálogo (el viejo de "Bogotá y Cundinamarca" en formato RGF1)
/// no cuenta: hay que bajar el nuevo.
final hasNavigationDataProvider = FutureProvider<bool>((ref) async {
  final downloaded = await ref.watch(downloadedRegionsProvider.future);
  if (downloaded.isEmpty) return false;
  final position = await ref.watch(currentPositionProvider.future);
  final snapshot = await ref.watch(regionCatalogProvider.future);
  return snapshot.catalog.regionForRoute(
        downloaded: downloaded.map((d) => d.regionId),
        fromLat: position.latitude,
        fromLng: position.longitude,
      ) !=
      null;
});

/// Por qué no se puede calcular una ruta, dicho para el ciclista.
class RouteUnavailableException implements Exception {
  final String message;
  const RouteUnavailableException(this.message);

  @override
  String toString() => message;
}

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

/// En qué va el cálculo de una ruta: es lo que cuenta la animación
/// mientras tanto.
enum RouteComputeStage {
  /// Cargando el grafo de la región (solo la primera vez).
  loadingMap,

  /// Buscando la ruta por vías principales y pavimentadas.
  routing,

  /// Calculando la altimetría y si el destino es un alto.
  profile,
}

/// Ruta que se está calculando: a dónde y en qué paso va. `null` si no
/// se está calculando ninguna.
final routeComputingProvider =
    StateProvider<({NavigationTarget target, RouteComputeStage stage})?>(
      (ref) => null,
    );

/// Índice de la próxima instrucción a mostrar/anunciar dentro de
/// `activeNavigationRouteProvider.instructions`.
final nextInstructionIndexProvider = StateProvider<int>((ref) => 0);

class NavigationController {
  final Ref ref;
  const NavigationController(this.ref);

  /// Cuál es el cálculo vigente. Si el ciclista cancela o pide otro
  /// destino, el resultado del anterior llega igual (el isolate no se
  /// puede interrumpir), pero se descarta.
  static int _generation = 0;

  /// Deja cargando el mapa de tu región para que la primera ruta salga
  /// sin esperar. Se llama al abrir el buscador de destino.
  Future<void> warmUp() async {
    final position = await ref.read(currentPositionProvider.future);
    final regionId = await _regionFor(position.latitude, position.longitude);
    if (regionId == null) return;
    await ref.read(roadRegionRepositoryProvider).warmUp(regionId);
  }

  Future<String?> _regionFor(
    double fromLat,
    double fromLng, [
    double? toLat,
    double? toLng,
  ]) async {
    final downloaded = await ref.read(downloadedRegionsProvider.future);
    final snapshot = await ref.read(regionCatalogProvider.future);
    return snapshot.catalog.regionForRoute(
      downloaded: downloaded.map((d) => d.regionId),
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
  }

  /// Nombre del lugar donde cae un punto según el catálogo ("Boyacá").
  Future<String?> _placeName(double lat, double lng) async {
    final snapshot = await ref.read(regionCatalogProvider.future);
    final found = snapshot.catalog.locate(lat, lng);
    return found?.part?.name ?? found?.region.name;
  }

  /// Deja de esperar la ruta que se estaba calculando.
  void cancelComputing() {
    _generation++;
    ref.read(routeComputingProvider.notifier).state = null;
  }

  /// Calcula la ruta entre dos puntos con el grafo de la región donde
  /// cae `fromLat/fromLng`. No la activa ni la deja en preview -- solo
  /// la devuelve.
  Future<NavigationRoute> _computeRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required void Function(RouteComputeStage stage) onStage,
  }) async {
    final regionId = await _regionFor(fromLat, fromLng, toLat, toLng);
    if (regionId == null) {
      final here = await _placeName(fromLat, fromLng);
      throw RouteUnavailableException(
        'No tienes descargado el mapa de ${here ?? 'esta zona'}. '
        'Descárgalo en Ajustes › Navegación.',
      );
    }

    final repo = ref.read(roadRegionRepositoryProvider);
    if (!repo.isLoaded(regionId)) onStage(RouteComputeStage.loadingMap);
    final route = repo.route(
      regionId,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
    if (repo.isLoaded(regionId)) onStage(RouteComputeStage.routing);
    final NavigationRoute? result;
    try {
      result = await route;
    } on OutsideMapException catch (e) {
      final place = e.destination
          ? await _placeName(toLat, toLng)
          : await _placeName(fromLat, fromLng);
      throw RouteUnavailableException(
        e.destination
            ? 'El destino queda en ${place ?? 'otra región'}, por fuera del '
                  'mapa que tienes. Descarga ese mapa en Ajustes › Navegación.'
            : 'Estás en ${place ?? 'otra región'}: descarga ese mapa en '
                  'Ajustes › Navegación.',
      );
    }
    if (result == null) {
      throw const RouteUnavailableException(
        'Descarga primero el mapa de tu zona en Ajustes › Navegación.',
      );
    }
    return result;
  }

  /// Calcula la ruta hacia [target] y la deja en
  /// `routePreviewProvider` para que el usuario la confirme -- junto
  /// con el perfil de altimetría estimado y si el destino es un alto.
  ///
  /// Mientras tanto `routeComputingProvider` dice en qué va, para la
  /// animación.
  Future<void> previewRoute({
    required NavigationTarget target,
    required double fromLat,
    required double fromLng,
  }) async {
    final generation = ++_generation;
    final computing = ref.read(routeComputingProvider.notifier);
    bool current() => generation == _generation;
    void stage(RouteComputeStage s) {
      if (current()) computing.state = (target: target, stage: s);
    }

    ref.read(routePreviewProvider.notifier).state = null;
    stage(RouteComputeStage.routing);
    try {
      final route = await _computeRoute(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: target.lat,
        toLng: target.lng,
        onStage: stage,
      );
      if (!current()) return;

      stage(RouteComputeStage.profile);
      final resolver = ref.read(elevationResolverProvider);
      await resolver.preload();
      if (!current()) return;

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
    } finally {
      if (current()) computing.state = null;
    }
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
    cancelComputing();
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
