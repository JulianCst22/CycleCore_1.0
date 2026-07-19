import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../shared_widgets/stat_tile.dart';
import '../domain/activity_summary.dart';
import 'activities_providers.dart';

enum ActivityKind { race, training }

class SaveActivityScreen extends ConsumerStatefulWidget {
  final ActivitySummary summary;

  const SaveActivityScreen({super.key, required this.summary});

  @override
  ConsumerState<SaveActivityScreen> createState() =>
      _SaveActivityScreenState();
}

class _SaveActivityScreenState extends ConsumerState<SaveActivityScreen> {
  final _titleCtrl = TextEditingController(text: 'Actividad sin título');
  final _bikeCtrl = TextEditingController(text: 'Mi bicicleta');
  final _notesCtrl = TextEditingController();

  ActivityKind _kind = ActivityKind.training;
  final List<XFile> _photos = [];
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bikeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _photos.addAll(picked));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un título a la actividad.')),
      );
      return;
    }

    setState(() => _saving = true);

    await ref.read(activitiesRepositoryProvider).saveActivity(
          summary: widget.summary,
          title: _titleCtrl.text.trim(),
          activityType: _kind == ActivityKind.race ? 'race' : 'training',
          bikeName: _bikeCtrl.text.trim().isEmpty
              ? 'Mi bicicleta'
              : _bikeCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          temporaryPhotoPaths: _photos.map((f) => f.path).toList(),
        );

    if (!mounted) return;

    // Volvemos hasta la pantalla del mapa (raíz), descartando también
    // esta pantalla de guardado del stack de navegación.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _discard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panelBackground,
        title: const Text(
          '¿Descartar actividad?',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        content: const Text(
          'Se perderá todo el registro de este recorrido. Esta acción no '
          'se puede deshacer.',
          style: TextStyle(color: AppColors.textSecondaryOnPanel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Descartar',
              style: TextStyle(color: AppColors.recordButtonActive),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        elevation: 0,
        title: const Text(
          'Guardar actividad',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // --- Título ---
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(
              color: AppColors.textPrimaryOnPanel,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Título de la actividad',
              hintStyle: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
          const SizedBox(height: 16),

          // --- Tipo: Carrera / Entrenamiento ---
          Row(
            children: [
              Expanded(
                child: _KindChip(
                  label: 'Entrenamiento',
                  icon: Icons.fitness_center,
                  selected: _kind == ActivityKind.training,
                  onTap: () => setState(() => _kind = ActivityKind.training),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KindChip(
                  label: 'Carrera',
                  icon: Icons.emoji_events_outlined,
                  selected: _kind == ActivityKind.race,
                  onTap: () => setState(() => _kind = ActivityKind.race),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- Bicicleta (texto libre por ahora; gestión completa luego) ---
          _LabeledField(
            label: 'BICICLETA',
            icon: Icons.pedal_bike,
            accentColor: AppColors.accentSlope,
            controller: _bikeCtrl,
          ),
          const SizedBox(height: 24),

          // --- Totales ---
          const Text(
            'RESUMEN',
            style: TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.15,
            children: [
              StatTile(
                icon: Icons.timer_outlined,
                accentColor: AppColors.accentTime,
                value: formatDuration(s.duration),
                unit: '',
                label: 'TIEMPO',
              ),
              StatTile(
                icon: Icons.straighten,
                accentColor: AppColors.accentDistance,
                value: formatDistanceKm(s.distanceMeters),
                unit: 'km',
                label: 'DISTANCIA',
              ),
              StatTile(
                icon: Icons.speed,
                accentColor: AppColors.accentSpeed,
                value: formatSpeedKmh(s.avgSpeedKmh),
                unit: 'km/h',
                label: 'PROMEDIO',
              ),
              StatTile(
                icon: Icons.bolt,
                accentColor: AppColors.accentSpeed,
                value: formatSpeedKmh(s.maxSpeedKmh),
                unit: 'km/h',
                label: 'VEL. MÁX',
              ),
              StatTile(
                icon: Icons.terrain,
                accentColor: AppColors.accentElevation,
                value: s.elevationGainMeters.toStringAsFixed(0),
                unit: 'm',
                label: 'DESNIVEL',
              ),
              StatTile(
                icon: Icons.favorite,
                accentColor: AppColors.accentHeartRate,
                value: s.avgHeartRate?.toString() ?? '--',
                unit: 'bpm',
                label: 'FC PROM.',
              ),
              // --- Nuevos: potencia y cadencia (Fase C) ---
              StatTile(
                icon: Icons.electric_bolt,
                accentColor: AppColors.accentPower,
                value: s.avgPower?.toString() ?? '--',
                unit: 'W',
                label: 'POT. PROM.',
              ),
              StatTile(
                icon: Icons.bolt,
                accentColor: AppColors.accentPower,
                value: s.maxPower?.toString() ?? '--',
                unit: 'W',
                label: 'POT. MÁX',
              ),
              StatTile(
                icon: Icons.autorenew,
                accentColor: AppColors.accentCadence,
                value: s.avgCadence?.toString() ?? '--',
                unit: 'rpm',
                label: 'CAD. PROM.',
              ),
              StatTile(
                icon: Icons.loop,
                accentColor: AppColors.accentCadence,
                value: s.maxCadence?.toString() ?? '--',
                unit: 'rpm',
                label: 'CAD. MÁX',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Fotos ---
          const Text(
            'FOTOS',
            style: TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i < _photos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_photos[i].path),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removePhoto(i),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                GestureDetector(
                  onTap: _pickPhotos,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Notas ---
          _LabeledField(
            label: 'NOTAS (OPCIONAL)',
            icon: Icons.notes,
            accentColor: AppColors.accentTime,
            controller: _notesCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 32),

          // --- Guardar / Eliminar ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _discard,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.recordButtonActive,
                    side: const BorderSide(color: AppColors.recordButtonActive),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Eliminar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Guardar actividad',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _KindChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondaryOnPanel,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.textPrimaryOnPanel
                    : AppColors.textSecondaryOnPanel,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final TextEditingController controller;
  final int maxLines;

  const _LabeledField({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                  fontSize: 11,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
