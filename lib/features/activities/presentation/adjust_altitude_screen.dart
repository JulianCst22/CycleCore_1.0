import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../elevation/presentation/elevation_providers.dart';
import '../domain/activity_json_helpers.dart';
import '../domain/activity_summary.dart';
import '../domain/elevation_gain_loss.dart';
import 'activities_providers.dart';

/// "Ajustar altimetría" -- vuelve a correr el aplanado de una actividad
/// ya guardada usando la cadena de prioridades ACTUAL (GPX > HGT >
/// fusión). Se puede repetir: si descargás teselas HGT de la zona o
/// importás un GPX del recorrido y volvés a tocar "Re-procesar", el
/// resultado mejora.
class AdjustAltitudeScreen extends ConsumerStatefulWidget {
  final int activityId;

  const AdjustAltitudeScreen({super.key, required this.activityId});

  @override
  ConsumerState<AdjustAltitudeScreen> createState() =>
      _AdjustAltitudeScreenState();
}

class _AdjustAltitudeScreenState extends ConsumerState<AdjustAltitudeScreen> {
  Activity? _activity;
  bool _loading = true;
  bool _processing = false;
  String? _statusMessage;
  bool _statusOk = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);
    final activity = await db.getActivityById(widget.activityId);
    if (!mounted) return;
    setState(() {
      _activity = activity;
      _loading = false;
    });
  }

  Future<void> _reprocess() async {
    setState(() {
      _processing = true;
      _statusMessage = null;
    });
    try {
      final result =
          await ref.read(activitiesRepositoryProvider).readjustAltitude(
                activityId: widget.activityId,
                resolver: ref.read(elevationResolverProvider),
              );
      await _load();
      if (!mounted) return;
      final pct = (result.reliableFraction * 100).round();
      setState(() {
        _statusOk = pct >= 80;
        _statusMessage = 'Listo. Desnivel: '
            '+${result.gainMeters.toStringAsFixed(0)} m / '
            '−${result.lossMeters.toStringAsFixed(0)} m.\n'
            '$pct% de los puntos con fuente precisa '
            '(${result.gpxPoints} GPX · ${result.hgtPoints} HGT · '
            '${result.approxPoints} aproximados).';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusOk = false;
        _statusMessage = 'No se pudo ajustar: $e';
      });
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
        title: const Text(
          'Ajustar altimetría',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _activity == null
              ? const Center(
                  child: Text(
                    'La actividad ya no existe.',
                    style: TextStyle(color: AppColors.textSecondaryOnPanel),
                  ),
                )
              : _body(_activity!),
    );
  }

  Widget _body(Activity activity) {
    final points = activity.routePoints;
    final loss = points.length < 2
        ? 0.0
        : computeGainLoss(points.map((p) => p.altitude).toList()).lossMeters;
    final approx = points.where((p) => p.isElevationApproximate).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text(
          'PERFIL ACTUAL',
          style: TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: points.length < 2
              ? const Center(
                  child: Text(
                    'Sin trazado.',
                    style: TextStyle(color: AppColors.textSecondaryOnPanel),
                  ),
                )
              : CustomPaint(painter: _ProfilePainter(points)),
        ),
        const SizedBox(height: 16),
        _StatRow(
          label: 'Desnivel positivo',
          value: '+${activity.elevationGainMeters.toStringAsFixed(0)} m',
        ),
        _StatRow(
          label: 'Desnivel negativo',
          value: '−${loss.toStringAsFixed(0)} m',
        ),
        _StatRow(
          label: 'Puntos aproximados',
          value: '$approx de ${points.length}',
        ),
        const SizedBox(height: 20),
        const Text(
          'Si el desnivel no cuadra (p.ej. una subida pura te marca '
          'desnivel negativo alto), es porque en esa zona no había '
          'datos precisos al grabar. Para mejorarlo:',
          style: TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        const _Bullet('Descargá las teselas de tu zona en '
            'Ajustes → Elevación.'),
        const _Bullet('Importá un GPX del recorrido en Segmentos '
            '(su altimetría barométrica tiene prioridad 1).'),
        const _Bullet('Volvé acá y tocá "Re-procesar" -- podés repetir '
            'hasta que quede bien.'),
        const SizedBox(height: 20),
        if (_statusMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_statusOk ? AppColors.segmentStart : AppColors.accentSlope)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: _statusOk
                    ? AppColors.segmentStart
                    : AppColors.textPrimaryOnPanel,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _processing ? null : _reprocess,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            label: Text(
              _processing ? 'Procesando...' : 'Re-procesar altimetría',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimaryOnPanel,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: AppColors.textSecondaryOnPanel)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondaryOnPanel,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final List<RoutePointSnapshot> points;
  const _ProfilePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final total = points.last.distanceFromStartMeters;
    if (total <= 0) return;

    double minA = points.first.altitude;
    double maxA = points.first.altitude;
    for (final p in points) {
      if (p.altitude < minA) minA = p.altitude;
      if (p.altitude > maxA) maxA = p.altitude;
    }
    final span = maxA - minA;

    Offset o(RoutePointSnapshot p) {
      final x = (p.distanceFromStartMeters / total) * size.width;
      final t = span <= 0 ? 0.5 : (p.altitude - minA) / span;
      return Offset(x, size.height - t * size.height);
    }

    final path = Path();
    final fill = Path()..moveTo(0, size.height);
    for (int i = 0; i < points.length; i++) {
      final pt = o(points[i]);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
      fill.lineTo(pt.dx, pt.dy);
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()..color = AppColors.accentElevation.withValues(alpha: 0.15),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accentElevation
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter oldDelegate) =>
      oldDelegate.points != points;
}
