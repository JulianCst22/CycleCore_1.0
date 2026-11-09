import '../../../core/geo/geo.dart';
import '../../elevation/elevation.dart';
import 'barometric_profile.dart';
import 'route_point.dart';

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

  /// true si la forma del perfil salió del barómetro (y el nivel del
  /// modelo de elevación) -- ver `barometricProfile`.
  final bool barometric;

  const FlattenedAltitudeResult({
    required this.altitudes,
    required this.slopePercents,
    required this.sources,
    required this.isApproximate,
    required this.elevationGainMeters,
    required this.elevationLossMeters,
    this.barometric = false,
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
///  1. Altitud por punto según la cadena de prioridades. Los tramos
///     sin GPX ni HGT conservan la forma de la altitud en vivo, pero
///     su nivel se engancha a los puntos confiables de los extremos
///     (ver [_anchorUnresolvedRuns]).
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
    // Con barómetro, su forma manda y el nivel lo pone el modelo; sin
    // él, los tramos sin modelo se enganchan a sus extremos.
    final barometric = barometricProfile(
      pressures: [for (final p in points) p.pressureHpa],
      distances: cumulativeDistanceMeters,
      reference: [
        for (var i = 0; i < points.length; i++)
          sources[i] == ElevationSource.none ? null : rawAltitudes[i],
      ],
      fallback: [for (final p in points) p.altitude],
    );
    if (barometric != null) {
      final hasReference = sources.any((s) => s != ElevationSource.none);
      for (var i = 0; i < points.length; i++) {
        rawAltitudes[i] = barometric[i];
        isApproximate[i] = !hasReference;
      }
    } else {
      _anchorUnresolvedRuns(
        rawAltitudes,
        sources,
        points,
        cumulativeDistanceMeters,
      );
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
      barometric: barometric != null,
      elevationGainMeters: gl.gainMeters,
      elevationLossMeters: gl.lossMeters,
    );
  }

  /// Tramos sin GPX ni HGT: la altitud en vivo (barómetro + GPS) trae
  /// bien la forma, pero su nivel puede derivar cientos de metros (en la
  /// salida a La Calera del 28-oct-2026 quedó 800-1.000 m por debajo).
  /// Se corre el tramo para que empalme con el punto confiable de cada
  /// extremo: con los dos, el corrimiento va de uno a otro según la
  /// distancia; con uno solo, es constante. Sin ningún punto confiable
  /// en la salida no hay a qué engancharse y se deja tal cual.
  void _anchorUnresolvedRuns(
    List<double> altitudes,
    List<ElevationSource> sources,
    List<RoutePoint> points,
    List<double> distances,
  ) {
    var i = 0;
    while (i < altitudes.length) {
      if (sources[i] != ElevationSource.none) {
        i++;
        continue;
      }
      var j = i;
      while (j + 1 < altitudes.length &&
          sources[j + 1] == ElevationSource.none) {
        j++;
      }
      final left = i - 1;
      final right = j + 1;
      final double? offsetLeft =
          left >= 0 ? altitudes[left] - points[left].altitude : null;
      final double? offsetRight = right < altitudes.length
          ? altitudes[right] - points[right].altitude
          : null;
      if (offsetLeft != null || offsetRight != null) {
        final span = offsetLeft != null && offsetRight != null
            ? distances[right] - distances[left]
            : 0.0;
        for (var k = i; k <= j; k++) {
          var offset = offsetLeft ?? offsetRight!;
          if (offsetLeft != null && offsetRight != null && span > 0) {
            final t = (distances[k] - distances[left]) / span;
            offset = offsetLeft + (offsetRight - offsetLeft) * t;
          }
          altitudes[k] = points[k].altitude + offset;
        }
      }
      i = j + 1;
    }
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
