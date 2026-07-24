import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../domain/activity_json_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../shared_widgets/stat_tile.dart';
import '../domain/activity_summary.dart';
import 'activities_providers.dart';

enum ActivityKind { race, training }

/// Pantalla de guardar/editar actividad.
///
/// Se usa en dos modos, según qué se pase al constructor:
/// - `summary` (grabación recién terminada) -> modo "crear": guarda una
///   actividad nueva a partir de los datos en vivo del recorrido.
/// - `existingActivity` -> modo "editar": precarga los datos ya
///   guardados y permite modificarlos (o eliminar la actividad).
class SaveActivityScreen extends ConsumerStatefulWidget {
  final ActivitySummary? summary;
  final Activity? existingActivity;

  const SaveActivityScreen({
    super.key,
    this.summary,
    this.existingActivity,
  }) : assert(
          summary != null || existingActivity != null,
          'SaveActivityScreen necesita summary (nueva grabación) o '
          'existingActivity (editar una ya guardada).',
        );

  bool get isEditing => existingActivity != null;

  @override
  ConsumerState<SaveActivityScreen> createState() =>
      _SaveActivityScreenState();
}

class _SaveActivityScreenState extends ConsumerState<SaveActivityScreen> {
  final _titleCtrl = TextEditingController();
  final _bikeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  ActivityKind _kind = ActivityKind.training;

  // Fotos ya guardadas (solo existen en modo edición, con ruta
  // permanente) y fotos nuevas elegidas en esta sesión (con ruta
  // temporal del picker) -- se combinan al guardar.
  final List<String> _existingPhotoPaths = [];
  final List<XFile> _newPhotos = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingActivity;
    _titleCtrl.text = existing?.title ?? 'Actividad sin título';
    _bikeCtrl.text = existing?.bikeName ?? 'Mi bicicleta';
    _notesCtrl.text = existing?.notes ?? '';
    if (existing != null) {
      _kind = existing.activityType == 'race'
          ? ActivityKind.race
          : ActivityKind.training;
      _existingPhotoPaths.addAll(existing.photoPaths);
    }
  }

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
      setState(() => _newPhotos.addAll(picked));
    }
  }

  void _removeExistingPhoto(int index) {
    setState(() => _existingPhotoPaths.removeAt(index));
  }

  void _removeNewPhoto(int index) {
    setState(() => _newPhotos.removeAt(index));
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un título a la actividad.')),
      );
      return;
    }

    setState(() => _saving = true);

    final repo = ref.read(activitiesRepositoryProvider);
    final title = _titleCtrl.text.trim();
    final activityType = _kind == ActivityKind.race ? 'race' : 'training';
    final bikeName =
        _bikeCtrl.text.trim().isEmpty ? 'Mi bicicleta' : _bikeCtrl.text.trim();
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    if (widget.isEditing) {
      final newTempPaths = _newPhotos.map((f) => f.path).toList();
      await repo.updateActivity(
        id: widget.existingActivity!.id,
        title: title,
        activityType: activityType,
        bikeName: bikeName,
        notes: notes,
        photoPaths: [..._existingPhotoPaths, ...newTempPaths],
        newTemporaryPhotoPaths: newTempPaths,
      );
      if (!mounted) return;
      // Devuelve `true` para que el detalle sepa que debe refrescar.
      Navigator.of(context).pop(true);
    } else {
      await repo.saveActivity(
        summary: widget.summary!,
        title: title,
        activityType: activityType,
        bikeName: bikeName,
        notes: notes,
        temporaryPhotoPaths: _newPhotos.map((f) => f.path).toList(),
      );
      if (!mounted) return;
      // Volvemos hasta la pantalla del mapa (raíz), descartando también
      // esta pantalla de guardado del stack de navegación.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _discardOrDelete() async {
    final isEditing = widget.isEditing;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panelBackground,
        title: Text(
          isEditing ? '¿Eliminar actividad?' : '¿Descartar actividad?',
          style: const TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        content: Text(
          isEditing
              ? 'Esta acción no se puede deshacer.'
              : 'Se perderá todo el registro de este recorrido. Esta '
                  'acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.textSecondaryOnPanel),
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
              'Eliminar',
              style: TextStyle(color: AppColors.recordButtonActive),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (isEditing) {
      await ref
          .read(activitiesRepositoryProvider)
          .deleteActivity(widget.existingActivity!.id);
      if (!mounted) return;
      // Devuelve 'deleted' para que la pantalla de detalle (que sigue
      // debajo en el stack) sepa que también debe cerrarse.
      Navigator.of(context).pop('deleted');
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existingActivity;
    final summary = widget.summary;

    // Los totales pueden venir de una grabación en vivo (`summary`) o
    // de una actividad ya guardada que se está editando (`existing`).
    //
    // OJO: decidimos la FUENTE una sola vez (summary != null) y NO
    // campo por campo con `??`, porque un campo individual (FC,
    // potencia, cadencia) puede ser legítimamente null si no había
    // sensor conectado durante la grabación -- y eso NO significa
    // "usa la otra fuente". Antes, `summary?.avgPower ?? existing!.avgPower`
    // caía en el `existing!` cuando `avgPower` era null aunque `summary`
    // sí existiera, y como `existing` es null en modo grabación, crasheaba.
    late final Duration duration;
    late final double distanceMeters;
    late final double avgSpeedKmh;
    late final double maxSpeedKmh;
    late final double elevationGainMeters;
    late final int? avgHeartRate;
    late final int? avgPower;
    late final int? maxPower;
    late final int? avgCadence;
    late final int? maxCadence;

    if (summary != null) {
      duration = summary.duration;
      distanceMeters = summary.distanceMeters;
      avgSpeedKmh = summary.avgSpeedKmh;
      maxSpeedKmh = summary.maxSpeedKmh;
      elevationGainMeters = summary.elevationGainMeters;
      avgHeartRate = summary.avgHeartRate;
      avgPower = summary.avgPower;
      maxPower = summary.maxPower;
      avgCadence = summary.avgCadence;
      maxCadence = summary.maxCadence;
    } else {
      duration = Duration(seconds: existing!.durationSeconds);
      distanceMeters = existing.distanceMeters;
      avgSpeedKmh = existing.avgSpeedKmh;
      maxSpeedKmh = existing.maxSpeedKmh;
      elevationGainMeters = existing.elevationGainMeters;
      avgHeartRate = existing.avgHeartRate;
      avgPower = existing.avgPower;
      maxPower = existing.maxPower;
      avgCadence = existing.avgCadence;
      maxCadence = existing.maxCadence;
    }

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Editar actividad' : 'Guardar actividad',
          style: const TextStyle(color: AppColors.textPrimaryOnPanel),
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
                value: formatDuration(duration),
                unit: '',
                label: 'TIEMPO',
              ),
              StatTile(
                icon: Icons.straighten,
                accentColor: AppColors.accentDistance,
                value: formatDistanceKm(distanceMeters),
                unit: 'km',
                label: 'DISTANCIA',
              ),
              StatTile(
                icon: Icons.speed,
                accentColor: AppColors.accentSpeed,
                value: formatSpeedKmh(avgSpeedKmh),
                unit: 'km/h',
                label: 'PROMEDIO',
              ),
              StatTile(
                icon: Icons.bolt,
                accentColor: AppColors.accentSpeed,
                value: formatSpeedKmh(maxSpeedKmh),
                unit: 'km/h',
                label: 'VEL. MÁX',
              ),
              StatTile(
                icon: Icons.terrain,
                accentColor: AppColors.accentElevation,
                value: elevationGainMeters.toStringAsFixed(0),
                unit: 'm',
                label: 'DESNIVEL',
              ),
              StatTile(
                icon: Icons.favorite,
                accentColor: AppColors.accentHeartRate,
                value: avgHeartRate?.toString() ?? '--',
                unit: 'bpm',
                label: 'FC PROM.',
              ),
              // --- Nuevos: potencia y cadencia (Fase C) ---
              StatTile(
                icon: Icons.electric_bolt,
                accentColor: AppColors.accentPower,
                value: avgPower?.toString() ?? '--',
                unit: 'W',
                label: 'POT. PROM.',
              ),
              StatTile(
                icon: Icons.bolt,
                accentColor: AppColors.accentPower,
                value: maxPower?.toString() ?? '--',
                unit: 'W',
                label: 'POT. MÁX',
              ),
              StatTile(
                icon: Icons.autorenew,
                accentColor: AppColors.accentCadence,
                value: avgCadence?.toString() ?? '--',
                unit: 'rpm',
                label: 'CAD. PROM.',
              ),
              StatTile(
                icon: Icons.loop,
                accentColor: AppColors.accentCadence,
                value: maxCadence?.toString() ?? '--',
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
                // Fotos que ya estaban guardadas (solo en modo editar).
                for (int i = 0; i < _existingPhotoPaths.length; i++)
                  _PhotoThumb(
                    imageFile: File(_existingPhotoPaths[i]),
                    onRemove: () => _removeExistingPhoto(i),
                  ),
                // Fotos nuevas elegidas en esta sesión.
                for (int i = 0; i < _newPhotos.length; i++)
                  _PhotoThumb(
                    imageFile: File(_newPhotos[i].path),
                    onRemove: () => _removeNewPhoto(i),
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
                  onPressed: _saving ? null : _discardOrDelete,
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
                      : Text(
                          widget.isEditing
                              ? 'Guardar cambios'
                              : 'Guardar actividad',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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

class _PhotoThumb extends StatelessWidget {
  final File imageFile;
  final VoidCallback onRemove;

  const _PhotoThumb({required this.imageFile, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              imageFile,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                color: AppColors.panelBackground,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSecondaryOnPanel,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
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