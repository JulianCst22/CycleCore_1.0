import '../core/fuzzy_inference_engine.dart';
import '../core/fuzzy_membership.dart';
import '../core/fuzzy_rule.dart';
import 'altitude_source_reading.dart';

/// Resultado de fusionar las fuentes de altitud disponibles para un
/// punto: la altitud de confianza a usar, cuánto pesó el DEM en esa
/// decisión, y si se sospecha estructura elevada (puente/viaducto).
class AltitudeFusionResult {
  final double fusedAltitude;
  final double trustDem;
  final bool bridgeSuspected;

  const AltitudeFusionResult({
    required this.fusedAltitude,
    required this.trustDem,
    required this.bridgeSuspected,
  });
}

/// CAPA 1 del modelo geoespacial: decide, punto por punto, cuánto pesar
/// el DEM (SRTM/NASA) frente a la altitud en tiempo real usando un
/// motor difuso Sugeno de orden cero.
///
/// La persistencia de una discrepancia (¿cuánta distancia lleva
/// sostenida?) se mide con una RACHA CONTINUA por distancia -- se
/// acumula mientras el signo de la discrepancia (DEM más arriba o más
/// abajo que el tiempo real) se mantiene igual al de la muestra
/// anterior, y se reinicia en cuanto cambia. Es la misma técnica que
/// usa SlopePlausibilityFilter (Capa 2) para su `_persistenceDistance`
/// -- antes esta capa usaba un ratio de conteo de muestras
/// (positivas/total dentro de una ventana), que a alta velocidad (pocas
/// muestras por ventana) daba una granularidad demasiado gruesa (1/2,
/// 1/3...). La racha continua es precisa sin importar cuántas muestras
/// haya, y además deja a las dos capas consistentes entre sí.
class AltitudeFusionFilter {
  double _persistenceDistance = 0;
  double _lastSign = 0;

  /// Distancia acumulada desde la última recalibración del barómetro
  /// contra el DEM (ver [shouldRecalibrate]).
  double _distanceSinceRecalibration = 0;

  late final FuzzyInferenceEngine _engine = FuzzyInferenceEngine(
    fallbackOutput: 0.5,
    rules: [
      FuzzyRule(
        name: 'acuerdo_confia_dem',
        firingStrength: (d) => d['agreementSmall']!,
        outputValue: 0.9,
      ),
      FuzzyRule(
        name: 'discrepancia_puntual_ignora',
        firingStrength: (d) =>
            FuzzyRule.and([d['agreementLarge']!, d['persistenceShort']!]),
        outputValue: 0.85,
      ),
      FuzzyRule(
        name: 'estructura_elevada_confia_realtime',
        firingStrength: (d) => FuzzyRule.and([
          d['agreementLarge']!,
          d['persistenceSustained']!,
        ]),
        outputValue: 0.1,
      ),
      FuzzyRule(
        name: 'zona_gris_mezcla',
        firingStrength: (d) =>
            FuzzyRule.or([d['agreementMedium']!, d['persistenceMedium']!]),
        outputValue: 0.5,
      ),
      FuzzyRule(
        name: 'gps_impreciso_confia_dem',
        firingStrength: (d) => d['gpsInaccurate']!,
        outputValue: 0.8,
      ),
    ],
  );

  AltitudeFusionResult fuse(AltitudeSourceReading reading) {
    if (!reading.tileAvailable) {
      // Sin tesela DEM: no hay nada que fusionar, se vive 100% del
      // tiempo real. Se reinicia la racha para no arrastrar contexto
      // de otra zona cuando vuelva a haber tesela.
      _persistenceDistance = 0;
      _lastSign = 0;
      return AltitudeFusionResult(
        fusedAltitude: reading.realtimeAltitude,
        trustDem: 0,
        bridgeSuspected: false,
      );
    }

    final discrepancy = reading.demAltitude! - reading.realtimeAltitude;
    final magnitude = discrepancy.abs();

    final sign = discrepancy.sign;
    _persistenceDistance = (sign == _lastSign && sign != 0)
        ? _persistenceDistance + reading.stepDistanceMeters
        : reading.stepDistanceMeters;
    _lastSign = sign;

    final degrees = <String, double>{
      'agreementSmall': rampDown(magnitude, 2, 6),
      'agreementMedium': triangular(magnitude, 3, 8, 15),
      'agreementLarge': rampUp(magnitude, 8, 15),
      'persistenceShort': rampDown(_persistenceDistance, 5, 20),
      'persistenceMedium': triangular(_persistenceDistance, 10, 25, 40),
      'persistenceSustained': rampUp(_persistenceDistance, 25, 45),
      'gpsInaccurate': reading.gpsAccuracyMeters == null
          ? 0.0
          : rampUp(reading.gpsAccuracyMeters!, 15, 30),
    };

    final trustDem = _engine.infer(degrees).clamp(0.0, 1.0);
    final bridgeSuspected = trustDem < 0.3;

    if (!bridgeSuspected) {
      _distanceSinceRecalibration += reading.stepDistanceMeters;
    }

    final fusedAltitude = (trustDem * reading.demAltitude!) +
        ((1 - trustDem) * reading.realtimeAltitude);

    return AltitudeFusionResult(
      fusedAltitude: fusedAltitude,
      trustDem: trustDem,
      bridgeSuspected: bridgeSuspected,
    );
  }

  /// Debe consultarse después de cada [fuse]. Si devuelve true, el
  /// llamador debe ejecutar la recalibración sobre AltitudeFusionService
  /// en ESE punto -- este filtro solo decide CUÁNDO es seguro.
  bool shouldRecalibrate({double minDistanceMeters = 100}) {
    if (_distanceSinceRecalibration < minDistanceMeters) return false;
    _distanceSinceRecalibration = 0;
    return true;
  }

  void reset() {
    _persistenceDistance = 0;
    _lastSign = 0;
    _distanceSinceRecalibration = 0;
  }
}
