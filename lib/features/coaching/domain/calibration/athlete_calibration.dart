import '../../../../core/physiology/physiology.dart';

/// De dónde sale la potencia crítica del ciclista, de la más confiable a
/// la menos.
enum CalibrationBasis {
  /// Regresión trabajo–tiempo sobre sus mejores esfuerzos de 3 a 20 min
  /// que pasó los criterios de calidad.
  fitted,

  /// 95 % de su mejor potencia de 20 min: la regresión no se pudo hacer o
  /// no pasó los criterios.
  twentyMinutes,

  /// Su FTP del perfil, tomada como CP: no hay esfuerzos de 20 min.
  ftp,

  /// El punto de partida de su nivel y su peso: todavía no ha rodado con
  /// datos suficientes. La banda es ancha y el motor lo tiene en cuenta.
  level,

  /// Ni datos, ni FTP, ni peso y nivel: no hay con qué empezar.
  none,
}

/// Potencia crítica y W′ del ciclista para el coach.
///
/// Se calibra con la curva de potencia de los últimos [window]: los
/// esfuerzos viejos no describen la forma actual.
final class AthleteCalibration {
  static const window = Duration(days: 90);

  final CalibrationBasis basis;

  /// Modelo que usa el coach; `null` si [basis] es `none`.
  final CriticalPowerModel? model;

  /// Regresión intentada, aunque no se haya usado.
  final CriticalPowerModel? fit;

  /// Por qué no se usó la regresión (vacía si se usó).
  final List<String> rejectionReasons;

  const AthleteCalibration._({
    required this.basis,
    required this.model,
    required this.fit,
    required this.rejectionReasons,
  });

  factory AthleteCalibration.from({
    required MeanMaxCurve recentPower,
    int? ftpWatts,
    RiderLevel? level,
    double? weightKg,
    CriticalPowerCriteria criteria = const CriticalPowerCriteria(),
  }) {
    final fit = CriticalPowerModel.fit(recentPower, criteria: criteria);
    final reasons = fit == null
        ? const ['faltan esfuerzos máximos de 3 a 20 min']
        : fit.rejectionReasons(criteria);
    if (fit != null && reasons.isEmpty) {
      return AthleteCalibration._(
        basis: CalibrationBasis.fitted,
        model: fit,
        fit: fit,
        rejectionReasons: const [],
      );
    }
    final twenty = recentPower[1200];
    if (twenty != null) {
      return AthleteCalibration._(
        basis: CalibrationBasis.twentyMinutes,
        model: CriticalPowerModel.estimated(
          twentyMinutePower: Watts(twenty.value),
        ),
        fit: fit,
        rejectionReasons: reasons,
      );
    }
    if (ftpWatts != null && ftpWatts > 0) {
      // La FTP se define como ~95 % de la potencia de 20 min, igual que
      // la CP estimada: se toma directamente como CP.
      return AthleteCalibration._(
        basis: CalibrationBasis.ftp,
        model: CriticalPowerModel.estimated(
          twentyMinutePower: Watts(ftpWatts / 0.95),
        ),
        fit: fit,
        rejectionReasons: reasons,
      );
    }
    // Todavía sin nada medido: se arranca con lo que corresponde a su
    // nivel y su peso. No es preciso, y por eso la banda es ancha, pero
    // es mucho mejor que callarse o que suponerle a todo el mundo los
    // mismos 20 kJ de reserva.
    if (level != null && weightKg != null && weightKg > 0) {
      return AthleteCalibration._(
        basis: CalibrationBasis.level,
        model: priorModel(level, weightKg: weightKg),
        fit: fit,
        rejectionReasons: reasons,
      );
    }
    return AthleteCalibration._(
      basis: CalibrationBasis.none,
      model: null,
      fit: fit,
      rejectionReasons: reasons,
    );
  }

  /// Frase corta que dice de dónde salen los números.
  String get explanation {
    switch (basis) {
      case CalibrationBasis.fitted:
        final m = model!;
        final r2 = m.rSquared?.toStringAsFixed(3);
        final out = m.dropped.isEmpty
            ? ''
            : ', sin contar ${m.dropped.length} que no fueron a tope';
        return 'Ajustada con ${m.points} esfuerzos de los últimos 90 días'
            '${r2 == null ? '' : ' (R² $r2)'}$out';
      case CalibrationBasis.twentyMinutes:
        return 'Estimada con el 95 % de tu mejor potencia de 20 min';
      case CalibrationBasis.ftp:
        return 'Estimada con tu FTP: faltan salidas con potenciómetro';
      case CalibrationBasis.level:
        return 'Punto de partida de tu nivel y tu peso: sube tu FTP o sal '
            'a rodar y se ajusta sola';
      case CalibrationBasis.none:
        return 'Sin datos de potencia en los últimos 90 días';
    }
  }
}
