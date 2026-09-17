import 'package:flutter/material.dart';

import '../domain/level_info.dart';
import '../domain/rank_tier.dart';
import 'package:core_ui/core_ui.dart';

/// Lo visual de cada rango -- color e ícono --, separado de
/// [RankTierInfo] (dominio) para que las reglas de niveles no dependan
/// de Flutter.
///
/// Los colores reutilizan la paleta de acentos de las métricas
/// (`AppColors.accentTime`, `accentSlope`, etc.) en vez de definir hex
/// nuevos, para que el roadmap se sienta parte de la misma identidad
/// visual del resto de la app.
extension RankTierStyle on RankTierInfo {
  Color get color => switch (rank) {
    CyclistRank.novato => AppColors.textSecondaryOnPanel,
    CyclistRank.rodador => AppColors.accentTime,
    CyclistRank.escalador => AppColors.accentSlope,
    CyclistRank.fondista => AppColors.accentElevation,
    CyclistRank.elite => AppColors.accentPower,
    CyclistRank.leyenda => AppColors.primary,
  };

  IconData get icon => switch (rank) {
    CyclistRank.novato => Icons.directions_bike,
    CyclistRank.rodador => Icons.pedal_bike,
    CyclistRank.escalador => Icons.terrain,
    CyclistRank.fondista => Icons.landscape,
    CyclistRank.elite => Icons.bolt,
    CyclistRank.leyenda => Icons.emoji_events,
  };
}
