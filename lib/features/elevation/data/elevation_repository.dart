import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/elevation/srtm_tile_naming.dart';
import '../../../core/elevation/srtm_tile_reader.dart';

class ElevationRepository {
  final AppDatabase database;
  final SrtmTileReader _reader = SrtmTileReader();

  /// Caché en memoria de "nombre de tesela -> ruta local", cargada una
  /// vez al iniciar una grabación. Es lo que permite que la consulta de
  /// elevación durante el pedaleo (`elevationAtSync`) sea 100% síncrona
  /// y rapidísima, sin tocar la base de datos en cada punto GPS.
  final Map<String, String> _catalogCache = {};

  ElevationRepository(this.database);

  Stream<List<DownloadedElevationTile>> watchDownloadedTiles() =>
      database.watchDownloadedTiles();

  /// Carga el catálogo completo a memoria. Llamar al iniciar una
  /// grabación (el catálogo es pequeño -- unas cuantas filas de texto --
  /// así que esto es instantáneo incluso con decenas de teselas).
  Future<void> preloadCatalog() async {
    final tiles = await database.getAllDownloadedTiles();
    _catalogCache.clear();
    for (final tile in tiles) {
      _catalogCache[tile.tileName] = tile.filePath;
    }
  }

  /// Altitud confiable (DEM) en (lat, lng), o null si esa tesela no está
  /// en el caché (no descargada) -- el llamador debe hacer fallback a
  /// GPS/barómetro en ese caso. Totalmente síncrono: seguro de llamar
  /// dentro del callback de cada punto GPS nuevo.
  double? elevationAtSync(double lat, double lng) {
    final tileId = SrtmTileId.fromLatLng(lat, lng);
    final filePath = _catalogCache[tileId.fileName];
    if (filePath == null) return null;

    return _reader.elevationAt(
      filePath: filePath,
      tileLatFloor: tileId.latFloor,
      tileLngFloor: tileId.lngFloor,
      lat: lat,
      lng: lng,
    );
  }

  /// Teselas que faltan por descargar para cubrir un radio alrededor de
  /// una posición (consulta la BD directamente, no el caché en memoria,
  /// porque esto se llama antes de grabar, no durante).
  Future<List<SrtmTileId>> missingTilesForRadius({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  }) async {
    final needed = tilesForRadius(
      centerLat: centerLat,
      centerLng: centerLng,
      radiusKm: radiusKm,
    );

    final missing = <SrtmTileId>[];
    for (final tile in needed) {
      final entry = await database.getTile(tile.fileName);
      if (entry == null) missing.add(tile);
    }
    return missing;
  }

  /// Descarga una tesela desde TU bucket (nunca desde NASA directamente)
  /// y la registra en el catálogo local.
  Future<void> downloadTile(SrtmTileId tile) async {
    final uri = Uri.parse(
      '${AppConfig.elevationTilesBaseUrl}/${tile.fileName}',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo descargar la tesela ${tile.fileName} '
        '(HTTP ${response.statusCode}).',
      );
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final tilesDir = Directory(p.join(docsDir.path, 'elevation_tiles'));
    if (!await tilesDir.exists()) {
      await tilesDir.create(recursive: true);
    }

    final filePath = p.join(tilesDir.path, tile.fileName);
    await File(filePath).writeAsBytes(response.bodyBytes);

    await database.upsertTile(
      DownloadedElevationTilesCompanion.insert(
        tileName: tile.fileName,
        filePath: filePath,
        sizeBytes: response.bodyBytes.length,
        downloadedAt: DateTime.now(),
      ),
    );
  }

  /// Descarga varias teselas en secuencia, reportando progreso (0.0 a
  /// 1.0) — usado por el popup de descarga.
  Future<void> downloadTiles(
    List<SrtmTileId> tiles, {
    void Function(double progress)? onProgress,
  }) async {
    for (int i = 0; i < tiles.length; i++) {
      await downloadTile(tiles[i]);
      onProgress?.call((i + 1) / tiles.length);
    }
  }

  Future<void> deleteTile(String tileName) async {
    final entry = await database.getTile(tileName);
    if (entry != null) {
      final file = File(entry.filePath);
      if (await file.exists()) await file.delete();
    }
    await database.deleteTile(tileName);
    _catalogCache.remove(tileName);
  }
}
