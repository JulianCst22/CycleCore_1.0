import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;

import 'package:cyclecore_core/database/app_database.dart';
import 'package:cyclecore_core/theme/app_colors.dart';
import '../../activities/domain/activity_json_helpers.dart';
import '../../activities/domain/activity_summary.dart';
import '../data/segments_repository.dart';
import '../domain/segment_profile_builder.dart';
import '../domain/segment_stats_calculator.dart';
import 'segments_providers.dart';

/// Pantalla de creación de segmento: el usuario arrastra dos
/// marcadores (A = inicio, B = fin) sobre la polilínea de una
/// actividad YA GRABADA -- y ya aplanada contra HGT (Fase 1), así que
/// nace con la mayor confiabilidad geográfica posible. Debajo del
/// mapa, un mini-perfil de altimetría muestra la curva completa con
/// el tramo elegido resaltado, para que el usuario confirme
/// visualmente "sí, ahí empieza la subida" antes de guardar.
///
/// La conversión pantalla <-> lat/lng usa `camera.pointToLatLng` /
/// `camera.latLngToScreenPoint` de `flutter_map` (disponibles desde la
/// 7.x -- antes esta pantalla proyectaba a mano por miedo a que el API
/// cambiara de nombre, lo que distorsionaba en vertical por Mercator y
/// hacía que el marcador no cayera bajo el dedo).
///
/// NOTA sobre `MapController`: `_mapController.camera` NO se puede usar
/// hasta que `FlutterMap` haya renderizado su primer frame -- por eso
/// los marcadores A/B solo se dibujan cuando `onMapReady` avisa
/// (`_mapReady`).
class SegmentCreationScreen extends ConsumerStatefulWidget {
  final Activity activity;

  const SegmentCreationScreen({super.key, required this.activity});

  @override
  ConsumerState<SegmentCreationScreen> createState() =>
      _SegmentCreationScreenState();
}

class _SegmentCreationScreenState
    extends ConsumerState<SegmentCreationScreen> {
  late final MapController _mapController;
  late final List<RoutePointSnapshot> _points;
  final GlobalKey _stackKey = GlobalKey();
  final TextEditingController _nameController = TextEditingController();

  int _startIndex = 0;
  int _endIndex = 0;
  bool _saving = false;

  /// Cuál marcador se está arrastrando ahora mismo: 0 = A (inicio),
  /// 1 = B (fin), null = ninguno. Mientras se arrastra, ese marcador
  /// se dibuja pegado al dedo (`_dragFingerLocal`) en vez de saltar al
  /// punto ya "snapeado" -- el salto de golpe era el bug que se sentía
  /// al crear segmentos.
  int? _draggingHandle;
  Offset? _dragFingerLocal;

  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Se parsea UNA sola vez -- `activity.routePoints` decodifica el
    // JSON completo cada vez que se llama.
    _points = widget.activity.routePoints;
    _startIndex = 0;
    _endIndex = _points.isEmpty ? 0 : _points.length - 1;
    _nameController.text = widget.activity.title;
    // Reposiciona los marcadores cuando el mapa se mueve/hace zoom --
    // pero NO mientras se arrastra un handle (ahí el handle sigue al
    // dedo y el mapa no se mueve porque el gesto lo captura el handle).
    _mapController.mapEventStream.listen((_) {
      if (mounted && _draggingHandle == null) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- Conversión pantalla <-> lat/lng vía la cámara del mapa. Ambas
  // asumen `_mapReady == true`. El `Offset` de pantalla está en el
  // mismo espacio que el `Stack` (esquina superior izquierda del
  // mapa), que es donde se posicionan los `_DragHandle`. ---

  latlng.LatLng _screenOffsetToLatLng(Offset local) {
    return _mapController.camera.pointToLatLng(
      math.Point(local.dx, local.dy),
    );
  }

  Offset _latLngToScreenOffset(latlng.LatLng point) {
    final p = _mapController.camera.latLngToScreenPoint(point);
    return Offset(p.x, p.y);
  }

  /// Índice del punto de la actividad más cercano a [target]. Búsqueda
  /// lineal, acotada a una ventana alrededor del índice actual del
  /// handle que se arrastra -- suficiente para el arrastre, que mueve
  /// el marcador de a poco, y evita barrer miles de puntos por frame.
  int _nearestIndexTo(latlng.LatLng target, {required int around}) {
    const window = 400;
    final from = (around - window).clamp(0, _points.length - 1);
    final to = (around + window).clamp(0, _points.length - 1);

    int bestIndex = around;
    double bestDistance = double.infinity;
    for (int i = from; i <= to; i++) {
      final d = Geolocator.distanceBetween(
        target.latitude,
        target.longitude,
        _points[i].latitude,
        _points[i].longitude,
      );
      if (d < bestDistance) {
        bestDistance = d;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  Offset? _globalToStackLocal(Offset global) {
    final stackBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return null;
    return stackBox.globalToLocal(global);
  }

  void _onHandleDragStart(int handle) {
    if (!_mapReady) return;
    setState(() => _draggingHandle = handle);
  }

  void _onHandleDragUpdate(DragUpdateDetails details, {required int handle}) {
    if (!_mapReady) return;
    final local = _globalToStackLocal(details.globalPosition);
    if (local == null) return;

    final target = _screenOffsetToLatLng(local);
    final isStart = handle == 0;
    final nearest = _nearestIndexTo(
      target,
      around: isStart ? _startIndex : _endIndex,
    );

    setState(() {
      _dragFingerLocal = local;
      if (isStart) {
        _startIndex = nearest.clamp(0, _endIndex - 1);
      } else {
        _endIndex = nearest.clamp(_startIndex + 1, _points.length - 1);
      }
    });
  }

  void _onHandleDragEnd() {
    setState(() {
      _draggingHandle = null;
      _dragFingerLocal = null;
    });
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
      final id = await ref
          .read(segmentsRepositoryProvider)
          .createSegmentFromActivity(
            activity: widget.activity,
            startPointIndex: _startIndex,
            endPointIndex: _endIndex,
            name: name,
          );
      if (!mounted) return;
      Navigator.of(context).pop(id);
    } on SegmentCreationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el segmento: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_points.length < 3) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
          title: const Text(
            'Crear segmento',
            style: TextStyle(color: AppColors.textPrimaryOnPanel),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Esta actividad no tiene suficientes puntos para crear '
              'un segmento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
        ),
      );
    }

    final latLngs =
        _points.map((p) => latlng.LatLng(p.latitude, p.longitude)).toList();
    final bounds = LatLngBounds.fromPoints(latLngs);
    final selectedLatLngs = latLngs.sublist(_startIndex, _endIndex + 1);
    final stats = computeSegmentStats(
      profilePointsFromActivitySlice(
        _points.sublist(_startIndex, _endIndex + 1),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
        title: const Text(
          'Crear segmento',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  key: _stackKey,
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCameraFit: CameraFit.bounds(
                          bounds: bounds,
                          padding: const EdgeInsets.all(48),
                        ),
                        interactionOptions: const InteractionOptions(
                          flags:
                              InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                        ),
                        onMapReady: () {
                          if (mounted) setState(() => _mapReady = true);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.cyclecore_app',
                        ),
                        PolylineLayer(
                          polylines: [
                            // Ruta completa, tenue -- da contexto.
                            Polyline(
                              points: latLngs,
                              strokeWidth: 4,
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                            // Tramo elegido, resaltado.
                            Polyline(
                              points: selectedLatLngs,
                              strokeWidth: 5,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_mapReady) ...[
                      _DragHandle(
                        position: _draggingHandle == 0 && _dragFingerLocal != null
                            ? _dragFingerLocal!
                            : _latLngToScreenOffset(latLngs[_startIndex]),
                        color: AppColors.segmentStart,
                        label: 'A',
                        dragging: _draggingHandle == 0,
                        onDragStart: () => _onHandleDragStart(0),
                        onDragUpdate: (d) =>
                            _onHandleDragUpdate(d, handle: 0),
                        onDragEnd: _onHandleDragEnd,
                      ),
                      _DragHandle(
                        position: _draggingHandle == 1 && _dragFingerLocal != null
                            ? _dragFingerLocal!
                            : _latLngToScreenOffset(latLngs[_endIndex]),
                        color: AppColors.segmentEnd,
                        label: 'B',
                        dragging: _draggingHandle == 1,
                        onDragStart: () => _onHandleDragStart(1),
                        onDragUpdate: (d) =>
                            _onHandleDragUpdate(d, handle: 1),
                        onDragEnd: _onHandleDragEnd,
                      ),
                    ] else
                      const Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(child: _MapLoadingPill()),
                      ),
                  ],
                );
              },
            ),
          ),
          _BottomPanel(
            stats: stats,
            nameController: _nameController,
            saving: _saving,
            onSave: _save,
            points: _points,
            startIndex: _startIndex,
            endIndex: _endIndex,
          ),
        ],
      ),
    );
  }
}

/// Aviso breve mientras el mapa termina su primer render y los
/// marcadores A/B todavía no se pueden dibujar.
class _MapLoadingPill extends StatelessWidget {
  const _MapLoadingPill();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Cargando mapa...',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marcador circular arrastrable ("A" o "B"). Se posiciona con
/// `Positioned` calculado afuera (ver `_latLngToScreenOffset`) en vez
/// de vivir dentro del `MarkerLayer` del mapa -- así el gesto de
/// arrastre no compite con los gestos de paneo/zoom del mapa. Mientras
/// se arrastra, `position` es la posición cruda del dedo, así que el
/// círculo lo sigue sin saltar.
class _DragHandle extends StatelessWidget {
  final Offset position;
  final Color color;
  final String label;
  final bool dragging;
  final VoidCallback onDragStart;
  final void Function(DragUpdateDetails) onDragUpdate;
  final VoidCallback onDragEnd;

  const _DragHandle({
    required this.position,
    required this.color,
    required this.label,
    required this.dragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  static const double _size = 38;

  @override
  Widget build(BuildContext context) {
    // Un poco más grande el "hit area" que el círculo visible, para que
    // sea fácil de agarrar con el dedo en movimiento.
    const hit = _size + 16;
    return Positioned(
      left: position.dx - hit / 2,
      top: position.dy - hit / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => onDragStart(),
        onPanUpdate: onDragUpdate,
        onPanEnd: (_) => onDragEnd(),
        onPanCancel: onDragEnd,
        child: SizedBox(
          width: hit,
          height: hit,
          child: Center(
            child: AnimatedScale(
              scale: dragging ? 1.25 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel inferior: mini-perfil de altimetría + estadísticas en vivo +
/// nombre + botón de guardar.
class _BottomPanel extends StatelessWidget {
  final SegmentStatsPreview stats;
  final TextEditingController nameController;
  final bool saving;
  final VoidCallback onSave;
  final List<RoutePointSnapshot> points;
  final int startIndex;
  final int endIndex;

  const _BottomPanel({
    required this.stats,
    required this.nameController,
    required this.saving,
    required this.onSave,
    required this.points,
    required this.startIndex,
    required this.endIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERFIL DEL TRAMO SELECCIONADO',
            style: TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          _SegmentPreviewChart(
            allPoints: points,
            startIndex: startIndex,
            endIndex: endIndex,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                label: 'DISTANCIA',
                value: '${(stats.distanceMeters / 1000).toStringAsFixed(2)} km',
              ),
              _MiniStat(
                label: 'DESNIVEL +',
                value: '${stats.elevationGainMeters.toStringAsFixed(0)} m',
              ),
              _MiniStat(
                label: 'PEND. PROM',
                value: '${stats.avgSlopePercent.toStringAsFixed(1)}%',
              ),
              _MiniStat(
                label: 'PEND. MÁX',
                value: '${stats.maxSlopePercent.toStringAsFixed(1)}%',
              ),
            ],
          ),
          if (stats.isTooShort) ...[
            const SizedBox(height: 8),
            Text(
              'El segmento debe medir al menos '
              '${kMinSegmentDistanceMeters.round()} metros -- separa un '
              'poco más los marcadores A y B.',
              style: const TextStyle(
                color: AppColors.segmentEnd,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: nameController,
            style: const TextStyle(color: AppColors.textPrimaryOnPanel),
            decoration: InputDecoration(
              labelText: 'Nombre del segmento',
              labelStyle: const TextStyle(
                color: AppColors.textSecondaryOnPanel,
              ),
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (stats.isTooShort || saving) ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: saving
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
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 2),
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

/// Curva de altimetría de TODA la actividad, con el tramo
/// seleccionado resaltado y una línea vertical en cada extremo (A/B).
class _SegmentPreviewChart extends StatelessWidget {
  final List<RoutePointSnapshot> allPoints;
  final int startIndex;
  final int endIndex;

  const _SegmentPreviewChart({
    required this.allPoints,
    required this.startIndex,
    required this.endIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      width: double.infinity,
      child: CustomPaint(
        painter: _SegmentPreviewPainter(
          points: allPoints,
          startIndex: startIndex,
          endIndex: endIndex,
        ),
      ),
    );
  }
}

class _SegmentPreviewPainter extends CustomPainter {
  final List<RoutePointSnapshot> points;
  final int startIndex;
  final int endIndex;

  const _SegmentPreviewPainter({
    required this.points,
    required this.startIndex,
    required this.endIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final totalDistance = points.last.distanceFromStartMeters;
    if (totalDistance <= 0) return;

    double minAltitude = points.first.altitude;
    double maxAltitude = points.first.altitude;
    for (final p in points) {
      if (p.altitude < minAltitude) minAltitude = p.altitude;
      if (p.altitude > maxAltitude) maxAltitude = p.altitude;
    }
    final altitudeSpan = maxAltitude - minAltitude;

    Offset offsetFor(RoutePointSnapshot p) {
      final x = (p.distanceFromStartMeters / totalDistance) * size.width;
      final t = altitudeSpan <= 0
          ? 0.5
          : (p.altitude - minAltitude) / altitudeSpan;
      final y = size.height - (t * size.height);
      return Offset(x, y);
    }

    final startX = offsetFor(points[startIndex]).dx;
    final endX = offsetFor(points[endIndex]).dx;

    canvas.drawRect(
      Rect.fromLTRB(startX, 0, endX, size.height),
      Paint()..color = AppColors.primary.withValues(alpha: 0.18),
    );

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final o = offsetFor(points[i]);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      Offset(startX, 0),
      Offset(startX, size.height),
      Paint()
        ..color = AppColors.segmentStart
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(endX, 0),
      Offset(endX, size.height),
      Paint()
        ..color = AppColors.segmentEnd
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SegmentPreviewPainter oldDelegate) =>
      oldDelegate.startIndex != startIndex || oldDelegate.endIndex != endIndex;
}
