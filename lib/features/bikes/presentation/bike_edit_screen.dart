import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/ui/ui.dart';
import '../application/bikes_providers.dart';
import '../domain/bike.dart';

/// Ficha de una bicicleta: la que se agrega o la que se corrige.
///
/// El peso y el tipo son los que de verdad importan para el motor; lo
/// demás es para reconocerla.
class BikeEditScreen extends ConsumerStatefulWidget {
  /// `null` para agregar una nueva.
  final Bike? bike;

  const BikeEditScreen({super.key, this.bike});

  @override
  ConsumerState<BikeEditScreen> createState() => _BikeEditScreenState();
}

class _BikeEditScreenState extends ConsumerState<BikeEditScreen> {
  static const _colors = [
    0xFFFF6B35,
    0xFF4FC3F7,
    0xFF3FC46B,
    0xFF8155C6,
    0xFFE0A93C,
    0xFFE5484D,
    0xFF8C96A8,
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _chainringCtrl = TextEditingController();
  final _cogCtrl = TextEditingController();
  final _bigChainringCtrl = TextEditingController();
  final _smallCogCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  BikeKind _kind = BikeKind.ruta;
  int? _color;
  String? _photoPath;
  bool _isDefault = false;
  bool _saving = false;

  bool get _isNew => widget.bike == null;

  @override
  void initState() {
    super.initState();
    final bike = widget.bike;
    if (bike == null) return;
    _nameCtrl.text = bike.name;
    _brandCtrl.text = bike.brand ?? '';
    _weightCtrl.text = bike.weightKg?.toString() ?? '';
    _chainringCtrl.text = bike.lowestChainring?.toString() ?? '';
    _cogCtrl.text = bike.largestCog?.toString() ?? '';
    _bigChainringCtrl.text = bike.largestChainring?.toString() ?? '';
    _smallCogCtrl.text = bike.smallestCog?.toString() ?? '';
    _notesCtrl.text = bike.notes ?? '';
    _kind = bike.kind;
    _color = bike.color;
    _photoPath = bike.photoPath;
    _isDefault = bike.isDefault;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _weightCtrl.dispose();
    _chainringCtrl.dispose();
    _cogCtrl.dispose();
    _bigChainringCtrl.dispose();
    _smallCogCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repository = ref.read(bikesRepositoryProvider);
    final weight = double.tryParse(
      _weightCtrl.text.trim().replaceAll(',', '.'),
    );
    final chainring = int.tryParse(_chainringCtrl.text.trim());
    final cog = int.tryParse(_cogCtrl.text.trim());
    final bigChainring = int.tryParse(_bigChainringCtrl.text.trim());
    final smallCog = int.tryParse(_smallCogCtrl.text.trim());
    final notes = _notesCtrl.text.trim().isEmpty
        ? null
        : _notesCtrl.text.trim();
    final brand = _brandCtrl.text.trim().isEmpty
        ? null
        : _brandCtrl.text.trim();

    if (_isNew) {
      await repository.add(
        name: _nameCtrl.text.trim(),
        kind: _kind,
        brand: brand,
        weightKg: weight,
        color: _color,
        photoPath: _photoPath,
        notes: notes,
        lowestChainring: chainring,
        largestCog: cog,
        largestChainring: bigChainring,
        smallestCog: smallCog,
        isDefault: _isDefault,
      );
    } else {
      await repository.save(
        Bike(
          id: widget.bike!.id,
          name: _nameCtrl.text.trim(),
          brand: brand,
          kind: _kind,
          weightKg: weight,
          color: _color,
          photoPath: _photoPath,
          notes: notes,
          lowestChainring: chainring,
          largestCog: cog,
          largestChainring: bigChainring,
          smallestCog: smallCog,
          wheelCircumferenceMm: widget.bike!.wheelCircumferenceMm,
          isDefault: _isDefault,
          createdAt: widget.bike!.createdAt,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CcColors.surfaceHi,
        title: const Text('¿Borrar esta bicicleta?'),
        content: const Text(
          'Tus salidas no se borran: siguen guardadas con el nombre que '
          'tenían.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: CcColors.danger),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(bikesRepositoryProvider).remove(widget.bike!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Nueva bicicleta' : 'Editar bicicleta'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: CcColors.danger),
              tooltip: 'Borrar',
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            children: [
              _PhotoPicker(path: _photoPath, onTap: _pickPhoto),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _nameCtrl,
                label: 'Nombre',
                icon: Icons.pedal_bike_outlined,
                hint: 'La de ruta, La vieja confiable…',
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Ponle un nombre' : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _brandCtrl,
                label: 'Marca (opcional)',
                icon: Icons.sell_outlined,
                hint: 'Specialized, Scott…',
              ),
              const SizedBox(height: 18),
              const ActivitySectionLabel('Qué tipo es'),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final kind in BikeKind.values) ...[
                    Expanded(
                      child: _KindCard(
                        kind: kind,
                        selected: _kind == kind,
                        onTap: () => setState(() => _kind = kind),
                      ),
                    ),
                    if (kind != BikeKind.values.last) const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _weightCtrl,
                label: 'Peso (opcional)',
                icon: Icons.monitor_weight_outlined,
                hint: 'Ej. ${_kind.typicalWeightKg.toStringAsFixed(0)}',
                suffixText: 'kg',
                helperText:
                    'Si no lo sabes, se usa el típico de su tipo y el coach '
                    'lo tiene en cuenta como una suposición.',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return null;
                  final n = double.tryParse(v!.trim().replaceAll(',', '.'));
                  if (n == null || n < 3 || n > 30) return 'Peso inválido';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const ActivitySectionLabel('El piñón más suave'),
              const SizedBox(height: 6),
              Text(
                'Con esto el coach sabe si de verdad te queda piñón para '
                'subir la cadencia. Por defecto usa '
                '${_kind.typicalLowestGear.chainring}×'
                '${_kind.typicalLowestGear.cog}.',
                style: CcType.label(size: 11, color: CcColors.inkDim),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      controller: _chainringCtrl,
                      label: 'Plato chico',
                      icon: Icons.settings_outlined,
                      hint: '${_kind.typicalLowestGear.chainring}',
                      keyboardType: TextInputType.number,
                      validator: (v) => _teeth(v, 20, 60),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthTextField(
                      controller: _cogCtrl,
                      label: 'Piñón grande',
                      icon: Icons.settings_outlined,
                      hint: '${_kind.typicalLowestGear.cog}',
                      keyboardType: TextInputType.number,
                      validator: (v) => _teeth(v, 20, 60),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const ActivitySectionLabel('El piñón más duro'),
              const SizedBox(height: 6),
              Text(
                'Y con esto sabe si te queda piñón para bajar cuando la '
                'cadencia se dispara. Por defecto usa '
                '${_kind.typicalHighestGear.chainring}×'
                '${_kind.typicalHighestGear.cog}.',
                style: CcType.label(size: 11, color: CcColors.inkDim),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      controller: _bigChainringCtrl,
                      label: 'Plato grande',
                      icon: Icons.settings_outlined,
                      hint: '${_kind.typicalHighestGear.chainring}',
                      keyboardType: TextInputType.number,
                      validator: (v) => _teeth(v, 24, 60),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthTextField(
                      controller: _smallCogCtrl,
                      label: 'Piñón chico',
                      icon: Icons.settings_outlined,
                      hint: '${_kind.typicalHighestGear.cog}',
                      keyboardType: TextInputType.number,
                      validator: (v) => _teeth(v, 9, 25),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const ActivitySectionLabel('Color de su ficha'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in _colors)
                    GestureDetector(
                      onTap: () => setState(() => _color = color),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _color == color
                                ? CcColors.ink
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _notesCtrl,
                label: 'Notas (opcional)',
                icon: Icons.notes_outlined,
                hint: 'Grupo nuevo, llantas de 28…',
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                activeThumbColor: CcColors.orange,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Usar esta por defecto',
                  style: CcType.displayStyle(size: 14),
                ),
                subtitle: Text(
                  'Es la que se propone al guardar una salida y con la que '
                  'cuenta el coach.',
                  style: CcType.label(size: 11, color: CcColors.inkDim),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: CcColors.orange,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(_isNew ? 'Guardar bicicleta' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _teeth(String? value, int min, int max) {
    if ((value ?? '').trim().isEmpty) return null;
    final n = int.tryParse(value!.trim());
    if (n == null || n < min || n > max) return 'Entre $min y $max';
    return null;
  }
}

class _KindCard extends StatelessWidget {
  final BikeKind kind;
  final bool selected;
  final VoidCallback onTap;

  const _KindCard({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? CcColors.orange.withValues(alpha: 0.14)
              : CcColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? CcColors.orange : CcColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kind.label,
              style: CcType.displayStyle(
                size: 14,
              ).copyWith(color: selected ? CcColors.orangeText : null),
            ),
            const SizedBox(height: 3),
            Text(
              kind.description,
              style: CcType.label(size: 10.5, color: CcColors.inkDim),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final String? path;
  final VoidCallback onTap;

  const _PhotoPicker({required this.path, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final file = path == null ? null : File(path!);
    final hasPhoto = file != null && file.existsSync();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: CcColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CcColors.line),
          image: hasPhoto
              ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
              : null,
        ),
        child: hasPhoto
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    color: CcColors.inkFaint,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ponle una foto (opcional)',
                    style: CcType.label(size: 11.5),
                  ),
                ],
              ),
      ),
    );
  }
}
