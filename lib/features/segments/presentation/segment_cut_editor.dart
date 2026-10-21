import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/geo/geo.dart';
import '../../../core/platform/platform.dart' show CachedTileProvider;
import '../../../core/ui/ui.dart';
import '../application/ride_analysis_providers.dart';
import '../application/segments_providers.dart';
import '../data/segments_repository.dart';
import '../domain/ride_track.dart';
import '../domain/segment_stats_calculator.dart';

/// Editor de un tramo de una salida para guardarlo como segmento.
///
/// El inicio (A) y el fin (B) se mueven sobre el PERFIL de altimetría,
/// no sobre el mapa: el perfil es un eje de distancia, así que un
/// marcador no puede saltar a otro pedazo de la ruta aunque la salida
/// pase dos veces por el mismo lugar. El mapa acompaña: muestra el
/// tramo, A, B y el punto que se está mirando, y se mueve libre sin
/// pelear con A y B.
///
/// A y B se ajustan de grueso a fino:
/// - "Toda la salida": la salida entera en una tira. Se arrastra A, B o
///   el tramo completo; sirve para salidas de varias horas, donde el
///   tramo es una franja pequeña.
/// - "De cerca": el tramo con un margen a cada lado.
/// - Botones de 10 m y 100 m (mantener apretado repite).
///
/// Tocar un extremo lo toma en el acto, sin esperar a que el dedo se
/// mueva, y desde ahí el gesto es suyo: no compite con el scroll del
/// panel. A y B nunca se cruzan ni quedan a menos de [_minGapMeters].
///
/// Devuelve el id del segmento guardado al cerrarse.
class SegmentCutEditor extends ConsumerStatefulWidget {
  final RideAnalysis analysis;
  final int initialStart;
  final int initialEnd;
  final String suggestedName;

  /// Lo que se muestra arriba ("Subida 2 · Cat. 3"), si viene de una
  /// subida detectada.
  final String? heading;

  const SegmentCutEditor({
    super.key,
    required this.analysis,
    required this.initialStart,
    required this.initialEnd,
    required this.suggestedName,
    this.heading,
  });

  @override
  ConsumerState<SegmentCutEditor> createState() => _SegmentCutEditorState();
}

/// Lo que se toma con el dedo: un extremo o el tramo entero.
enum _Handle { start, end, both }

/// Distancia mínima entre A y B.
const double _minGapMeters = 60;

/// Puntos que se dibujan como máximo para una línea del mapa: una
/// salida de 3 h a 1 Hz trae más de 10 000.
const int _maxDrawn = 1500;

class _SegmentCutEditorState extends ConsumerState<SegmentCutEditor> {
  final _map = MapController();
  late final TextEditingController _name;
  late final List<latlng.LatLng> _route;

  /// Índices de la traza que se dibujan (uno de cada tantos, siempre el
  /// primero y el último).
  late final List<int> _drawn;

  /// Altitud mínima y máxima de la salida, para la tira de arriba.
  late final (double, double) _wholeRange;

  // Las partes fijas del mapa se crean una sola vez: al mover A o B
  // Flutter las reutiliza tal cual en lugar de volver a proyectar toda
  // la salida en cada movimiento (era lo que trababa el arrastre).
  late final MapOptions _mapOptions;
  late final Widget _tiles;
  late final Widget _wholeRoute;

  late int _start;
  late int _end;
  late double _viewFrom;
  late double _viewTo;

  _Handle? _dragging;
  bool _dragFromOverview = false;

  /// Metros entre el dedo y lo que se tomó, para que no salte al
  /// agarrarlo un poco al lado.
  double _grab = 0;

  /// A o B está contra su tope (el otro extremo o la punta de la salida).
  bool _atLimit = false;
  int? _cursor;
  (int, int)? _chunk;
  bool _mapReady = false;
  bool _showWholeRide = false;
  bool _saveTime = true;
  bool _saving = false;
  Timer? _repeat;

  // El mapa se arma solo cuando cambia lo que muestra; mientras se
  // arrastra, a lo sumo cada [_mapRefresh] (el perfil va a cada frame).
  Widget? _mapCache;
  Object? _mapKey;
  final _mapClock = Stopwatch()..start();
  Timer? _mapCatchUp;
  static const _mapRefresh = Duration(milliseconds: 80);

  RideTrack get _t => widget.analysis.track;
  double _d(int index) => _t.distances[index];

  @override
  void initState() {
    super.initState();
    _route = [
      for (final p in _t.points) latlng.LatLng(p.latitude, p.longitude),
    ];
    final step = math.max(1, (_t.length / _maxDrawn).ceil());
    _drawn = [for (var i = 0; i < _t.length; i += step) i];
    if (_drawn.last != _t.length - 1) _drawn.add(_t.length - 1);
    _wholeRange = _altitudeRange(_t, 0, _t.length - 1);

    _start = widget.initialStart.clamp(0, _t.length - 2);
    _end = widget.initialEnd.clamp(_start + 1, _t.length - 1);
    _name = TextEditingController(text: widget.suggestedName);
    _setViewAroundSelection();

    _mapOptions = MapOptions(
      initialCameraFit: CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(_pointsBetween(_start, _end)),
        padding: const EdgeInsets.fromLTRB(36, 56, 36, 36),
      ),
      interactionOptions: const InteractionOptions(
        flags:
            InteractiveFlag.pinchZoom |
            InteractiveFlag.drag |
            InteractiveFlag.doubleTapZoom,
      ),
      onMapReady: () => _mapReady = true,
    );
    _tiles = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.cyclecore_app',
      tileProvider: CachedTileProvider.instance,
    );
    _wholeRoute = PolylineLayer(
      polylines: [
        Polyline(
          points: [for (final i in _drawn) _route[i]],
          strokeWidth: 3,
          color: CcColors.ink.withValues(alpha: 0.45),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _repeat?.cancel();
    _mapCatchUp?.cancel();
    _name.dispose();
    super.dispose();
  }

  /// Los puntos del mapa entre dos índices: todos si son pocos; si no,
  /// los de [_drawn] que caen adentro, más los dos extremos exactos.
  List<latlng.LatLng> _pointsBetween(int from, int to) {
    if (to - from <= _maxDrawn) return _route.sublist(from, to + 1);
    var lo = 0;
    var hi = _drawn.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_drawn[mid] <= from) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return [
      _route[from],
      for (var k = lo; k < _drawn.length && _drawn[k] < to; k++)
        _route[_drawn[k]],
      _route[to],
    ];
  }

  // --- Ventana del perfil y cámara del mapa ---------------------------

  /// El perfil de cerca muestra el tramo con un margen a cada lado (no
  /// la salida entera: en 200 km un tramo de 3 km no se podría ajustar
  /// con el dedo).
  void _setViewAroundSelection() {
    final d0 = _d(_start);
    final d1 = _d(_end);
    final pad = math.max((d1 - d0) * 0.3, 400.0);
    _viewFrom = math.max(0, d0 - pad);
    _viewTo = math.min(_t.totalDistance, d1 + pad);
  }

  /// Hay que volver a encuadrar el perfil de cerca: un extremo quedó
  /// pegado al borde (y del otro lado hay más salida) o el tramo se ve
  /// muy chico.
  bool _viewNeedsUpdate() {
    final width = _viewTo - _viewFrom;
    final margin = width * 0.06;
    final a = _d(_start);
    final b = _d(_end);
    return (a < _viewFrom + margin && _viewFrom > 0) ||
        (b > _viewTo - margin && _viewTo < _t.totalDistance) ||
        (b - a) < width * 0.25;
  }

  /// Encuadra el mapa. Con [onlyIfNeeded] lo deja quieto si A y B se ven
  /// y el tramo no quedó diminuto: así no salta tras cada ajuste.
  void _fitMap({bool onlyIfNeeded = false}) {
    if (!_mapReady || !mounted) return;
    final points = _showWholeRide
        ? [for (final i in _drawn) _route[i]]
        : _pointsBetween(_start, _end);
    if (points.length < 2) return;
    final bounds = LatLngBounds.fromPoints(points);
    if (onlyIfNeeded && !_showWholeRide) {
      final visible = _map.camera.visibleBounds;
      final latShare =
          (bounds.north - bounds.south) / (visible.north - visible.south);
      final lngShare =
          (bounds.east - bounds.west) / (visible.east - visible.west);
      final shown =
          visible.contains(_route[_start]) && visible.contains(_route[_end]);
      if (shown && math.max(latShare, lngShare) > 0.3) return;
    }
    _map.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(36, 56, 36, 36),
      ),
    );
  }

  // --- Mover A y B ----------------------------------------------------

  /// Lleva A, B o el tramo entero a [meters] desde el inicio de la
  /// salida, sin que A y B se crucen ni queden a menos de
  /// [_minGapMeters]. La búsqueda del punto es binaria sobre la distancia
  /// acumulada. Devuelve si algo cambió (no hace setState).
  bool _place(_Handle handle, double meters) {
    var start = _start;
    var end = _end;
    var limited = false;
    switch (handle) {
      case _Handle.start:
        final max = _d(_end) - _minGapMeters;
        limited = meters >= max || meters <= 0;
        start = _t.indexAtDistance(math.min(meters, max));
        if (start >= _end) start = _end - 1;
      case _Handle.end:
        final min = _d(_start) + _minGapMeters;
        limited = meters <= min || meters >= _t.totalDistance;
        end = _t.indexAtDistance(math.max(meters, min));
        if (end <= _start) end = _start + 1;
      case _Handle.both:
        final length = _d(_end) - _d(_start);
        final top = math.max(0.0, _t.totalDistance - length);
        final from = meters.clamp(0.0, top);
        limited = from != meters;
        start = math.min(_t.indexAtDistance(from), _t.length - 2);
        end = math.max(_t.indexAtDistance(from + length), start + 1);
    }
    if (limited && !_atLimit) HapticFeedback.selectionClick();
    _atLimit = limited;
    if (start == _start && end == _end) return false;
    _start = start;
    _end = end;
    _chunk = null;
    return true;
  }

  void _grip(_Handle handle, double fingerMeters, {required bool overview}) {
    if (_dragging != null) return;
    HapticFeedback.selectionClick();
    _grab = (handle == _Handle.end ? _d(_end) : _d(_start)) - fingerMeters;
    _atLimit = false;
    setState(() {
      _dragging = handle;
      _dragFromOverview = overview;
      _cursor = null;
      _chunk = null;
    });
  }

  void _dragTo(double fingerMeters) {
    final handle = _dragging;
    if (handle == null) return;
    var target = fingerMeters + _grab;
    // En el perfil de cerca el extremo se queda bajo el dedo: llega al
    // borde y ahí para; al soltarlo el perfil se vuelve a encuadrar.
    if (!_dragFromOverview) target = target.clamp(_viewFrom, _viewTo);
    if (!_place(handle, target)) return;
    setState(() {
      // Desde la tira de arriba el perfil de cerca acompaña en vivo;
      // desde el de cerca, su escala queda quieta bajo el dedo.
      if (_dragFromOverview) _setViewAroundSelection();
    });
  }

  void _release() {
    if (!mounted || _dragging == null) return;
    setState(() {
      if (_dragFromOverview || _viewNeedsUpdate()) _setViewAroundSelection();
      _dragging = null;
    });
    _fitMap(onlyIfNeeded: true);
  }

  /// Un toque en la tira de arriba, fuera del tramo, lleva ahí el
  /// extremo más cercano (como un deslizador de rango).
  void _jumpNearest(double meters) {
    final toStart = (meters - _d(_start)).abs();
    final toEnd = (meters - _d(_end)).abs();
    final handle = toStart <= toEnd ? _Handle.start : _Handle.end;
    HapticFeedback.selectionClick();
    _atLimit = false;
    if (!_place(handle, meters)) return;
    setState(() {
      _cursor = null;
      _setViewAroundSelection();
    });
    _fitMap(onlyIfNeeded: true);
  }

  void _showCursor(double meters) {
    if (_dragging != null) return;
    setState(() {
      _cursor = _t.indexAtDistance(meters);
      _chunk = null;
    });
  }

  void _nudge(_Handle handle, double meters) {
    final current = handle == _Handle.start ? _start : _end;
    var target = _d(current) + meters;
    // Con puntos muy separados, un paso mueve por lo menos un punto.
    if (_t.indexAtDistance(target) == current) {
      final next = (current + meters.sign.toInt()).clamp(0, _t.length - 1);
      target = _d(next);
    }
    if (!_place(handle, target)) return;
    setState(() {
      _cursor = null;
      if (_viewNeedsUpdate()) _setViewAroundSelection();
    });
  }

  void _step(_Handle handle, double meters) {
    HapticFeedback.selectionClick();
    _atLimit = false;
    _nudge(handle, meters);
    _fitMap(onlyIfNeeded: true);
  }

  void _startRepeat(_Handle handle, double meters) {
    HapticFeedback.selectionClick();
    _atLimit = false;
    _repeat?.cancel();
    _nudge(handle, meters);
    _repeat = Timer.periodic(
      const Duration(milliseconds: 70),
      (_) => _nudge(handle, meters),
    );
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
    _fitMap(onlyIfNeeded: true);
  }

  /// Corre A al punto más bajo y B al más alto que haya a menos de
  /// 300 m de donde están: el pie y la cima de la subida.
  void _snapToClimb() {
    int extreme(int around, bool lowest, int lo, int hi) {
      final from = _t.indexAtDistance(_d(around) - 300).clamp(lo, hi);
      final to = _t.indexAtDistance(_d(around) + 300).clamp(lo, hi);
      var best = around.clamp(lo, hi);
      for (var i = from; i <= to; i++) {
        final better = lowest
            ? _t.altitudes[i] < _t.altitudes[best]
            : _t.altitudes[i] > _t.altitudes[best];
        if (better) best = i;
      }
      return best;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _start = extreme(_start, true, 0, _end - 1);
      _end = extreme(_end, false, _start + 1, _t.length - 1);
      _chunk = null;
      _setViewAroundSelection();
    });
    _fitMap();
  }

  // --- Guardar --------------------------------------------------------

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre al segmento.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(rideAnalyzerProvider)
          .saveSegment(
            widget.analysis,
            from: _start,
            to: _end,
            name: name,
            saveTime: _canSaveTime && _saveTime,
          );
      if (mounted) Navigator.of(context).pop(id);
    } on SegmentCreationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _canSaveTime => widget.analysis.isGpx && _t.hasTime;

  /// Un segmento tuyo que empieza y termina casi donde este tramo.
  String? _similarSegmentName() {
    final segments = ref.watch(segmentsListProvider).valueOrNull ?? const [];
    final a = _t.points[_start];
    final b = _t.points[_end];
    for (final s in segments) {
      final dStart = haversineMeters(
        a.latitude,
        a.longitude,
        s.startLat,
        s.startLng,
      );
      final dEnd = haversineMeters(b.latitude, b.longitude, s.endLat, s.endLng);
      if (dStart < 60 && dEnd < 60) return s.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _t.statsBetween(_start, _end);
    final tooShort = stats.distanceMeters < kMinSegmentDistanceMeters;
    final span = stats.distanceMeters;
    final chunkSize = span > 3000 ? 1000.0 : (span > 1200 ? 500.0 : 200.0);
    final chunks = _t.chunks(_start, _end, chunkSize);
    final similar = _similarSegmentName();
    final dragging = _dragging;

    return Scaffold(
      backgroundColor: CcColors.bg,
      appBar: AppBar(title: Text(widget.heading ?? 'Recortar un segmento')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              SizedBox(
                height: (constraints.maxHeight * 0.3).clamp(160.0, 300.0),
                child: _mapNow(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: _StatsStrip(stats: stats),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Label(
                        'Toda la salida · '
                        '${_comma(formatDistanceKm(_t.totalDistance))} km',
                      ),
                      const SizedBox(height: 4),
                      _OverviewStrip(
                        track: _t,
                        range: _wholeRange,
                        start: _start,
                        end: _end,
                        dragging: _dragFromOverview ? dragging : null,
                        enabled: dragging == null || _dragFromOverview,
                        onGrip: (h, m) => _grip(h, m, overview: true),
                        onMove: _dragTo,
                        onRelease: _release,
                        onTap: _jumpNearest,
                      ),
                      const SizedBox(height: 12),
                      const _Label(
                        'De cerca · toca el perfil para ver un punto',
                      ),
                      const SizedBox(height: 4),
                      _DetailProfile(
                        track: _t,
                        viewFrom: _viewFrom,
                        viewTo: _viewTo,
                        start: _start,
                        end: _end,
                        cursor: _cursor,
                        chunk: _chunk,
                        dragging: _dragFromOverview ? null : dragging,
                        enabled: dragging == null || !_dragFromOverview,
                        onGrip: (h, m) => _grip(h, m, overview: false),
                        onMove: _dragTo,
                        onRelease: _release,
                        onCursor: _showCursor,
                      ),
                      const SizedBox(height: 10),
                      _NudgeRow(
                        letter: 'A',
                        label: 'Inicio',
                        color: CcColors.segmentStart,
                        meters: _d(_start),
                        onStep: (m) => _step(_Handle.start, m),
                        onHoldStart: (m) => _startRepeat(_Handle.start, m),
                        onHoldEnd: _stopRepeat,
                      ),
                      const SizedBox(height: 8),
                      _NudgeRow(
                        letter: 'B',
                        label: 'Fin',
                        color: CcColors.danger,
                        meters: _d(_end),
                        onStep: (m) => _step(_Handle.end, m),
                        onHoldStart: (m) => _startRepeat(_Handle.end, m),
                        onHoldEnd: _stopRepeat,
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Tooltip(
                          message:
                              'Lleva A al punto más bajo y B al más alto que '
                              'estén cerca.',
                          child: TextButton.icon(
                            onPressed: _snapToClimb,
                            icon: const Icon(Icons.auto_fix_high, size: 17),
                            label: const Text('Encajar en la subida'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Label(
                        'Tramo por tramo · cada '
                        '${chunkSize >= 1000 ? '1 km' : '${chunkSize.round()} m'}',
                      ),
                      const SizedBox(height: 8),
                      _ChunkBars(
                        chunks: chunks,
                        selected: _chunk,
                        onTap: (c) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            final same = _chunk == (c.startIndex, c.endIndex);
                            _chunk = same ? null : (c.startIndex, c.endIndex);
                            _cursor = null;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del segmento',
                        ),
                      ),
                      if (_canSaveTime) ...[
                        const SizedBox(height: 6),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _saveTime,
                          onChanged: (v) => setState(() => _saveTime = v),
                          title: const Text(
                            'Guardar mi tiempo de esta salida',
                            style: TextStyle(color: CcColors.ink, fontSize: 14),
                          ),
                          subtitle: Text(
                            stats.duration == null
                                ? 'Como marca de antes de la app'
                                : '${formatElapsedShort(stats.duration!)} · '
                                      'como marca de antes de la app',
                            style: const TextStyle(
                              color: CcColors.inkDim,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (similar != null) ...[
                        const SizedBox(height: 8),
                        _Warning(
                          text:
                              'Se parece a tu segmento «$similar»: empieza y '
                              'termina casi en el mismo sitio.',
                        ),
                      ],
                      if (tooShort) ...[
                        const SizedBox(height: 8),
                        _Warning(
                          text:
                              'Un segmento debe medir al menos '
                              '${kMinSegmentDistanceMeters.round()} m: separa '
                              'un poco más A y B.',
                        ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: tooShort || _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Guardar segmento'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapNow() {
    final key = (_start, _end, _cursor, _chunk, _showWholeRide);
    final cached = _mapCache;
    if (cached != null && key == _mapKey) return cached;
    final busy = _dragging != null || _repeat != null;
    final wait = _mapRefresh - _mapClock.elapsed;
    if (cached != null && busy && wait > Duration.zero) {
      _mapCatchUp ??= Timer(wait, () {
        _mapCatchUp = null;
        if (mounted) setState(() {});
      });
      return cached;
    }
    _mapKey = key;
    _mapClock.reset();
    if (busy) WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    return _mapCache = _buildMap();
  }

  /// Mientras se mueve el tramo, si se sale del mapa lo trae al centro
  /// sin cambiar el zoom (al soltar se encuadra del todo).
  void _follow() {
    if (!_mapReady || !mounted || _showWholeRide) return;
    final visible = _map.camera.visibleBounds;
    final a = _route[_start];
    final b = _route[_end];
    if (visible.contains(a) && visible.contains(b)) return;
    _map.move(
      latlng.LatLng(
        (a.latitude + b.latitude) / 2,
        (a.longitude + b.longitude) / 2,
      ),
      _map.camera.zoom,
    );
  }

  Widget _buildMap() {
    final chunk = _chunk;
    final cursor = _cursor;
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: _mapOptions,
          children: [
            _tiles,
            _wholeRoute,
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _pointsBetween(_start, _end),
                  strokeWidth: 5.5,
                  color: CcColors.orange,
                  borderStrokeWidth: 1.5,
                  borderColor: Colors.black54,
                ),
                if (chunk != null)
                  Polyline(
                    points: _pointsBetween(chunk.$1, chunk.$2),
                    strokeWidth: 7,
                    color: Colors.white,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                _pin(_route[_start], 'A', CcColors.segmentStart),
                _pin(_route[_end], 'B', CcColors.danger),
                if (cursor != null)
                  Marker(
                    point: _route[cursor],
                    width: 18,
                    height: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: CcColors.blue, width: 4),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Material(
            color: CcColors.glassDeep,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() => _showWholeRide = !_showWholeRide);
                _fitMap();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showWholeRide
                            ? Icons.center_focus_strong
                            : Icons.zoom_out_map,
                        size: 16,
                        color: CcColors.ink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showWholeRide ? 'Ver el tramo' : 'Ver toda la salida',
                        style: CcType.label(size: 12, color: CcColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Marker _pin(latlng.LatLng point, String label, Color color) {
    return Marker(
      point: point,
      width: 30,
      height: 30,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5)],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Altitud mínima y máxima entre dos índices, con un margen.
(double, double) _altitudeRange(RideTrack track, int from, int to) {
  var lo = track.altitudes[from];
  var hi = lo;
  for (var i = from; i <= to; i++) {
    final a = track.altitudes[i];
    if (a < lo) lo = a;
    if (a > hi) hi = a;
  }
  final pad = math.max(4.0, (hi - lo) * 0.08);
  return (lo - pad, hi + pad);
}

String _km(double meters) => _comma((meters / 1000).toStringAsFixed(2));

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: CcType.label(
        size: 11,
        color: CcColors.inkFaint,
      ).copyWith(letterSpacing: 1.2),
    );
  }
}

class _Warning extends StatelessWidget {
  final String text;
  const _Warning({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 16, color: CcColors.warn),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: CcColors.warn,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

String _comma(String number) => number.replaceAll('.', ',');

/// Distancia, desnivel, pendiente media y máxima, y tiempo del tramo.
class _StatsStrip extends StatelessWidget {
  final SectionStats stats;
  const _StatsStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cells = <(String, String, String)>[
      ('Distancia', _comma(formatDistanceKm(stats.distanceMeters)), 'km'),
      ('Desnivel', '+${stats.elevationGainMeters.round()}', 'm'),
      ('Media', _comma(stats.avgGradePercent.toStringAsFixed(1)), '%'),
      ('Máx', _comma(stats.maxGradePercent.toStringAsFixed(1)), '%'),
      if (stats.duration != null)
        ('Tiempo', formatElapsedShort(stats.duration!), ''),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: CcColors.lineSoft),
          bottom: BorderSide(color: CcColors.lineSoft),
        ),
      ),
      child: Row(
        children: [
          for (final (label, value, unit) in cells)
            Expanded(
              child: Column(
                children: [
                  Text(
                    label.toUpperCase(),
                    style: CcType.label(size: 8.5, color: CcColors.inkFaint),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        text: value,
                        style: CcType.displayStyle(size: 16),
                        children: [
                          if (unit.isNotEmpty)
                            TextSpan(
                              text: ' $unit',
                              style: const TextStyle(
                                color: CcColors.inkDim,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
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

/// Una barra por pedazo del tramo, coloreada por pendiente. Tocarla la
/// resalta en el perfil y en el mapa.
class _ChunkBars extends StatelessWidget {
  final List<SlopeChunk> chunks;
  final (int, int)? selected;
  final void Function(SlopeChunk) onTap;

  const _ChunkBars({
    required this.chunks,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (chunks.isEmpty) return const SizedBox.shrink();
    var maxGrade = 1.0;
    for (final c in chunks) {
      maxGrade = math.max(maxGrade, c.gradePercent.abs());
    }

    Widget bar(SlopeChunk c) {
      final isSelected = selected == (c.startIndex, c.endIndex);
      final color = CyclecorePalette.slopeColorFor(c.gradePercent);
      final h = 14 + 34 * (c.gradePercent.abs() / maxGrade);
      return GestureDetector(
        onTap: () => onTap(c),
        child: SizedBox(
          width: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${c.gradePercent.toStringAsFixed(1).replaceAll('.', ',')}%',
                style: CcType.label(
                  size: 10.5,
                  color: isSelected ? CcColors.ink : CcColors.inkDim,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isSelected ? 1 : 0.8),
                  borderRadius: BorderRadius.circular(5),
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _chunkLabel(c),
                style: CcType.label(size: 9.5, color: CcColors.inkFaint),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [for (final c in chunks) bar(c)],
      ),
    );
  }

  /// Dónde termina el pedazo, redondeado a 10 m: los puntos del GPX no
  /// caen justo en el kilómetro y "999 m" confunde.
  static String _chunkLabel(SlopeChunk c) {
    final meters = (c.endMeters / 10).round() * 10;
    return meters >= 1000
        ? 'km ${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')}'
        : '$meters m';
  }
}

/// "A · Inicio · km 20,35" con pasos de 100 m y 10 m a cada lado
/// (mantener apretado repite). Botones de 48 × 48.
class _NudgeRow extends StatelessWidget {
  final String letter;
  final String label;
  final Color color;

  /// Dónde está el extremo, en metros desde el inicio de la salida.
  final double meters;
  final void Function(double meters) onStep;
  final void Function(double meters) onHoldStart;
  final VoidCallback onHoldEnd;

  const _NudgeRow({
    required this.letter,
    required this.label,
    required this.color,
    required this.meters,
    required this.onStep,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, double step) {
      final size = step.abs().round();
      return _NudgeButton(
        icon: icon,
        caption: '$size m',
        tooltip: '$label $size m ${step < 0 ? 'antes' : 'después'}',
        onTap: () => onStep(step),
        onHoldStart: () => onHoldStart(step),
        onHoldEnd: onHoldEnd,
      );
    }

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            letter,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: CcType.label(size: 9.5, color: CcColors.inkFaint),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'km ${_km(meters)}',
                  style: CcType.displayStyle(size: 16),
                ),
              ),
            ],
          ),
        ),
        button(Icons.keyboard_double_arrow_left, -100),
        const SizedBox(width: 4),
        button(Icons.chevron_left, -10),
        const SizedBox(width: 4),
        button(Icons.chevron_right, 10),
        const SizedBox(width: 4),
        button(Icons.keyboard_double_arrow_right, 100),
      ],
    );
  }
}

class _NudgeButton extends StatefulWidget {
  final IconData icon;
  final String caption;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  const _NudgeButton({
    required this.icon,
    required this.caption,
    required this.tooltip,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  State<_NudgeButton> createState() => _NudgeButtonState();
}

class _NudgeButtonState extends State<_NudgeButton> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapCancel: () => _set(false),
          onTapUp: (_) => _set(false),
          onTap: widget.onTap,
          onLongPressStart: (_) {
            _set(true);
            widget.onHoldStart();
          },
          onLongPressEnd: (_) {
            _set(false);
            widget.onHoldEnd();
          },
          onLongPressCancel: () {
            _set(false);
            widget.onHoldEnd();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _down ? CcColors.line : CcColors.surfaceHi,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _down ? CcColors.inkFaint : CcColors.line,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 20, color: CcColors.ink),
                Text(
                  widget.caption,
                  style: CcType.label(size: 9, color: CcColors.inkDim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Perfiles ---------------------------------------------------------

/// Escala horizontal de un perfil: metros de la salida ↔ píxeles.
class _Scale {
  final double from;
  final double to;
  final double left;
  final double width;

  const _Scale(this.from, this.to, this.left, this.width);

  double x(double meters) => left + (meters - from) / (to - from) * width;

  /// Sin recortar: el dedo puede salirse del perfil.
  double meters(double x) => from + (x - left) / width * (to - from);
}

/// Alto de la fila de las pestañas A y B, debajo del perfil.
const double _knobRow = 40;

/// Qué pestaña hay bajo [x]. La de A cuelga a la izquierda de su línea y
/// la de B a la derecha, así que no se tapan aunque A y B estén juntos;
/// cada una se puede tomar en unos 52 px de ancho.
_Handle? _knobAt(double x, double ax, double bx) {
  final onA = x >= ax - 44 && x <= ax + 8;
  final onB = x >= bx - 8 && x <= bx + 44;
  if (onA && onB) return x < (ax + bx) / 2 ? _Handle.start : _Handle.end;
  if (onA) return _Handle.start;
  if (onB) return _Handle.end;
  return null;
}

/// La salida entera en una tira: el tramo es una ventana que se arrastra
/// (por dentro mueve A y B juntos; por sus pestañas, uno solo). Tocar
/// fuera lleva ahí el extremo más cercano.
class _OverviewStrip extends StatelessWidget {
  final RideTrack track;
  final (double, double) range;
  final int start;
  final int end;
  final _Handle? dragging;
  final bool enabled;
  final void Function(_Handle handle, double meters) onGrip;
  final void Function(double meters) onMove;
  final VoidCallback onRelease;
  final void Function(double meters) onTap;

  const _OverviewStrip({
    required this.track,
    required this.range,
    required this.start,
    required this.end,
    required this.dragging,
    required this.enabled,
    required this.onGrip,
    required this.onMove,
    required this.onRelease,
    required this.onTap,
  });

  static const double _top = 4;
  static const double _plot = 46;
  static const double _side = 10;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = _Scale(0, track.totalDistance, _side, width - 2 * _side);
        const plotBottom = _top + _plot;

        _Handle? pick(Offset p) {
          if (!enabled) return null;
          final ax = scale.x(track.distances[start]);
          final bx = scale.x(track.distances[end]);
          if (p.dy >= plotBottom - 8) return _knobAt(p.dx, ax, bx);
          final half = math.max((bx - ax) / 2, 24.0);
          return (p.dx - (ax + bx) / 2).abs() <= half ? _Handle.both : null;
        }

        return RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            _GripRecognizer:
                GestureRecognizerFactoryWithHandlers<_GripRecognizer>(
                  () => _GripRecognizer(debugOwner: this),
                  (r) => r
                    ..pick = pick
                    ..onGrip = ((h, p) => onGrip(h, scale.meters(p.dx)))
                    ..onMove = ((p) => onMove(scale.meters(p.dx)))
                    ..onRelease = onRelease,
                ),
            TapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                  () => TapGestureRecognizer(debugOwner: this),
                  (r) => r.onTapUp = (d) {
                    if (!enabled) return;
                    onTap(
                      scale
                          .meters(d.localPosition.dx)
                          .clamp(0.0, track.totalDistance),
                    );
                  },
                ),
          },
          child: SizedBox(
            width: width,
            height: plotBottom + _knobRow,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _ProfileBackground(
                        track: track,
                        from: 0,
                        to: track.totalDistance,
                        left: _side,
                        right: _side,
                        top: _top,
                        bottom: _knobRow,
                        range: range,
                        labels: false,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ProfileOverlay(
                      track: track,
                      from: 0,
                      to: track.totalDistance,
                      left: _side,
                      right: _side,
                      top: _top,
                      bottom: _knobRow,
                      range: range,
                      start: start,
                      end: end,
                      dragging: dragging,
                      window: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// El tramo de cerca, con un margen a cada lado. A y B se toman por su
/// línea o su pestaña; el resto del perfil mueve un cursor para mirar
/// cualquier punto. Mientras se arrastra, la escala no cambia.
class _DetailProfile extends StatelessWidget {
  final RideTrack track;
  final double viewFrom;
  final double viewTo;
  final int start;
  final int end;
  final int? cursor;
  final (int, int)? chunk;
  final _Handle? dragging;
  final bool enabled;
  final void Function(_Handle handle, double meters) onGrip;
  final void Function(double meters) onMove;
  final VoidCallback onRelease;
  final void Function(double meters) onCursor;

  const _DetailProfile({
    required this.track,
    required this.viewFrom,
    required this.viewTo,
    required this.start,
    required this.end,
    required this.cursor,
    required this.chunk,
    required this.dragging,
    required this.enabled,
    required this.onGrip,
    required this.onMove,
    required this.onRelease,
    required this.onCursor,
  });

  /// Arriba queda lugar para la burbuja con la cifra del punto.
  static const double _top = 26;
  static const double _plot = 124;

  /// Margen a la izquierda para las altitudes.
  static const double _left = 34;
  static const double _right = 10;

  @override
  Widget build(BuildContext context) {
    final range = _altitudeRange(
      track,
      track.indexAtDistance(viewFrom),
      track.indexAtDistance(viewTo),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = _Scale(viewFrom, viewTo, _left, width - _left - _right);
        const plotBottom = _top + _plot;

        _Handle? pick(Offset p) {
          if (!enabled) return null;
          final ax = scale.x(track.distances[start]);
          final bx = scale.x(track.distances[end]);
          if (p.dy >= plotBottom - 8) return _knobAt(p.dx, ax, bx);
          final da = (p.dx - ax).abs();
          final db = (p.dx - bx).abs();
          if (da > 18 && db > 18) return null;
          return da <= db ? _Handle.start : _Handle.end;
        }

        double clamped(double x) =>
            scale.meters(x).clamp(viewFrom, viewTo).toDouble();

        return RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            _GripRecognizer:
                GestureRecognizerFactoryWithHandlers<_GripRecognizer>(
                  () => _GripRecognizer(debugOwner: this),
                  (r) => r
                    ..pick = pick
                    ..onGrip = ((h, p) => onGrip(h, scale.meters(p.dx)))
                    ..onMove = ((p) => onMove(scale.meters(p.dx)))
                    ..onRelease = onRelease,
                ),
            TapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                  () => TapGestureRecognizer(debugOwner: this),
                  (r) =>
                      r.onTapUp = (d) => onCursor(clamped(d.localPosition.dx)),
                ),
            HorizontalDragGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  HorizontalDragGestureRecognizer
                >(
                  () => HorizontalDragGestureRecognizer(debugOwner: this),
                  (r) => r
                    ..dragStartBehavior = DragStartBehavior.down
                    ..onStart = ((d) => onCursor(clamped(d.localPosition.dx)))
                    ..onUpdate = ((d) => onCursor(clamped(d.localPosition.dx))),
                ),
          },
          child: SizedBox(
            width: width,
            height: plotBottom + _knobRow,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _ProfileBackground(
                        track: track,
                        from: viewFrom,
                        to: viewTo,
                        left: _left,
                        right: _right,
                        top: _top,
                        bottom: _knobRow,
                        range: range,
                        labels: true,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ProfileOverlay(
                      track: track,
                      from: viewFrom,
                      to: viewTo,
                      left: _left,
                      right: _right,
                      top: _top,
                      bottom: _knobRow,
                      range: range,
                      start: start,
                      end: end,
                      cursor: cursor,
                      chunk: chunk,
                      dragging: dragging,
                      window: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// El perfil coloreado por pendiente entre [from] y [to] metros. Solo
/// cambia cuando cambia la ventana: mover A o B no lo repinta.
class _ProfileBackground extends CustomPainter {
  final RideTrack track;
  final double from;
  final double to;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final (double, double) range;
  final bool labels;

  _ProfileBackground({
    required this.track,
    required this.from,
    required this.to,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.range,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (to <= from) return;
    final w = size.width - left - right;
    final plotBottom = size.height - bottom;
    final (lo, hi) = range;
    final scale = _Scale(from, to, left, w);
    double y(double alt) =>
        top + (1 - (alt - lo) / (hi - lo)) * (plotBottom - top);

    // Área por columnas de pocos píxeles (dos búsquedas binarias cada
    // una: no depende de cuántos puntos tenga la salida).
    const columnPx = 3.0;
    final columns = (w / columnPx).ceil();
    final fill = Paint();
    for (var c = 0; c < columns; c++) {
      final m0 = from + c * columnPx / w * (to - from);
      final m1 = math.min(to, from + (c + 1) * columnPx / w * (to - from));
      final a = track.indexAtDistance(m0);
      final b = track.indexAtDistance(m1);
      final span = track.distances[b] - track.distances[a];
      final grade = span > 0
          ? (track.altitudes[b] - track.altitudes[a]) / span * 100
          : 0.0;
      fill.color = CyclecorePalette.slopeColorFor(
        grade,
      ).withValues(alpha: 0.85);
      canvas.drawPath(
        Path()
          ..moveTo(scale.x(m0), plotBottom)
          ..lineTo(scale.x(m0), y(track.altitudes[a]))
          ..lineTo(scale.x(m1), y(track.altitudes[b]))
          ..lineTo(scale.x(m1), plotBottom)
          ..close(),
        fill,
      );
    }

    // La línea, con a lo sumo dos puntos por píxel.
    final i0 = track.indexAtDistance(from);
    final i1 = track.indexAtDistance(to);
    final step = math.max(1, ((i1 - i0) / (w * 2)).floor());
    final line = Path()
      ..moveTo(scale.x(track.distances[i0]), y(track.altitudes[i0]));
    for (var i = i0 + step; i < i1; i += step) {
      line.lineTo(scale.x(track.distances[i]), y(track.altitudes[i]));
    }
    line.lineTo(scale.x(track.distances[i1]), y(track.altitudes[i1]));
    canvas.drawPath(
      line,
      Paint()
        ..color = CcColors.ink.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = labels ? 1.6 : 1.2,
    );

    if (labels) {
      _text(canvas, '${hi.round()} m', Offset(0, top - 6), CcColors.inkFaint);
      _text(
        canvas,
        '${lo.round()} m',
        Offset(0, plotBottom - 12),
        CcColors.inkFaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProfileBackground old) =>
      old.track != track ||
      old.from != from ||
      old.to != to ||
      old.range != range;
}

/// Lo que se mueve encima del perfil: la sombra fuera del tramo, A y B
/// con sus pestañas, el cursor y la burbuja con las cifras.
class _ProfileOverlay extends CustomPainter {
  final RideTrack track;
  final double from;
  final double to;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final (double, double) range;
  final int start;
  final int end;
  final int? cursor;
  final (int, int)? chunk;
  final _Handle? dragging;

  /// Dibuja el tramo como una ventana con marco (la tira de arriba).
  final bool window;

  _ProfileOverlay({
    required this.track,
    required this.from,
    required this.to,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.range,
    required this.start,
    required this.end,
    required this.dragging,
    required this.window,
    this.cursor,
    this.chunk,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (to <= from) return;
    final w = size.width - left - right;
    final plotBottom = size.height - bottom;
    final scale = _Scale(from, to, left, w);
    final (lo, hi) = range;
    double y(double alt) =>
        top + (1 - (alt - lo) / (hi - lo)) * (plotBottom - top);

    final dStart = track.distances[start];
    final dEnd = track.distances[end];
    final ax = scale.x(dStart);
    final bx = scale.x(dEnd);
    final plotRight = size.width - right;

    // Sombra fuera del tramo.
    final shade = Paint()..color = CcColors.bg.withValues(alpha: 0.74);
    if (ax > left) {
      canvas.drawRect(
        Rect.fromLTRB(left, top - 2, math.min(ax, plotRight), plotBottom),
        shade,
      );
    }
    if (bx < plotRight) {
      canvas.drawRect(
        Rect.fromLTRB(math.max(bx, left), top - 2, plotRight, plotBottom),
        shade,
      );
    }

    if (window) {
      final frame = Rect.fromLTRB(
        math.min(ax, bx - 2),
        top - 2,
        math.max(bx, ax + 2),
        plotBottom,
      );
      if (dragging == _Handle.both) {
        canvas.drawRect(
          frame,
          Paint()..color = Colors.white.withValues(alpha: 0.12),
        );
      }
      canvas.drawRect(
        frame,
        Paint()
          ..color = Colors.white.withValues(
            alpha: dragging == _Handle.both ? 1 : 0.7,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = dragging == _Handle.both ? 2 : 1.2,
      );
    }

    final ch = chunk;
    if (ch != null) {
      canvas.drawRect(
        Rect.fromLTRB(
          scale.x(track.distances[ch.$1]),
          top,
          scale.x(track.distances[ch.$2]),
          plotBottom,
        ),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final cur = cursor;
    if (cur != null && dragging == null) {
      final cx = scale.x(track.distances[cur]);
      canvas.drawLine(
        Offset(cx, top),
        Offset(cx, plotBottom),
        Paint()
          ..color = CcColors.blue
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        Offset(cx, y(track.altitudes[cur])),
        4.5,
        Paint()..color = CcColors.blue,
      );
      final km = (track.distances[cur] - dStart) / 1000;
      final label =
          '${km >= 0 ? 'km' : '−km'} ${_comma(km.abs().toStringAsFixed(2))} '
          'del tramo · ${track.altitudes[cur].round()} m · '
          '${_comma(track.gradeAt(cur).toStringAsFixed(1))} %';
      _bubble(canvas, label, cx, size.width, CcColors.blue);
    }

    final knobY = size.height - bottom / 2;
    final active = dragging;
    _handle(
      canvas,
      ax,
      knobY,
      'A',
      CcColors.segmentStart,
      active == _Handle.start || active == _Handle.both,
      leftSide: true,
      size: size,
    );
    _handle(
      canvas,
      bx,
      knobY,
      'B',
      CcColors.danger,
      active == _Handle.end || active == _Handle.both,
      leftSide: false,
      size: size,
    );

    // Mientras se arrastra en el perfil de cerca, la cifra del extremo.
    if (!window && (active == _Handle.start || active == _Handle.end)) {
      final i = active == _Handle.start ? start : end;
      _bubble(
        canvas,
        '${active == _Handle.start ? 'A' : 'B'} · km '
        '${_km(track.distances[i])} · ${track.altitudes[i].round()} m',
        scale.x(track.distances[i]),
        size.width,
        active == _Handle.start ? CcColors.segmentStart : CcColors.danger,
      );
    }
  }

  void _handle(
    Canvas canvas,
    double hx,
    double knobY,
    String label,
    Color color,
    bool active, {
    required bool leftSide,
    required Size size,
  }) {
    if (hx < left - 1 || hx > size.width - right + 1) return;
    canvas.drawLine(
      Offset(hx, top - 2),
      Offset(hx, knobY),
      Paint()
        ..color = color
        ..strokeWidth = active ? 3 : 2,
    );
    final w = active ? 34.0 : 30.0;
    final h = active ? 30.0 : 26.0;
    final rect = leftSide
        ? Rect.fromLTWH(hx - w, knobY - h / 2, w, h)
        : Rect.fromLTWH(hx, knobY - h / 2, w, h);
    final tab = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(leftSide ? 9 : 2),
      bottomLeft: Radius.circular(leftSide ? 9 : 2),
      topRight: Radius.circular(leftSide ? 2 : 9),
      bottomRight: Radius.circular(leftSide ? 2 : 9),
    );
    canvas.drawRRect(
      tab.inflate(active ? 2.5 : 1.5),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(tab, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          fontFamily: CcType.family,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ProfileOverlay old) =>
      old.start != start ||
      old.end != end ||
      old.cursor != cursor ||
      old.chunk != chunk ||
      old.from != from ||
      old.to != to ||
      old.range != range ||
      old.dragging != dragging;
}

void _bubble(Canvas canvas, String text, double cx, double width, Color edge) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        color: CcColors.ink,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        fontFamily: CcType.family,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final bw = tp.width + 14;
  final left = (cx - bw / 2).clamp(0.0, math.max(0.0, width - bw)).toDouble();
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(left, 0, bw, 20),
    const Radius.circular(7),
  );
  canvas.drawRRect(rect, Paint()..color = CcColors.surfaceHi);
  canvas.drawRRect(
    rect,
    Paint()
      ..color = edge
      ..style = PaintingStyle.stroke,
  );
  tp.paint(canvas, Offset(left + 7, 10 - tp.height / 2));
}

void _text(Canvas canvas, String text, Offset at, Color color) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: 9, fontFamily: CcType.family),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, at);
}

/// Toma A, B o el tramo apenas el dedo los toca, sin esperar a que se
/// mueva: responde al instante y le gana al scroll del panel. Lo que no
/// es un extremo lo deja pasar a los demás gestos (el cursor, el toque).
///
/// Qué se tomó vive en el reconocedor, que sobrevive a cada rebuild;
/// el editor anterior lo guardaba en una variable del build y el primer
/// setState lo borraba, por eso A y B "se trababan".
class _GripRecognizer extends OneSequenceGestureRecognizer {
  _GripRecognizer({super.debugOwner});

  _Handle? Function(Offset local)? pick;
  void Function(_Handle handle, Offset local)? onGrip;
  void Function(Offset local)? onMove;
  VoidCallback? onRelease;

  bool _active = false;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      !_active &&
      super.isPointerAllowed(event) &&
      pick?.call(event.localPosition) != null;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    final handle = pick!(event.localPosition)!;
    startTrackingPointer(event.pointer, event.transform);
    _active = true;
    resolve(GestureDisposition.accepted);
    onGrip?.call(handle, event.localPosition);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onMove?.call(event.localPosition);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) => _finish();

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
    _finish();
  }

  @override
  void acceptGesture(int pointer) {}

  void _finish() {
    if (!_active) return;
    _active = false;
    onRelease?.call();
  }

  @override
  String get debugDescription => 'agarre de A y B';
}
