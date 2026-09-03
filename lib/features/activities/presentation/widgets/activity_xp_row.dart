import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cc_colors.dart';
import '../../../../core/theme/cc_type.dart';
import '../../../profile/domain/xp_calculator.dart';
import '../../../profile/presentation/profile_providers.dart';

/// Fila de XP en el detalle de la actividad: cuánta experiencia aportó
/// esta salida + un botón de info que explica cómo se gana y cómo se
/// calcula. El XP no se guarda: se recalcula siempre desde las
/// actividades, así que borrar o editar una lo reajusta solo.
class ActivityXpRow extends ConsumerWidget {
  final int activityId;

  const ActivityXpRow({super.key, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(activityXpProvider).valueOrNull?[activityId];
    if (breakdown == null) return const SizedBox.shrink();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: CcColors.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CcColors.gold.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, size: 13, color: CcColors.gold),
              const SizedBox(width: 4),
              Text(
                '+${breakdown.totalXp} XP',
                style: const TextStyle(
                  color: CcColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _InfoButton(onTap: () => _showXpInfoSheet(context, breakdown)),
      ],
    );
  }
}

class _InfoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _InfoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.info_outline, size: 17, color: CcColors.inkDim),
      ),
    );
  }
}

Future<void> _showXpInfoSheet(BuildContext context, ActivityXpBreakdown b) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: CcColors.surfaceHi,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _XpInfoSheet(breakdown: b),
  );
}

/// Formatea una tarifa de XP como texto en español: 12.0 -> "12",
/// 0.4 -> "0,4".
String _n(double rate) {
  final s = rate == rate.roundToDouble()
      ? rate.toStringAsFixed(0)
      : rate.toString();
  return s.replaceAll('.', ',');
}

class _XpInfoSheet extends StatelessWidget {
  final ActivityXpBreakdown breakdown;

  const _XpInfoSheet({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final b = breakdown;
    final rows = <(String, int)>[
      ('Distancia', b.distanceXp),
      ('Duración', b.durationXp),
      ('Desnivel', b.elevationXp),
      if (b.powerXp > 0) ('Potencia media', b.powerXp),
      if (b.streakXp > 0) ('Bono de racha', b.streakXp),
      if (b.recordXp > 0)
        ('Récords batidos (${b.recordDimensions.length})', b.recordXp),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: CcColors.inkFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.bolt, color: CcColors.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  'XP de esta actividad',
                  style: CcType.displayStyle(size: 18, weight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'La experiencia sube tu nivel. Se reparte así:',
              style: TextStyle(color: CcColors.inkDim, fontSize: 13),
            ),
            const SizedBox(height: 16),

            for (final (label, xp) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: CcColors.ink,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Text(
                      '+$xp',
                      style: CcType.displayStyle(
                        size: 13.5,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(color: CcColors.line, height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: CcType.displayStyle(
                      size: 15,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '+${b.totalXp} XP',
                  style: CcType.displayStyle(
                    size: 16,
                    weight: FontWeight.w800,
                    color: CcColors.gold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),
            Text(
              'CÓMO SE CALCULA',
              style: CcType.label(
                size: 11,
                color: CcColors.inkFaint,
              ).copyWith(letterSpacing: 1.4),
            ),
            const SizedBox(height: 10),
            _Rule(
              text: '${_n(XpCalculator.xpPerKm)} XP por kilómetro recorrido.',
            ),
            _Rule(
              text:
                  '${_n(XpCalculator.xpPerMinute)} XP por minuto en movimiento.',
            ),
            _Rule(
              text:
                  '${_n(XpCalculator.xpPerTenMetersElevation)} XP por cada 10 m '
                  'de desnivel positivo.',
            ),
            _Rule(
              text:
                  '${_n(XpCalculator.xpPerWattAvgPower)} XP por vatio de '
                  'potencia media, solo si llevabas potenciómetro (premia la '
                  'intensidad, no solo el volumen).',
            ),
            _Rule(
              text:
                  '${XpCalculator.xpPerStreakDay} XP por cada día de racha que '
                  'llevabas ese día, hasta ${XpCalculator.maxStreakDaysCounted} '
                  'días (${XpCalculator.xpPerStreakDay * XpCalculator.maxStreakDaysCounted} '
                  'XP máximo).',
            ),
            _Rule(
              text:
                  '${XpCalculator.xpPerRecordDimension} XP por cada marca '
                  'personal que batiste con esta salida (distancia, duración, '
                  'desnivel, velocidad o potencia).',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CcColors.surfaceInset,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'La XP no se guarda: se recalcula siempre desde tus '
                'actividades. Si editas o borras una salida, tu nivel se '
                'ajusta solo.',
                style: TextStyle(
                  color: CcColors.inkDim,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final String text;

  const _Rule({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 9),
            child: SizedBox(
              width: 4,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: CcColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: CcColors.inkDim,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
