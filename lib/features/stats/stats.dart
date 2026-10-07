/// Estadísticas del historial: totales por periodo, tendencia, récords,
/// rachas, calendario y curvas de potencia y FC.
///
/// API pública de la feature: lo único que otros módulos pueden
/// importar. Todo lo que no se exporta acá es detalle interno.
library;

export 'application/curves_providers.dart'
    show
        learnedClimbingCadenceProvider,
        BestCurveQuery,
        activityCurvesProvider,
        bestCurveProvider,
        curvesSampleProvider,
        curvesSyncProvider,
        periodBestCurveProvider;
export 'application/stats_providers.dart';
export 'domain/activity_series.dart';
export 'domain/calendar_day_info.dart';
export 'domain/climbing_cadence.dart';
export 'domain/featured_photo.dart';
export 'domain/personal_records.dart';
export 'domain/profile_stats.dart';
export 'domain/ride_curves.dart'
    show CurveKind, CurveOrigin, RideCurves, originOf;
export 'presentation/widgets/activity_type_breakdown_bar.dart';
export 'presentation/widgets/mean_max_curve_chart.dart';
export 'presentation/widgets/period_selector.dart';
export 'presentation/widgets/stats_trend_chart.dart';
export 'presentation/widgets/streak_badge.dart';
