import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../data/gpx_segment_importer.dart';
import 'segments_providers.dart';
import 'widgets/segment_altitude_profile.dart';
import 'widgets/segment_mini_map.dart';

/// Previsualización de un GPX antes de guardarlo como segmento: mapa
/// con el trazado, perfil de altimetría, stats recalculadas del propio
/// GPX y un campo de nombre. Es la última pantalla del flujo
/// "Importar segmento" (el picker de archivo lo dispara
/// `SegmentsListScreen`).
class SegmentImportPreviewScreen extends ConsumerStatefulWidget {
  final GpxImportResult result;

  const SegmentImportPreviewScreen({super.key, required this.result});

  @override
  ConsumerState<SegmentImportPreviewScreen> createState() =>
      _SegmentImportPreviewScreenState();
}

class _SegmentImportPreviewScreenState
    extends ConsumerState<SegmentImportPreviewScreen> {
  late final TextEditingController _nameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.result.suggestedName ?? 'Segmento importado',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre al segmento.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await ref.read(segmentsRepositoryProvider).createSegmentFromGpx(
            name: name,
            profilePoints: widget.result.profilePoints,
            stats: widget.result.stats,
            startBearingDegrees: widget.result.startBearingDegrees,
          );
      if (!mounted) return;
      Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo importar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final stats = result.stats;

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
        title: const Text(
          'Importar segmento',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          SegmentMiniMap(profilePoints: result.profilePoints),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'PERFIL DE ALTIMETRÍA',
              style: TextStyle(
                color: AppColors.textSecondaryOnPanel,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentAltitudeProfile(points: result.profilePoints),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: _StatsRow(
              distanceMeters: stats.distanceMeters,
              gainMeters: stats.elevationGainMeters,
              avgSlope: stats.avgSlopePercent,
              maxSlope: stats.maxSlopePercent,
            ),
          ),
          if (!result.elevationLooksReliable)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                'Este GPX trae poca o ninguna altitud -- la distancia y la '
                'posición son fiables, pero la pendiente puede no serlo. '
                'Si es un GPX de ciclocomputador debería traerla; revisá el '
                'archivo.',
                style: TextStyle(
                  color: AppColors.segmentEnd,
                  fontSize: 12,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimaryOnPanel),
              decoration: InputDecoration(
                labelText: 'Nombre del segmento',
                labelStyle:
                    const TextStyle(color: AppColors.textSecondaryOnPanel),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar segmento',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final double distanceMeters;
  final double gainMeters;
  final double avgSlope;
  final double maxSlope;

  const _StatsRow({
    required this.distanceMeters,
    required this.gainMeters,
    required this.avgSlope,
    required this.maxSlope,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _cell('DISTANCIA', '${formatDistanceKm(distanceMeters)} km'),
          _cell('DESNIVEL +', '${gainMeters.toStringAsFixed(0)} m'),
          _cell('PEND. PROM', formatSlopePercent(avgSlope)),
          _cell('PEND. MÁX', formatSlopePercent(maxSlope)),
        ],
      ),
    );
  }

  Widget _cell(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimaryOnPanel,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}
