import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cc_colors.dart';
import 'navigation_providers.dart';

/// Pide confirmación antes de terminar la navegación activa -- las dos
/// X (el banner de giro y el botón flotante del mapa) llaman a esto en
/// vez de cancelar de una, para no perder la ruta por un roce con el
/// guante. Mismo espíritu que el diálogo de "¿Terminar actividad?".
Future<void> confirmEndNavigation(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: CcColors.surfaceHi,
      title: const Text(
        '¿Terminar la navegación?',
        style: TextStyle(color: CcColors.ink),
      ),
      content: const Text(
        'Puedes retomarla después desde "Navegar".',
        style: TextStyle(color: CcColors.inkDim),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Seguir'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Terminar',
            style: TextStyle(color: CcColors.danger),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    ref.read(navigationControllerProvider).cancelNavigation();
  }
}
