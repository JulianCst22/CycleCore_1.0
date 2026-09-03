import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../../core/theme/cc_colors.dart';
import '../../../../core/theme/cc_type.dart';
import '../../domain/voice_persona.dart';

/// El festejo de "¡Desbloqueaste una voz!" -- foco cenital + la voz bajo
/// la luz + cómo la conseguiste + "Probar / Usar ahora / Después". Se
/// encadena tras el festejo de subida de nivel / rango / pieza del kit.
class VoiceUnlockFlow {
  VoiceUnlockFlow._();

  static Future<void> showUnlock(
    BuildContext context,
    VoicePersona persona, {
    required VoidCallback onEquip,
    required VoidCallback onPreview,
  }) {
    HapticFeedback.mediumImpact();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Desbloqueaste una voz',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, _, _) => _VoiceUnlockOverlay(
        persona: persona,
        onEquip: onEquip,
        onPreview: onPreview,
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

class _VoiceUnlockOverlay extends StatelessWidget {
  final VoicePersona persona;
  final VoidCallback onEquip;
  final VoidCallback onPreview;

  const _VoiceUnlockOverlay({
    required this.persona,
    required this.onEquip,
    required this.onPreview,
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
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CcColors.gold.withValues(alpha: 0.14),
                        border: Border.all(color: CcColors.gold, width: 2.5),
                      ),
                      child: Text(
                        persona.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'DESBLOQUEASTE UNA VOZ',
                      style: CcType.label(
                        size: 12,
                        color: CcColors.inkDim,
                      ).copyWith(letterSpacing: 2.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      persona.name,
                      textAlign: TextAlign.center,
                      style: CcType.displayStyle(
                        size: 24,
                        color: CcColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      persona.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CcColors.inkDim,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    if (persona.unlock != null) ...[
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
                              'Por: ${persona.unlock!.label}',
                              style: CcType.label(
                                size: 11,
                                color: CcColors.inkDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: onPreview,
                      style: TextButton.styleFrom(
                        foregroundColor: CcColors.blue,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Probar'),
                    ),
                    const SizedBox(height: 6),
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
                            child: const Text('Usar ahora'),
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
