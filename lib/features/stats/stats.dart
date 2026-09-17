/// Estadísticas del historial: totales por periodo, tendencia, récords, rachas
/// y calendario.
///
/// API pública de la feature: lo único que otros módulos pueden
/// importar. Todo lo que no se exporta acá es detalle interno.
library;

export 'application/stats_providers.dart';
export 'domain/calendar_day_info.dart';
export 'domain/personal_records.dart';
export 'domain/profile_stats.dart';
export 'presentation/widgets/activity_type_breakdown_bar.dart';
export 'presentation/widgets/period_selector.dart';
export 'presentation/widgets/stats_trend_chart.dart';
export 'presentation/widgets/streak_badge.dart';
