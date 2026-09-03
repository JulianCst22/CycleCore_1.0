import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// TODO(verify): ajustá esta ruta a donde tengas AppConfig real. Este
// repositorio necesita un campo nuevo, `roadRegionsBaseUrl`, con la
// misma idea que `elevationTilesBaseUrl` -- la URL base de tu bucket
// donde vas a subir los archivos `.roadgraph` ya preprocesados.
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/navigation/road_region_id.dart';
import '../domain/road_graph.dart';

class RoadRegionRepository {
  final AppDatabase database;

  /// Caché en memoria del grafo ya parseado, por región -- a
  /// diferencia de ElevationRepository (que solo cachea la ruta del
  /// archivo porque leer un punto de un .hgt es barato), acá sí vale
  /// la pena cachear el grafo completo porque parsear el binario tiene
  /// un costo que no querés pagar en cada cálculo de ruta.
  final Map<String, RoadGraph> _graphCache = {};

  RoadRegionRepository(this.database);

  Stream<List<DownloadedRoadRegion>> watchDownloadedRegions() =>
      database.watchDownloadedRoadRegions();

  Future<bool> isRegionDownloaded(String regionId) async {
    final entry = await database.getRoadRegion(regionId);
    return entry != null;
  }

  /// Descarga el `.roadgraph` de una región y lo registra en la base
  /// local. `onProgress` solo reporta 0.0 -> 1.0 al terminar (el
  /// archivo se baja de una sola vez con `http.get`); si tus archivos
  /// terminan siendo grandes (>20MB), conviene cambiar esto a
  /// streaming con `http.Client().send()` para progreso real.
  Future<void> downloadRegion(
    RoadRegionId region, {
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.roadRegionsBaseUrl}/${region.fileName}',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo descargar el mapa de "${region.displayName}" '
        '(HTTP ${response.statusCode}).',
      );
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'road_regions'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final filePath = p.join(dir.path, region.fileName);
    await File(filePath).writeAsBytes(response.bodyBytes);

    await database.upsertRoadRegion(
      DownloadedRoadRegionsCompanion.insert(
        regionId: region.id,
        filePath: filePath,
        sizeBytes: response.bodyBytes.length,
        downloadedAt: DateTime.now(),
      ),
    );

    // Si ya había un grafo viejo de esta región en memoria (ej.
    // re-descarga tras una actualización), lo invalidamos.
    _graphCache.remove(region.id);
    onProgress?.call(1.0);
  }

  Future<void> deleteRegion(String regionId) async {
    final entry = await database.getRoadRegion(regionId);
    if (entry != null) {
      final file = File(entry.filePath);
      if (await file.exists()) await file.delete();
    }
    await database.deleteRoadRegion(regionId);
    _graphCache.remove(regionId);
  }

  /// Grafo ya parseado y listo para el router -- null si esa región
  /// todavía no está descargada.
  Future<RoadGraph?> loadGraph(String regionId) async {
    final cached = _graphCache[regionId];
    if (cached != null) return cached;

    final entry = await database.getRoadRegion(regionId);
    if (entry == null) return null;

    final graph = await RoadGraph.loadFromFile(entry.filePath);
    _graphCache[regionId] = graph;
    return graph;
  }
}
