import 'rank_tier.dart';

/// Rango temático de ciclismo asociado a un rango de niveles.
enum CyclistRank { novato, rodador, escalador, fondista, elite, leyenda }

extension CyclistRankLabel on CyclistRank {
  String get label => switch (this) {
        CyclistRank.novato => 'Novato',
        CyclistRank.rodador => 'Rodador',
        CyclistRank.escalador => 'Escalador',
        CyclistRank.fondista => 'Fondista',
        CyclistRank.elite => 'Élite',
        CyclistRank.leyenda => 'Leyenda',
      };
}

/// Nivel y progreso actual del usuario, derivado de su XP total.
class LevelInfo {
  final int level;
  final CyclistRank rank;
  final int totalXp;

  /// XP acumulado dentro del nivel actual (0 al recién subir de nivel).
  final int xpIntoLevel;

  /// XP total que requiere este nivel para completarse.
  final int xpForThisLevel;

  const LevelInfo({
    required this.level,
    required this.rank,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpForThisLevel,
  });

  double get progress => xpForThisLevel == 0
      ? 0
      : (xpIntoLevel / xpForThisLevel).clamp(0.0, 1.0);

  int get xpRemainingForNextLevel => xpForThisLevel - xpIntoLevel;
}

/// Convierte XP total en nivel + rango, con una curva de dificultad
/// creciente (cada nivel requiere más XP que el anterior) -- típica de
/// sistemas de progresión tipo RPG, para que subir de nivel siga
/// sintiéndose especial más adelante en la app.
class LevelCalculator {
  LevelCalculator._();

  /// XP acumulado (desde 0) necesario para *alcanzar* el nivel [level].
  /// El nivel 1 empieza en 0 XP.
  ///
  /// Pública (antes era privada) porque el editor de XP de testing del
  /// perfil la necesita para convertir "quiero probar el nivel N" en el
  /// total de XP equivalente.
  static int cumulativeXpToReach(int level) {
    if (level <= 1) return 0;
    return 150 * (level - 1) * (level - 1);
  }

  static LevelInfo fromTotalXp(int totalXp) {
    var level = 1;
    while (cumulativeXpToReach(level + 1) <= totalXp) {
      level++;
    }

    final xpAtLevelStart = cumulativeXpToReach(level);
    final xpAtNextLevel = cumulativeXpToReach(level + 1);

    return LevelInfo(
      level: level,
      rank: RankTier.rankForLevel(level),
      totalXp: totalXp,
      xpIntoLevel: totalXp - xpAtLevelStart,
      xpForThisLevel: xpAtNextLevel - xpAtLevelStart,
    );
  }
}
