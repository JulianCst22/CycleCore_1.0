import 'package:flutter/material.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';

/// Medidor de fuerza de contraseña que aparece al escribir en el
/// asistente de cuenta. Tres tramos que se llenan y cambian de color, un
/// texto ("Muy corta" / "Aceptable" / "Segura") y la regla mínima
/// ("mín. 6 caracteres") que se marca cuando se cumple.
///
/// El mínimo real que exige el registro son 6 caracteres; el medidor
/// anima a poner más, pero no bloquea.
class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({super.key, required this.password});

  static const _minLength = 6;

  _Strength _assess() {
    final p = password;
    if (p.isEmpty) {
      return const _Strength(0, '', CcColors.line);
    }
    if (p.length < _minLength) {
      return const _Strength(1, 'Un poco corta todavía', CcColors.danger);
    }
    var variety = 0;
    if (RegExp('[a-z]').hasMatch(p)) variety++;
    if (RegExp('[A-Z]').hasMatch(p)) variety++;
    if (RegExp(r'\d').hasMatch(p)) variety++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) variety++;

    if (p.length >= 10 && variety >= 3) {
      return const _Strength(3, '¡Perfecta!', CcColors.ok);
    }
    return const _Strength(2, 'Va bien', CcColors.warn);
  }

  @override
  Widget build(BuildContext context) {
    final s = _assess();
    final meetsMin = password.length >= _minLength;

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 2, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (i) {
              final filled = i < s.level;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                  decoration: BoxDecoration(
                    color: filled ? s.color : CcColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              if (s.label.isNotEmpty)
                Text(
                  s.label,
                  style: TextStyle(
                    color: s.color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const Spacer(),
              Icon(
                meetsMin ? Icons.check_circle : Icons.circle_outlined,
                size: 12,
                color: meetsMin ? CcColors.ok : CcColors.inkFaint,
              ),
              const SizedBox(width: 4),
              Text(
                'mín. 6 caracteres',
                style: TextStyle(
                  color: meetsMin ? CcColors.inkDim : CcColors.inkFaint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Strength {
  final int level;
  final String label;
  final Color color;
  const _Strength(this.level, this.label, this.color);
}
