import 'cockpit_tile_config.dart';

/// Resultado de acomodar un tile dentro de la grilla interna de 2
/// columnas: en qué celda (fila/columna) cae y cuántas ocupa.
class PackedTile {
  final int tileIndex;
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;

  const PackedTile({
    required this.tileIndex,
    required this.row,
    required this.col,
    required this.rowSpan,
    required this.colSpan,
  });
}

class PackedLayout {
  final List<PackedTile> tiles;
  final int totalRows;
  const PackedLayout(this.tiles, this.totalRows);
}

/// Acomoda tiles de los tamaños [sizes] en una grilla de [columns]
/// columnas, EN ORDEN, sin dejar huecos: cada tile cae en la primera
/// celda libre que alcance para su tamaño (mismo principio que el
/// auto-acomodo de CSS Grid). El número de filas resultante es
/// exactamente el necesario.
///
/// Antes vivía dentro de `cockpit_grid_layout.dart` acoplado a
/// `CockpitTileConfig`; se sacó acá y se dejó dependiendo solo de
/// `CockpitTileSize` para que lo reusen el cockpit del mapa Y la
/// pantalla de segmento (Fase D) sin duplicar el algoritmo.
PackedLayout packCockpitTiles(
  List<CockpitTileSize> sizes, {
  int columns = 2,
}) {
  final occupancy = <List<bool>>[];

  bool isFree(int row, int col, int rowSpan, int colSpan) {
    for (var r = row; r < row + rowSpan; r++) {
      if (r >= occupancy.length) continue;
      for (var c = col; c < col + colSpan; c++) {
        if (occupancy[r][c]) return false;
      }
    }
    return true;
  }

  void occupy(int row, int col, int rowSpan, int colSpan) {
    for (var r = row; r < row + rowSpan; r++) {
      while (occupancy.length <= r) {
        occupancy.add(List.filled(columns, false));
      }
      for (var c = col; c < col + colSpan; c++) {
        occupancy[r][c] = true;
      }
    }
  }

  final result = <PackedTile>[];

  for (var i = 0; i < sizes.length; i++) {
    final size = sizes[i];
    final colSpan = size.colSpan.clamp(1, columns);
    final rowSpan = size.rowSpan;

    var row = 0;
    while (true) {
      var placed = false;
      for (var col = 0; col <= columns - colSpan; col++) {
        if (isFree(row, col, rowSpan, colSpan)) {
          occupy(row, col, rowSpan, colSpan);
          result.add(PackedTile(
            tileIndex: i,
            row: row,
            col: col,
            rowSpan: rowSpan,
            colSpan: colSpan,
          ));
          placed = true;
          break;
        }
      }
      if (placed) break;
      row++;
    }
  }

  return PackedLayout(result, occupancy.length);
}
