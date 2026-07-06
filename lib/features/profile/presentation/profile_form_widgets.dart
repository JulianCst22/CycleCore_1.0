import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Etiqueta de sección en mayúsculas, estilo "PENDIENTE" / "TIEMPO" que ya
/// usas en los StatTile del mapa.
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondaryOnPanel,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Campo de formulario estilizado con acento de color e ícono, en línea
/// con la identidad visual "cockpit oscuro" del resto de la app.
class ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accentColor;
  final String? suffix;
  final String? helperText;
  final TextInputType keyboardType;
  final String? Function(String?) validator;

  const ProfileField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.validator,
    this.suffix,
    this.helperText,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: const TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: accentColor,
              decoration: InputDecoration(
                labelText: label,
                suffixText: suffix,
                helperText: helperText,
                helperMaxLines: 2,
                labelStyle: const TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                  fontSize: 14,
                ),
                suffixStyle: const TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                  fontSize: 13,
                ),
                helperStyle: const TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                  fontSize: 11,
                ),
                errorStyle: const TextStyle(
                  color: AppColors.recordButtonActive,
                  fontSize: 11,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
