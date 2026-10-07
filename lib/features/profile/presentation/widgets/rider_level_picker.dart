import 'package:flutter/material.dart';

import '../../../../core/physiology/physiology.dart' show RiderLevel;
import '../../../../core/ui/ui.dart';

/// Nivel del ciclista: el que la app deduce de cuánto rueda, y la
/// posibilidad de corregirlo.
///
/// Se muestra ya resuelto en vez de preguntarlo en frío porque la gente
/// se califica mal a sí misma: unos se ponen por encima y otros, por
/// pudor, muy por debajo. Pero sí sabe cuántas horas sale a la semana,
/// y de ahí sale el nivel. Quien no esté de acuerdo, toca y lo cambia.
class RiderLevelPicker extends StatelessWidget {
  /// El que sale de los años y las horas; `null` si aún no hay datos.
  final RiderLevel? suggested;

  /// El que el ciclista eligió a mano, si lo hizo.
  final RiderLevel? declared;

  /// Devuelve `null` cuando se vuelve al nivel deducido.
  final ValueChanged<RiderLevel?> onChanged;

  const RiderLevelPicker({
    super.key,
    required this.suggested,
    required this.declared,
    required this.onChanged,
  });

  RiderLevel? get _effective => declared ?? suggested;

  @override
  Widget build(BuildContext context) {
    final effective = _effective;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.directions_bike_outlined,
              size: 16,
              color: CcColors.inkDim,
            ),
            const SizedBox(width: 8),
            Text('Tu nivel', style: CcType.displayStyle(size: 13.5)),
            const Spacer(),
            if (declared != null && declared != suggested)
              TextButton(
                onPressed: () => onChanged(null),
                style: TextButton.styleFrom(
                  foregroundColor: CcColors.blue,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Usar el calculado'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in RiderLevel.values)
              _LevelPill(
                level: level,
                selected: level == effective,
                suggested: level == suggested,
                onTap: () => onChanged(level == suggested ? null : level),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          effective == null
              ? 'Dinos cuántas horas ruedas y calculamos tu nivel.'
              : '${effective.description}. Con esto el coach sabe con cuánta '
                    'reserva cuentas; se va ajustando solo con tus salidas.',
          style: CcType.label(size: 11, color: CcColors.inkDim),
        ),
      ],
    );
  }
}

class _LevelPill extends StatelessWidget {
  final RiderLevel level;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;

  const _LevelPill({
    required this.level,
    required this.selected,
    required this.suggested,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? CcColors.orange.withValues(alpha: 0.16)
              : CcColors.surfaceHi,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? CcColors.orange : CcColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              level.label,
              style: CcType.label(
                size: 12.5,
                color: selected ? CcColors.orangeText : CcColors.inkDim,
              ),
            ),
            if (suggested) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.auto_awesome,
                size: 12,
                color: selected ? CcColors.orangeText : CcColors.inkFaint,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
