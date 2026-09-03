import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/cyclecore_palette.dart';
import '../domain/segment_cockpit_field.dart';
import '../domain/segment_cockpit_tile_config.dart';
import 'segment_cockpit_field_ui.dart';
import 'segment_cockpit_layout_providers.dart';
import 'widgets/segment_cockpit_grid.dart';

/// Editor de la pantalla de segmento en vivo -- se llega desde
/// Perfil → Ajustes → "Datos del segmento". Acá el usuario decide
/// QUÉ datos ve mientras recorre un segmento, en qué ORDEN y con qué
/// TAMAÑO (Chico / Ancho / Grande).
///
/// Es una pantalla propia (y no un modo de edición dentro de la
/// pantalla de segmento) porque es una configuración "grande": hay
/// muchos campos, varios necesitan explicación, y no es algo que se
/// toque a mitad de una subida.
///
/// Guarda automáticamente cada cambio (`segmentCockpitLayoutProvider`).
class SegmentDataSettingsScreen extends ConsumerWidget {
  const SegmentDataSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutAsync = ref.watch(segmentCockpitLayoutProvider);
    final notifier = ref.read(segmentCockpitLayoutProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
        title: const Text(
          'Datos del segmento',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        actions: [
          TextButton(
            onPressed: notifier.resetToDefault,
            child: const Text(
              'Restablecer',
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
        ],
      ),
      body: layoutAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'No se pudo cargar la configuración.\n$e',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ),
        data: (tiles) => _Editor(tiles: tiles, notifier: notifier),
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  final List<SegmentCockpitTileConfig> tiles;
  final SegmentCockpitLayoutNotifier notifier;

  const _Editor({required this.tiles, required this.notifier});

  List<SegmentCockpitField> get _available => SegmentCockpitField.values
      .where((f) => !tiles.any((t) => t.field == f))
      .toList();

  void _reorder(int oldIndex, int newIndex) {
    final next = List<SegmentCockpitTileConfig>.of(tiles);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);
    notifier.setTiles(next);
  }

  void _remove(SegmentCockpitField field) {
    notifier.setTiles(tiles.where((t) => t.field != field).toList());
  }

  void _add(SegmentCockpitField field) {
    notifier.setTiles([
      ...tiles,
      SegmentCockpitTileConfig(field: field, size: CockpitTileSize.small),
    ]);
  }

  void _resize(SegmentCockpitField field, CockpitTileSize size) {
    notifier.setTiles([
      for (final t in tiles)
        if (t.field == field) t.copyWith(size: size) else t,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const _SectionLabel('CÓMO SE VE'),
        const SizedBox(height: 4),
        const Text(
          'Vista previa con datos de ejemplo -- así queda la pantalla '
          'mientras recorrés un segmento.',
          style: TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: (tiles.length <= 3 ? 200.0 : 380.0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: IgnorePointer(
            child: SegmentCockpitGrid(
              tiles: tiles,
              data: sampleSegmentLiveData(),
              preview: true,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('ELEMENTOS QUE VES'),
        const SizedBox(height: 4),
        const Text(
          'Mantén presionado y arrastra para reordenar. Toca S / M / L '
          'para el tamaño.',
          style: TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        if (tiles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No hay nada. Agregá algún elemento abajo.',
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          )
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: _reorder,
            children: [
              for (int i = 0; i < tiles.length; i++)
                _ActiveFieldTile(
                  key: ValueKey(tiles[i].field),
                  index: i,
                  config: tiles[i],
                  onRemove: () => _remove(tiles[i].field),
                  onResize: (s) => _resize(tiles[i].field, s),
                ),
            ],
          ),
        const SizedBox(height: 24),
        const _SectionLabel('AGREGAR ELEMENTO'),
        const SizedBox(height: 10),
        if (_available.isEmpty)
          const Text(
            'Ya están todos los elementos disponibles.',
            style: TextStyle(color: AppColors.textSecondaryOnPanel),
          )
        else
          ..._available.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AvailableFieldTile(field: f, onAdd: () => _add(f)),
            ),
          ),
      ],
    );
  }
}

class _ActiveFieldTile extends StatelessWidget {
  final int index;
  final SegmentCockpitTileConfig config;
  final VoidCallback onRemove;
  final void Function(CockpitTileSize) onResize;

  const _ActiveFieldTile({
    super.key,
    required this.index,
    required this.config,
    required this.onRemove,
    required this.onResize,
  });

  @override
  Widget build(BuildContext context) {
    final field = config.field;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(6, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.drag_indicator,
                color: AppColors.textSecondaryOnPanel,
                size: 20,
              ),
            ),
          ),
          Icon(field.icon, color: field.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: const TextStyle(
                    color: AppColors.textPrimaryOnPanel,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  field.helpText,
                  style: const TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SizeChips(current: config.size, onSelect: onResize),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.remove_circle_outline,
              color: AppColors.textSecondaryOnPanel,
              size: 20,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _SizeChips extends StatelessWidget {
  final CockpitTileSize current;
  final void Function(CockpitTileSize) onSelect;

  const _SizeChips({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: CockpitTileSize.values.map((size) {
        final selected = size == current;
        return GestureDetector(
          onTap: () => onSelect(size),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? CyclecorePalette.paramo
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              size.shortLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: selected
                    ? Colors.white
                    : AppColors.textSecondaryOnPanel,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AvailableFieldTile extends StatelessWidget {
  final SegmentCockpitField field;
  final VoidCallback onAdd;

  const _AvailableFieldTile({required this.field, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(field.icon, color: field.color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnPanel,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      field.helpText,
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondaryOnPanel,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }
}
