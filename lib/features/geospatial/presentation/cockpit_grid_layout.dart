import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/cyclecore_palette.dart';
import '../domain/cockpit_field.dart';
import '../domain/cockpit_tile_config.dart';
import 'cockpit_field_ui.dart';

/// Resultado de acomodar un campo dentro de la grilla interna de 2
/// columnas: en qué celda (fila/columna) cae y cuántas celdas ocupa.
class _PackedTile {
  final int tileIndex;
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;

  const _PackedTile({
    required this.tileIndex,
    required this.row,
    required this.col,
    required this.rowSpan,
    required this.colSpan,
  });
}

class _PackedLayout {
  final List<_PackedTile> tiles;
  final int totalRows;
  const _PackedLayout(this.tiles, this.totalRows);
}

/// Acomoda [tiles] en una grilla de [columns] columnas (2, pensado para
/// teléfono en vertical), sin dejar huecos: recorre los campos EN
/// ORDEN y cada uno cae en la primera celda libre que alcance para su
/// tamaño (mismo principio que el auto-acomodo de CSS Grid). El número
/// de filas resultante es exactamente el que se necesita -- ni una
/// fila de más -- así el widget que consume esto puede repartir la
/// altura disponible entre esas filas exactas, sin dejar espacio vacío
/// abajo (el problema que había con la grilla uniforme de tamaño fijo
/// anterior).
///
/// Reordenar la lista [tiles] (arrastrar en modo edición) cambia el
/// acomodo resultante porque el algoritmo respeta el orden de entrada.
_PackedLayout packCockpitTiles(
  List<CockpitTileConfig> tiles, {
  int columns = 2,
}) {
  final occupancy = <List<bool>>[];

  bool isFree(int row, int col, int rowSpan, int colSpan) {
    for (var r = row; r < row + rowSpan; r++) {
      if (r >= occupancy.length) continue; // fila aún no creada = libre
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

  final result = <_PackedTile>[];

  for (var i = 0; i < tiles.length; i++) {
    final size = tiles[i].size;
    final colSpan = size.colSpan.clamp(1, columns);
    final rowSpan = size.rowSpan;

    var row = 0;
    while (true) {
      var placedInThisRow = false;
      for (var col = 0; col <= columns - colSpan; col++) {
        if (isFree(row, col, rowSpan, colSpan)) {
          occupy(row, col, rowSpan, colSpan);
          result.add(_PackedTile(
            tileIndex: i,
            row: row,
            col: col,
            rowSpan: rowSpan,
            colSpan: colSpan,
          ));
          placedInThisRow = true;
          break;
        }
      }
      if (placedInThisRow) break;
      row++;
    }
  }

  return _PackedLayout(result, occupancy.length);
}

/// Grilla del cockpit -- renderiza [tiles] usando [packCockpitTiles], y
/// opcionalmente permite editarla: arrastrar un campo (long-press) lo
/// reordena con el que soltó encima; tocar el chip de tamaño lo cambia
/// entre Chico/Ancho/Grande.
///
/// Por qué `Positioned` con alto/ancho calculado en vez de `GridView`:
/// con `GridView` + `childAspectRatio` fijo (el enfoque anterior), si
/// la proporción no calzaba exactamente con el alto disponible, sobraba
/// espacio vacío debajo de la última fila. Aquí la altura de fila se
/// calcula como `alturaDisponible / totalRows` -- siempre llena el
/// espacio exacto, sin sobras ni overflow, sin importar cuántos campos
/// o filas resulten.
class CockpitGridLayout extends StatelessWidget {
  final List<CockpitTileConfig> tiles;
  final CockpitLiveData liveData;
  final bool editing;
  final void Function(int fromIndex, int toIndex)? onReorder;
  final void Function(int index, CockpitTileSize newSize)? onResize;

  static const double _spacing = 10;
  static const int _columns = 2;

  const CockpitGridLayout({
    super.key,
    required this.tiles,
    required this.liveData,
    this.editing = false,
    this.onReorder,
    this.onResize,
  });

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();

    final packed = packCockpitTiles(tiles, columns: _columns);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalRows = packed.totalRows.clamp(1, 999);
        final colWidth =
            (constraints.maxWidth - _spacing * (_columns - 1)) / _columns;
        final rowHeight =
            (constraints.maxHeight - _spacing * (totalRows - 1)) / totalRows;

        return Stack(
          children: [
            for (final p in packed.tiles)
              Positioned(
                left: p.col * (colWidth + _spacing),
                top: p.row * (rowHeight + _spacing),
                width: p.colSpan * colWidth + (p.colSpan - 1) * _spacing,
                height: p.rowSpan * rowHeight + (p.rowSpan - 1) * _spacing,
                child: editing
                    ? _EditableCockpitTile(
                        tileIndex: p.tileIndex,
                        config: tiles[p.tileIndex],
                        liveData: liveData,
                        onDroppedOn: (fromIndex) =>
                            onReorder?.call(fromIndex, p.tileIndex),
                        onResize: (size) =>
                            onResize?.call(p.tileIndex, size),
                      )
                    : _CockpitTile(
                        config: tiles[p.tileIndex],
                        liveData: liveData,
                      ),
              ),
          ],
        );
      },
    );
  }
}

/// Contenido visual de un campo -- SIN modo edición. El tamaño de
/// fuente se calcula a partir del alto real del tile (vía
/// `LayoutBuilder`), no un valor fijo -- esto es lo que elimina el
/// overflow que aparecía antes con combinaciones de 4/6/8 campos: sin
/// importar qué tan chico quede el tile, el texto se ajusta a lo que
/// realmente cabe en vez de asumir un tamaño de pantalla típico.
class _CockpitTile extends StatelessWidget {
  final CockpitTileConfig config;
  final CockpitLiveData liveData;

  const _CockpitTile({required this.config, required this.liveData});

  @override
  Widget build(BuildContext context) {
    final display = config.field.display(liveData);
    final isSlope = config.field == CockpitField.pendiente;
    final accentColor = isSlope
        ? CyclecorePalette.slopeColorFor(liveData.slopePercent)
        : display.color;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Proporciones relativas al alto real del tile -- clamps para
        // no verse ridículo en los extremos (un tile de 1 celda muy
        // bajito, o uno Grande muy alto en una pantalla grande).
        final valueFontSize = (constraints.maxHeight * 0.34).clamp(18.0, 64.0);
        final labelFontSize = (constraints.maxHeight * 0.09).clamp(10.0, 14.0);
        final unitFontSize = (constraints.maxHeight * 0.11).clamp(11.0, 18.0);
        final iconSize = (constraints.maxHeight * 0.12).clamp(14.0, 22.0);
        final padding = (constraints.maxHeight * 0.09).clamp(8.0, 22.0);

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: isSlope
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: isSlope ? null : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.28),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(display.icon, size: iconSize, color: accentColor),
                  SizedBox(width: iconSize * 0.35),
                  Flexible(
                    child: Text(
                      display.label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        display.value,
                        style: TextStyle(
                          // Alto contraste fijo (Hueso), a propósito
                          // NUNCA coloreado -- en la calle, con sol
                          // directo, un número de color pastel sobre
                          // fondo oscuro se lee peor que uno blanco
                          // puro con alto contraste. El color de acento
                          // ya se ve en el ícono/borde, no hace falta
                          // repetirlo en el número.
                          color: AppColors.textPrimaryOnPanel,
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  if (display.unit.isNotEmpty) ...[
                    SizedBox(width: padding * 0.4),
                    Text(
                      display.unit,
                      style: TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: unitFontSize,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Envoltorio del tile en modo edición: arrastrable (long-press) para
/// reordenar, y con una fila de chips S/M/L para cambiar el tamaño.
class _EditableCockpitTile extends StatelessWidget {
  final int tileIndex;
  final CockpitTileConfig config;
  final CockpitLiveData liveData;
  final void Function(int fromIndex) onDroppedOn;
  final void Function(CockpitTileSize size) onResize;

  const _EditableCockpitTile({
    required this.tileIndex,
    required this.config,
    required this.liveData,
    required this.onDroppedOn,
    required this.onResize,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != tileIndex,
      onAcceptWithDetails: (details) => onDroppedOn(details.data),
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;
        return Stack(
          children: [
            Positioned.fill(
              child: LongPressDraggable<int>(
                data: tileIndex,
                delay: const Duration(milliseconds: 180),
                feedback: Opacity(
                  opacity: 0.85,
                  child: SizedBox(
                    width: 160,
                    height: 100,
                    child: _CockpitTile(config: config, liveData: liveData),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: _CockpitTile(config: config, liveData: liveData),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDropTarget
                          ? CyclecorePalette.paramo
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: _CockpitTile(config: config, liveData: liveData),
                ),
              ),
            ),
            // Selector de tamaño -- esquina inferior derecha, siempre
            // visible en modo edición. Chips chicos para no competir
            // visualmente con el contenido del campo.
            Positioned(
              right: 4,
              bottom: 4,
              child: _SizeChipRow(
                current: config.size,
                onSelect: onResize,
              ),
            ),
            // Ícono de "arrastrable" -- comunica sin texto que este
            // tile se puede mover, además del long-press ya
            // descubierto por casi todos con listas reordenables.
            const Positioned(
              left: 4,
              top: 4,
              child: Icon(
                Icons.drag_indicator,
                size: 16,
                color: AppColors.textSecondaryOnPanel,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SizeChipRow extends StatelessWidget {
  final CockpitTileSize current;
  final void Function(CockpitTileSize) onSelect;

  const _SizeChipRow({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: CyclecorePalette.grafito.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: CockpitTileSize.values.map((size) {
          final selected = size == current;
          return GestureDetector(
            onTap: () => onSelect(size),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? CyclecorePalette.paramo
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                size.shortLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? CyclecorePalette.grafito
                      : AppColors.textSecondaryOnPanel,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
