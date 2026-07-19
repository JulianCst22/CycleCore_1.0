import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/cyclecore_palette.dart';
import '../domain/cockpit_field.dart';
import '../domain/cockpit_tile_config.dart';
import 'cockpit_field_ui.dart';
import 'cockpit_grid_layout.dart';
import 'cockpit_layout_providers.dart';
import 'cockpit_settings_sheet.dart';

/// Vista de cockpit en pantalla completa, estilo ciclocomputador Garmin.
///
/// Dos formas de personalizarlo, separadas a propósito:
/// - Ícono de engranaje (`onOpenSettings`): elegir CUÁNTOS campos y
///   CUÁLES -- abre `showCockpitSettingsSheet` (sin cambios de fondo
///   en esa parte).
/// - Ícono de lápiz (nuevo, en este archivo): entrar en modo edición
///   para ARRASTRAR y reordenar los campos, y ajustar su TAMAÑO
///   (Chico/Ancho/Grande) -- los cambios quedan en un borrador local
///   hasta tocar "Guardar"; "Cancelar" descarta todo y vuelve al
///   layout guardado.
class CockpitFullscreenView extends ConsumerStatefulWidget {
  final List<CockpitTileConfig> tiles;
  final CockpitLiveData liveData;
  final VoidCallback onSwipeDown;

  const CockpitFullscreenView({
    super.key,
    required this.tiles,
    required this.liveData,
    required this.onSwipeDown,
  });

  @override
  ConsumerState<CockpitFullscreenView> createState() =>
      _CockpitFullscreenViewState();
}

class _CockpitFullscreenViewState extends ConsumerState<CockpitFullscreenView> {
  bool _editing = false;
  late List<CockpitTileConfig> _draftTiles;

  @override
  void initState() {
    super.initState();
    _draftTiles = List.of(widget.tiles);
  }

  @override
  void didUpdateWidget(covariant CockpitFullscreenView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el layout guardado cambió desde afuera (p.ej. se cambiaron
    // los campos desde la hoja de ajustes) y no estamos editando,
    // el borrador se refresca para no mostrar datos viejos.
    if (!_editing && oldWidget.tiles != widget.tiles) {
      _draftTiles = List.of(widget.tiles);
    }
  }

  void _startEditing() {
    setState(() {
      _draftTiles = List.of(widget.tiles);
      _editing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _draftTiles = List.of(widget.tiles);
      _editing = false;
    });
  }

  Future<void> _saveEditing() async {
    await ref.read(cockpitLayoutProvider.notifier).setTiles(_draftTiles);
    if (mounted) setState(() => _editing = false);
  }

  void _reorder(int fromIndex, int toIndex) {
    setState(() {
      final moved = _draftTiles.removeAt(fromIndex);
      _draftTiles.insert(toIndex, moved);
    });
  }

  void _resize(int index, CockpitTileSize size) {
    setState(() {
      _draftTiles[index] = _draftTiles[index].copyWith(size: size);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tilesToShow = _editing ? _draftTiles : widget.tiles;

    return Material(
      color: AppColors.panelBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Solo esta franja de arriba (la manija + los botones)
            // escucha el gesto de deslizar hacia abajo para cerrar.
            // Antes el GestureDetector envolvía TODA la pantalla, y
            // competía por el gesto con el panel exterior que anima la
            // transición -- ambos "escuchaban" el mismo arrastre, y el
            // de aquí adentro ganaba la pelea pero estaba conectado a
            // un callback vacío, así que el resultado era que no pasaba
            // NADA al deslizar hacia abajo. Ahora solo hay un lugar que
            // reacciona a ese gesto en esta pantalla, y si el usuario
            // arrastra desde el cuerpo de la grilla, el gesto sigue de
            // largo hacia el panel exterior (que sí sabe colapsar).
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (_editing) return;
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 200) widget.onSwipeDown();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondaryOnPanel.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    if (_editing) ...[
                      TextButton(
                        onPressed: _cancelEditing,
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: AppColors.textSecondaryOnPanel,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _saveEditing,
                        child: const Text(
                          'Guardar',
                          style: TextStyle(
                            color: CyclecorePalette.paramo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else ...[
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.textSecondaryOnPanel,
                        ),
                        onPressed: _startEditing,
                        tooltip: 'Mover y ajustar tamaño de campos',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.tune,
                          color: AppColors.textSecondaryOnPanel,
                        ),
                        onPressed: () async {
                          await showCockpitSettingsSheet(context, ref);
                        },
                        tooltip: 'Elegir campos',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_editing)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Mantén presionado un campo para moverlo. Toca S/M/L '
                  'para cambiar su tamaño.',
                  style: TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 12,
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: CockpitGridLayout(
                  tiles: tilesToShow,
                  liveData: widget.liveData,
                  editing: _editing,
                  onReorder: _reorder,
                  onResize: _resize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
