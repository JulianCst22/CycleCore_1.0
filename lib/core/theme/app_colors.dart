import 'package:flutter/material.dart';

import 'cc_colors.dart';

/// Paleta histórica de CycleCore.
///
/// **Los valores ahora se derivan de [CcColors]** -- esta clase se
/// mantiene para no tener que tocar las ~200 pantallas que la usan de
/// una sola vez. En código nuevo, usa [CcColors] directamente. Cada
/// pantalla se irá migrando a `CcColors` en su pasada de rediseño.
class AppColors {
  AppColors._();

  static const Color primary = CcColors.orange;

  /// Panel/scaffold oscuro.
  static const Color panelBackground = CcColors.surface;

  // Un color de acento por métrica -- para gráficos y cockpit (series
  // de datos, no decoración).
  static const Color accentTime = CcColors.mTime;
  static const Color accentDistance = CcColors.mDist;
  static const Color accentSpeed = CcColors.mSpeed;
  static const Color accentHeartRate = CcColors.mHeartRate;
  static const Color accentElevation = CcColors.mElevation;
  static const Color accentSlope = CcColors.mSlope;
  static const Color accentPower = CcColors.mPower;
  static const Color accentCadence = CcColors.mCadence;

  static const Color textPrimaryOnPanel = CcColors.ink;
  static const Color textSecondaryOnPanel = CcColors.inkDim;

  static const Color recordButtonActive = CcColors.danger;
  static const Color recordButtonInactive = CcColors.ok;

  static const Color accentTraining = CcColors.entreno;

  // Segmentos.
  static const Color segmentStart = CcColors.segmentStart;
  static const Color segmentEnd = CcColors.danger;
  static const Color segmentActiveTrack = CcColors.segmentActiveTrack;
  static const Color segmentIdleTrack = CcColors.segmentIdleTrack;

  static const Color ghostAhead = CcColors.ghostAhead;
  static const Color ghostBehind = CcColors.ghostBehind;
}
