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

/// Teselas de elevación de Copernicus GLO-30 descargadas al teléfono.
/// Cada una se registra con la clave `copernicus-glo30/<tesela>` y vive
/// en su propia carpeta.
class ElevationRepository {
  /// Modelo de las teselas: lo que antecede a cada clave de registro.
  static const datasetId = 'copernicus-glo30';

  /// Teselas que el ciclista pidió no volver a ofrecer al grabar (por
  /// ejemplo, porque su servidor no las tiene).
  static const _declinedKey = 'elevation_tiles_declined_v1';

  /// Preferencias de cuando hubo otros modelos de elevación: se borran en
  /// la limpieza.
  static const _obsoleteKeys = [
    'elevation_tile_datasets_v1',
    'elevation_dataset_v1',
    'activity_elevation_dataset_v1',
  ];

  /// La limpieza se hace una vez por ejecución de la app.
  static Future<void>? _cleanup;

  final AppDatabase database;
  final SrtmTileReader _reader = SrtmTileReader();

  /// Caché en memoria de "nombre de tesela -> ruta local", cargada una
  /// vez al iniciar una grabación. Es lo que permite que la consulta de
  /// elevación durante el pedaleo (`elevationAtSync`) sea 100% síncrona
  /// y rapidísima, sin tocar la base de datos en cada punto GPS.
  final Map<String, String> _catalogCache = {};

  ElevationRepository(this.database);

  /// Clave de registro de [tile].
  static String keyOf(SrtmTileId tile) => '$datasetId/${tile.fileName}';

  /// Nombre de archivo de una clave de registro.
  static String fileNameOf(String key) => key.substring(key.indexOf('/') + 1);

  Stream<List<DownloadedElevationTile>> watchDownloadedTiles() =>
      database.watchDownloadedTiles();

  /// Carga el catálogo completo a memoria. Llamar al iniciar una
  /// grabación (el catálogo es pequeño -- unas cuantas filas de texto --
  /// así que esto es instantáneo incluso con decenas de teselas).
  Future<void> preloadCatalog() async {
    await _removeObsoleteTiles();
    final tiles = await database.getAllDownloadedTiles();
    _catalogCache.clear();
    for (final tile in tiles) {
      if (tile.tileName.startsWith('$datasetId/')) {
        _catalogCache[fileNameOf(tile.tileName)] = tile.filePath;
      }
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
    await _removeObsoleteTiles();
    final needed = tilesForRadius(
      centerLat: centerLat,
      centerLng: centerLng,
      radiusKm: radiusKm,
    );

    final missing = <SrtmTileId>[];
    for (final tile in needed) {
      final entry = await database.getTile(keyOf(tile));
      // Registrada pero sin archivo, o con un archivo incompleto: para
      // la app es lo mismo que no tenerla, y se vuelve a ofrecer.
      if (entry == null || !await _isComplete(entry.filePath)) {
        missing.add(tile);
      }
    }
    return missing;
  }

  /// El archivo existe y mide lo que mide una tesela `.hgt` completa.
  static Future<bool> _isComplete(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    return SrtmTileReader.sideForLength(await file.length()) != null;
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

  /// Descarga una tesela desde TU bucket (nunca desde Copernicus
  /// directamente) y la registra en el catálogo local.
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
    final bytes = response.bodyBytes;
    if (SrtmTileReader.sideForLength(bytes.length) == null) {
      throw Exception(
        'La tesela ${tile.fileName} llegó incompleta '
        '(${bytes.length} bytes). Vuelve a descargarla.',
      );
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final tilesDir = Directory(
      p.join(docsDir.path, 'elevation_tiles', datasetId),
    );
    if (!await tilesDir.exists()) {
      await tilesDir.create(recursive: true);
    }

    // Se escribe aparte y se renombra al final: si la app se cierra a
    // mitad de la escritura, la tesela anterior (o ninguna) sigue ahí,
    // nunca un archivo a medias con el nombre bueno.
    final filePath = p.join(tilesDir.path, tile.fileName);
    final partial = File('$filePath.descargando');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(filePath);
    _reader.forget(filePath);
    await _forgetDeclined(tile);

    await database.upsertTile(
      DownloadedElevationTilesCompanion.insert(
        tileName: keyOf(tile),
        filePath: filePath,
        sizeBytes: bytes.length,
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

  /// Borra una tesela por su clave de registro.
  Future<void> deleteTile(String key) async {
    final entry = await database.getTile(key);
    if (entry != null) {
      _reader.forget(entry.filePath);
      final file = File(entry.filePath);
      if (await file.exists()) await file.delete();
    }
    await database.deleteTile(key);
    _catalogCache.remove(fileNameOf(key));
  }

  /// La app usó antes otros modelos de elevación. Sus teselas se borran
  /// del teléfono -- el registro y el archivo -- y quedan solo las de
  /// Copernicus.
  Future<void> _removeObsoleteTiles() =>
      _cleanup ??= _runCleanup().catchError((Object _) {
        _cleanup = null; // se reintenta la próxima vez
      });

  Future<void> _runCleanup() async {
    final rows = await database.getAllDownloadedTiles();
    for (final row in rows) {
      if (row.tileName.startsWith('$datasetId/')) continue;
      _reader.forget(row.filePath);
      final file = File(row.filePath);
      if (await file.exists()) await file.delete();
      await database.deleteTile(row.tileName);
    }
    final prefs = await SharedPreferences.getInstance();
    for (final key in _obsoleteKeys) {
      await prefs.remove(key);
    }
  }
}
