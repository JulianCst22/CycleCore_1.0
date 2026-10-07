import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Cuadros del mapa guardados en el teléfono.
///
/// Cada cuadro que se baja queda en disco, así que sin internet (modo
/// avión, la montaña sin señal) el mapa sigue mostrando lo que ya se
/// vio; lo que nunca se bajó queda en blanco, sin errores ni esperas.
///
/// Es liviano a propósito: un archivo por cuadro (10–30 KB), sin base de
/// datos ni descargas por adelantado. Un cuadro guardado se usa tal cual
/// durante [maxAge]; después se pide de nuevo y, si no hay red, sirve el
/// viejo. El total no pasa de [maxBytes]: al abrir la app, si se pasó,
/// se borran los más viejos hasta [pruneToBytes].
///
/// Es uno solo para toda la app ([instance]): todas las capas de mapa
/// comparten los mismos cuadros.
class CachedTileProvider extends TileProvider {
  CachedTileProvider._()
    : super(
        // Los servidores de OpenStreetMap piden identificar la app. Se
        // fija acá porque el proveedor es compartido: si lo pusiera la
        // primera capa que se crea, ganaría la que no lo trae.
        headers: {'User-Agent': 'flutter_map (com.example.cyclecore_app)'},
      );

  static final instance = CachedTileProvider._();

  static const maxAge = Duration(days: 30);
  static const maxBytes = 150 * 1024 * 1024;
  static const pruneToBytes = 100 * 1024 * 1024;

  /// Sin red, la petición falla al instante; con una red mala no se
  /// espera más que esto por un cuadro.
  static const downloadTimeout = Duration(seconds: 10);

  final http.Client _client = http.Client();
  Future<Directory>? _folder;

  Future<Directory> get folder => _folder ??= _openFolder();

  Future<Directory> _openFolder() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'map_tiles'));
    if (!await dir.exists()) await dir.create(recursive: true);
    // Se recorta después del arranque, sin estorbarlo.
    Timer(const Duration(seconds: 20), () => unawaited(_prune(dir.path)));
    return dir;
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _CachedTileImage(url: getTileUrl(coordinates, options), provider: this);

  /// La capa que lo usa se destruye seguido (cada pantalla con mapa); el
  /// proveedor es compartido y sigue vivo.
  @override
  void dispose() {}

  Future<File> _fileFor(String url) async {
    final uri = Uri.parse(url);
    return File(
      p.joinAll([(await folder).path, uri.host, ...uri.pathSegments]),
    );
  }

  Future<Uint8List?> _bytesFor(String url) async {
    final file = await _fileFor(url);
    FileStat? stat;
    try {
      stat = await file.stat();
    } catch (_) {}
    final exists = stat != null && stat.type == FileSystemEntityType.file;
    if (exists && DateTime.now().difference(stat.modified) < maxAge) {
      return file.readAsBytes();
    }
    try {
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(downloadTimeout);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        unawaited(_save(file, response.bodyBytes));
        return response.bodyBytes;
      }
    } catch (_) {
      // Sin red: se sigue con lo guardado, si hay.
    }
    return exists ? file.readAsBytes() : null;
  }

  /// Borra un cuadro guardado que salió dañado.
  Future<void> _forget(String url) async {
    try {
      await (await _fileFor(url)).delete();
    } catch (_) {}
  }

  /// Se escribe a un temporal y se renombra: un cuadro a medio escribir
  /// nunca queda como bueno.
  static Future<void> _save(File file, Uint8List bytes) async {
    try {
      await file.parent.create(recursive: true);
      final partial = File('${file.path}.part');
      await partial.writeAsBytes(bytes, flush: true);
      await partial.rename(file.path);
    } catch (_) {
      // Sin espacio o sin permiso: el cuadro se ve igual, solo no queda.
    }
  }

  static Future<void> _prune(String root) => Isolate.run(() {
    final files = <File>[];
    var total = 0;
    final dir = Directory(root);
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File) {
        files.add(entity);
        total += entity.lengthSync();
      }
    }
    if (total <= maxBytes) return;
    files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    for (final file in files) {
      if (total <= pruneToBytes) break;
      try {
        total -= file.lengthSync();
        file.deleteSync();
      } catch (_) {}
    }
  });
}

/// Un cuadro: del disco si está, si no de la red (y queda guardado). Si
/// no hay ninguno de los dos, transparente: el mapa se ve en blanco ahí.
@immutable
class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  final String url;
  final CachedTileProvider provider;

  const _CachedTileImage({required this.url, required this.provider});

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(key, decode),
    scale: 1,
    debugLabel: url,
  );

  Future<Codec> _load(_CachedTileImage key, ImageDecoderCallback decode) async {
    Uint8List? bytes;
    try {
      bytes = await provider._bytesFor(url);
    } catch (_) {
      // Un archivo que se borró justo al leerlo, por ejemplo.
    }
    if (bytes != null) {
      try {
        return await decode(await ImmutableBuffer.fromUint8List(bytes));
      } catch (_) {
        // Archivo dañado: se borra para que la próxima vez se baje bien.
        unawaited(provider._forget(url));
      }
    }
    // No se guarda en la caché de imágenes: cuando vuelva la red, el
    // cuadro se pide otra vez.
    scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
    return decode(
      await ImmutableBuffer.fromUint8List(TileProvider.transparentImage),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
