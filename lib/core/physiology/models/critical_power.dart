import 'dart:math' as math;

import '../signal/mean_max.dart';
import '../units.dart';

/// De dónde salen los parámetros del modelo.
enum CriticalPowerSource {
  /// Regresión sobre esfuerzos máximos que pasó los criterios.
  fitted,

  /// Respaldo: 95 % de la potencia de 20 min y W′ poblacional.
  estimated,

  /// Valores que el usuario conoce (por ejemplo, de un test de
  /// laboratorio) y escribe a mano.
  manual,
}

/// Criterios para aceptar una regresión de potencia crítica.
final class CriticalPowerCriteria {
  final int minPoints;

  /// Diferencia mínima entre el esfuerzo más largo y el más corto.
  final int minRangeSeconds;
  final double minRSquared;

  /// Error estándar máximo de CP y de W′, relativos a su valor.
  final double maxRelativeSeCp;
  final double maxRelativeSeWPrime;

  /// Cuánto puede quedarse un punto por debajo de la recta antes de
  /// considerarlo un esfuerzo no máximo y sacarlo del ajuste.
  final double maxShortfall;

  const CriticalPowerCriteria({
    this.minPoints = 3,
    this.minRangeSeconds = 600,
    this.minRSquared = 0.98,
    this.maxRelativeSeCp = 0.05,
    this.maxRelativeSeWPrime = 0.20,
    this.maxShortfall = 0.02,
  });
}

/// Duraciones que se usan para ajustar: entre 3 y 20 minutos, donde el
/// modelo lineal es válido (más cortas domina el sistema anaeróbico
/// rápido; más largas pesa la fatiga).
///
/// Seis puntos en vez de los cuatro del documento: cuantos más entran,
/// más angosta queda la banda de CP y antes se le puede creer al
/// ajuste. No se ponen más juntos a propósito —dos duraciones vecinas
/// suelen salir del mismo esfuerzo, así que aportan poco y harían
/// parecer el error menor de lo que es.
const criticalPowerDurations = <int>[180, 300, 480, 720, 960, 1200];

/// Modelo de potencia crítica del atleta: `W(t) = CP·t + W′`.
///
/// Con un ajuste por mínimos cuadrados, la pendiente es la potencia
/// crítica y el corte con el eje es la reserva anaeróbica. El modelo
/// guarda también la incertidumbre de ambos y su covarianza: salen de la
/// misma recta, así que sus errores están correlacionados.
final class CriticalPowerModel {
  final Watts cp;
  final Joules wPrime;
  final CriticalPowerSource source;

  /// Errores estándar y covarianza de CP (W) y W′ (J).
  final double seCp;
  final double seWPrime;
  final double covariance;

  /// Calidad del ajuste; `null` si el modelo es estimado.
  final double? rSquared;
  final double? standardError;
  final int points;

  /// Residuos `W real − W predicho`, por duración.
  final Map<int, double> residuals;

  /// Duraciones que se descartaron por quedar muy por debajo de la
  /// recta: esfuerzos que casi seguro no fueron máximos.
  final List<int> dropped;

  const CriticalPowerModel._({
    required this.cp,
    required this.wPrime,
    required this.source,
    required this.seCp,
    required this.seWPrime,
    required this.covariance,
    required this.rSquared,
    required this.standardError,
    required this.points,
    required this.residuals,
    this.dropped = const [],
  });

  /// Correlación entre CP y W′ (−1 a 1); 0 si no hay incertidumbre.
  double get correlation =>
      seCp == 0 || seWPrime == 0 ? 0 : covariance / (seCp * seWPrime);

  double get relativeSeCp => seCp / cp;
  double get relativeSeWPrime => seWPrime / wPrime;

  /// Ajuste de trabajo contra tiempo sobre las mejores medias de
  /// [durations]. Devuelve `null` si no hay al menos dos duraciones
  /// distintas con datos.
  /// Es un ajuste **robusto**: descarta los puntos que quedan muy por
  /// debajo de la recta y vuelve a ajustar.
  ///
  /// La curva no sabe si un esfuerzo fue máximo. El mejor promedio de
  /// tres minutos de los últimos noventa días puede venir de una subida
  /// a tope o del pedazo más rápido de una salida tranquila, y en el
  /// segundo caso ese punto no dice cuánto puede el ciclista: dice
  /// cuánto hizo ese día. Un punto así tira la recta y el resultado es
  /// una CP inflada con una W′ enana.
  ///
  /// Solo se descarta hacia abajo. Un punto por encima de la recta es un
  /// esfuerzo mejor de lo que el modelo esperaba —evidencia de que el
  /// modelo se queda corto—, y tirar los mejores esfuerzos sería
  /// justamente perder la información que se quiere.
  static CriticalPowerModel? fit(
    MeanMaxCurve curve, {
    List<int> durations = criticalPowerDurations,
    CriticalPowerCriteria criteria = const CriticalPowerCriteria(),
  }) {
    var pts = <(int, double)>[
      for (final d in durations)
        if (curve[d] case final p?) (d, p.value * d),
    ];
    if (pts.length < 2) return null;

    final dropped = <int>[];
    var model = _ols(pts);
    while (model != null && pts.length > criteria.minPoints) {
      final worst = _worstShortfall(model, pts, criteria.maxShortfall);
      if (worst == null) break;
      dropped.add(worst);
      pts = [
        for (final p in pts)
          if (p.$1 != worst) p,
      ];
      model = _ols(pts);
    }
    if (model == null || dropped.isEmpty) return model;
    return model._withDropped(dropped);
  }

  /// La duración que más se queda por debajo de la recta, si alguna se
  /// pasa de [tolerance] (fracción del trabajo predicho).
  static int? _worstShortfall(
    CriticalPowerModel model,
    List<(int, double)> pts,
    double tolerance,
  ) {
    int? worst;
    var deepest = -tolerance;
    for (final (t, _) in pts) {
      final predicted = model.cp.toDouble() * t + model.wPrime.toDouble();
      final residual = model.residuals[t];
      if (residual == null || predicted <= 0) continue;
      final relative = residual / predicted;
      if (relative < deepest) {
        deepest = relative;
        worst = t;
      }
    }
    return worst;
  }

  CriticalPowerModel _withDropped(List<int> dropped) => CriticalPowerModel._(
    cp: cp,
    wPrime: wPrime,
    source: source,
    seCp: seCp,
    seWPrime: seWPrime,
    covariance: covariance,
    rSquared: rSquared,
    standardError: standardError,
    points: points,
    residuals: residuals,
    dropped: List.unmodifiable(dropped),
  );

  /// Ajuste llano (sin descartes) sobre pares (duración en s, potencia
  /// media en W). Es el del anexo de la tesis, que trabaja con cuatro
  /// puntos ya elegidos a mano.
  static CriticalPowerModel? fitPoints(Map<int, double> meanPowerByDuration) {
    final pts = <(int, double)>[
      for (final e in meanPowerByDuration.entries) (e.key, e.value * e.key),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    if (pts.length < 2) return null;
    return _ols(pts);
  }

  static CriticalPowerModel? _ols(List<(int, double)> pts) {
    final n = pts.length;
    final tMean = pts.fold(0.0, (s, p) => s + p.$1) / n;
    final wMean = pts.fold(0.0, (s, p) => s + p.$2) / n;
    var sxx = 0.0, sxy = 0.0, syy = 0.0;
    for (final (t, w) in pts) {
      sxx += (t - tMean) * (t - tMean);
      sxy += (t - tMean) * (w - wMean);
      syy += (w - wMean) * (w - wMean);
    }
    if (sxx == 0) return null;
    final cp = sxy / sxx;
    final wPrime = wMean - cp * tMean;

    var ssRes = 0.0;
    final residuals = <int, double>{};
    for (final (t, w) in pts) {
      final r = w - (cp * t + wPrime);
      residuals[t] = r;
      ssRes += r * r;
    }
    final dof = n - 2;
    final s = dof > 0 ? math.sqrt(ssRes / dof) : 0.0;
    final variance = s * s;
    return CriticalPowerModel._(
      cp: Watts(cp),
      wPrime: Joules(wPrime),
      source: CriticalPowerSource.fitted,
      seCp: s / math.sqrt(sxx),
      seWPrime: s * math.sqrt(1 / n + tMean * tMean / sxx),
      covariance: -tMean * variance / sxx,
      rSquared: syy == 0 ? null : 1 - ssRes / syy,
      standardError: s,
      points: n,
      residuals: Map.unmodifiable(residuals),
    );
  }

  /// Modelo de respaldo cuando no hay regresión válida:
  /// `CP ≈ 0,95 · potencia de 20 min` y un W′ poblacional.
  factory CriticalPowerModel.estimated({
    required Watts twentyMinutePower,
    Joules wPrime = const Joules(20000),
    double relativeSeCp = 0.05,
    double relativeSeWPrime = 0.30,
  }) {
    final cp = 0.95 * twentyMinutePower;
    return CriticalPowerModel._(
      cp: Watts(cp),
      wPrime: wPrime,
      source: CriticalPowerSource.estimated,
      seCp: relativeSeCp * cp,
      seWPrime: relativeSeWPrime * wPrime,
      covariance: 0,
      rSquared: null,
      standardError: null,
      points: 0,
      residuals: const {},
    );
  }

  /// Modelo con valores conocidos, con la incertidumbre que el usuario
  /// declare (por defecto, la de un test de laboratorio: ±2 % y ±10 %).
  factory CriticalPowerModel.manual({
    required Watts cp,
    required Joules wPrime,
    double? seCp,
    double? seWPrime,
    double covariance = 0,
  }) {
    assert(cp > 0 && wPrime > 0);
    return CriticalPowerModel._(
      cp: cp,
      wPrime: wPrime,
      source: CriticalPowerSource.manual,
      seCp: seCp ?? 0.02 * cp,
      seWPrime: seWPrime ?? 0.10 * wPrime,
      covariance: covariance,
      rSquared: null,
      standardError: null,
      points: 0,
      residuals: const {},
    );
  }

  /// Por qué el ajuste no pasa [criteria]; lista vacía si pasa. Un modelo
  /// estimado nunca pasa; uno manual siempre (lo decidió el usuario).
  List<String> rejectionReasons([
    CriticalPowerCriteria criteria = const CriticalPowerCriteria(),
  ]) {
    if (source == CriticalPowerSource.estimated) return ['modelo estimado'];
    if (source == CriticalPowerSource.manual) return const [];
    final reasons = <String>[];
    if (points < criteria.minPoints) {
      reasons.add('solo $points esfuerzos (mínimo ${criteria.minPoints})');
    }
    final durations = residuals.keys;
    if (durations.isNotEmpty) {
      final range = durations.reduce(math.max) - durations.reduce(math.min);
      if (range < criteria.minRangeSeconds) {
        reasons.add('rango de $range s (mínimo ${criteria.minRangeSeconds})');
      }
    }
    final r2 = rSquared;
    if (r2 == null || r2 < criteria.minRSquared) {
      reasons.add('R² ${r2?.toStringAsFixed(4)} bajo');
    }
    if (cp <= 0 || wPrime <= 0) reasons.add('parámetros no físicos');
    if (cp > 0 && relativeSeCp > criteria.maxRelativeSeCp) {
      reasons.add('CP con error relativo alto');
    }
    if (wPrime > 0 && relativeSeWPrime > criteria.maxRelativeSeWPrime) {
      reasons.add('W′ con error relativo alto');
    }
    return reasons;
  }

  bool isAccepted([
    CriticalPowerCriteria criteria = const CriticalPowerCriteria(),
  ]) => rejectionReasons(criteria).isEmpty;

  /// Intervalo de confianza del 95 % de CP y de W′ (t de Student con
  /// `n − 2` grados de libertad); `null` para modelos estimados o con
  /// menos de 3 puntos.
  ({({double lo, double hi}) cp, ({double lo, double hi}) wPrime})?
  confidence95() {
    final dof = points - 2;
    if (source != CriticalPowerSource.fitted || dof < 1) return null;
    final t = studentT975(dof);
    return (
      cp: (lo: cp - t * seCp, hi: cp + t * seCp),
      wPrime: (lo: wPrime - t * seWPrime, hi: wPrime + t * seWPrime),
    );
  }

  /// Modelo alternativo `P = CP + W′/t` (regresión de potencia contra
  /// 1/t), solo para comparar: los esfuerzos cortos dominan su pendiente.
  static ({Watts cp, Joules wPrime, double rSquared})? fitInverseTime(
    Map<int, double> meanPowerByDuration,
  ) {
    final pts = [
      for (final e in meanPowerByDuration.entries) (1 / e.key, e.value),
    ];
    final n = pts.length;
    if (n < 2) return null;
    final xm = pts.fold(0.0, (s, p) => s + p.$1) / n;
    final ym = pts.fold(0.0, (s, p) => s + p.$2) / n;
    var sxx = 0.0, sxy = 0.0, syy = 0.0;
    for (final (x, y) in pts) {
      sxx += (x - xm) * (x - xm);
      sxy += (x - xm) * (y - ym);
      syy += (y - ym) * (y - ym);
    }
    if (sxx == 0 || syy == 0) return null;
    final slope = sxy / sxx;
    final intercept = ym - slope * xm;
    var ssRes = 0.0;
    for (final (x, y) in pts) {
      final r = y - (intercept + slope * x);
      ssRes += r * r;
    }
    return (
      cp: Watts(intercept),
      wPrime: Joules(slope),
      rSquared: 1 - ssRes / syy,
    );
  }

  @override
  String toString() =>
      'CriticalPowerModel(CP ${cp.toStringAsFixed(1)} W ± '
      '${seCp.toStringAsFixed(1)}, W′ ${wPrime.toStringAsFixed(0)} J ± '
      '${seWPrime.toStringAsFixed(0)}, ${source.name})';
}

/// Percentil 97,5 de la t de Student (intervalos del 95 %).
double studentT975(int degreesOfFreedom) {
  assert(degreesOfFreedom >= 1);
  const table = [
    12.706,
    4.303,
    3.182,
    2.776,
    2.571,
    2.447,
    2.365,
    2.306,
    2.262,
    2.228,
    2.201,
    2.179,
    2.160,
    2.145,
    2.131,
    2.120,
    2.110,
    2.101,
    2.093,
    2.086,
    2.080,
    2.074,
    2.069,
    2.064,
    2.060,
    2.056,
    2.052,
    2.048,
    2.045,
    2.042,
  ];
  if (degreesOfFreedom <= table.length) return table[degreesOfFreedom - 1];
  return 1.960;
}
