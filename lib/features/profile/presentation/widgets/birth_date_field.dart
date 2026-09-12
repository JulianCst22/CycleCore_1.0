import 'package:flutter/material.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';

/// Campo "fecha de nacimiento" con el look de los campos de auth pero
/// que abre un selector de fecha al tocarlo. Se usa en el registro y en
/// Editar perfil. Sólo sirve para estimar la FC máxima.
class BirthDateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String label;

  const BirthDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'FECHA DE NACIMIENTO (OPCIONAL)',
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 10, now.month, now.day),
      helpText: 'Tu fecha de nacimiento',
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: CcType.label(size: 10, color: CcColors.inkFaint),
          ),
        ),
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: CcColors.surfaceInset,
              border: Border.all(color: CcColors.line, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cake_outlined,
                  size: 18,
                  color: CcColors.inkFaint,
                ),
                const SizedBox(width: 10),
                Text(
                  v == null
                      ? 'Elegir fecha'
                      : '${v.day.toString().padLeft(2, '0')}/'
                            '${v.month.toString().padLeft(2, '0')}/${v.year}',
                  style: TextStyle(
                    color: v == null ? CcColors.inkFaint : CcColors.ink,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: CcColors.inkFaint,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 2, top: 6),
          child: const Text(
            'Solo para estimar tu FC máxima si no la conoces.',
            style: TextStyle(
              color: CcColors.inkFaint,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
