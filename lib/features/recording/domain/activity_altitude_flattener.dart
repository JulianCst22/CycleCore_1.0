import '../../../core/geo/geo.dart';
import '../../elevation/elevation.dart';
import 'altitude_fusion/profile_fusion.dart';
import 'route_point.dart';

/// Resultado de "aplanar" la altimetría de una actividad completa con la
/// capa 3 difusa (barómetro, Copernicus, GPX y altitud en vivo pesados
/// tramo por tramo), en vez de confiar en la altitud que se calculó en
/// tiempo real.
///
/// Los arreglos quedan alineados índice a índice con la lista de
/// `RoutePoint` original.
class FlattenedAltitudeResult {
  final List<double> altitudes;
  final List<double> slopePercents;

  /// Fuente usada en cada punto -- para que "Ajustar altimetría"
  /// pueda decir "X% con GPX, Y% con HGT, Z% aproximado".
  final List<ElevationSource> sources;

  /// true en los puntos sin Copernicus ni GPX: su forma salió del
  /// barómetro o de la altitud en vivo, y su nivel de los puntos vecinos
  /// que sí tenían modelo. Equivale a `sources[i] == ElevationSource.none`.
  final List<bool> isApproximate;

  final double elevationGainMeters;
  final double elevationLossMeters;

  /// true si el barómetro fue una de las fuentes (había presión en
  /// suficientes puntos).
  final bool barometric;

  /// Cuánto pesó cada fuente en la forma del perfil (capa 3).
  final ProfileSourceShares shares;

  const FlattenedAltitudeResult({
    required this.altitudes,
    required this.slopePercents,
    required this.sources,
    required this.isApproximate,
    required this.elevationGainMeters,
    required this.elevationLossMeters,
    this.barometric = false,
    this.shares = const ProfileSourceShares(),
  });

  static const empty = FlattenedAltitudeResult(
    altitudes: [],
    slopePercents: [],
    sources: [],
    isApproximate: [],
    elevationGainMeters: 0,
    elevationLossMeters: 0,
  );

  int get approximatePointCount => isApproximate.where((a) => a).length;
  int countFrom(ElevationSource s) => sources.where((x) => x == s).length;
}

/// Aplana la altimetría de una actividad con las fuentes que haya en cada
/// punto: el barómetro grabado, Copernicus, el GPX importado que pase
/// por ahí y la altitud que se calculó en vivo. La capa 3 difusa
/// (`ProfileFusionFilter`) decide cuánto pesa cada una tramo por tramo.
///
/// Se ejecuta al terminar de grabar (`finishRecording`) y de nuevo cada
/// vez que el usuario toca "Ajustar altimetría" (útil tras descargar
/// teselas HGT o importar un GPX del recorrido).
///
/// Algoritmo:
///  1. Perfil de la capa 3: los cambios de altura de las fuentes,
///     pesados con lógica difusa, al nivel de Copernicus.
///  2. **Clamp de pendiente físicamente plausible** entre puntos
///     consecutivos ([maxPlausibleGradePercent]) -- corta el efecto
///     "costura" al cambiar de fuente y los outliers puntuales.
///  3. Suavizado corto (promedio móvil) contra el "diente de sierra"
///     de la grilla DEM.
///  4. Pendiente recalculada por regresión de ventana
///     (`SlopeWindowCalculator`), alimentada con la altitud ya limpia.
///
/// El desnivel (+/-) se mide sobre la distancia (`computeRouteGainLoss`:
/// remuestreo, promedio móvil y histéresis), no sumando cada delta --
/// así el ruido del modelo de elevación (techos y árboles del SRTM, sus
/// costuras) no infla el desnivel en ambos sentidos.
class ActivityAltitudeFlattener {
  final ElevationLookup resolver;
  final int smoothingRadius;
  final double slopeWindowMeters;

  /// Promedio móvil (m) y cambio mínimo (m) con que se mide el
  /// desnivel -- ver `computeRouteGainLoss`.
  final double gainWindowMeters;
  final double elevationHysteresisMeters;

  final double maxPlausibleGradePercent;

  ActivityAltitudeFlattener(
    this.resolver, {
    this.smoothingRadius = 1,
    this.slopeWindowMeters = 40,
    this.gainWindowMeters = routeGainWindowMeters,
    this.elevationHysteresisMeters = routeGainMinChangeMeters,
    this.maxPlausibleGradePercent = 35,
  });

  FlattenedAltitudeResult flatten({
    required List<RoutePoint> points,
    required List<double> cumulativeDistanceMeters,
  }) {
    assert(
      points.length == cumulativeDistanceMeters.length,
      'points y cumulativeDistanceMeters deben tener la misma longitud',
    );
    if (points.isEmpty) return FlattenedAltitudeResult.empty;

    // --- Paso 1: perfil de la capa 3 (fuentes pesadas con lógica difusa). ---
    final sources = <ElevationSource>[];
    final isApproximate = <bool>[];
    final model = <double?>[];
    final gpx = <double?>[];
    for (final point in points) {
      final samples = resolver.samples(point.latitude, point.longitude);
      model.add(samples.model);
      gpx.add(samples.gpx);
      sources.add(
        samples.gpx != null
            ? ElevationSource.gpx
            : (samples.model != null
                ? ElevationSource.hgt
                : ElevationSource.none),
      );
      isApproximate.add(samples.gpx == null && samples.model == null);
    }
    final fusion = ProfileFusionFilter().fuse(
      ProfileSources(
        distances: cumulativeDistanceMeters,
        model: model,
        gpx: gpx,
        pressures: [for (final p in points) p.pressureHpa],
        live: [for (final p in points) p.altitude],
        speeds: [for (final p in points) p.speedMetersPerSecond],
      ),
    );
    final rawAltitudes = fusion.altitudes;

    // --- Paso 2: clamp de pendiente físicamente plausible. ---
    final clampedAltitudes =
        _clampImplausibleSteps(rawAltitudes, cumulativeDistanceMeters);

    // --- Paso 3: suavizado corto. ---
    final smoothedAltitudes = _movingAverage(clampedAltitudes, smoothingRadius);

    // --- Paso 4: pendiente por regresión de ventana. ---
    final slopeCalculator =
        SlopeWindowCalculator(windowMeters: slopeWindowMeters);
    final slopePercents = <double>[];
    for (int i = 0; i < points.length; i++) {
      slopePercents.add(
        slopeCalculator.addSample(
          cumulativeDistanceMeters: cumulativeDistanceMeters[i],
          altitude: smoothedAltitudes[i],
        ),
      );
    }

    // --- Desnivel +/- sobre la distancia, con histéresis. ---
    // Misma receta con o sin barómetro. Strava cuenta los archivos
    // barométricos con un umbral más bajo (2 m), pero en una prueba con
    // un barómetro simulado sobre el terreno real ese umbral sumaba el
    // microrrelieve del modelo (1.100 m contra 911 del Garmin): queda
    // por calibrar con una salida real grabada junto al Garmin.
    final gl = computeRouteGainLoss(
      smoothedAltitudes,
      cumulativeDistanceMeters,
      windowMeters: gainWindowMeters,
      minChangeMeters: elevationHysteresisMeters,
    );

    return FlattenedAltitudeResult(
      altitudes: smoothedAltitudes,
      slopePercents: slopePercents,
      sources: sources,
      isApproximate: isApproximate,
      barometric: fusion.barometric,
      shares: fusion.shares,
      elevationGainMeters: gl.gainMeters,
      elevationLossMeters: gl.lossMeters,
    );
  }

  List<double> _clampImplausibleSteps(
    List<double> altitudes,
    List<double> cumulativeDistanceMeters,
  ) {
    if (altitudes.length < 2) return List.of(altitudes);
    final clamped = List<double>.of(altitudes);
    for (int i = 1; i < clamped.length; i++) {
      final stepDistance =
          cumulativeDistanceMeters[i] - cumulativeDistanceMeters[i - 1];
      if (stepDistance <= 0) continue;
      final maxDelta = (maxPlausibleGradePercent / 100) * stepDistance;
      final delta = clamped[i] - clamped[i - 1];
      if (delta.abs() > maxDelta) {
        clamped[i] = clamped[i - 1] + maxDelta * delta.sign;
      }
    }
    return clamped;
  }

  List<double> _movingAverage(List<double> values, int radius) {
    if (radius <= 0 || values.length < 3) return List.of(values);
    final result = <double>[];
    for (int i = 0; i < values.length; i++) {
      final start = (i - radius).clamp(0, values.length - 1);
      final end = (i + radius).clamp(0, values.length - 1);
      double sum = 0;
      int count = 0;
      for (int j = start; j <= end; j++) {
        sum += values[j];
        count++;
      }
      result.add(sum / count);
    }
    return result;
  }
}
