import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/domain/activity_json_helpers.dart';
import '../../domain/calendar_day_info.dart';
import '../profile_providers.dart';
import 'day_detail_sheet.dart';

/// Calendario de actividad interactivo: cada celda muestra el número
/// del día, se tiñe con el color del tipo de actividad dominante ese
/// día (mayor distancia acumulada), y si el día forma parte de la
/// racha activa se le superpone un ícono de fuego. Tocar un día con
/// actividad abre su detalle.
class ActivityCalendar extends ConsumerWidget {
  const ActivityCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayInfoAsync = ref.watch(calendarDayInfoProvider);
    final streakDaysAsync = ref.watch(activeStreakDaysProvider);
    final mode = ref.watch(calendarViewModeProvider);
    final referenceDate = ref.watch(calendarReferenceDateProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mode == CalendarViewMode.month
                      ? _monthLabel(referenceDate)
                      : _weekLabel(referenceDate),
                  style: const TextStyle(
                    color: AppColors.textPrimaryOnPanel,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              _NavButton(
                icon: Icons.chevron_left,
                onTap: () => _shift(ref, mode, referenceDate, -1),
              ),
              _NavButton(
                icon: Icons.chevron_right,
                onTap: () => _shift(ref, mode, referenceDate, 1),
              ),
              const SizedBox(width: 4),
              _ModeToggle(mode: mode),
            ],
          ),
          const SizedBox(height: 14),
          dayInfoAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (_, __) => const SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  'No se pudo cargar el calendario',
                  style: TextStyle(color: AppColors.textSecondaryOnPanel),
                ),
              ),
            ),
            data: (dayInfo) {
              final streakDays = streakDaysAsync.valueOrNull ?? const {};
              return mode == CalendarViewMode.month
                  ? _MonthGrid(
                      referenceDate: referenceDate,
                      dayInfo: dayInfo,
                      streakDays: streakDays,
                    )
                  : _WeekRow(
                      referenceDate: referenceDate,
                      dayInfo: dayInfo,
                      streakDays: streakDays,
                    );
            },
          ),
          const SizedBox(height: 10),
          const _CalendarLegend(),
        ],
      ),
    );
  }

  void _shift(
    WidgetRef ref,
    CalendarViewMode mode,
    DateTime reference,
    int delta,
  ) {
    final next = mode == CalendarViewMode.month
        ? DateTime(reference.year, reference.month + delta, 1)
        : reference.add(Duration(days: 7 * delta));
    ref.read(calendarReferenceDateProvider.notifier).state = next;
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio',
      'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _weekLabel(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }
}

class _ModeToggle extends ConsumerWidget {
  final CalendarViewMode mode;
  const _ModeToggle({required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final next = mode == CalendarViewMode.month
            ? CalendarViewMode.week
            : CalendarViewMode.month;
        ref.read(calendarViewModeProvider.notifier).state = next;
        ref.read(calendarReferenceDateProvider.notifier).state =
            DateTime.now();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          mode == CalendarViewMode.month ? 'Mes' : 'Semana',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: AppColors.textSecondaryOnPanel, size: 20),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime referenceDate;
  final Map<DateTime, CalendarDayInfo> dayInfo;
  final Set<DateTime> streakDays;

  const _MonthGrid({
    required this.referenceDate,
    required this.dayInfo,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(referenceDate.year, referenceDate.month, 1);
    final daysInMonth =
        DateTime(referenceDate.year, referenceDate.month + 1, 0).day;
    // Lunes = 1 ... Domingo = 7 -- desplazamos para que la cuadrícula
    // empiece en lunes, como en la mayoría de calendarios en español.
    final leadingEmpty = firstOfMonth.weekday - 1;

    return Column(
      children: [
        Row(
          children: const ['L', 'M', 'X', 'J', 'V', 'S', 'D']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leadingEmpty + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            if (index < leadingEmpty) return const SizedBox.shrink();
            final day = index - leadingEmpty + 1;
            final date =
                DateTime(referenceDate.year, referenceDate.month, day);
            return _DayCell(
              date: date,
              info: dayInfo[date],
              isToday: _isSameDay(date, DateTime.now()),
              isStreakDay: streakDays.contains(date),
            );
          },
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _WeekRow extends StatelessWidget {
  final DateTime referenceDate;
  final Map<DateTime, CalendarDayInfo> dayInfo;
  final Set<DateTime> streakDays;

  const _WeekRow({
    required this.referenceDate,
    required this.dayInfo,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final start =
        referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Row(
      children: List.generate(7, (i) {
        final date = DateTime(start.year, start.month, start.day + i);
        return Expanded(
          child: Column(
            children: [
              Text(
                labels[i],
                style: const TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 6),
              _DayCell(
                date: date,
                info: dayInfo[date],
                isToday: _isSameDay(date, DateTime.now()),
                isStreakDay: streakDays.contains(date),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: const TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Celda de día: número, color del tipo de actividad dominante (con
/// opacidad según cuántas actividades hubo ese día) y, si corresponde,
/// el ícono de fuego de racha activa encima. Interactiva: si hay
/// actividad ese día, tocarla abre el detalle.
class _DayCell extends StatelessWidget {
  final DateTime date;
  final CalendarDayInfo? info;
  final bool isToday;
  final bool isStreakDay;

  const _DayCell({
    required this.date,
    required this.info,
    required this.isToday,
    required this.isStreakDay,
  });

  @override
  Widget build(BuildContext context) {
    final count = info?.activityCount ?? 0;
    final hasActivity = count > 0;
    final typeColor = info?.dominantActivityType != null
        ? ActivityTypeUi.fromValue(info!.dominantActivityType!).color
        : null;

    final alpha = switch (count) {
      0 => 0.0,
      1 => 0.35,
      2 => 0.6,
      _ => 0.95,
    };

    return GestureDetector(
      onTap: hasActivity ? () => showDayDetailSheet(context, date) : null,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: hasActivity
                ? typeColor!.withValues(alpha: alpha)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6),
            border: isToday
                ? Border.all(color: AppColors.textPrimaryOnPanel, width: 1.4)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  color: hasActivity
                      ? Colors.white
                      : AppColors.textSecondaryOnPanel.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight:
                      hasActivity ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isStreakDay)
                const Positioned(
                  right: 1,
                  top: 1,
                  child: Icon(
                    Icons.local_fire_department,
                    size: 10,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black45, blurRadius: 2),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.local_fire_department,
          size: 12,
          color: AppColors.primary,
        ),
        const SizedBox(width: 4),
        const Text(
          'Racha activa',
          style:
              TextStyle(color: AppColors.textSecondaryOnPanel, fontSize: 10.5),
        ),
        const SizedBox(width: 14),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'Color = tipo de actividad',
          style:
              TextStyle(color: AppColors.textSecondaryOnPanel, fontSize: 10.5),
        ),
      ],
    );
  }
}
