import '../../../core/database/app_database.dart';
import '../../segments/domain/segment_geometry.dart';
import '../../segments/domain/segment_profile.dart';

/// Un track GPX cargado en memoria, con su bounding box para descartar
/// rápido las consultas que caen lejos.
class _LoadedTrack {
  final SegmentProfile profile;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const _LoadedTrack({
    required this.profile,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
}

/// Fuente de elevación de **PRIORIDAD 1**: los perfiles congelados de
/// los segmentos que nacieron de un GPX (importados o del catálogo).
/// La altitud de un GPX de ciclocomputador es barométrica y más fiable
/// que la grilla SRTM (~30 m) -- por eso gana.
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
          best = alt;
          bestOffset = proj.offsetMeters;
        }
      }
    }
    return best;
  }
}
