import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cyclecore_core/database/app_database.dart';
import 'package:cyclecore_core/theme/app_colors.dart';
import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/utils/format_utils.dart';
import '../../profile/domain/activity_climb_result.dart';
import '../../profile/domain/xp_calculator.dart';
import '../../profile/presentation/climb_screen.dart';
import '../../profile/presentation/xp_debug_provider.dart';
import 'package:cyclecore_core/database/activity_json_helpers.dart';
import 'package:cyclecore_core/database/activity_summary.dart';
import 'activities_providers.dart';
import 'widgets/activity_summary_block.dart';

enum ActivityKind { race, training }

/// Pantalla de guardar/editar actividad.
///
/// Se usa en dos modos, según qué se pase al constructor:
/// - `summary` (grabación recién terminada) -> modo "crear": guarda una
///   actividad nueva a partir de los datos en vivo del recorrido.
/// - `existingActivity` -> modo "editar": precarga los datos ya
///   guardados y permite modificarlos (o eliminar la actividad).
///
/// El bloque "Resumen" reusa los mismos widgets que el detalle de la
/// actividad ([ActivitySummaryHero], [ActivityDividedRow],
/// [ActivityDataRow]) -- antes los totales se veían de una forma al
/// guardar y de otra al abrir la actividad.
class SaveActivityScreen extends ConsumerStatefulWidget {
  final ActivitySummary? summary;
  final Activity? existingActivity;

  /// Se llama tras guardar una actividad NUEVA (no en modo editar), ya
  /// con el id asignado en la base de datos. Quien construya esta
  /// pantalla (hoy, `MapScreen`) decide qué hacer con los esfuerzos de
  /// segmento detectados durante la grabación -- esta pantalla ya no
  /// conoce `SegmentDetectionController` directamente.
  final Future<void> Function(int activityId)? onActivitySaved;

  /// Se llama al descartar una grabación nueva (no en modo editar), antes
  /// de volver al mapa -- típicamente para tirar esos mismos esfuerzos
  /// de segmento bufferizados.
  final VoidCallback? onRecordingDiscarded;

  const SaveActivityScreen({
    super.key,
    this.summary,
    this.existingActivity,
    this.onActivitySaved,
    this.onRecordingDiscarded,
  }) : assert(
        summary != null || existingActivity != null,
        'SaveActivityScreen necesita summary (nueva grabación) o '
        'existingActivity (editar una ya guardada).',
      );

  bool get isEditing => existingActivity != null;

  @override
  ConsumerState<SaveActivityScreen> createState() => _SaveActivityScreenState();
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
    final bikeName = _bikeCtrl.text.trim().isEmpty
        ? 'Mi bicicleta'
        : _bikeCtrl.text.trim();
    final notes = _notesCtrl.text.trim().isEmpty
        ? null
        : _notesCtrl.text.trim();

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
      final navigator = Navigator.of(context);

      // XP total ANTES de guardar (para el avance del ciclista de "la
      // subida" en modo post-actividad). El XP se recalcula desde las
      // actividades, no se persiste -- ver [XpCalculator].
      final xpBefore = XpCalculator.totalXpFor(
        ref.read(activitiesListProvider).valueOrNull ?? const <Activity>[],
      );
      final debugXpActive = ref.read(xpDebugOverrideProvider) != null;

      final activityId = await repo.saveActivity(
        summary: widget.summary!,
        title: title,
        activityType: activityType,
        bikeName: bikeName,
        notes: notes,
        temporaryPhotoPaths: _newPhotos.map((f) => f.path).toList(),
      );
      // Avisa a quien nos construyó (ver `onActivitySaved`) que ya hay
      // id -- típicamente para volcar los esfuerzos de segmento
      // detectados durante la grabación.
      await widget.onActivitySaved?.call(activityId);

      // XP total DESPUÉS de guardar -- recalculado sobre la lista ya con
      // la actividad nueva (una salida puede además cambiar el récord
      // personal de otras, así que hay que recalcular todo el conjunto).
      ActivityClimbResult? climbResult;
      if (!debugXpActive) {
        try {
          final after = await repo.watchActivities().first;
          climbResult = computeActivityClimbResult(
            totalXpBefore: xpBefore,
            totalXpAfter: XpCalculator.totalXpFor(after),
          );
        } catch (_) {
          climbResult = null;
        }
      }

      if (!mounted) return;
      // Volvemos hasta la pantalla del mapa (raíz), descartando esta
      // pantalla de guardado, y encima abrimos "la subida" en modo
      // post-actividad: el ciclista avanza por el Alto de Patios según
      // la XP ganada (aunque no haya subido de nivel).
      navigator.popUntil((route) => route.isFirst);
      if (climbResult != null && climbResult.xpGained > 0) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ClimbScreen(activityResult: climbResult),
          ),
        );
      }
    }
  }

  Future<void> _discardOrDelete() async {
    final isEditing = widget.isEditing;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CcColors.surfaceHi,
        title: Text(
          isEditing ? '¿Eliminar actividad?' : '¿Descartar actividad?',
          style: const TextStyle(color: CcColors.ink),
        ),
        content: Text(
          isEditing
              ? 'Esta acción no se puede deshacer.'
              : 'Se perderá todo el registro de este recorrido. Esta '
                    'acción no se puede deshacer.',
          style: const TextStyle(color: CcColors.inkDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: CcColors.inkDim),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isEditing ? 'Eliminar' : 'Descartar',
              style: const TextStyle(color: CcColors.danger),
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
      // Se descarta la grabación -> avisa a quien nos construyó (ver
      // `onRecordingDiscarded`), típicamente para tirar los esfuerzos
      // de segmento detectados en ella.
      widget.onRecordingDiscarded?.call();
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
    late final int? maxHeartRate;
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
      maxHeartRate = summary.maxHeartRate;
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
      maxHeartRate = existing.maxHeartRate;
      avgPower = existing.avgPower;
      maxPower = existing.maxPower;
      avgCadence = existing.avgCadence;
      maxCadence = existing.maxCadence;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar actividad' : 'Guardar actividad',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // --- Título ---
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: CcColors.lineSoft)),
            ),
            child: TextField(
              controller: _titleCtrl,
              style: const TextStyle(
                color: CcColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.02,
              ),
              cursorColor: CcColors.blue,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.only(bottom: 10),
                hintText: 'Título de la actividad',
                hintStyle: TextStyle(color: CcColors.inkFaint),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Tipo: Entrenamiento (cian) / Carrera (naranja) ---
          Row(
            children: [
              Expanded(
                child: _KindChip(
                  label: 'Entrenamiento',
                  icon: Icons.fitness_center,
                  accent: CcColors.entreno,
                  selected: _kind == ActivityKind.training,
                  onTap: () => setState(() => _kind = ActivityKind.training),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KindChip(
                  label: 'Carrera',
                  icon: Icons.emoji_events_outlined,
                  accent: CcColors.orange,
                  selected: _kind == ActivityKind.race,
                  onTap: () => setState(() => _kind = ActivityKind.race),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Bicicleta (texto libre por ahora; gestión completa luego) ---
          _BoxedField(
            label: 'BICICLETA',
            icon: Icons.pedal_bike,
            controller: _bikeCtrl,
          ),
          const SizedBox(height: 24),

          // --- Resumen: el mismo bloque que el detalle de la actividad ---
          const ActivitySectionLabel('Resumen'),
          const SizedBox(height: 10),
          ActivitySummaryHero(
            label: 'Distancia',
            value: formatDistanceKm(distanceMeters),
            unit: 'km',
          ),
          ActivityDividedRow(
            cells: [
              ActivityStatCell(
                label: 'Tiempo',
                value: formatDuration(duration),
              ),
              ActivityStatCell(
                label: 'Promedio',
                value: formatSpeedKmh(avgSpeedKmh),
                unit: 'km/h',
              ),
              ActivityStatCell(
                label: 'Desnivel+',
                value: elevationGainMeters.toStringAsFixed(0),
                unit: 'm',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._summaryDataRows(
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            avgPower: avgPower,
            maxPower: maxPower,
            avgCadence: avgCadence,
            maxCadence: maxCadence,
            maxSpeedKmh: maxSpeedKmh,
          ),
          const SizedBox(height: 24),

          // --- Fotos ---
          const ActivitySectionLabel('Fotos'),
          const SizedBox(height: 12),
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
                      color: CcColors.orange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CcColors.orange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: CcColors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Notas ---
          const ActivitySectionLabel('Notas · opcional'),
          const SizedBox(height: 12),
          _BoxedField(
            icon: Icons.notes,
            controller: _notesCtrl,
            hintText: 'Cómo te sentiste, el clima, con quién…',
            maxLines: 3,
          ),
          const SizedBox(height: 32),

          // --- Descartar/Eliminar / Guardar ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _discardOrDelete,
                  icon: Icon(
                    widget.isEditing ? Icons.delete_outline : Icons.close,
                    size: 18,
                  ),
                  label: Text(widget.isEditing ? 'Eliminar' : 'Descartar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CcColors.danger,
                    side: const BorderSide(color: CcColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(
                    widget.isEditing ? 'Guardar cambios' : 'Guardar actividad',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: CcColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Filas de sensores del resumen. Un sensor que no grabó nada
  /// (no había pulsómetro / potenciómetro / sensor de cadencia en esa
  /// salida) muestra "Sin datos" en gris en vez de "-- · --": así, antes
  /// de guardar, ves de una qué se registró.
  List<Widget> _summaryDataRows({
    required int? avgHeartRate,
    required int? maxHeartRate,
    required int? avgPower,
    required int? maxPower,
    required int? avgCadence,
    required int? maxCadence,
    required double maxSpeedKmh,
  }) {
    ActivityDataValue pair(String tag, int? value) =>
        (pair: tag, value: value?.toString() ?? '--', gold: false);

    final hasHr = avgHeartRate != null || maxHeartRate != null;
    final hasPower = avgPower != null || maxPower != null;
    final hasCadence = avgCadence != null || maxCadence != null;

    return [
      ActivityDataRow(
        icon: Icons.favorite,
        iconColor: AppColors.accentHeartRate,
        label: 'Ritmo cardíaco',
        unit: 'bpm',
        emptyPlaceholder: 'Sin datos',
        values: hasHr
            ? [pair('prom', avgHeartRate), pair('máx', maxHeartRate)]
            : const [],
      ),
      ActivityDataRow(
        icon: Icons.electric_bolt,
        iconColor: AppColors.accentPower,
        label: 'Potencia',
        unit: 'W',
        emptyPlaceholder: 'Sin datos',
        values: hasPower
            ? [pair('prom', avgPower), pair('máx', maxPower)]
            : const [],
      ),
      ActivityDataRow(
        icon: Icons.autorenew,
        iconColor: AppColors.accentCadence,
        label: 'Cadencia',
        unit: 'rpm',
        emptyPlaceholder: 'Sin datos',
        values: hasCadence
            ? [pair('prom', avgCadence), pair('máx', maxCadence)]
            : const [],
      ),
      ActivityDataRow(
        icon: Icons.speed,
        iconColor: AppColors.accentSpeed,
        label: 'Velocidad máx',
        unit: 'km/h',
        values: <ActivityDataValue>[
          (pair: null, value: formatSpeedKmh(maxSpeedKmh), gold: false),
        ],
      ),
    ];
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
              errorBuilder: (_, _, _) => Container(
                width: 90,
                height: 90,
                color: CcColors.surface,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: CcColors.inkDim,
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

/// Chip de tipo de actividad. Seleccionado se pinta con su [accent]
/// (cian para Entrenamiento, naranja para Carrera).
class _KindChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _KindChip({
    required this.label,
    required this.icon,
    required this.accent,
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
              ? accent.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? accent : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? accent : CcColors.inkDim),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? CcColors.ink : CcColors.inkDim,
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

/// Campo de texto en caja hundida, al estilo del resto de la app.
/// Con [label] muestra una etiqueta en versalitas dentro de la caja
/// (bici); sin ella, solo el ícono y el texto (notas).
class _BoxedField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final IconData icon;
  final TextEditingController controller;
  final int maxLines;

  const _BoxedField({
    required this.icon,
    required this.controller,
    this.label,
    this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: CcColors.surfaceInset,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: CcColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: CcColors.inkDim, size: 16),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      label!.toUpperCase(),
                      style: const TextStyle(
                        color: CcColors.inkFaint,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  style: const TextStyle(color: CcColors.ink, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(color: CcColors.inkFaint),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
