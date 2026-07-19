import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/cockpit_layout_repository.dart';
import '../domain/cockpit_field.dart';
import '../domain/cockpit_tile_config.dart';
import 'cockpit_field_ui.dart';
import 'cockpit_layout_providers.dart';

/// Tamaños de grid soportados, estilo Garmin -- no cualquier número, así
/// la distribución de la grilla siempre queda prolija.
const List<int> kCockpitFieldCounts = [1, 2, 3, 4, 6, 8];

Future<void> showCockpitSettingsSheet(BuildContext context, WidgetRef ref) {
  final current =
      ref.read(cockpitLayoutProvider).valueOrNull ??
      CockpitLayoutRepository.defaultTiles;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.panelBackground,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CockpitSettingsSheetBody(initialTiles: current),
  );
}

class _CockpitSettingsSheetBody extends ConsumerStatefulWidget {
  final List<CockpitTileConfig> initialTiles;

  const _CockpitSettingsSheetBody({required this.initialTiles});

  @override
  ConsumerState<_CockpitSettingsSheetBody> createState() =>
      _CockpitSettingsSheetBodyState();
}

class _CockpitSettingsSheetBodyState
    extends ConsumerState<_CockpitSettingsSheetBody> {
  late List<CockpitTileConfig> _tiles;

  @override
  void initState() {
    super.initState();
    _tiles = List.of(widget.initialTiles);
  }

  void _setCount(int count) {
    setState(() {
      _tiles = CockpitLayoutRepository.adjustCount(_tiles, count);
    });
  }

  Future<void> _pickFieldFor(int index) async {
    final usedFields = _tiles.map((t) => t.field).toList();
    final picked = await showModalBottomSheet<CockpitField>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FieldPickerList(currentlyUsed: usedFields),
    );
    if (picked != null) {
      setState(() => _tiles[index] = _tiles[index].copyWith(field: picked));
    }
  }

  Future<void> _save() async {
    await ref.read(cockpitLayoutProvider.notifier).setTiles(_tiles);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Elegir campos',
              style: TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Elige cuántos campos quieres ver y qué dato va en cada uno. '
              'El tamaño y el orden se ajustan aparte, con el lápiz.',
              style: TextStyle(
                color: AppColors.textSecondaryOnPanel,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: kCockpitFieldCounts.map((count) {
                final selected = _tiles.length == count;
                return ChoiceChip(
                  label: Text('$count'),
                  selected: selected,
                  onSelected: (_) => _setCount(count),
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : AppColors.textSecondaryOnPanel,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(_tiles.length, (i) {
                    final field = _tiles[i].field;
                    return Card(
                      color: Colors.white.withValues(alpha: 0.05),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(field.icon, color: field.color),
                        title: Text(
                          field.label,
                          style: const TextStyle(
                            color: AppColors.textPrimaryOnPanel,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondaryOnPanel,
                        ),
                        onTap: () => _pickFieldFor(i),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Guardar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldPickerList extends StatelessWidget {
  final List<CockpitField> currentlyUsed;

  const _FieldPickerList({required this.currentlyUsed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: CockpitField.values.map((field) {
          final alreadyUsed = currentlyUsed.contains(field);
          return ListTile(
            leading: Icon(field.icon, color: field.color),
            title: Text(
              field.label,
              style: const TextStyle(color: AppColors.textPrimaryOnPanel),
            ),
            trailing: alreadyUsed
                ? const Icon(
                    Icons.check,
                    color: AppColors.textSecondaryOnPanel,
                    size: 18,
                  )
                : null,
            onTap: () => Navigator.of(context).pop(field),
          );
        }).toList(),
      ),
    );
  }
}
