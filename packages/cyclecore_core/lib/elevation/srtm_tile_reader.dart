import 'dart:collection';
import 'dart:io';

/// Lee archivos SRTM (`.hgt`) para obtener una altitud confiable en una
/// coordenada exacta, en vez de depender del GPS/barómetro del celular.
///
/// Formato SRTM: grilla cuadrada de enteros de 16 bits con signo,
/// big-endian, fila por fila de norte a sur, columna por columna de
/// oeste a este. El tamaño del lado (1201 para SRTM3 ~90m, 3601 para
/// SRTM1 ~30m) se deduce del tamaño del archivo -- no hay que asumirlo.
///
/// Todo es SÍNCRONO a propósito: son lecturas de disco locales, muy
/// rápidas, y así se puede llamar directo desde `_onNewPosition` sin
/// meter async al medio del stream de GPS (evita reordenar puntos).
class SrtmTileReader {
  static const int _maxOpenHandles = 3;
  final LinkedHashMap<String, RandomAccessFile> _openHandles = LinkedHashMap();

  /// Altitud interpolada (metros) en (lat, lng), o null si el archivo no
  /// existe o el dato en esa coordenada es un "hueco" conocido de SRTM.
  double? elevationAt({
    required String filePath,
    required int tileLatFloor,
    required int tileLngFloor,
    required double lat,
    required double lng,
  }) {
    final raf = _openHandle(filePath);
    if (raf == null) return null;

    final fileLength = raf.lengthSync();
    final side = _integerSqrt(fileLength ~/ 2);
    if (side < 2) return null;

    // Fila 0 = borde norte (lat = tileLatFloor + 1); última fila = borde
    // sur (lat = tileLatFloor). Columna 0 = borde oeste.
    final rowF = (tileLatFloor + 1 - lat) * (side - 1);
    final colF = (lng - tileLngFloor) * (side - 1);

    final row0 = rowF.floor().clamp(0, side - 1);
    final row1 = (row0 + 1).clamp(0, side - 1);
    final col0 = colF.floor().clamp(0, side - 1);
    final col1 = (col0 + 1).clamp(0, side - 1);

    final v00 = _sampleAt(raf, side, row0, col0);
    final v01 = _sampleAt(raf, side, row0, col1);
    final v10 = _sampleAt(raf, side, row1, col0);
    final v11 = _sampleAt(raf, side, row1, col1);

    if (v00 == null || v01 == null || v10 == null || v11 == null) {
      return null;
    }

    final rowT = (rowF - row0).clamp(0.0, 1.0);
    final colT = (colF - col0).clamp(0.0, 1.0);

    final top = v00 + (v01 - v00) * colT;
    final bottom = v10 + (v11 - v10) * colT;
    return top + (bottom - top) * rowT;
  }

  double? _sampleAt(RandomAccessFile raf, int side, int row, int col) {
    final offset = (row * side + col) * 2;
    raf.setPositionSync(offset);
    final bytes = raf.readSync(2);
    if (bytes.length < 2) return null;

    final value = (bytes[0] << 8) | bytes[1];
    final signed = value >= 0x8000 ? value - 0x10000 : value;

    // -32768 es el valor estándar "sin dato" de SRTM (huecos de radar,
    // típicamente sobre agua o sombras del sensor).
    if (signed == -32768) return null;
    return signed.toDouble();
  }

  int _integerSqrt(int value) {
    if (value <= 1) return value;
    var x = value;
    var y = (x + 1) ~/ 2;
    while (y < x) {
      x = y;
      y = (x + value ~/ x) ~/ 2;
    }
    return x;
  }

  RandomAccessFile? _openHandle(String filePath) {
    final cached = _openHandles.remove(filePath);
    if (cached != null) {
      // Se re-inserta al final para marcarlo como "recién usado" (LRU).
      _openHandles[filePath] = cached;
      return cached;
    }

    final file = File(filePath);
    if (!file.existsSync()) return null;

    final raf = file.openSync(mode: FileMode.read);

    if (_openHandles.length >= _maxOpenHandles) {
      final oldestKey = _openHandles.keys.first;
      _openHandles.remove(oldestKey)?.closeSync();
    }
    _openHandles[filePath] = raf;
    return raf;
  }

  void closeAll() {
    for (final raf in _openHandles.values) {
      raf.closeSync();
    }
    _openHandles.clear();
  }
}
