import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/platform.dart';
import '../../../core/database/database.dart';
import '../domain/elevation_dataset.dart';
import '../domain/srtm_tile_naming.dart';
import 'elevation_dataset_preference.dart';
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

/// Teselas de elevación descargadas, de cada modelo
/// (`ElevationDataset`). Los dos modelos pueden estar en el teléfono a la
/// vez: cada tesela se registra con la clave `<modelo>/<tesela>` (por
/// ejemplo `fabdem-v1-2/N04W075.hgt`) y vive en su propia carpeta.
///
/// Los métodos trabajan con el modelo que se les pase o, si no, con el
/// que eligió el ciclista (`ElevationDatasetPreference`).
class ElevationRepository {
  /// Teselas que el ciclista pidió no volver a ofrecer al grabar (por
  /// ejemplo, porque su servidor no las tiene). Guarda claves de registro.
  static const _declinedKey = 'elevation_tiles_declined_v1';

  /// De cuando había un solo modelo: qué modelo era cada tesela (nombre ->
  /// id). Solo se lee para migrar las teselas de antes.
  static const _legacyDatasetsKey = 'elevation_tile_datasets_v1';

  /// Modelo con que quedan registradas las teselas de antes que no eran
  /// de ningún modelo actual: las SRTM de la NASA.
  static const legacyDatasetId = 'srtm';

  /// La migración se hace una vez por ejecución de la app, aunque haya
  /// varios repositorios (el de la grabación y el de "Ajustar
  /// altimetría"): dos a la vez moverían los mismos archivos.
  static Future<void>? _migration;

  final AppDatabase database;
  final SrtmTileReader _reader = SrtmTileReader();

  /// Caché en memoria de "nombre de tesela -> ruta local" del modelo
  /// cargado, armada una vez al iniciar una grabación. Es lo que permite
  /// que la consulta de elevación durante el pedaleo (`elevationAtSync`)
  /// sea 100% síncrona y rapidísima, sin tocar la base de datos en cada
  /// punto GPS.
  final Map<String, String> _catalogCache = {};
  ElevationDataset? _loaded;

  ElevationRepository(this.database);

  /// Modelo con el que quedó cargado el caché (el del último
  /// [preloadCatalog]).
  ElevationDataset? get loadedDataset => _loaded;

  /// Clave de registro de [tile] en [dataset].
  static String keyOf(ElevationDataset dataset, SrtmTileId tile) =>
      '${dataset.id}/${tile.fileName}';

  /// Modelo (id) y nombre de archivo de una clave de registro.
  static ({String datasetId, String fileName}) splitKey(String key) {
    final slash = key.indexOf('/');
    if (slash < 0) return (datasetId: legacyDatasetId, fileName: key);
    return (
      datasetId: key.substring(0, slash),
      fileName: key.substring(slash + 1),
    );
  }

  static String _baseUrlOf(ElevationDataset dataset) => switch (dataset) {
    ElevationDataset.copernicus => AppConfig.copernicusTilesBaseUrl,
    ElevationDataset.fabdem => AppConfig.fabdemTilesBaseUrl,
  };

  Stream<List<DownloadedElevationTile>> watchDownloadedTiles() =>
      database.watchDownloadedTiles();

  /// Carga a memoria las teselas de [dataset] (o del modelo elegido).
  /// Llamar al iniciar una grabación o antes de re-aplanar una actividad.
  Future<void> preloadCatalog({ElevationDataset? dataset}) async {
    await _migrateLegacyTiles();
    final target = dataset ?? await ElevationDatasetPreference.load();
    final tiles = await database.getAllDownloadedTiles();
    _catalogCache.clear();
    for (final tile in tiles) {
      final key = splitKey(tile.tileName);
      if (key.datasetId == target.id) {
        _catalogCache[key.fileName] = tile.filePath;
      }
    }
    _loaded = target;
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

  /// Teselas de [dataset] (o del modelo elegido) que faltan para cubrir
  /// un radio alrededor de una posición (consulta la BD directamente, no
  /// el caché en memoria, porque esto se llama antes de grabar, no
  /// durante).
  Future<List<SrtmTileId>> missingTilesForRadius({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    ElevationDataset? dataset,
  }) async {
    await _migrateLegacyTiles();
    final target = dataset ?? await ElevationDatasetPreference.load();
    final needed = tilesForRadius(
      centerLat: centerLat,
      centerLng: centerLng,
      radiusKm: radiusKm,
    );

    final missing = <SrtmTileId>[];
    for (final tile in needed) {
      final entry = await database.getTile(keyOf(target, tile));
      // Registrada pero sin archivo, o con un archivo incompleto: para
      // la app es lo mismo que no tenerla, y se vuelve a ofrecer.
      if (entry == null || !await _isComplete(entry.filePath)) {
        missing.add(tile);
      }
    }
    return missing;
  }

  /// El archivo existe y mide lo que mide una tesela SRTM completa.
  static Future<bool> _isComplete(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    return SrtmTileReader.sideForLength(await file.length()) != null;
  }

  /// Teselas de [dataset] (o del modelo elegido) que el ciclista pidió
  /// no volver a ofrecer antes de grabar (nombres de archivo).
  Future<Set<String>> declinedTiles({ElevationDataset? dataset}) async {
    final target = dataset ?? await ElevationDatasetPreference.load();
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final key in prefs.getStringList(_declinedKey) ?? const <String>[])
        if (splitKey(key).datasetId == target.id) splitKey(key).fileName,
    };
  }

  Future<void> declineTiles(
    Iterable<SrtmTileId> tiles, {
    ElevationDataset? dataset,
  }) async {
    final target = dataset ?? await ElevationDatasetPreference.load();
    final prefs = await SharedPreferences.getInstance();
    final declined = (prefs.getStringList(_declinedKey) ?? const []).toSet()
      ..addAll(tiles.map((t) => keyOf(target, t)));
    await prefs.setStringList(_declinedKey, declined.toList());
  }

  Future<void> _forgetDeclined(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final declined = prefs.getStringList(_declinedKey);
    if (declined == null || !declined.contains(key)) return;
    await prefs.setStringList(
      _declinedKey,
      declined.where((name) => name != key).toList(),
    );
  }

  /// Descarga una tesela de [dataset] (o del modelo elegido) desde TU
  /// bucket (nunca desde NASA ni Copernicus directamente) y la registra en
  /// el catálogo local.
  Future<void> downloadTile(
    SrtmTileId tile, {
    ElevationDataset? dataset,
  }) async {
    final target = dataset ?? await ElevationDatasetPreference.load();
    final uri = Uri.parse('${_baseUrlOf(target)}/${tile.fileName}');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo descargar la tesela ${tile.fileName} de '
        '${target.label} (HTTP ${response.statusCode}).',
      );
    }
    final bytes = response.bodyBytes;
    if (SrtmTileReader.sideForLength(bytes.length) == null) {
      throw Exception(
        'La tesela ${tile.fileName} llegó incompleta '
        '(${bytes.length} bytes). Vuelve a descargarla.',
      );
    }

    final tilesDir = await _datasetDir(target.id);

    // Se escribe aparte y se renombra al final: si la app se cierra a
    // mitad de la escritura, la tesela anterior (o ninguna) sigue ahí,
    // nunca un archivo a medias con el nombre bueno.
    final filePath = p.join(tilesDir.path, tile.fileName);
    final partial = File('$filePath.descargando');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(filePath);
    _reader.forget(filePath);
    final key = keyOf(target, tile);
    await _forgetDeclined(key);

    await database.upsertTile(
      DownloadedElevationTilesCompanion.insert(
        tileName: key,
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
    ElevationDataset? dataset,
    void Function(double progress)? onProgress,
  }) async {
    final target = dataset ?? await ElevationDatasetPreference.load();
    final failed = <SrtmTileId>[];
    String? firstError;
    for (int i = 0; i < tiles.length; i++) {
      try {
        await downloadTile(tiles[i], dataset: target);
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
    _catalogCache.remove(splitKey(key).fileName);
  }

  static Future<Directory> _datasetDir(String datasetId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'elevation_tiles', datasetId));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Las teselas de cuando había un solo modelo se registraban con su
  /// nombre a secas. Se pasan a `<modelo>/<tesela>` y a la carpeta de su
  /// modelo: las que el registro viejo marcaba como FABDEM quedan como
  /// FABDEM, y el resto como SRTM (se ven en Ajustes y se pueden borrar,
  /// pero ya no se usan). Nada se borra.
  Future<void> _migrateLegacyTiles() =>
      _migration ??= _runMigration().catchError((Object _) {
        _migration = null; // se reintenta la próxima vez
      });

  Future<void> _runMigration() async {
    final rows = await database.getAllDownloadedTiles();
    final legacy = [
      for (final row in rows)
        if (!row.tileName.contains('/')) row,
    ];
    if (legacy.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    var datasets = <String, dynamic>{};
    try {
      datasets =
          jsonDecode(prefs.getString(_legacyDatasetsKey) ?? '{}')
              as Map<String, dynamic>;
    } on FormatException {
      datasets = {};
    }

    for (final row in legacy) {
      final datasetId = datasets[row.tileName] == ElevationDataset.fabdem.id
          ? ElevationDataset.fabdem.id
          : legacyDatasetId;
      var filePath = row.filePath;
      final file = File(filePath);
      if (await file.exists()) {
        final dir = await _datasetDir(datasetId);
        filePath = p.join(dir.path, row.tileName);
        _reader.forget(row.filePath);
        await file.rename(filePath);
      }
      await database.upsertTile(
        DownloadedElevationTilesCompanion.insert(
          tileName: '$datasetId/${row.tileName}',
          filePath: filePath,
          sizeBytes: row.sizeBytes,
          downloadedAt: row.downloadedAt,
        ),
      );
      await database.deleteTile(row.tileName);
    }
  }
}
