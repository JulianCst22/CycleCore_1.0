import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../core/ui/ui.dart';
import '../../profile/profile.dart';
import '../../segments/segments.dart';
import '../application/activities_providers.dart';
import '../domain/segment_effort_analysis.dart';
import 'activity_charts.dart';
import 'activity_detail_screen.dart';

/// Análisis de un esfuerzo en un segmento, como el de Strava: el tramo en
/// el mapa, el tiempo y el puesto entre tus intentos, el gráfico punto a
/// punto (altimetría, pulso, velocidad, potencia, cadencia) con las curvas
/// de tu mejor marca superpuestas y la ventaja en segundos a lo largo del
/// segmento, y todas las cifras del esfuerzo.
///
/// Se abre desde "Segmentos en esta ruta" de una actividad y desde el
/// historial del segmento (ver `openSegmentEffortProvider`).
class SegmentEffortScreen extends ConsumerWidget {
  final int segmentId;
  final int effortId;

  /// Se abrió desde la ficha del segmento: el atajo de abajo lleva a la
  /// salida; si no, a la ficha del segmento.
  final bool fromSegment;

  const SegmentEffortScreen({
    super.key,
    required this.segmentId,
    required this.effortId,
    this.fromSegment = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(segmentByIdProvider(segmentId)).valueOrNull;
    final effortsAsync = ref.watch(segmentEffortsProvider(segmentId));
    final efforts = effortsAsync.valueOrNull;

    Widget message(String text) => Scaffold(
      appBar: AppBar(
        backgroundColor: CcColors.bg,
        iconTheme: const IconThemeData(color: CcColors.ink),
      ),
      body: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: CcColors.inkDim),
        ),
      ),
    );

    if (efforts == null || segment == null) {
      if (effortsAsync.isLoading) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }
      return message('Este segmento ya no existe.');
    }
    final index = efforts.indexWhere((e) => e.id == effortId);
    if (index < 0) return message('Este tiempo ya no existe.');
    final effort = efforts[index];

    // Contra quién se compara: la mejor marca; si este ES la mejor marca,
    // el segundo mejor tiempo (comparar contra sí mismo no dice nada).
    final isBest = index == 0;
    final reference = isBest
        ? (efforts.length > 1 ? efforts[1] : null)
        : efforts.first;

    final activity = ref.watch(activityByIdProvider(effort.activityId));
    final referenceActivity = reference == null
        ? null
        : ref.watch(activityByIdProvider(reference.activityId));
    final weightKg = ref.watch(profileProvider).valueOrNull?.weightKg;

    if (activity.isLoading || (referenceActivity?.isLoading ?? false)) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final ride = activity.valueOrNull;
    final points = ride == null
        ? const <RoutePointSnapshot>[]
        : effortPoints(
            points: ride.routePoints,
            activityStartedAt: ride.startedAt,
            completedAt: effort.completedAt,
            durationSeconds: effort.durationSeconds,
          );
    final referenceRide = referenceActivity?.valueOrNull;
    final referencePoints = reference == null || referenceRide == null
        ? const <RoutePointSnapshot>[]
        : effortPoints(
            points: referenceRide.routePoints,
            activityStartedAt: referenceRide.startedAt,
            completedAt: reference.completedAt,
            durationSeconds: reference.durationSeconds,
          );

    return Scaffold(
      body: _EffortBody(
        segment: segment,
        effort: effort,
        rank: index + 1,
        total: efforts.length,
        best: efforts.first,
        reference: reference,
        referenceIsBest: !isBest,
        ride: ride,
        points: points,
        referencePoints: referencePoints,
        weightKg: weightKg,
        fromSegment: fromSegment,
      ),
    );
  }
}

class _EffortBody extends StatelessWidget {
  final Segment segment;
  final SegmentEffort effort;
  final int rank;
  final int total;
  final SegmentEffort best;
  final SegmentEffort? reference;
  final bool referenceIsBest;
  final Activity? ride;
  final List<RoutePointSnapshot> points;
  final List<RoutePointSnapshot> referencePoints;
  final double? weightKg;
  final bool fromSegment;

  const _EffortBody({
    required this.segment,
    required this.effort,
    required this.rank,
    required this.total,
    required this.best,
    required this.reference,
    required this.referenceIsBest,
    required this.ride,
    required this.points,
    required this.referencePoints,
    required this.weightKg,
    required this.fromSegment,
  });

  @override
  Widget build(BuildContext context) {
    final hasPoints = points.length > 1;
    final figures = hasPoints ? effortFiguresOf(points) : null;
    final isBest = effort.id == best.id;

    // Los promedios de pulso y potencia del esfuerzo se midieron con cada
    // lectura del sensor; los de los puntos, solo como respaldo.
    final avgHeartRate = effort.avgHeartRate ?? figures?.avgHeartRate;
    final avgPower = effort.avgPower ?? figures?.avgPower;
    final weight = weightKg;
    final wattsPerKg = avgPower != null && weight != null && weight > 0
        ? avgPower / weight
        : null;
    final vam = vamOf(segment.elevationGainMeters, effort.durationSeconds);

    final dateLabel = DateFormat(
      "EEE d MMM y · HH:mm",
      'es',
    ).format(effort.completedAt);

    final comparisonPhrase = referenceIsBest
        ? 'tu mejor marca'
        : 'tu 2.º mejor tiempo';
    final reference = this.reference;
    final delta = reference == null
        ? null
        : effort.durationSeconds - reference.durationSeconds;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: CcColors.bg,
          pinned: true,
          expandedHeight: hasPoints ? 220 : 0,
          iconTheme: const IconThemeData(color: CcColors.ink),
          title: Text(
            segment.name,
            style: const TextStyle(color: CcColors.ink),
          ),
          flexibleSpace: hasPoints
              ? FlexibleSpaceBar(background: ActivityRouteMap(points: points))
              : null,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                ride == null ? dateLabel : '$dateLabel · ${ride!.title}',
                style: const TextStyle(color: CcColors.inkDim, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              _RankLine(
                rank: rank,
                total: total,
                isBest: isBest,
                delta: delta,
                comparisonPhrase: comparisonPhrase,
              ),
              const SizedBox(height: 16),
              ActivitySummaryHero(
                label: 'Tiempo',
                value: formatElapsedShort(
                  Duration(seconds: effort.durationSeconds),
                ),
                unit: '',
                gold: isBest,
              ),
              ActivityDividedRow(
                cells: [
                  ActivityStatCell(
                    label: 'Distancia',
                    value: formatDistanceKm(segment.distanceMeters),
                    unit: 'km',
                  ),
                  ActivityStatCell(
                    label: 'Promedio',
                    value: formatSpeedKmh(effort.avgSpeedKmh),
                    unit: 'km/h',
                  ),
                  ActivityStatCell(
                    label: 'Desnivel+',
                    value: segment.elevationGainMeters.toStringAsFixed(0),
                    unit: 'm',
                  ),
                ],
              ),
              if (hasPoints) ...[
                const SizedBox(height: 26),
                ActivityChartsCard(
                  points: points,
                  comparison: referencePoints.length > 1
                      ? ChartComparison(
                          points: referencePoints,
                          label: referenceIsBest
                              ? 'mejor marca'
                              : '2.º mejor tiempo',
                          phrase: comparisonPhrase,
                        )
                      : null,
                ),
              ] else ...[
                const SizedBox(height: 22),
                Text(
                  ride == null
                      ? 'La salida de este tiempo ya no está guardada: '
                            'solo quedan sus cifras.'
                      : 'Esta salida no guardó la hora de cada punto, así '
                            'que no se puede recortar el tramo del segmento.',
                  style: const TextStyle(
                    color: CcColors.inkDim,
                    fontSize: 12.5,
                  ),
                ),
              ],
              const SizedBox(height: 26),
              const ActivitySectionLabel('Todos los datos'),
              const SizedBox(height: 2),
              if (segment.elevationGainMeters > 0)
                ActivityDataRow(
                  icon: Icons.landscape_outlined,
                  iconColor: AppColors.accentElevation,
                  label: 'VAM',
                  unit: 'm/h',
                  values: [
                    (pair: null, value: vam.round().toString(), gold: false),
                  ],
                ),
              ActivityDataRow(
                icon: Icons.trending_up,
                iconColor: AppColors.accentSlope,
                label: 'Pendiente',
                unit: '%',
                values: [
                  (
                    pair: 'prom',
                    value: segment.avgSlopePercent.toStringAsFixed(1),
                    gold: false,
                  ),
                  (
                    pair: 'máx',
                    value: segment.maxSlopePercent.toStringAsFixed(1),
                    gold: false,
                  ),
                ],
              ),
              if (avgHeartRate != null || figures?.maxHeartRate != null)
                ActivityDataRow(
                  icon: Icons.favorite,
                  iconColor: AppColors.accentHeartRate,
                  label: 'Ritmo cardíaco',
                  unit: 'bpm',
                  values: [
                    (
                      pair: 'prom',
                      value: avgHeartRate?.toString() ?? '--',
                      gold: false,
                    ),
                    (
                      pair: 'máx',
                      value: figures?.maxHeartRate?.toString() ?? '--',
                      gold: false,
                    ),
                  ],
                ),
              if (avgPower != null || figures?.maxPower != null)
                ActivityDataRow(
                  icon: Icons.electric_bolt,
                  iconColor: AppColors.accentPower,
                  label: 'Potencia',
                  unit: 'W',
                  values: [
                    (
                      pair: 'prom',
                      value: avgPower?.toString() ?? '--',
                      gold: false,
                    ),
                    (
                      pair: 'máx',
                      value: figures?.maxPower?.toString() ?? '--',
                      gold: false,
                    ),
                  ],
                ),
              if (wattsPerKg != null)
                ActivityDataRow(
                  icon: Icons.fitness_center,
                  iconColor: AppColors.accentPower,
                  label: 'Potencia por kilo',
                  unit: 'W/kg',
                  values: [
                    (
                      pair: null,
                      value: wattsPerKg.toStringAsFixed(2),
                      gold: false,
                    ),
                  ],
                ),
              if (figures?.avgCadence != null)
                ActivityDataRow(
                  icon: Icons.autorenew,
                  iconColor: AppColors.accentCadence,
                  label: 'Cadencia',
                  unit: 'rpm',
                  values: [
                    (
                      pair: 'prom',
                      value: figures!.avgCadence.toString(),
                      gold: false,
                    ),
                  ],
                ),
              if (figures != null)
                ActivityDataRow(
                  icon: Icons.speed,
                  iconColor: AppColors.accentSpeed,
                  label: 'Velocidad máx',
                  unit: 'km/h',
                  values: [
                    (
                      pair: null,
                      value: formatSpeedKmh(figures.maxSpeedKmh),
                      gold: false,
                    ),
                  ],
                ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: fromSegment
                      ? (ride == null
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ActivityDetailScreen(
                                    activityId: ride!.id,
                                  ),
                                ),
                              ))
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SegmentDetailScreen(segmentId: segment.id),
                          ),
                        ),
                  icon: Icon(
                    fromSegment ? Icons.route_outlined : Icons.flag_outlined,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    fromSegment ? 'Ver la salida completa' : 'Ver el segmento',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

/// "Mejor marca · 1.º de 7", o "3.º de 7 · +0:35 sobre tu mejor marca".
class _RankLine extends StatelessWidget {
  final int rank;
  final int total;
  final bool isBest;

  /// Segundos de más (positivo) o de menos contra la comparación.
  final int? delta;
  final String comparisonPhrase;

  const _RankLine({
    required this.rank,
    required this.total,
    required this.isBest,
    required this.delta,
    required this.comparisonPhrase,
  });

  @override
  Widget build(BuildContext context) {
    final delta = this.delta;
    final position = '$rank.º de $total';
    final String detail;
    if (isBest) {
      detail = delta == null
          ? 'Tu primer tiempo aquí'
          : '${formatElapsedShort(Duration(seconds: -delta))} menos que '
                '$comparisonPhrase';
    } else {
      detail =
          '+${formatElapsedShort(Duration(seconds: delta ?? 0))} '
          'sobre $comparisonPhrase';
    }
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: (isBest ? CcColors.gold : CcColors.ink).withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isBest ? 'Mejor marca' : position,
            style: TextStyle(
              color: isBest ? CcColors.gold : CcColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isBest && total > 1 ? '$position · $detail' : detail,
            style: const TextStyle(color: CcColors.inkDim, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

/// Implementación del punto de extensión de `segments`
/// (`openSegmentEffortProvider`) para abrir el análisis de un tiempo desde
/// la ficha del segmento. `main.dart` la registra ahí.
void openSegmentEffortAnalysis(BuildContext context, SegmentEffort effort) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SegmentEffortScreen(
        segmentId: effort.segmentId,
        effortId: effort.id,
        fromSegment: true,
      ),
    ),
  );
}
