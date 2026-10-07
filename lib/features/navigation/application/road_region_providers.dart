import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/platform/platform.dart';
import '../data/road_region_repository.dart';
import '../domain/road_region.dart';

export '../data/road_region_repository.dart' show CatalogSnapshot;
export '../domain/road_region.dart';

final roadRegionRepositoryProvider = Provider<RoadRegionRepository>((ref) {
  return RoadRegionRepository(ref.read(appDatabaseProvider));
});

/// El catálogo de regiones: del servidor si contesta, si no la copia
/// guardada en el teléfono. Ajustes › Navegación lo vuelve a pedir al
/// entrar (`ref.invalidate`), por si se acaba de prender el servidor.
final regionCatalogProvider = FutureProvider<CatalogSnapshot>((ref) {
  return ref.watch(roadRegionRepositoryProvider).loadCatalog();
});

/// Regiones descargadas en el teléfono.
final downloadedRegionsProvider = StreamProvider<List<DownloadedRoadRegion>>((
  ref,
) {
  return ref.watch(roadRegionRepositoryProvider).watchDownloadedRegions();
});

/// Versión instalada de cada región descargada (para ofrecer
/// "Actualizar" cuando el catálogo trae una más nueva).
final installedRegionVersionsProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  await ref.watch(downloadedRegionsProvider.future);
  return ref.read(roadRegionRepositoryProvider).installedVersions();
});

/// Dónde estás según el catálogo: la región y, si se sabe, el
/// departamento exacto ("Estás en Bogotá" dentro de "Bogotá y
/// Cundinamarca"). `null` si el catálogo no tiene tu zona.
final currentRegionProvider =
    FutureProvider<({RoadRegion region, RegionPart? part})?>((ref) async {
      final position = await ref.watch(currentPositionProvider.future);
      final snapshot = await ref.watch(regionCatalogProvider.future);
      return snapshot.catalog.locate(position.latitude, position.longitude);
    });

/// Estado de una región en el teléfono.
enum RegionStatus { notDownloaded, downloaded, outdated }

RegionStatus regionStatus(
  RoadRegion region,
  Set<String> downloaded,
  Map<String, String> versions,
) {
  if (!downloaded.contains(region.id)) return RegionStatus.notDownloaded;
  return versions[region.id] == region.version
      ? RegionStatus.downloaded
      : RegionStatus.outdated;
}

/// Una descarga en curso o que falló.
class RegionDownload {
  final double progress;
  final String? error;

  const RegionDownload({this.progress = 0, this.error});

  bool get failed => error != null;
}

/// Las descargas de mapas, compartidas por todas las pantallas: si el
/// ciclista sale de la lista mientras baja Boyacá, la descarga sigue y
/// el progreso se ve igual al volver.
class RegionDownloads extends StateNotifier<Map<String, RegionDownload>> {
  RegionDownloads(this._ref) : super(const {});

  final Ref _ref;

  bool isDownloading(String id) => state[id] != null && !(state[id]!.failed);

  Future<void> download(RoadRegion region) async {
    if (isDownloading(region.id)) return;
    _set(region.id, const RegionDownload());
    try {
      // Se vuelve a preguntar al servidor cada vez: puede que se haya
      // prendido después de abrir la pantalla, y lo que se baja tiene que
      // ser lo que él publica ahora (archivo y versión), no la copia.
      final snapshot = await _ref.refresh(regionCatalogProvider.future);
      if (!snapshot.online) {
        throw Exception(
          'No hay conexión con el servidor. Conecta el celular por USB y '
          'abre INICIAR SERVIDOR.bat en el PC.',
        );
      }
      final target = snapshot.catalog.byId(region.id);
      if (target == null) {
        throw Exception('El servidor ya no tiene el mapa de ${region.name}.');
      }
      await _ref
          .read(roadRegionRepositoryProvider)
          .downloadRegion(
            target,
            onProgress: (p) => _set(region.id, RegionDownload(progress: p)),
          );
      _clear(region.id);
    } catch (e) {
      _set(
        region.id,
        RegionDownload(error: e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  Future<void> delete(String regionId) async {
    await _ref.read(roadRegionRepositoryProvider).deleteRegion(regionId);
    _clear(regionId);
  }

  void dismissError(String regionId) => _clear(regionId);

  void _set(String id, RegionDownload value) {
    if (!mounted) return;
    state = {...state, id: value};
  }

  void _clear(String id) {
    if (!mounted) return;
    state = {...state}..remove(id);
  }
}

final regionDownloadsProvider =
    StateNotifierProvider<RegionDownloads, Map<String, RegionDownload>>(
      RegionDownloads.new,
    );
