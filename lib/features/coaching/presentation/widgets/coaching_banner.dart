import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/ui.dart';
import '../../application/coaching_controller.dart';
import '../../domain/advice/governor.dart';

/// Banner del coach sobre el mapa: lo mismo que acaba de decir la voz,
/// pero para leerlo de un vistazo.
///
/// Se resalta el recuadro del objetivo (los vatios) porque es el único
/// número que hay que mirar; el resto es contexto. Fuera de un segmento
/// no aparece.
class CoachingBanner extends ConsumerWidget {
  const CoachingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coachingControllerProvider);
    final advice = state.advice;
    if (!state.isActive || advice == null) return const SizedBox.shrink();

    final message = state.spoken;
    final power = advice.power;
    // Sin sensor de cadencia el objetivo no se puede comprobar: no va.
    final cadence = advice.features.cadence == null ? null : advice.cadence;
    final accent = _accentOf(advice.register);
    // Sin potenciómetro el objetivo se muestra, pero marcado: es una
    // estimación a partir de la velocidad y la pendiente.
    final estimated = advice.features.powerIsEstimated;

    return Material(
      color: CcColors.glass,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_score, size: 16, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message?.text ?? 'Midiendo tu esfuerzo…',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CcColors.ink,
                      fontSize: 13.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (power != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  _TargetBox(
                    label: estimated ? 'Objetivo estimado' : 'Objetivo',
                    value:
                        '${estimated ? '≈' : ''}'
                        '${power.spoken.round()}',
                    unit: 'W',
                    accent: accent,
                    highlighted: true,
                  ),
                  const SizedBox(width: 8),
                  if (power.floor case final floor? when floor < power.spoken)
                    _TargetBox(
                      label: power.limitedBySustainable ? 'Sostenible' : 'Piso',
                      value: floor.round().toString(),
                      unit: 'W',
                      accent: CcColors.inkDim,
                    ),
                  if (cadence != null) ...[
                    const SizedBox(width: 8),
                    _TargetBox(
                      label: 'Cadencia',
                      value: cadence.spoken.round().toString(),
                      unit: 'rpm',
                      accent: CcColors.mCadence,
                    ),
                  ],
                ],
              ),
            ],
            if (estimated) ...[
              const SizedBox(height: 8),
              const Text(
                'Sin potenciómetro: los vatios salen de tu velocidad y la '
                'pendiente, así que son aproximados.',
                style: TextStyle(color: CcColors.inkFaint, fontSize: 10.5),
              ),
            ],
            if (advice.ignoreSpeed) ...[
              const SizedBox(height: 8),
              const Text(
                'En subida la velocidad no dice nada: guíate por los vatios.',
                style: TextStyle(color: CcColors.inkFaint, fontSize: 10.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// El tono del consejo también se ve: seguro en naranja, dudoso en
  /// gris.
  static Color _accentOf(Register register) => switch (register) {
    Register.asertivo => CcColors.orange,
    Register.conMatiz => CcColors.orangeText,
    Register.cauto => CcColors.blue,
    Register.neutro => CcColors.inkDim,
  };
}

class _TargetBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color accent;
  final bool highlighted;

  const _TargetBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.accent,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: highlighted ? 3 : 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: highlighted ? 0.16 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: highlighted ? 0.75 : 0.25),
            width: highlighted ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: CcType.label(
                size: 8.5,
                color: CcColors.inkFaint,
              ).copyWith(letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: CcType.displayStyle(
                    size: highlighted ? 22 : 16,
                    weight: FontWeight.w800,
                  ).copyWith(color: highlighted ? accent : CcColors.ink),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: const TextStyle(color: CcColors.inkDim, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
