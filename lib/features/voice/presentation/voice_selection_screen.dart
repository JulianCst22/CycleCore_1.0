import 'package:flutter/material.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'widgets/voice_roster_view.dart';

/// Pantalla para elegir la voz de guía y probarla antes de confirmar. Se
/// llega aquí desde Ajustes → "Voz de guía"; es la misma lista que la
/// pestaña "Voz" del Vestidor ([VoiceRosterView]).
class VoiceSelectionScreen extends StatelessWidget {
  const VoiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CcColors.bg,
      appBar: AppBar(title: const Text('Voz de guía')),
      body: const SafeArea(child: VoiceRosterView()),
    );
  }
}
