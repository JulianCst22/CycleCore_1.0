import 'package:flutter/material.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';

/// Banner de error compartido por Login y el asistente de cuenta.
///
/// Antes esta clase estaba duplicada (`_ErrorBanner`) en
/// `login_screen.dart` y `account_setup_wizard.dart`. Ahora vive en un
/// solo sitio. Estilo plano -- fondo teñido de rojo y borde, sin glow.
class AuthErrorBanner extends StatelessWidget {
  final String text;

  const AuthErrorBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: CcColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: CcColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: CcColors.danger, size: 16),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFF5A6A4), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
