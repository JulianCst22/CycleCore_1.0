import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import 'package:core_ui/core_ui.dart';
import '../../domain/cyclist_kit.dart';

/// El festejo de "¡Desbloqueaste una pieza!" -- foco cenital + la pieza
/// bajo la luz + cómo la conseguiste + su set + "Equipar ahora / Después".
/// Se encadena tras el festejo de subida de nivel / cambio de rango.
class KitUnlockFlow {
  KitUnlockFlow._();

  static Future<void> showUnlock(
    BuildContext context,
    KitItem item, {
    String? setName,
    ({int have, int total})? setProgress,
    required VoidCallback onEquip,
  }) {
    HapticFeedback.mediumImpact();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Desbloqueaste una pieza',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, _, _) => _KitUnlockOverlay(
        item: item,
        setName: setName,
        setProgress: setProgress,
        onEquip: onEquip,
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        ),
      ),
    );
  }
}

IconData kitSlotIcon(KitSlot slot) => switch (slot) {
  KitSlot.maillot => Icons.checkroom,
  KitSlot.bici => Icons.pedal_bike,
  KitSlot.gesto => Icons.waving_hand_outlined,
};

String kitSlotLabel(KitSlot slot) => switch (slot) {
  KitSlot.maillot => 'Maillot',
  KitSlot.bici => 'Bici',
  KitSlot.gesto => 'Gesto',
};

class _KitUnlockOverlay extends StatelessWidget {
  final KitItem item;
  final String? setName;
  final ({int have, int total})? setProgress;
  final VoidCallback onEquip;

  const _KitUnlockOverlay({
    required this.item,
    required this.setName,
    required this.setProgress,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.center,
          children: [
            // Foco cenital.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.9),
                    radius: 1.1,
                    colors: [
                      CcColors.gold.withValues(alpha: 0.16),
                      CcColors.gold.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                decoration: BoxDecoration(
                  color: CcColors.surfaceHi,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: CcColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CcColors.gold.withValues(alpha: 0.14),
                        border: Border.all(color: CcColors.gold, width: 2.5),
                      ),
                      child: Icon(
                        kitSlotIcon(item.slot),
                        color: CcColors.gold,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'DESBLOQUEASTE',
                      style: CcType.label(
                        size: 12,
                        color: CcColors.inkDim,
                      ).copyWith(letterSpacing: 2.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: CcType.displayStyle(
                        size: 24,
                        color: CcColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CcColors.inkDim,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: CcColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CcColors.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_outlined,
                            size: 15,
                            color: CcColors.inkDim,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Por: ${item.unlock.label}',
                            style: CcType.label(
                              size: 11,
                              color: CcColors.inkDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (setName != null && setProgress != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Set ${setName!} · '
                        '${setProgress!.have}/${setProgress!.total}',
                        style: CcType.label(size: 11, color: CcColors.blue),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: const Text('Después'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: CcColors.gold,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () {
                              onEquip();
                              Navigator.of(context).maybePop();
                            },
                            child: const Text('Equipar ahora'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
