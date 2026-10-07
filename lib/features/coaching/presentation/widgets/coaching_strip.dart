import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/ui.dart';
import '../../application/coaching_controller.dart';
import '../../domain/advice/governor.dart';

/// El coach dentro de la vista del segmento, en una franja.
///
/// Reemplaza a la tarjeta grande (`CoachingBanner`) donde el espacio es
/// del segmento: arriba van los objetivos -lo único que hay que mirar-
/// y debajo, en pequeño, la última frase que dijo la voz. Nada de notas
/// al pie ni cajas para cada número: pedaleando se lee un renglón, no
/// un panel.
class CoachingStrip extends ConsumerWidget {
  const CoachingStrip({super.key});

  /// Pasado este tiempo la frase ya no es de ahora: se atenúa.
  static const _freshSeconds = 45;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coachingControllerProvider);
    if (!state.isActive && state.blocked == null) {
      return const SizedBox.shrink();
    }

    final blocked = state.blocked;
    if (blocked != null) {
      return _Frame(
        accent: CcColors.warn,
        child: Text(
          blocked,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CcType.label(size: 12, color: CcColors.inkDim),
        ),
      );
    }

    final advice = state.advice;
    if (advice == null) {
      return _Frame(
        accent: CcColors.inkFaint,
        child: Text(
          'El coach está midiendo tu esfuerzo…',
          style: CcType.label(size: 12, color: CcColors.inkDim),
        ),
      );
    }

    final accent = _accentOf(advice.register);
    final estimated = advice.features.powerIsEstimated;
    final power = advice.power;
    final cadence = advice.cadence;
    final heartRate = advice.targetHeartRate;
    final message = state.spoken;
    final age = message == null || state.spokenAt == null
        ? null
        : advice.second - state.spokenAt!;
    final fresh = age != null && age <= _freshSeconds;

    final targets = <Widget>[
      if (power != null)
        _Target(
          value: '${estimated ? '≈' : ''}${power.spoken.round()}',
          unit: 'W',
          color: accent,
          tag: estimated ? 'estimado' : null,
        ),
      // Sin sensor de cadencia el objetivo no se puede comprobar: no se
      // muestra (tampoco se dice).
      if (cadence != null && advice.features.cadence != null)
        _Target(
          value: '${cadence.spoken.round()}',
          unit: 'rpm',
          color: CcColors.mCadence,
        ),
      if (heartRate != null)
        _Target(
          value: '${heartRate.round()}',
          unit: 'ppm',
          color: CcColors.mHeartRate,
          // Rubik no trae la flecha «↓»: va como ícono.
          icon: Icons.south,
        ),
    ];

    return _Frame(
      accent: accent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (targets.isNotEmpty)
            // Un solo renglón siempre: en un teléfono angosto se achica
            // antes que partirse en dos.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'APUNTA A',
                    style: CcType.label(
                      size: 9.5,
                      color: CcColors.inkFaint,
                    ).copyWith(letterSpacing: 1.1),
                  ),
                  const SizedBox(width: 10),
                  for (var i = 0; i < targets.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    targets[i],
                  ],
                ],
              ),
            ),
          if (message != null) ...[
            if (targets.isNotEmpty) const SizedBox(height: 4),
            Text(
              message.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fresh ? CcColors.ink : CcColors.inkFaint,
                fontSize: 12.5,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else if (targets.isEmpty)
            Text(
              'Vas bien. Te aviso cuando haya algo que cambiar.',
              style: CcType.label(size: 12, color: CcColors.inkDim),
            ),
        ],
      ),
    );
  }

  /// El tono del consejo también se ve: seguro en naranja, dudoso en
  /// azul o gris.
  static Color _accentOf(Register register) => switch (register) {
    Register.asertivo => CcColors.orange,
    Register.conMatiz => CcColors.orangeText,
    Register.cauto => CcColors.blue,
    Register.neutro => CcColors.inkDim,
  };
}

class _Frame extends StatelessWidget {
  final Color accent;
  final Widget child;

  const _Frame({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: CcColors.surfaceInset,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: child,
    );
  }
}

class _Target extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;
  final String? tag;

  /// Marca delante del número; la flecha del pulso que hay que bajar.
  final IconData? icon;

  const _Target({
    required this.value,
    required this.unit,
    required this.color,
    this.tag,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (icon != null) Icon(icon, size: 17, color: color),
        Text(
          value,
          style: CcType.displayStyle(
            size: 22,
            weight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(width: 3),
        Text(unit, style: CcType.label(size: 11, color: CcColors.inkDim)),
        if (tag != null) ...[
          const SizedBox(width: 4),
          Text(tag!, style: CcType.label(size: 9.5, color: CcColors.inkFaint)),
        ],
      ],
    );
  }
}
