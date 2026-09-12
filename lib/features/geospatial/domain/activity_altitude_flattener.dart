import 'package:cyclecore_core/utils/elevation_gain_loss.dart';
import '../../elevation/data/elevation_resolver.dart';
import 'route_point.dart';
import 'slope_window_calculator.dart';

/// Resultado de "aplanar" la altimetría de una actividad completa
/// contra la cadena de prioridades de elevación (GPX > HGT > fusión en
/// vivo), en vez de confiar en la altitud fusionada GPS+barómetro que
/// se usó en tiempo real.
///
/// Los arreglos quedan alineados índice a índice con la lista de
/// `RoutePoint` original.
class FlattenedAltitudeResult {
  final List<double> altitudes;
  final List<double> slopePercents;

  /// Fuente usada en cada punto -- para que "Ajustar altimetría"
  /// pueda decir "X% con GPX, Y% con HGT, Z% aproximado".
  final List<ElevationSource> sources;

  /// true en los puntos donde NINGUNA fuente confiable tenía dato y se
  /// tuvo que caer a la altitud fusionada en vivo. Equivale a
  /// `sources[i] == ElevationSource.none`.
  final List<bool> isApproximate;

  final double elevationGainMeters;
  final double elevationLossMeters;

  const FlattenedAltitudeResult({
    required this.altitudes,
    required this.slopePercents,
    required this.sources,
    required this.isApproximate,
    required this.elevationGainMeters,
    required this.elevationLossMeters,
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

/// Aplana la altimetría de una actividad contra la cadena de
/// prioridades de elevación (`ElevationResolver`):
///
///   1. **GPX** -- si la actividad pasa cerca de un track GPX conocido
///      (segmento importado o del catálogo), su altitud barométrica.
///   2. **HGT** -- grilla SRTM descargada.
///   3. **Fusión en vivo** -- el GPS/barómetro que se usó grabando; el
///      punto queda marcado como aproximado.
///
/// Se ejecuta al terminar de grabar (`finishRecording`) y de nuevo cada
/// vez que el usuario toca "Ajustar altimetría" (útil tras descargar
/// teselas HGT o importar un GPX del recorrido).
///
/// Algoritmo:
///  1. Altitud por punto según la cadena de prioridades.
///  2. **Clamp de pendiente físicamente plausible** entre puntos
///     consecutivos ([maxPlausibleGradePercent]) -- corta el efecto
///     "costura" al cambiar de fuente y los outliers puntuales.
///  3. Suavizado corto (promedio móvil) contra el "diente de sierra"
///     de la grilla DEM.
///  4. Pendiente recalculada por regresión de ventana
///     (`SlopeWindowCalculator`), alimentada con la altitud ya limpia.
///
/// El desnivel (+/-) se calcula con histéresis (`computeGainLoss`), no
/// sumando cada delta -- así una serie ruidosa (barómetro indoor de un
/// test, costuras de HGT) no infla el desnivel en ambos sentidos.
class ActivityAltitudeFlattener {
  final ElevationResolver resolver;
  final int smoothingRadius;
  final double slopeWindowMeters;

  /// Cambio de altitud (m) por debajo del cual, entre dos pivotes de la
  /// serie ya suavizada, NO se cuenta como desnivel. Histéresis, no
  /// piso fijo -- ver `computeGainLoss`.
  final double elevationHysteresisMeters;

  final double maxPlausibleGradePercent;

  ActivityAltitudeFlattener(
    this.resolver, {
    this.smoothingRadius = 1,
    this.slopeWindowMeters = 40,
    this.elevationHysteresisMeters = 3,
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

    // --- Paso 1: altitud por punto según GPX > HGT > fusión en vivo. ---
    final rawAltitudes = <double>[];
    final sources = <ElevationSource>[];
    final isApproximate = <bool>[];

    for (final point in points) {
      final resolved = resolver.resolve(point.latitude, point.longitude);
      if (resolved.altitudeMeters != null) {
        rawAltitudes.add(resolved.altitudeMeters!);
        sources.add(resolved.source);
        isApproximate.add(false);
      } else {
        rawAltitudes.add(point.altitude);
        sources.add(ElevationSource.none);
        isApproximate.add(true);
      }
    }

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

    // --- Desnivel +/- con histéresis. ---
    final gl = computeGainLoss(
      smoothedAltitudes,
      minChangeMeters: elevationHysteresisMeters,
    );

    return FlattenedAltitudeResult(
      altitudes: smoothedAltitudes,
      slopePercents: slopePercents,
      sources: sources,
      isApproximate: isApproximate,
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
