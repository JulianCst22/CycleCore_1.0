import 'dart:math' as math;

import '../../../core/database/database.dart';
import '../../../core/geo/geo.dart';

/// Un track GPX cargado en memoria, con su bounding box para descartar
/// rápido las consultas que caen lejos.
class _LoadedTrack {
  final SegmentProfile profile;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  /// Lo que se le suma a la altitud del GPX para dejarla al nivel del
  /// modelo de elevación (ver [GpxTrackRepository.anchorTo]).
  final double offset;

  const _LoadedTrack({
    required this.profile,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    this.offset = 0,
  });

  _LoadedTrack withOffset(double offset) => _LoadedTrack(
    profile: profile,
    minLat: minLat,
    maxLat: maxLat,
    minLng: minLng,
    maxLng: maxLng,
    offset: offset,
  );
}

/// Fuente de elevación de **PRIORIDAD 1**: los perfiles congelados de
/// los segmentos que nacieron de un GPX (importados o del catálogo).
/// La altitud de un GPX de ciclocomputador es barométrica: su FORMA es
/// más fiable que la grilla SRTM (~30 m), pero su NIVEL depende de cómo
/// se calibró el aparato. Por eso, en cuanto hay modelo de elevación,
/// cada track se ancla a él ([anchorTo]): de uno se toma la forma y del
/// otro el nivel.
///
/// Solo aporta datos donde efectivamente pasás cerca (< [_toleranceMeters])
/// de un track conocido; el resto lo cubre `ElevationRepository` (HGT).
///
/// Mismo patrón `preload()` -> consulta síncrona que `ElevationRepository`,
/// para poder llamarse desde `_onNewPosition` sin async al medio.
class GpxTrackRepository {
  final AppDatabase database;

  /// A qué distancia perpendicular máxima del track se considera que
  /// "vas por ahí" y su altitud aplica.
  static const double _toleranceMeters = 20;

  /// Margen de bounding box (grados ~ metros/111000) para no descartar
  /// un punto que está justo al borde.
  static const double _bboxMarginDegrees = 0.0005;

  /// Puntos de cada track que se comparan contra el modelo de elevación
  /// al anclarlo, y cuántos tienen que tener dato para confiar en la
  /// comparación.
  static const int _anchorSamples = 60;
  static const int _minAnchorSamples = 10;

  /// Si, ya corrido al nivel del modelo, el GPX se aparta de él más que
  /// esto en la mediana, su forma no es la del terreno (un GPX sin
  /// alturas, o con alturas inventadas por un planificador): se descarta
  /// y manda el modelo.
  static const double _maxShapeDisagreementMeters = 15;

  final List<_LoadedTrack> _tracks = [];

  GpxTrackRepository(this.database);

  /// Carga a memoria todos los perfiles GPX. Llamar antes de grabar y
  /// antes de re-aplanar una actividad. Es barato: son unos pocos
  /// segmentos y el JSON ya está en la BD.
  Future<void> preload() async {
    _tracks.clear();
    final segments = await database.getGpxOriginSegments();
    for (final s in segments) {
      final profile = SegmentProfile.decode(s.profileJson);
      if (profile.points.length < 2) continue;
      // Un GPX sin `<ele>` llega con todas las alturas en 0 (ver
      // `GpxSegmentImporter`): no aporta altitud.
      if (profile.points.every((p) => p.altitude == 0)) continue;

      double minLat = profile.points.first.latitude;
      double maxLat = minLat;
      double minLng = profile.points.first.longitude;
      double maxLng = minLng;
      for (final p in profile.points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      _tracks.add(
        _LoadedTrack(
          profile: profile,
          minLat: minLat,
          maxLat: maxLat,
          minLng: minLng,
          maxLng: maxLng,
        ),
      );
    }
  }

  bool get hasTracks => _tracks.isNotEmpty;

  /// Ancla cada track al modelo de elevación [reference]: el corrimiento
  /// es la mediana de (modelo - GPX) sobre puntos repartidos a lo largo
  /// del track. Llamar después de [preload], con el modelo ya cargado.
  ///
  /// En la salida a La Calera del 28-oct-2026, un GPX importado traía
  /// la forma de la subida Teusacá - Patios bien pero 730 m por debajo,
  /// y como el GPX ganaba sobre el SRTM, la actividad «bajó» hasta
  /// 2.100 m. Anclado, ese mismo GPX queda al nivel del terreno.
  ///
  /// Un track que el modelo no cubre lo bastante se deja tal cual (no
  /// hay con qué compararlo); uno cuya forma no cuadra con el terreno se
  /// descarta.
  void anchorTo(double? Function(double lat, double lng) reference) {
    final anchored = <_LoadedTrack>[];
    for (final track in _tracks) {
      final points = track.profile.points;
      final every = math.max(1, points.length ~/ _anchorSamples);
      final residuals = <double>[];
      var sampled = 0;
      for (var i = 0; i < points.length; i += every) {
        sampled++;
        final model = reference(points[i].latitude, points[i].longitude);
        if (model != null) residuals.add(model - points[i].altitude);
      }
      if (residuals.length < _minAnchorSamples ||
          residuals.length * 2 < sampled) {
        anchored.add(track);
        continue;
      }
      final offset = _median(residuals);
      final disagreement = _median([
        for (final r in residuals) (r - offset).abs(),
      ]);
      if (disagreement > _maxShapeDisagreementMeters) continue;
      anchored.add(track.withOffset(offset));
    }
    _tracks
      ..clear()
      ..addAll(anchored);
  }

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /// Altitud del track GPX más cercano si estás a menos de
  /// [_toleranceMeters] de él, o `null` si no hay ninguno cerca.
  /// Totalmente síncrono.
  double? elevationAtSync(double lat, double lng) {
    double? best;
    double bestOffset = double.infinity;

    for (final t in _tracks) {
      if (lat < t.minLat - _bboxMarginDegrees ||
          lat > t.maxLat + _bboxMarginDegrees ||
          lng < t.minLng - _bboxMarginDegrees ||
          lng > t.maxLng + _bboxMarginDegrees) {
        continue;
      }

      final proj = projectOntoProfile(t.profile.points, lat, lng);
      if (proj.offsetMeters <= _toleranceMeters &&
          proj.offsetMeters < bestOffset) {
        final alt = t.profile.altitudeAtDistance(proj.alongMeters);
        if (alt != null) {
          best = alt + t.offset;
          bestOffset = proj.offsetMeters;
        }
      }
    }
    return best;
  }
}
