import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/ui/ui.dart';
import '../application/ride_analysis_providers.dart';
import 'ride_climbs_screen.dart';

/// Crear segmentos desde una actividad grabada con la app: muestra las
/// subidas que encontró en la salida (y deja recortar cualquier tramo a
/// mano), con el mismo flujo que un GPX.
///
/// Devuelve el id del último segmento guardado, o `null`.
class SegmentCreationScreen extends ConsumerStatefulWidget {
  final Activity activity;

  const SegmentCreationScreen({super.key, required this.activity});

  @override
  ConsumerState<SegmentCreationScreen> createState() =>
      _SegmentCreationScreenState();
}

class _SegmentCreationScreenState extends ConsumerState<SegmentCreationScreen> {
  RideAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    if (widget.activity.routePoints.length >= 3) {
      _analysis = ref
          .read(rideAnalyzerProvider)
          .analyzeActivity(widget.activity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;
    if (analysis != null) return RideClimbsScreen(analysis: analysis);
    return Scaffold(
      backgroundColor: CcColors.bg,
      appBar: AppBar(title: const Text('Crear segmento')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Esta actividad no tiene suficientes puntos para crear un '
            'segmento.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CcColors.inkDim),
          ),
        ),
      ),
    );
  }
}
