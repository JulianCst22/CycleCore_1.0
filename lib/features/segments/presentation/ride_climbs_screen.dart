import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/platform/platform.dart' show CachedTileProvider;
import '../../../core/ui/ui.dart';
import '../application/ride_analysis_providers.dart';
import '../domain/climb_finder.dart';
import '../domain/ride_track.dart';
import 'segment_cut_editor.dart';

/// Las subidas de una salida (un GPX o una actividad de la app), para
/// elegir cuáles guardar como segmento.
///
/// Arriba, la salida entera en el mapa y en el perfil con las subidas
/// numeradas; abajo, una tarjeta por subida con sus cifras. Tocar una
/// abre el editor para ajustar dónde empieza y termina. Si la salida es
/// un GPX, también aparecen los segmentos que ya tienes por los que pasa,
/// con su tiempo para guardarlo como marca de antes de la app.
///
/// Al cerrarse devuelve el id del último segmento guardado (o `null`).
class RideClimbsScreen extends ConsumerStatefulWidget {
  final RideAnalysis analysis;

  const RideClimbsScreen({super.key, required this.analysis});

  @override
  ConsumerState<RideClimbsScreen> createState() => _RideClimbsScreenState();
}

class _RideClimbsScreenState extends ConsumerState<RideClimbsScreen> {
  /// Subidas ya guardadas en esta pantalla: índice → nombre.
  final Map<int, String> _savedClimbs = {};
  final Set<int> _savedPasses = {};
  int? _lastSavedId;

  RideAnalysis get _a => widget.analysis;

  Future<void> _openClimb(int index) async {
    final climb = _a.climbs[index];
    final km = _km(climb.startMeters);
    await _openEditor(
      start: climb.startIndex,
      end: climb.endIndex,
      name: 'Subida del km $km',
      heading: 'Subida ${index + 1} · ${climb.category.label}',
      climbIndex: index,
    );
  }

  Future<void> _openManual() async {
    final t = _a.track;
    final total = t.totalDistance;
    final span = math.max(1000.0, total * 0.2);
    final from = t.indexAtDistance(math.max(0, total / 2 - span / 2));
    final to = t.indexAtDistance(math.min(total, total / 2 + span / 2));
    await _openEditor(
      start: from,
      end: math.max(from + 1, to),
      name: _a.title,
      heading: 'Recortar a mano',
    );
  }

  Future<void> _openEditor({
    required int start,
    required int end,
    required String name,
    required String heading,
    int? climbIndex,
  }) async {
    final id = await Navigator.of(context).push<int?>(
      MaterialPageRoute(
        builder: (_) => SegmentCutEditor(
          analysis: _a,
          initialStart: start,
          initialEnd: end,
          suggestedName: name,
          heading: heading,
        ),
      ),
    );
    if (id == null || !mounted) return;
    _lastSavedId = id;
    if (climbIndex != null) setState(() => _savedClimbs[climbIndex] = name);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Segmento guardado.')));
  }

  Future<void> _savePassTime(int index) async {
    final found = _a.passes[index];
    await ref
        .read(rideAnalyzerProvider)
        .saveTimeFromPass(_a, found.segment, found.pass);
    if (!mounted) return;
    setState(() => _savedPasses.add(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Guardado como tu marca de antes en «${found.segment.name}».',
        ),
      ),
    );
  }

  /// La subida coincide en su mayor parte con un segmento que ya tienes.
  String? _existingSegmentFor(DetectedClimb climb) {
    for (final p in _a.passes) {
      final overlap =
          math.min(climb.endIndex, p.pass.endIndex) -
          math.max(climb.startIndex, p.pass.startIndex);
      final length = climb.endIndex - climb.startIndex;
      if (length > 0 && overlap / length > 0.6) return p.segment.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = _a.track;
    final total = t.statsBetween(0, t.length - 1);
    final climbs = _a.climbs;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_lastSavedId);
      },
      child: Scaffold(
        backgroundColor: CcColors.bg,
        appBar: AppBar(title: const Text('Subidas de la salida')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text(
              _a.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CcType.displayStyle(size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (_a.date != null)
                  '${formatShortDate(_a.date!.toLocal())} ${_a.date!.year}',
                '${_comma(formatDistanceKm(total.distanceMeters))} km',
                '+${formatThousands(total.elevationGainMeters.round())} m',
                if (_a.isGpx) 'GPX',
              ].join(' · '),
              style: CcType.label(size: 12, color: CcColors.inkDim),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                child: _OverviewMap(
                  track: t,
                  climbs: climbs,
                  onTapClimb: _openClimb,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _OverviewProfile(track: t, climbs: climbs, onTapClimb: _openClimb),
            const SizedBox(height: 16),
            Text(
              climbs.isEmpty
                  ? 'No encontramos subidas de al menos 500 m al 3 %. '
                        'Puedes recortar un tramo a mano.'
                  : climbs.length == 1
                  ? 'Encontramos una posible subida. Tócala para verla en '
                        'detalle, ajustar dónde empieza y termina y guardarla '
                        'como segmento.'
                  : 'Encontramos ${climbs.length} posibles subidas. Toca '
                        'cualquiera para verla en detalle, ajustar dónde '
                        'empieza y termina y guardarla como segmento.',
              style: const TextStyle(
                color: CcColors.ink,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < climbs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ClimbCard(
                  number: i + 1,
                  climb: climbs[i],
                  track: t,
                  savedAs: _savedClimbs[i],
                  existing: _existingSegmentFor(climbs[i]),
                  onTap: () => _openClimb(i),
                ),
              ),
            if (_a.isGpx) ..._passesSection(t),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: OutlinedButton.icon(
              onPressed: _openManual,
              icon: const Icon(Icons.content_cut, size: 18),
              label: const Text('Recortar un tramo a mano'),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _passesSection(RideTrack t) {
    if (!t.hasTime) {
      return const [
        SizedBox(height: 10),
        _Note(
          text:
              'Este GPX no trae la hora de cada punto: se pueden recortar '
              'segmentos, pero no medir tus tiempos de antes de la app.',
        ),
      ];
    }
    if (_a.passes.isEmpty) return const [];
    return [
      const SizedBox(height: 14),
      Text(
        'TUS SEGMENTOS EN ESTA SALIDA',
        style: CcType.label(
          size: 11,
          color: CcColors.inkFaint,
        ).copyWith(letterSpacing: 1.2),
      ),
      const SizedBox(height: 6),
      const Text(
        'Estos tiempos son de antes de la app. Guárdalos para compararlos '
        'en «Mi progreso».',
        style: TextStyle(color: CcColors.inkDim, fontSize: 12.5, height: 1.4),
      ),
      const SizedBox(height: 6),
      for (var i = 0; i < _a.passes.length; i++)
        _PassRow(
          found: _a.passes[i],
          startMeters: t.distances[_a.passes[i].pass.startIndex],
          saved: _a.passes[i].alreadySaved || _savedPasses.contains(i),
          onSave: () => _savePassTime(i),
        ),
    ];
  }
}

String _km(double meters) => _comma((meters / 1000).toStringAsFixed(1));

String _comma(String number) => number.replaceAll('.', ',');

class _Note extends StatelessWidget {
  final String text;
  const _Note({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: CcColors.surfaceInset,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Text(
        text,
        style: const TextStyle(color: CcColors.inkDim, fontSize: 12.5),
      ),
    );
  }
}

/// Una subida encontrada.
class _ClimbCard extends StatelessWidget {
  final int number;
  final DetectedClimb climb;
  final RideTrack track;
  final String? savedAs;
  final String? existing;
  final VoidCallback onTap;

  const _ClimbCard({
    required this.number,
    required this.climb,
    required this.track,
    required this.savedAs,
    required this.existing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = climb.stats;
    final chunkMeters = math.max(100.0, s.distanceMeters / 14);
    final chunks = track.chunks(climb.startIndex, climb.endIndex, chunkMeters);

    return Material(
      color: CcColors.surfaceHi,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CcColors.lineSoft),
          ),
          child: Row(
            children: [
              _NumberBadge(number: number),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Subida $number',
                          style: CcType.displayStyle(size: 15.5),
                        ),
                        const SizedBox(width: 8),
                        _Chip(text: climb.category.label),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'km ${_km(climb.startMeters)} – '
                      '${_km(climb.startMeters + s.distanceMeters)} de la salida',
                      style: CcType.label(size: 11.5, color: CcColors.inkDim),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 12,
                      runSpacing: 3,
                      children: [
                        _Fact(
                          '${_comma(formatDistanceKm(s.distanceMeters))} km',
                        ),
                        _Fact(
                          '${_comma(s.avgGradePercent.toStringAsFixed(1))} % media',
                        ),
                        _Fact(
                          'máx ${_comma(s.maxGradePercent.toStringAsFixed(1))} %',
                        ),
                        _Fact('+${s.elevationGainMeters.round()} m'),
                        if (s.duration != null)
                          _Fact(formatElapsedShort(s.duration!)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 7,
                      child: Row(
                        children: [
                          for (final c in chunks)
                            Expanded(
                              flex: math.max(
                                1,
                                (c.endMeters - c.startMeters).round(),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(right: 1.5),
                                decoration: BoxDecoration(
                                  color: CyclecorePalette.slopeColorFor(
                                    c.gradePercent,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (savedAs != null || existing != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            savedAs != null
                                ? Icons.check_circle
                                : Icons.info_outline,
                            size: 14,
                            color: savedAs != null
                                ? CcColors.ok
                                : CcColors.warn,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              savedAs != null
                                  ? 'Guardada como «$savedAs»'
                                  : 'Ya tienes un segmento aquí: «$existing»',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: CcType.label(
                                size: 11.5,
                                color: savedAs != null
                                    ? CcColors.ok
                                    : CcColors.warn,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: CcColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String text;
  const _Fact(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: CcType.label(
        size: 12,
        color: CcColors.ink,
        weight: FontWeight.w600,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CcColors.line),
      ),
      child: Text(
        text.toUpperCase(),
        style: CcType.label(size: 9, color: CcColors.inkDim),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;
  const _NumberBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: CcColors.orange,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: CcType.displayStyle(size: 14, color: Colors.white),
      ),
    );
  }
}

/// Un segmento tuyo por el que pasa el GPX, con su tiempo de esa salida.
class _PassRow extends StatelessWidget {
  final FoundSegmentPass found;
  final double startMeters;
  final bool saved;
  final VoidCallback onSave;

  const _PassRow({
    required this.found,
    required this.startMeters,
    required this.saved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CcColors.lineSoft)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag, size: 18, color: CcColors.segmentActiveTrack),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  found.segment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CcType.displayStyle(size: 14, weight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatElapsedShort(found.pass.elapsed)} · km ${_km(startMeters)}',
                  style: CcType.label(size: 11.5, color: CcColors.inkDim),
                ),
              ],
            ),
          ),
          if (saved)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 16, color: CcColors.ok),
                const SizedBox(width: 4),
                Text(
                  'Guardada',
                  style: CcType.label(size: 12, color: CcColors.ok),
                ),
              ],
            )
          else
            TextButton(onPressed: onSave, child: const Text('Guardar tiempo')),
        ],
      ),
    );
  }
}

/// La salida en el mapa con las subidas resaltadas y numeradas.
class _OverviewMap extends StatelessWidget {
  final RideTrack track;
  final List<DetectedClimb> climbs;
  final void Function(int) onTapClimb;

  const _OverviewMap({
    required this.track,
    required this.climbs,
    required this.onTapClimb,
  });

  @override
  Widget build(BuildContext context) {
    final route = [
      for (final p in track.points) latlng.LatLng(p.latitude, p.longitude),
    ];
    List<latlng.LatLng> thin(List<latlng.LatLng> pts, int max) {
      if (pts.length <= max) return pts;
      final step = (pts.length / max).ceil();
      return [for (var i = 0; i < pts.length; i += step) pts[i], pts.last];
    }

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(thin(route, 600)),
          padding: const EdgeInsets.all(26),
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.cyclecore_app',
          tileProvider: CachedTileProvider.instance,
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: thin(route, 1500),
              strokeWidth: 3,
              color: CcColors.blueDeep,
            ),
            for (final c in climbs)
              Polyline(
                points: thin(route.sublist(c.startIndex, c.endIndex + 1), 400),
                strokeWidth: 5,
                color: CcColors.orange,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (var i = 0; i < climbs.length; i++)
              Marker(
                point: route[climbs[i].startIndex],
                width: 26,
                height: 26,
                child: GestureDetector(
                  onTap: () => onTapClimb(i),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: CcColors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// El perfil de toda la salida con las subidas en naranja y numeradas.
/// Tocar una subida la abre.
class _OverviewProfile extends StatelessWidget {
  final RideTrack track;
  final List<DetectedClimb> climbs;
  final void Function(int) onTapClimb;

  const _OverviewProfile({
    required this.track,
    required this.climbs,
    required this.onTapClimb,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return GestureDetector(
          onTapUp: (d) {
            final m = d.localPosition.dx / w * track.totalDistance;
            for (var i = 0; i < climbs.length; i++) {
              final c = climbs[i];
              // Un margen para poder tocar las subidas cortas.
              final pad = track.totalDistance * 0.01;
              if (m >= track.distances[c.startIndex] - pad &&
                  m <= track.distances[c.endIndex] + pad) {
                onTapClimb(i);
                return;
              }
            }
          },
          child: SizedBox(
            height: 86,
            width: w,
            child: CustomPaint(
              painter: _OverviewProfilePainter(track: track, climbs: climbs),
            ),
          ),
        );
      },
    );
  }
}

class _OverviewProfilePainter extends CustomPainter {
  final RideTrack track;
  final List<DetectedClimb> climbs;

  _OverviewProfilePainter({required this.track, required this.climbs});

  @override
  void paint(Canvas canvas, Size size) {
    final total = track.totalDistance;
    if (total <= 0) return;
    var lo = track.altitudes.reduce(math.min);
    var hi = track.altitudes.reduce(math.max);
    final pad = math.max(5.0, (hi - lo) * 0.08);
    lo -= pad;
    hi += pad;
    const top = 16.0;
    double x(double m) => m / total * size.width;
    double y(double a) =>
        top + (1 - (a - lo) / (hi - lo)) * (size.height - top);

    Path area(int from, int to) {
      final step = math.max(1, ((to - from) / size.width).floor());
      final p = Path()..moveTo(x(track.distances[from]), size.height);
      for (var i = from; i <= to; i += step) {
        p.lineTo(x(track.distances[i]), y(track.altitudes[i]));
      }
      p
        ..lineTo(x(track.distances[to]), y(track.altitudes[to]))
        ..lineTo(x(track.distances[to]), size.height)
        ..close();
      return p;
    }

    canvas.drawPath(
      area(0, track.length - 1),
      Paint()..color = CcColors.blueDeep.withValues(alpha: 0.55),
    );
    for (var i = 0; i < climbs.length; i++) {
      final c = climbs[i];
      canvas.drawPath(
        area(c.startIndex, c.endIndex),
        Paint()..color = CcColors.orange.withValues(alpha: 0.9),
      );
      final cx = x(
        (track.distances[c.startIndex] + track.distances[c.endIndex]) / 2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: CcColors.orange,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: CcType.family,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final topOfClimb = y(track.altitudes[c.endIndex]);
      tp.paint(
        canvas,
        Offset(cx - tp.width / 2, math.max(0, topOfClimb - tp.height - 2)),
      );
    }
  }

  @override
  bool shouldRepaint(_OverviewProfilePainter old) =>
      old.track != track || old.climbs != climbs;
}
