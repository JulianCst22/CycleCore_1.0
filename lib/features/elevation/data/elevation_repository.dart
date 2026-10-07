import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/platform.dart';
import '../../../core/database/database.dart';
import '../domain/srtm_tile_naming.dart';
import 'srtm_tile_reader.dart';

/// Cómo terminó una descarga de teselas.
class ElevationDownloadResult {
  /// Las que no se pudieron bajar (no están en el servidor, sin red...).
  final List<SrtmTileId> failed;

  /// El primer error, para mostrarlo.
  final String? firstError;

  const ElevationDownloadResult({this.failed = const [], this.firstError});

  bool get ok => failed.isEmpty;
}

class ElevationRepository {
  /// Teselas que el ciclista pidió no volver a ofrecer al grabar (por
  /// ejemplo, porque su servidor no las tiene).
  static const _declinedKey = 'elevation_tiles_declined_v1';

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
      // Registrada pero sin archivo (se borró, o la descarga quedó a
      // medias): para la app es lo mismo que no tenerla.
      if (entry == null || !await File(entry.filePath).exists()) {
        missing.add(tile);
      }
    }
    return missing;
  }

  /// Teselas que el ciclista pidió no volver a ofrecer antes de grabar.
  Future<Set<String>> declinedTiles() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_declinedKey) ?? const []).toSet();
  }

  Future<void> declineTiles(Iterable<SrtmTileId> tiles) async {
    final prefs = await SharedPreferences.getInstance();
    final declined = (prefs.getStringList(_declinedKey) ?? const []).toSet()
      ..addAll(tiles.map((t) => t.fileName));
    await prefs.setStringList(_declinedKey, declined.toList());
  }

  Future<void> _forgetDeclined(SrtmTileId tile) async {
    final prefs = await SharedPreferences.getInstance();
    final declined = prefs.getStringList(_declinedKey);
    if (declined == null || !declined.contains(tile.fileName)) return;
    await prefs.setStringList(
      _declinedKey,
      declined.where((name) => name != tile.fileName).toList(),
    );
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
    await _forgetDeclined(tile);

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
  /// 1.0). Si una falla se sigue con las demás: antes la primera que no
  /// estaba en el servidor cortaba todo, y las que sí estaban tampoco
  /// se bajaban.
  Future<ElevationDownloadResult> downloadTiles(
    List<SrtmTileId> tiles, {
    void Function(double progress)? onProgress,
  }) async {
    final failed = <SrtmTileId>[];
    String? firstError;
    for (int i = 0; i < tiles.length; i++) {
      try {
        await downloadTile(tiles[i]);
      } catch (e) {
        failed.add(tiles[i]);
        firstError ??= e is SocketException
            ? 'No hay conexión con el servidor de teselas.'
            : '$e';
      }
      onProgress?.call((i + 1) / tiles.length);
    }
    return ElevationDownloadResult(failed: failed, firstError: firstError);
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
