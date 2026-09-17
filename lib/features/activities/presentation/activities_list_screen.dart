import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:core_database/core_database.dart';
import 'package:core_ui/core_ui.dart';
import '../../profile/profile.dart';
import '../domain/activity_records.dart';
import '../application/activities_providers.dart';
import 'activity_detail_screen.dart';
import 'widgets/activity_record_badge.dart';
import 'widgets/pressable_scale.dart';
import 'widgets/route_hero_background.dart';

/// Pantalla de actividades -- pensada para ser el "home" de la app, al
/// estilo de Strava/Komoot: un saludo personal, el pulso de la semana en
/// una franja compacta y, debajo, el historial de recorridos en tarjetas
/// grandes con foto/mapa.
///
/// Rediseño (rama `feature/design-system`): se abandona el `AppBar`
/// "Tus actividades" por un encabezado propio (`Hola, <nombre>` + "Tu
/// trayectoria"), se añade el banner semanal y las cifras que son récord
/// personal se pintan en dorado ([CcColors.gold]) para que el logro
/// salte a la vista. El botón flotante lleva al Mapa, que es donde
/// arranca un recorrido.
class ActivitiesListScreen extends ConsumerWidget {
  const ActivitiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesListProvider);
    final firstName = ref
        .watch(profileProvider)
        .valueOrNull
        ?.name
        .trim()
        .split(RegExp(r'\s+'))
        .first;

    return Scaffold(
      backgroundColor: CcColors.bg,
      body: activitiesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CcColors.orange),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No se pudieron cargar tus actividades:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CcColors.inkDim),
            ),
          ),
        ),
        data: (activities) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(firstName: firstName),
                    const _WeekBanner(),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            if (activities.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
                sliver: SliverList.separated(
                  itemCount: activities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    final records = computeActivityRecords(
                      activity: activity,
                      allActivities: activities,
                    ).records;
                    return _ActivityCard(activity: activity, records: records);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? firstName;

  const _Header({this.firstName});

  @override
  Widget build(BuildContext context) {
    final name = firstName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name == null || name.isEmpty)
            const Text(
              '¡Hola! 👋',
              style: TextStyle(
                color: CcColors.inkDim,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: CcColors.inkDim,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(text: 'Hola, '),
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                      color: CcColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' 👋'),
                ],
              ),
            ),
          const SizedBox(height: 3),
          Text(
            'Tu trayectoria',
            style: CcType.displayStyle(size: 28, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Franja compacta con el resumen de la semana: cifra de distancia,
/// desnivel acumulado, salidas y tiempo, más un mini-gráfico de las
/// últimas 6 semanas. Deliberadamente baja de altura -- el protagonista
/// de la pantalla son las tarjetas de abajo, no este panel.
class _WeekBanner extends ConsumerWidget {
  const _WeekBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(weeklySummaryProvider).valueOrNull;
    if (summary == null || summary.isEmpty) return const SizedBox.shrink();

    final hours = summary.movingTime.inHours;
    final minutes = summary.movingTime.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final rideWord = summary.rideCount == 1 ? 'salida' : 'salidas';
    final km = summary.distanceKm;
    final kmText = km >= 100 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CcColors.surfaceHi, CcColors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CcColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'ESTA SEMANA',
                style: CcType.label(size: 9.5, color: CcColors.inkFaint),
              ),
              const Spacer(),
              Text(
                '${summary.rideCount} $rideWord · $hours:$minutes h',
                style: const TextStyle(
                  color: CcColors.inkDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        kmText,
                        style: CcType.displayStyle(
                          size: 25,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const Text(' km', style: _bannerUnitStyle),
                      const Text(
                        '   ·   ',
                        style: TextStyle(
                          color: CcColors.inkFaint,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        formatThousands(summary.elevationGainMeters.round()),
                        style: CcType.displayStyle(
                          size: 25,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const Text(' m D+', style: _bannerUnitStyle),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _WeekBars(values: summary.last6WeeksKm),
            ],
          ),
        ],
      ),
    );
  }
}

const _bannerUnitStyle = TextStyle(
  color: CcColors.inkDim,
  fontSize: 13,
  fontWeight: FontWeight.w600,
);

/// Mini-gráfico de barras de las últimas 6 semanas de distancia. La
/// última barra (semana en curso) va en naranja.
class _WeekBars extends StatelessWidget {
  final List<double> values;

  const _WeekBars({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxKm = values.fold<double>(0, (a, b) => b > a ? b : a);
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Container(
              width: 6,
              height: maxKm == 0
                  ? 4
                  : (4 + 24 * (values[i] / maxKm)).clamp(4, 28).toDouble(),
              decoration: BoxDecoration(
                color: i == values.length - 1 ? CcColors.orange : CcColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta grande de actividad -- carrusel (mapa de la ruta + fotos)
/// arriba, título y stats destacados abajo. Es `ConsumerStatefulWidget`
/// porque guarda en qué página del carrusel está el usuario (para los
/// puntos indicadores) y necesita `ref` para eliminar la actividad.
class _ActivityCard extends ConsumerStatefulWidget {
  final Activity activity;
  final Set<RecordType> records;

  const _ActivityCard({required this.activity, required this.records});

  @override
  ConsumerState<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends ConsumerState<_ActivityCard> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final records = widget.records;
    final typeUi = ActivityTypeUi.fromValue(activity.activityType);
    final photos = activity.photoPaths;
    final dateLabel = DateFormat(
      "EEE d MMM · HH:mm",
      'es',
    ).format(activity.startedAt);
    // Página 0 = mapa de la ruta; el resto, fotos. Siempre hay algo que
    // mostrar aunque la actividad no tenga fotos.
    final pageCount = 1 + photos.length;

    return PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(activityId: activity.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: CcColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: CcColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _mediaHeader(activity, typeUi, dateLabel, photos, pageCount),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcType.displayStyle(
                      size: 17.5,
                      weight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _CardStat(
                        label: 'Distancia',
                        value: formatDistanceKm(activity.distanceMeters),
                        unit: 'km',
                        big: true,
                        gold: records.contains(RecordType.distance),
                      ),
                      const _CardStatDivider(),
                      _CardStat(
                        label: 'Tiempo',
                        value: formatDuration(
                          Duration(seconds: activity.durationSeconds),
                        ),
                        gold: records.contains(RecordType.duration),
                      ),
                      const _CardStatDivider(),
                      _CardStat(
                        label: 'Desnivel+',
                        value: activity.elevationGainMeters.toStringAsFixed(0),
                        unit: 'm',
                        gold: records.contains(RecordType.elevationGain),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaHeader(
    Activity activity,
    ActivityTypeUi typeUi,
    String dateLabel,
    List<String> photos,
    int pageCount,
  ) {
    return SizedBox(
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: pageCount,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) {
              if (index == 0) {
                return RouteHeroBackground(
                  points: activity.routePoints,
                  accentColor: typeUi.color,
                );
              }
              return Image.file(
                File(photos[index - 1]),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: CcColors.surfaceInset,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: CcColors.inkFaint,
                  ),
                ),
              );
            },
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 62,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xE60E1116)],
                ),
              ),
            ),
          ),
          Positioned(left: 12, top: 12, child: _TypeChip(typeUi: typeUi)),
          if (widget.records.isNotEmpty)
            const Positioned(left: 12, top: 44, child: ActivityRecordBadge()),
          Positioned(
            left: 14,
            bottom: 9,
            child: Text(
              dateLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (pageCount > 1)
            Positioned(
              right: 12,
              bottom: 11,
              child: _PageDots(count: pageCount, current: _page),
            ),
        ],
      ),
    );
  }
}

/// Un dato de la tarjeta -- etiqueta en versalitas + cifra. `gold` la
/// pinta en dorado cuando esa métrica es récord personal; `big` la usa
/// para la distancia (el dato ancla de cada tarjeta).
class _CardStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool big;
  final bool gold;

  const _CardStat({
    required this.label,
    required this.value,
    this.unit = '',
    this.big = false,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: CcType.label(size: 9, color: CcColors.inkFaint),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: CcType.displayStyle(
                    size: big ? 25 : 17,
                    weight: FontWeight.w700,
                    color: gold ? CcColors.gold : CcColors.ink,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: CcColors.inkDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardStatDivider extends StatelessWidget {
  const _CardStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: CcColors.line,
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ActivityTypeUi typeUi;

  const _TypeChip({required this.typeUi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(typeUi.icon, size: 13, color: typeUi.color),
          const SizedBox(width: 5),
          Text(
            typeUi.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: active ? 14 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.route_outlined,
              size: 56,
              color: CcColors.inkFaint,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes actividades',
              textAlign: TextAlign.center,
              style: CcType.displayStyle(size: 18, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Graba tu primer recorrido desde el mapa y aparecerá aquí. '
              'Toca el botón naranja para empezar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CcColors.inkDim,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
