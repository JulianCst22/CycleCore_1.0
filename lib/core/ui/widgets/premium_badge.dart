import 'package:flutter/material.dart';

import '../theme/cc_colors.dart';

/// Insignia de lo que en producción sería el plan pago. En la versión de
/// la tesis no bloquea nada: solo marca qué funciones serían premium.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: CcColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CcColors.gold.withValues(alpha: 0.55)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 12, color: CcColors.gold),
          SizedBox(width: 3),
          Text(
            'PREMIUM',
            style: TextStyle(
              color: CcColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
