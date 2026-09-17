import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_ui/core_ui.dart';
import '../../domain/voice_persona.dart';
import '../../application/voice_providers.dart';

/// La lista de voces de guía en tres estantes -- **Gratis**, **Por
/// desbloquear** y **Premium** -- con el interruptor de voz on/off
/// arriba. Se usa tal cual como cuerpo de [VoiceSelectionScreen] y dentro
/// de la pestaña "Voz" del Vestidor.
class VoiceRosterView extends ConsumerStatefulWidget {
  const VoiceRosterView({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  ConsumerState<VoiceRosterView> createState() => _VoiceRosterViewState();
}

class _VoiceRosterViewState extends ConsumerState<VoiceRosterView> {
  @override
  void initState() {
    super.initState();
    // Al abrir la lista damos por "vistas" las voces desbloqueadas -- el
    // festejo grande ya lo dispara la subida; aquí sólo se limpia el
    // puntito de aviso (mismo patrón que el Vestidor).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(voiceUnlocksSeenProvider.notifier)
          .reconcile(ref.read(unlockedVoicePersonaIdsProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(voiceSettingsProvider);
    final notifier = ref.read(voiceSettingsProvider.notifier);
    final roster = ref.watch(voiceRosterProvider);

    final gratis = roster
        .where((e) => e.persona.tier == VoiceTier.gratis)
        .toList();
    final desbloqueables = roster
        .where((e) => e.persona.tier == VoiceTier.desbloqueable)
        .toList();

    Widget cardFor(VoiceRosterEntry entry) => _VoiceCard(
      entry: entry,
      onUse: entry.isLocked
          ? null
          : () => notifier.selectPersona(entry.persona),
      onPreview: () => notifier.previewPersona(entry.persona),
    );

    return ListView(
      padding: widget.padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        _EnabledCard(value: settings.enabled, onChanged: notifier.setEnabled),
        const SizedBox(height: 22),
        const _SectionHeader('GRATIS'),
        for (final e in gratis) cardFor(e),
        const SizedBox(height: 22),
        const _SectionHeader('POR DESBLOQUEAR', hint: 'Se ganan pedaleando.'),
        for (final e in desbloqueables) cardFor(e),
        const SizedBox(height: 22),
        const _SectionHeader(
          'PREMIUM',
          hint: 'Voces grabadas de verdad. Más adelante.',
        ),
        for (final v in kUpcomingVoices) _UpcomingCard(voice: v),
      ],
    );
  }
}

class _EnabledCard extends StatelessWidget {
  const _EnabledCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CcColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voz de guía', style: CcType.displayStyle(size: 15)),
                const SizedBox(height: 3),
                Text(
                  value
                      ? 'Te avisa en giros, segmentos e inicio o fin de la actividad.'
                      : 'En silencio durante las salidas.',
                  style: CcType.label(size: 11, color: CcColors.inkDim),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: CcColors.orange,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            label,
            style: CcType.label(
              size: 12,
              color: CcColors.inkFaint,
            ).copyWith(letterSpacing: 1.4),
          ),
          if (hint != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint!,
                style: CcType.label(size: 10, color: CcColors.inkFaint),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  const _VoiceCard({
    required this.entry,
    required this.onUse,
    required this.onPreview,
  });

  final VoiceRosterEntry entry;

  /// `null` cuando la voz está bloqueada (no se puede activar todavía).
  final VoidCallback? onUse;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final persona = entry.persona;
    final locked = entry.isLocked;
    final active = entry.isActive;

    final borderColor = active
        ? CcColors.gold
        : (locked ? CcColors.lineSoft : CcColors.line);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onUse,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: active ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EmojiTile(emoji: persona.emoji, dimmed: locked),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            persona.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CcType.displayStyle(
                              size: 15,
                              color: locked ? CcColors.inkDim : CcColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            persona.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: CcType.label(
                              size: 11,
                              color: CcColors.inkDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (active)
                      const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: CcColors.gold,
                      )
                    else if (locked)
                      const Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: CcColors.inkFaint,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _statusLine(entry),
                        style: CcType.label(
                          size: 10,
                          color: active
                              ? CcColors.gold
                              : (locked ? CcColors.inkFaint : CcColors.inkDim),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onPreview,
                      style: TextButton.styleFrom(
                        foregroundColor: CcColors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 34),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Probar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusLine(VoiceRosterEntry entry) {
    switch (entry.status) {
      case VoicePersonaStatus.activa:
        return 'En uso';
      case VoicePersonaStatus.disponible:
        return 'Tocar para usar';
      case VoicePersonaStatus.bloqueada:
        return entry.persona.unlock?.label ?? 'Bloqueada';
    }
  }
}

class _EmojiTile extends StatelessWidget {
  const _EmojiTile({required this.emoji, required this.dimmed});

  final String emoji;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CcColors.surfaceHi,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.voice});

  final UpcomingVoice voice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CcColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CcColors.gold.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CcColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CcColors.gold.withValues(alpha: 0.3)),
              ),
              child: Text(voice.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voice.name,
                    style: CcType.displayStyle(size: 15, color: CcColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    voice.tagline,
                    style: CcType.label(size: 11, color: CcColors.inkDim),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CcColors.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'PRONTO',
                style: CcType.label(
                  size: 9,
                  color: CcColors.gold,
                ).copyWith(letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
