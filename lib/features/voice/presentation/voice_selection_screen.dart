import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/voice_persona.dart';
import 'voice_providers.dart';

/// Pantalla para elegir la personalidad de voz de guía y probarla
/// antes de confirmar. Se llega aquí típicamente desde el perfil,
/// con un ListTile tipo "Voz de guía".
class VoiceSelectionScreen extends ConsumerWidget {
  const VoiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(voiceSettingsProvider);
    final notifier = ref.read(voiceSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        elevation: 0,
        title: const Text(
          'Voz de guía',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          SwitchListTile(
            value: settings.enabled,
            onChanged: notifier.setEnabled,
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Voz activada',
              style: TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Te avisa al iniciar, pausar, reanudar y terminar una actividad.',
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ELIGE TU VOZ',
            style: TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          for (final persona in kVoicePersonas)
            _PersonaCard(
              persona: persona,
              selected: persona.id == settings.persona.id,
              onSelect: () => notifier.selectPersona(persona),
              onPreview: () => notifier.previewPersona(persona),
            ),
        ],
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({
    required this.persona,
    required this.selected,
    required this.onSelect,
    required this.onPreview,
  });

  final VoicePersona persona;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Text(persona.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.name,
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnPanel,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      persona.description,
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onPreview,
                icon: const Icon(Icons.play_circle_outline),
                color: AppColors.primary,
                tooltip: 'Probar voz',
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
