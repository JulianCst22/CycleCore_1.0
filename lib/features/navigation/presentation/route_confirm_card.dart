import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_ui/core_ui.dart';
import '../domain/navigation_target.dart';
import '../domain/route_preview.dart';
import '../application/navigation_providers.dart';

/// Tarjeta inferior "Confirmar la ruta": aparece cuando hay un
/// `routePreviewProvider` -- muestra a dónde te manda antes de arrancar.
///
/// [onChange] vuelve al buscador de destino.
class RouteConfirmCard extends ConsumerWidget {
  final RoutePreview preview;
  final VoidCallback onChange;

  const RouteConfirmCard({
    super.key,
    required this.preview,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = preview.target;
    final saved = ref.watch(savedPlacesProvider).valueOrNull ?? const [];
    final matches = saved
        .where(
          (p) => _sameSpot(p.latitude, p.longitude, target.lat, target.lng),
        )
        .toList();
    final savedMatch = matches.isEmpty ? null : matches.first;
    final isSaved = savedMatch != null;

    final gain = preview.elevationGainMeters;
    final destAlt = preview.destinationAltitudeMeters;

    return Container(
      decoration: const BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CcColors.inkFaint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: (preview.isClimb ? CcColors.mSlope : CcColors.blue)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      preview.isClimb ? Icons.terrain : Icons.place,
                      size: 18,
                      color: preview.isClimb ? CcColors.mSlope : CcColors.blue,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CcType.displayStyle(
                            size: 17,
                            weight: FontWeight.w800,
                          ),
                        ),
                        if (destAlt != null)
                          Text(
                            '${destAlt.round()} msnm',
                            style: const TextStyle(
                              color: CcColors.inkDim,
                              fontSize: 11.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _StatsRow(
                distanceMeters: preview.distanceMeters,
                gainMeters: gain,
                time: preview.estimatedRideTime,
              ),
              if (preview.elevationSamples.length >= 2) ...[
                const SizedBox(height: 14),
                _MiniProfile(samples: preview.elevationSamples),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _OutlineButton(
                      icon: Icons.chevron_left,
                      label: 'Cambiar',
                      onTap: onChange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SaveButton(
                    isSaved: isSaved,
                    onTap: () async {
                      final repo = ref.read(savedPlacesRepositoryProvider);
                      if (isSaved) {
                        await repo.delete(savedMatch.id);
                      } else {
                        await repo.add(
                          name: target.name,
                          lat: target.lat,
                          lng: target.lng,
                          kind: preview.isClimb
                              ? PlaceKind.peak
                              : PlaceKind.generic,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: () => ref
                          .read(navigationControllerProvider)
                          .startPreviewedRoute(),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Empezar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: CcColors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameSpot(double aLat, double aLng, double bLat, double bLng) {
    final dLat = (aLat - bLat) * 111320;
    final dLng = (aLng - bLng) * 111320 * 0.9;
    return dLat * dLat + dLng * dLng < 120 * 120;
  }
}

class _StatsRow extends StatelessWidget {
  final double distanceMeters;
  final double? gainMeters;
  final Duration time;

  const _StatsRow({
    required this.distanceMeters,
    required this.gainMeters,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: CcColors.lineSoft),
          bottom: BorderSide(color: CcColors.lineSoft),
        ),
      ),
      child: Row(
        children: [
          _cell(
            'Distancia',
            formatDistanceKm(distanceMeters),
            'km',
            first: true,
          ),
          _cell(
            'Vas a subir',
            gainMeters != null ? gainMeters!.round().toString() : '--',
            'm',
          ),
          _cell('Tiempo est.', _timeValue(time), _timeUnit(time)),
        ],
      ),
    );
  }

  static String _timeValue(Duration d) => d.inMinutes >= 90
      ? (d.inMinutes / 60).toStringAsFixed(1)
      : '~${d.inMinutes}';

  static String _timeUnit(Duration d) => d.inMinutes >= 90 ? 'h' : 'min';

  Widget _cell(String label, String value, String unit, {bool first = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.fromLTRB(first ? 0 : 12, 11, 4, 11),
        decoration: BoxDecoration(
          border: first
              ? null
              : const Border(left: BorderSide(color: CcColors.lineSoft)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: CcType.label(
                size: 8.5,
                color: CcColors.inkFaint,
              ).copyWith(letterSpacing: 0.8),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: CcType.displayStyle(
                      size: 16,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: CcColors.inkDim,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniProfile extends StatelessWidget {
  final List<double?> samples;

  const _MiniProfile({required this.samples});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: CcColors.surfaceInset,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CcColors.lineSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _ProfilePainter(samples),
        size: Size.infinite,
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final List<double?> samples;

  _ProfilePainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {
    final valid = samples.whereType<double>().toList();
    if (valid.length < 2) return;
    var min = valid.first;
    var max = valid.first;
    for (final v in valid) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final span = (max - min).abs() < 1 ? 1.0 : (max - min);
    final stepX = size.width / (samples.length - 1);

    Offset? at(int i) {
      final v = samples[i];
      if (v == null) return null;
      final y = size.height - 3 - ((v - min) / span) * (size.height - 8);
      return Offset(i * stepX, y);
    }

    final line = Path();
    final area = Path();
    var started = false;
    for (var i = 0; i < samples.length; i++) {
      final o = at(i);
      if (o == null) continue;
      if (!started) {
        line.moveTo(o.dx, o.dy);
        area.moveTo(o.dx, size.height);
        area.lineTo(o.dx, o.dy);
        started = true;
      } else {
        line.lineTo(o.dx, o.dy);
        area.lineTo(o.dx, o.dy);
      }
    }
    area.lineTo((samples.length - 1) * stepX, size.height);
    area.close();

    canvas.drawPath(
      area,
      Paint()..color = CcColors.route.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = CcColors.route
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter oldDelegate) =>
      oldDelegate.samples != samples;
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: CcColors.ink,
        side: const BorderSide(color: CcColors.line),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;

  const _SaveButton({required this.isSaved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: isSaved ? CcColors.gold : CcColors.line),
        ),
        child: Icon(
          isSaved ? Icons.star : Icons.star_border,
          size: 20,
          color: isSaved ? CcColors.gold : CcColors.inkDim,
        ),
      ),
    );
  }
}
