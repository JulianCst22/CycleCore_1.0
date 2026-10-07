import '../../../../core/fuzzy_type2/fuzzy_type2.dart';
import '../../../../core/physiology/physiology.dart'
    show virtualPowerCredibility;
import '../variables/coaching_variables.dart';

/// De dónde sale el perfil del segmento.
enum TerrainSource {
  /// Catálogo de la app (GPX barométrico revisado).
  catalog,

  /// GPX importado por el usuario (altitud barométrica).
  gpxImport,

  /// Recortado de una actividad propia (altitud aplanada contra el DEM).
  ownActivity,
}

/// Estado de las fuentes de datos en un instante.
final class SensorStatus {
  /// Segundos desde la última lectura; `null` si el sensor no está
  /// conectado.
  final double? powerAgeSeconds;

  /// La potencia con la que trabaja el motor salió de la velocidad y la
  /// pendiente, no de un potenciómetro.
  final bool powerIsEstimated;
  final double? heartRateAgeSeconds;
  final double? cadenceAgeSeconds;

  /// Segundos desde que la pendiente cambió más de un punto: el pulso
  /// tarda en reaccionar a un cambio de carga.
  final double secondsSinceGradientChange;

  /// Pendiente actual, en %.
  final double currentGradient;

  final TerrainSource terrainSource;

  /// Hay un esfuerzo de referencia (el récord) para comparar.
  final bool hasReference;

  const SensorStatus({
    required this.powerAgeSeconds,
    this.powerIsEstimated = false,
    required this.heartRateAgeSeconds,
    required this.cadenceAgeSeconds,
    required this.secondsSinceGradientChange,
    required this.currentGradient,
    required this.terrainSource,
    required this.hasReference,
  });

  /// El mismo estado, diciendo si la potencia con la que se trabaja es
  /// estimada. Lo sabe la sesión, no quien lee los sensores.
  SensorStatus withEstimatedPower(bool estimated) => SensorStatus(
    powerAgeSeconds: powerAgeSeconds,
    powerIsEstimated: estimated,
    heartRateAgeSeconds: heartRateAgeSeconds,
    cadenceAgeSeconds: cadenceAgeSeconds,
    secondsSinceGradientChange: secondsSinceGradientChange,
    currentGradient: currentGradient,
    terrainSource: terrainSource,
    hasReference: hasReference,
  );
}

/// Cuánto vale cada fuente ahora mismo (0–1).
final class SensorCredibility {
  final double power;
  final double heartRate;
  final double cadence;

  /// La velocidad no entra a las reglas, pero decide si el mensaje debe
  /// advertir que no se mire: en subida no informa nada.
  final double speed;
  final double terrain;
  final double reference;

  const SensorCredibility({
    this.power = 1,
    this.heartRate = 1,
    this.cadence = 1,
    this.speed = 1,
    this.terrain = 1,
    this.reference = 1,
  });

  /// Credibilidad a partir del estado de los sensores:
  ///
  ///     potencia  = conectado · baja(edad; 3, 8)
  ///                 estimada: según la pendiente, con tope 0,8
  ///     pulso     = conectado · min(baja(edad; 5, 15), sube(t_Δg; 20, 40))
  ///     cadencia  = conectado · baja(edad; 3, 8)
  ///     velocidad = baja(|pendiente|; 2, 5)
  ///     terreno   = 1 catálogo o GPX, 0,8 actividad propia
  factory SensorCredibility.from(SensorStatus s) {
    double fresh(double? age, double full, double none) =>
        age == null ? 0 : Trapezoid.leftShoulder(full, none).mu(age);
    final hrLag = const Trapezoid.rightShoulder(
      20,
      40,
    ).mu(s.secondsSinceGradientChange);
    final hrFresh = fresh(s.heartRateAgeSeconds, 5, 15);
    return SensorCredibility(
      // Sin potenciómetro la potencia se estima con la velocidad: en
      // subida vale bastante, en llano no vale nada (ver
      // `virtualPowerCredibility`).
      power: s.powerIsEstimated
          ? virtualPowerCredibility(s.currentGradient)
          : fresh(s.powerAgeSeconds, 3, 8),
      heartRate: hrFresh < hrLag ? hrFresh : hrLag,
      cadence: fresh(s.cadenceAgeSeconds, 3, 8),
      speed: const Trapezoid.leftShoulder(2, 5).mu(s.currentGradient.abs()),
      terrain: switch (s.terrainSource) {
        TerrainSource.catalog || TerrainSource.gpxImport => 1,
        TerrainSource.ownActivity => 0.8,
      },
      reference: s.hasReference ? 1 : 0,
    );
  }

  double of(DataSource source) => switch (source) {
    DataSource.power => power,
    DataSource.heartRate => heartRate,
    DataSource.cadence => cadence,
    DataSource.terrain => terrain,
    DataSource.reference => reference,
  };
}
