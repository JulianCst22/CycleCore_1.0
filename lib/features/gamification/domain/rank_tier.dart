import 'level_info.dart';

/// Nombre + rango de niveles de un [CyclistRank].
///
/// Es la fuente única de verdad de "qué nivel pertenece a qué rango".
/// Lo visual (color e ícono de cada rango) vive aparte, en la capa de
/// presentación (`RankTierStyle`), para que el dominio no dependa de
/// Flutter.
class RankTierInfo {
  final CyclistRank rank;
  final String label;
  final int minLevel;
  final int maxLevel;

  const RankTierInfo({
    required this.rank,
    required this.label,
    required this.minLevel,
    required this.maxLevel,
  });

  bool containsLevel(int level) => level >= minLevel && level <= maxLevel;
}

/// Catálogo ordenado de los 6 rangos temáticos, de menor a mayor.
class RankTier {
  RankTier._();

  static const List<RankTierInfo> all = [
    RankTierInfo(
      rank: CyclistRank.novato,
      label: 'Novato',
      minLevel: 1,
      maxLevel: 4,
    ),
    RankTierInfo(
      rank: CyclistRank.rodador,
      label: 'Rodador',
      minLevel: 5,
      maxLevel: 9,
    ),
    RankTierInfo(
      rank: CyclistRank.escalador,
      label: 'Escalador',
      minLevel: 10,
      maxLevel: 14,
    ),
    RankTierInfo(
      rank: CyclistRank.fondista,
      label: 'Fondista',
      minLevel: 15,
      maxLevel: 19,
    ),
    RankTierInfo(
      rank: CyclistRank.elite,
      label: 'Élite',
      minLevel: 20,
      maxLevel: 24,
    ),
    RankTierInfo(
      rank: CyclistRank.leyenda,
      label: 'Leyenda',
      minLevel: 25,
      // Sin techo real: 999 es solo un valor alto para "resto de niveles".
      maxLevel: 999,
    ),
  ];

  static RankTierInfo forRank(CyclistRank rank) =>
      all.firstWhere((tier) => tier.rank == rank);

  /// Deriva el rango correspondiente a un nivel. `level_info.dart` usa
  /// esto en vez de tener su propio switch.
  static RankTierInfo forLevel(int level) => all.firstWhere(
        (tier) => tier.containsLevel(level),
        orElse: () => all.last,
      );

  static CyclistRank rankForLevel(int level) => forLevel(level).rank;

  static int indexOfRank(CyclistRank rank) =>
      all.indexWhere((tier) => tier.rank == rank);
}
