import 'rank_tier.dart';
import 'level_info.dart';

/// Un punto de interés fijo en la "subida", asociado a un nivel
/// concreto. Es contenido de producto (nombres y datos), separado del
/// cálculo de XP -- así se puede editar sin tocar la lógica de niveles.
class ClimbPointOfInterest {
  final int level;
  final String name;

  /// Dato curioso o estadística que se muestra al tocar el punto (ej.
  /// altitud, pendiente media, distancia acumulada de la subida).
  final String stat;
  final RankTierInfo tier;

  /// Altitud real (msnm), distancia acumulada (km) y pendiente local
  /// (%) en este punto, derivadas de [ElevationProfile] -- no son
  /// inventadas, se calculan interpolando el perfil real de la subida.
  final double altitudeM;
  final double distanceKm;
  final double gradePercent;

  const ClimbPointOfInterest({
    required this.level,
    required this.name,
    required this.stat,
    required this.tier,
    required this.altitudeM,
    required this.distanceKm,
    required this.gradePercent,
  });

  /// Posición normalizada (0.0 = base de la subida, 1.0 = cima) usada
  /// tanto para ubicar el punto sobre la carretera como para el
  /// conector del roadmap.
  double positionFor(int maxLevel) =>
      maxLevel <= 1 ? 0 : (level - 1) / (maxLevel - 1);
}

/// Una muestra (distancia, altitud) del perfil real de altimetría.
class ElevationSample {
  final double distanceKm;
  final double altitudeM;
  const ElevationSample(this.distanceKm, this.altitudeM);
}

/// Perfil real de altimetría del segmento Strava "Belisario - Alto de
/// Patios" (La Calera, Bogotá): 5.92 km, ~499 m de desnivel positivo,
/// pendiente media ~6.9%, con el primer 1.8 km más exigente (~7% con
/// rampas de hasta 11% pasando el mirador "La Paloma") y una rampa
/// final dura antes de coronar en los 3 001 msnm reales del Alto de
/// Patios. No es un GPX exacto punto a punto (eso requeriría el track
/// real), pero los extremos y la forma general del perfil sí son
/// datos reales, no inventados.
///
/// Esto es lo que alimenta tanto el mini-perfil de altimetría en
/// pantalla como la altitud/pendiente que se le asigna a cada nivel.
class ElevationProfile {
  ElevationProfile._();

  static const List<ElevationSample> samples = [
    ElevationSample(0.00, 2502),
    ElevationSample(0.50, 2540),
    ElevationSample(1.00, 2585),
    ElevationSample(1.80, 2628),
    ElevationSample(2.50, 2660),
    ElevationSample(3.20, 2705),
    ElevationSample(4.00, 2760),
    ElevationSample(4.70, 2825),
    ElevationSample(5.30, 2910),
    ElevationSample(5.92, 3001),
  ];

  static double get startAltitude => samples.first.altitudeM;
  static double get summitAltitude => samples.last.altitudeM;
  static double get totalDistanceKm => samples.last.distanceKm;

  /// Altitud interpolada (msnm) para una fracción [t] de la subida
  /// (0 = base en Belisario, 1 = cima del Alto de Patios).
  static double altitudeForFraction(double t) =>
      _interpolate(t.clamp(0.0, 1.0) * totalDistanceKm).altitude;

  /// Pendiente local (%) del tramo del perfil real en el que cae [t].
  static double gradeForFraction(double t) =>
      _interpolate(t.clamp(0.0, 1.0) * totalDistanceKm).grade;

  static double distanceKmForFraction(double t) =>
      t.clamp(0.0, 1.0) * totalDistanceKm;

  static ({double altitude, double grade}) _interpolate(double km) {
    for (var i = 0; i < samples.length - 1; i++) {
      final a = samples[i];
      final b = samples[i + 1];
      if (km >= a.distanceKm && km <= b.distanceKm) {
        final span = b.distanceKm - a.distanceKm;
        final f = span == 0 ? 0.0 : (km - a.distanceKm) / span;
        final altitude = a.altitudeM + (b.altitudeM - a.altitudeM) * f;
        final grade =
            span == 0 ? 0.0 : ((b.altitudeM - a.altitudeM) / (span * 1000)) * 100;
        return (altitude: altitude, grade: grade);
      }
    }
    return (altitude: samples.last.altitudeM, grade: 0.0);
  }
}

/// Genera y expone la ruta completa de la subida: un punto de interés
/// por nivel, agrupados por rango.
///
/// Los nombres y frases de ambiente están tematizados como el Alto de
/// Patios (La Calera, Bogotá) y son contenido de ejemplo -- reemplázalos
/// editando [_namesByTier] y [_flavorByTier]. La altitud/distancia/
/// pendiente de cada punto, en cambio, SÍ es real: sale de
/// [ElevationProfile], no de números inventados por punto.
class ClimbRoute {
  ClimbRoute._();

  /// Nivel más alto que dibuja la subida. Los niveles por encima de
  /// este comparten el último punto (la cima de "Leyenda").
  static const int maxLevel = 30;

  static final List<ClimbPointOfInterest> points = _buildPoints();

  static List<ClimbPointOfInterest> _buildPoints() {
    final result = <ClimbPointOfInterest>[];
    for (var level = 1; level <= maxLevel; level++) {
      final tier = RankTier.forLevel(level);
      final namesForTier = _namesByTier[tier.rank]!;
      final flavorForTier = _flavorByTier[tier.rank]!;
      final indexInTier = level - tier.minLevel;
      final safeIndex = indexInTier % namesForTier.length;

      final fraction = maxLevel <= 1 ? 0.0 : (level - 1) / (maxLevel - 1);
      final altitude = ElevationProfile.altitudeForFraction(fraction);
      final grade = ElevationProfile.gradeForFraction(fraction);
      final distanceKm = ElevationProfile.distanceKmForFraction(fraction);

      result.add(
        ClimbPointOfInterest(
          level: level,
          name: namesForTier[safeIndex],
          stat: '${altitude.round()} msnm · ${flavorForTier[safeIndex]}',
          tier: tier,
          altitudeM: altitude,
          distanceKm: distanceKm,
          gradePercent: grade,
        ),
      );
    }
    return result;
  }

  static ClimbPointOfInterest forLevel(int level) {
    final clamped = level.clamp(1, maxLevel);
    return points[clamped - 1];
  }

  static List<ClimbPointOfInterest> forTier(RankTierInfo tier) =>
      points.where((p) => p.tier.rank == tier.rank).toList();

  static const Map<CyclistRank, List<String>> _namesByTier = {
    CyclistRank.novato: [
      'Entrada a La Calera',
      'Puente del Río Teusacá',
      'Curva del Mirador Bajo',
      'Cruce a Patios',
    ],
    CyclistRank.rodador: [
      'Recta de Los Eucaliptos',
      'Mirador La Paloma',
      'Curva de Piedra',
      'Mirador de los Ciclistas',
      'Falso llano',
    ],
    CyclistRank.escalador: [
      'Rampa del Cañón',
      'Vuelta de la Neblina',
      'Alto de Patios (medio)',
      'Curva del Viento',
      'Recta de los Frailejones',
    ],
    CyclistRank.fondista: [
      'Páramo Bajo',
      'Recta Final del Bosque',
      'Alto de Patios (alto)',
      'Vuelta de los Frailejones',
      'Antesala de la rampa final',
    ],
    CyclistRank.elite: [
      'Rampa de la Cruz',
      'Mirador de la Sabana',
      'Curva de los Cóndores',
      'Últimos 500m',
      'La rampa final',
    ],
    CyclistRank.leyenda: [
      'Cima de Alto de Patios',
      'Techo de tu progreso',
      'El Salón de la Leyenda',
      'Cumbre Eterna',
      'Gloria del Ciclista',
    ],
  };

  /// Solo la frase de ambiente -- la altitud real ya no vive aquí, se
  /// calcula en [_buildPoints] a partir de [ElevationProfile].
  static const Map<CyclistRank, List<String>> _flavorByTier = {
    CyclistRank.novato: [
      'pendiente suave',
      'terreno plano',
      'primeras curvas',
      'empieza la subida real',
    ],
    CyclistRank.rodador: [
      'calentando motores',
      'primer tramo duro, hasta 11%',
      'curva cerrada',
      'vista a la sabana',
      'un respiro tras lo más duro',
    ],
    CyclistRank.escalador: [
      'aprieta otra vez',
      'niebla frecuente',
      'mitad de la subida',
      'viento de frente',
      'entre frailejones',
    ],
    CyclistRank.fondista: [
      'vegetación de páramo',
      'aire más delgado',
      'pendiente sostenida',
      'frailejones a los lados',
      'se siente el esfuerzo acumulado',
    ],
    CyclistRank.elite: [
      'empieza el tramo más duro',
      'vista de 360°',
      'pocos llegan aquí',
      'el último esfuerzo',
      'rampa final, la más dura de todas',
    ],
    CyclistRank.leyenda: [
      'la cima real: 3 001 msnm',
      'el punto más alto de tu progreso',
      'reservado para los grandes',
      'donde pocos han estado',
      'no hay nada más arriba',
    ],
  };
}
