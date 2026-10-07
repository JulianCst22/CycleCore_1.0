import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/ui.dart';
import '../../application/stats_providers.dart';
import '../../domain/profile_stats.dart';

/// Selector de periodo -- semana / mes / año / total -- con flechas
/// para moverse a la semana pasada, al mes pasado y así.
///
/// La fila de abajo dice qué se está mirando («Esta semana», «Semana
/// pasada», «8–14 sep») porque con las flechas ya no basta con la
/// pestaña: sin ese rótulo uno no sabe dónde quedó. Hacia adelante no
/// se puede pasar del periodo que corre, y en «Total» las flechas
/// desaparecen: no hay otro total que ver.
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => PeriodControls(
    period: statsPeriodProvider,
    offset: statsPeriodOffsetProvider,
  );
}

/// El mismo control, pero para el periodo de la pantalla de rendimiento
/// (FTP y curvas), que es independiente del de estadísticas.
class CurvesPeriodSelector extends ConsumerWidget {
  const CurvesPeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => PeriodControls(
    period: curvesPeriodProvider,
    offset: curvesPeriodOffsetProvider,
  );
}

/// Las pestañas y las flechas, sobre el par de providers que se le den.
class PeriodControls extends ConsumerWidget {
  final StateProvider<StatsPeriod> period;
  final StateProvider<int> offset;

  const PeriodControls({
    super.key,
    required this.period,
    required this.offset,
  });

  static const _labels = {
    StatsPeriod.week: 'Semana',
    StatsPeriod.month: 'Mes',
    StatsPeriod.year: 'Año',
    StatsPeriod.all: 'Total',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(period);
    final shift = ref.watch(offset);
    final navigable = selected != StatsPeriod.all;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: StatsPeriod.values.map((value) {
              final isSelected = value == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(period.notifier).state = value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _labels[value]!,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondaryOnPanel,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (navigable) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              _Arrow(
                icon: Icons.chevron_left,
                onTap: () => ref.read(offset.notifier).state = shift - 1,
              ),
              Expanded(
                child: Text(
                  statsPeriodLabel(selected, shift, DateTime.now()),
                  textAlign: TextAlign.center,
                  style: CcType.displayStyle(size: 13.5),
                ),
              ),
              _Arrow(
                icon: Icons.chevron_right,
                // Adelante no hay nada: el periodo que corre es el tope.
                onTap: shift >= 0
                    ? null
                    : () => ref.read(offset.notifier).state = shift + 1,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _Arrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon),
    iconSize: 22,
    visualDensity: VisualDensity.compact,
    color: CcColors.inkDim,
    disabledColor: CcColors.inkFaint.withValues(alpha: 0.4),
    tooltip: onTap == null ? null : 'Cambiar de periodo',
  );
}
