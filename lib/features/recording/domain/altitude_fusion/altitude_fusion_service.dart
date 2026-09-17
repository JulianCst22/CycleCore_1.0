import 'dart:math';

/// Snapshot de los valores intermedios del último cálculo de fusión,
/// expuesto SOLO para poder instrumentar/depurar -- no lo usa la
/// lógica de negocio normal, solo el AltitudeDebugLogger.
class AltitudeFusionDebugSnapshot {
  final double gpsAltitude;
  final double? smoothedPressureHpa;
  final double? barometricAltitude;
  final double barometricDeltaRaw;
  final double barometricDeltaClamped;
  final double fusedAltitude;

  const AltitudeFusionDebugSnapshot({
    required this.gpsAltitude,
    required this.smoothedPressureHpa,
    required this.barometricAltitude,
    required this.barometricDeltaRaw,
    required this.barometricDeltaClamped,
    required this.fusedAltitude,
  });
}

/// Fusiona la altitud reportada por GPS con la calculada a partir de
/// presión barométrica, usando un filtro complementario con dos
/// protecciones adicionales: suavizado de la presión cruda y rechazo
/// de outliers físicamente imposibles.
///
/// NUEVO en esta versión: [recalibrateOffset], que permite que la Capa
/// 1 del modelo geoespacial (AltitudeFusionFilter) ancle este servicio
/// contra el DEM cuando hay alta confianza en que el DEM es correcto,
/// para que la deriva barométrica no se acumule sin control en rutas
/// largas. Este servicio sigue sin saber nada de DEM ni de lógica
/// difusa -- solo expone el gancho para que lo llamen desde afuera.
class AltitudeFusionService {
  static const double _seaLevelPressureHpa = 1013.25;
  static const double _complementaryAlpha = 0.98;
  static const double _pressureSmoothingAlpha = 0.3;

  /// Velocidad vertical máxima considerada físicamente plausible para
  /// un ciclista (metros/segundo). Ni en el descenso más extremo real
  /// (30% de pendiente a 40 km/h) se supera ~3.3 m/s.
  static const double _maxPlausibleVerticalSpeedMs = 2.5;

  double? _fusedAltitude;
  double? _lastBarometricAltitude;
  double? _smoothedPressureHpa;
  DateTime? _lastUpdateTime;

  AltitudeFusionDebugSnapshot? _lastDebugSnapshot;

  /// Solo para instrumentación/depuración -- ver AltitudeDebugLogger.
  AltitudeFusionDebugSnapshot? get lastDebugSnapshot => _lastDebugSnapshot;

  double _pressureToAltitude(double pressureHpa) {
    return 44330.0 *
        (1.0 - pow(pressureHpa / _seaLevelPressureHpa, 1 / 5.255));
  }

  double fuse({required double gpsAltitude, double? pressureHpa}) {
    final now = DateTime.now();

    if (pressureHpa == null) {
      _fusedAltitude = gpsAltitude;
      _lastUpdateTime = now;
      _lastDebugSnapshot = AltitudeFusionDebugSnapshot(
        gpsAltitude: gpsAltitude,
        smoothedPressureHpa: null,
        barometricAltitude: null,
        barometricDeltaRaw: 0,
        barometricDeltaClamped: 0,
        fusedAltitude: gpsAltitude,
      );
      return gpsAltitude;
    }

    _smoothedPressureHpa = _smoothedPressureHpa == null
        ? pressureHpa
        : (_pressureSmoothingAlpha * pressureHpa) +
              ((1 - _pressureSmoothingAlpha) * _smoothedPressureHpa!);

    final barometricAltitude = _pressureToAltitude(_smoothedPressureHpa!);

    if (_fusedAltitude == null || _lastBarometricAltitude == null) {
      _fusedAltitude = gpsAltitude;
      _lastBarometricAltitude = barometricAltitude;
      _lastUpdateTime = now;
      _lastDebugSnapshot = AltitudeFusionDebugSnapshot(
        gpsAltitude: gpsAltitude,
        smoothedPressureHpa: _smoothedPressureHpa,
        barometricAltitude: barometricAltitude,
        barometricDeltaRaw: 0,
        barometricDeltaClamped: 0,
        fusedAltitude: _fusedAltitude!,
      );
      return _fusedAltitude!;
    }

    final barometricDeltaRaw = barometricAltitude - _lastBarometricAltitude!;
    var barometricDelta = barometricDeltaRaw;

    final secondsElapsed = _lastUpdateTime == null
        ? 1.0
        : now.difference(_lastUpdateTime!).inMilliseconds / 1000.0;
    final safeSeconds = secondsElapsed <= 0 ? 1.0 : secondsElapsed;

    final maxPlausibleDelta = _maxPlausibleVerticalSpeedMs * safeSeconds;
    if (barometricDelta.abs() > maxPlausibleDelta) {
      barometricDelta =
          maxPlausibleDelta * (barometricDelta.isNegative ? -1 : 1);
    }

    final predicted = _fusedAltitude! + barometricDelta;

    _fusedAltitude =
        (_complementaryAlpha * predicted) +
        ((1 - _complementaryAlpha) * gpsAltitude);
    _lastBarometricAltitude = barometricAltitude;
    _lastUpdateTime = now;

    _lastDebugSnapshot = AltitudeFusionDebugSnapshot(
      gpsAltitude: gpsAltitude,
      smoothedPressureHpa: _smoothedPressureHpa,
      barometricAltitude: barometricAltitude,
      barometricDeltaRaw: barometricDeltaRaw,
      barometricDeltaClamped: barometricDelta,
      fusedAltitude: _fusedAltitude!,
    );

    return _fusedAltitude!;
  }

  /// Recalibra el ancla de fusión (`_fusedAltitude`) hacia una
  /// referencia externa confiable -- en la práctica, el DEM, y SOLO
  /// cuando AltitudeFusionFilter (Capa 1) determinó que no hay
  /// sospecha de estructura elevada en este punto.
  ///
  /// No reemplaza `_fusedAltitude` de golpe (eso causaría un salto
  /// visible en la pendiente del siguiente punto); lo desplaza
  /// gradualmente con [blend] hacia la referencia. Esto es lo que evita
  /// que la deriva barométrica (la presión atmosférica cambia con el
  /// clima durante el recorrido, no solo con la altitud) se acumule
  /// sin control en una ruta larga.
  void recalibrateOffset(double referenceAltitude, {double blend = 0.3}) {
    if (_fusedAltitude == null) {
      _fusedAltitude = referenceAltitude;
      return;
    }
    _fusedAltitude =
        (_fusedAltitude! * (1 - blend)) + (referenceAltitude * blend);
  }

  void reset() {
    _fusedAltitude = null;
    _lastBarometricAltitude = null;
    _smoothedPressureHpa = null;
    _lastUpdateTime = null;
    _lastDebugSnapshot = null;
  }
}
