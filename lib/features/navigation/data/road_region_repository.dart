import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/platform.dart';
import '../../../core/database/database.dart';
import '../domain/navigation_route.dart';
import '../domain/road_region.dart';
import 'route_worker.dart';

/// Lo que se sabe del catálogo de regiones: el último que se leyó y si
/// el servidor contestó ahora o es la copia guardada en el teléfono.
class CatalogSnapshot {
  final RegionCatalog catalog;
  final bool online;

  const CatalogSnapshot(this.catalog, {required this.online});
}

/// Los mapas viales descargables: el catálogo que publica el servidor
/// (`<roadRegionsBaseUrl>/regiones.json`), la descarga de cada región y
/// el isolate de ruteo que usa el mapa descargado.
///
/// El servidor es la carpeta "Servidor CycleCore" del escritorio
/// (INICIAR SERVIDOR.bat). Sin servidor, lo ya descargado sigue
/// funcionando: el catálogo queda guardado en el teléfono.
class RoadRegionRepository {
  final AppDatabase database;

  RoadRegionRepository(this.database);

  static const _versionsKey = 'road_region_versions_v1';

  /// Un solo isolate de ruteo a la vez (ver `RouteWorker`): cada mapa
  /// cargado ocupa ~150 MB, así que al cambiar de región se suelta el
  /// anterior.
  String? _workerRegion;
  Future<RouteWorker>? _worker;
  bool _workerReady = false;

  Future<Directory> _folder() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'road_regions'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // --- Catálogo -------------------------------------------------------

  /// El catálogo del servidor; si no contesta, la última copia que mandó
  /// (guardada en el teléfono). La lista de mapas sale siempre del
  /// servidor: la app no trae ninguna escrita.
  Future<CatalogSnapshot> loadCatalog() async {
    final dir = await _folder();
    final cached = File(p.join(dir.path, 'regiones.json'));
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.roadRegionsBaseUrl}/regiones.json'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final text = utf8.decode(response.bodyBytes);
        final catalog = RegionCatalog.parse(text);
        await cached.writeAsString(text);
        return CatalogSnapshot(catalog, online: true);
      }
    } catch (_) {
      // Sin servidor: se sigue con la copia guardada.
    }
    if (await cached.exists()) {
      try {
        final catalog = RegionCatalog.parse(await cached.readAsString());
        return CatalogSnapshot(catalog, online: false);
      } catch (_) {
        // Copia dañada: como si no hubiera.
      }
    }
    return const CatalogSnapshot(RegionCatalog.empty, online: false);
  }

  // --- Descargas ------------------------------------------------------

  Stream<List<DownloadedRoadRegion>> watchDownloadedRegions() =>
      database.watchDownloadedRoadRegions();

  /// Versión instalada de cada región descargada.
  Future<Map<String, String>> installedVersions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_versionsKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).cast<String, String>();
  }

  Future<void> _setInstalledVersion(String regionId, String? version) async {
    final prefs = await SharedPreferences.getInstance();
    final versions = await installedVersions();
    if (version == null) {
      versions.remove(regionId);
    } else {
      versions[regionId] = version;
    }
    await prefs.setString(_versionsKey, jsonEncode(versions));
  }

  /// Descarga el mapa de [region] y lo registra en la base local.
  ///
  /// Se baja comprimido y se descomprime mientras llega, directo a
  /// disco; `onProgress` va de 0 a 1 con lo recibido. Se escribe a un
  /// archivo temporal y se reemplaza al final: si la descarga se corta,
  /// el mapa anterior sigue sirviendo.
  Future<void> downloadRegion(
    RoadRegion region, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await _folder();
    final filePath = p.join(dir.path, '${region.id}.roadgraph');
    final partial = File('$filePath.descargando');
    final uri = Uri.parse('${AppConfig.roadRegionsBaseUrl}/${region.fileName}');
    final client = http.Client();

    var written = 0;
    try {
      final response = await client.send(http.Request('GET', uri));
      if (response.statusCode != 200) {
        throw Exception(
          'El servidor no tiene el mapa de ${region.name} '
          '(HTTP ${response.statusCode}).',
        );
      }
      final total = response.contentLength ?? region.downloadBytes;
      var received = 0;
      final counted = response.stream.map((chunk) {
        received += chunk.length;
        if (total > 0) onProgress?.call((received / total).clamp(0.0, 0.99));
        return chunk;
      });
      final bytes = region.fileName.endsWith('.gz')
          ? counted.transform(gzip.decoder)
          : counted;
      final sink = partial.openWrite();
      try {
        await for (final chunk in bytes) {
          sink.add(chunk);
          written += chunk.length;
        }
      } finally {
        await sink.close();
      }
    } on SocketException {
      if (await partial.exists()) await partial.delete();
      throw Exception(
        'No hay conexión con el servidor. Conecta el celular y abre '
        'INICIAR SERVIDOR.bat en el PC.',
      );
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    } finally {
      client.close();
    }

    // El mapa viejo deja de usarse antes de reemplazar su archivo.
    await _dropWorker(region.id);
    await partial.rename(filePath);
    await database.upsertRoadRegion(
      DownloadedRoadRegionsCompanion.insert(
        regionId: region.id,
        filePath: filePath,
        sizeBytes: written,
        downloadedAt: DateTime.now(),
      ),
    );
    await _setInstalledVersion(region.id, region.version);
    onProgress?.call(1.0);
  }

  Future<void> deleteRegion(String regionId) async {
    final entry = await database.getRoadRegion(regionId);
    if (entry != null) {
      final file = File(entry.filePath);
      if (await file.exists()) await file.delete();
    }
    await database.deleteRoadRegion(regionId);
    await _setInstalledVersion(regionId, null);
    await _dropWorker(regionId);
  }

  // --- Ruteo ----------------------------------------------------------

  /// true si el mapa de [regionId] ya está cargado y la próxima ruta
  /// sale de inmediato (si no, primero hay que cargarlo).
  bool isLoaded(String regionId) => _workerRegion == regionId && _workerReady;

  /// Deja cargando el mapa de [regionId] sin esperar, para que la ruta
  /// salga enseguida cuando el ciclista la pida.
  Future<void> warmUp(String regionId) async {
    try {
      await _workerFor(regionId);
    } catch (_) {
      // Se reintenta al pedir la ruta, con el error a la vista.
    }
  }

  /// Ruta entre dos coordenadas con el mapa de [regionId]; `null` si esa
  /// región no está descargada.
  Future<NavigationRoute?> route(
    String regionId, {
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final worker = await _workerFor(regionId);
    if (worker == null) return null;
    return worker.route(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
  }

  Future<RouteWorker?> _workerFor(String regionId) async {
    if (_workerRegion == regionId && _worker != null) return _worker;
    final entry = await database.getRoadRegion(regionId);
    if (entry == null) return null;
    await _dropWorker(_workerRegion);
    _workerRegion = regionId;
    _workerReady = false;
    final starting = _worker = RouteWorker.start(entry.filePath);
    try {
      final worker = await starting;
      if (identical(starting, _worker)) _workerReady = true;
      return worker;
    } catch (_) {
      if (identical(starting, _worker)) {
        _worker = null;
        _workerRegion = null;
      }
      rethrow;
    }
  }

  Future<void> _dropWorker(String? regionId) async {
    if (regionId == null || regionId != _workerRegion) return;
    final worker = _worker;
    _worker = null;
    _workerRegion = null;
    _workerReady = false;
    if (worker == null) return;
    try {
      (await worker).dispose();
    } catch (_) {
      // Nunca terminó de arrancar: no hay nada que cerrar.
    }
  }
}
