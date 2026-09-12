import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/wardrobe_extra_tab.dart';
import '../domain/voice_persona.dart';
import 'voice_providers.dart';
import 'widgets/voice_roster_view.dart';
import 'widgets/voice_unlock_overlay.dart';

/// Implementaciones de los puntos de extensión de `profile` (ver
/// `profile/presentation/extension_points.dart`) para las voces de
/// guía. `main.dart` las registra ahí -- ninguna otra parte de `voice`
/// ni de `profile` necesita conocer este archivo.

/// Encadena el festejo de "¡Desbloqueaste una voz!" si la actividad
/// recién terminada desbloqueó alguna voz de guía nueva.
Future<bool> checkVoiceUnlockCelebration(
  BuildContext context,
  WidgetRef ref,
) async {
  final newIds = await ref
      .read(voiceUnlocksSeenProvider.notifier)
      .reconcile(ref.read(unlockedVoicePersonaIdsProvider));
  if (!context.mounted) return false;

  VoicePersona? chosen;
  for (final id in newIds) {
    final persona = voicePersonaById(id);
    if (persona != null && persona.tier == VoiceTier.desbloqueable) {
      chosen = persona;
      break;
    }
  }
  if (chosen == null) return false;
  final persona = chosen;

  await VoiceUnlockFlow.showUnlock(
    context,
    persona,
    onEquip: () =>
        ref.read(voiceSettingsProvider.notifier).selectPersona(persona),
    onPreview: () =>
        ref.read(voiceSettingsProvider.notifier).previewPersona(persona),
  );
  return true;
}

/// La pestaña "Voz" del Vestidor.
const voiceWardrobeTab = WardrobeExtraTab(
  label: 'Voz',
  builder: _buildVoiceRosterTab,
);

Widget _buildVoiceRosterTab(BuildContext context) => const VoiceRosterView();

/// Si hay voces desbloqueadas que el usuario aún no ha "visto" -- para
/// el puntito dorado del menú de `ClimbScreen`.
final voiceHasUnseenUnlocksProvider = Provider<bool>(
  (ref) => ref.watch(unseenVoiceUnlocksProvider).isNotEmpty,
);
