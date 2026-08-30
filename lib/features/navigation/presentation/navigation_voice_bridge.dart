import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../voice/domain/voice_event.dart';
import '../../voice/presentation/voice_providers.dart';
import '../domain/navigation_route.dart';
import 'navigation_providers.dart';

/// Traduce cada `TurnDirection` a su `VoiceEventType` fijo -- ver la
/// nota en voice_event.dart sobre por qué la distancia no va en el
/// texto hablado. `null` para `straight`: ir derecho no se anuncia.
VoiceEventType? _voiceEventFor(TurnDirection direction) {
  switch (direction) {
    case TurnDirection.left:
      return VoiceEventType.navigationTurnLeft;
    case TurnDirection.right:
      return VoiceEventType.navigationTurnRight;
    case TurnDirection.slightLeft:
      return VoiceEventType.navigationTurnSlightLeft;
    case TurnDirection.slightRight:
      return VoiceEventType.navigationTurnSlightRight;
    case TurnDirection.sharpLeft:
      return VoiceEventType.navigationTurnSharpLeft;
    case TurnDirection.sharpRight:
      return VoiceEventType.navigationTurnSharpRight;
    case TurnDirection.uTurn:
      return VoiceEventType.navigationUTurn;
    case TurnDirection.arrive:
      return VoiceEventType.navigationArrived;
    case TurnDirection.straight:
      return null;
  }
}

/// Envolvé con esto la pantalla del mapa (ver map_screen.dart) para
/// que cada vez que `TurnInstructionBanner` avanza a la próxima
/// instrucción (`nextInstructionIndexProvider`), se dispare el aviso
/// de voz correspondiente exactamente una vez.
///
/// También anuncia "navigationStarted" la primera vez que
/// `activeNavigationRouteProvider` pasa de null a tener una ruta.
class NavigationVoiceBridge extends ConsumerStatefulWidget {
  final Widget child;
  const NavigationVoiceBridge({super.key, required this.child});

  @override
  ConsumerState<NavigationVoiceBridge> createState() =>
      _NavigationVoiceBridgeState();
}

class _NavigationVoiceBridgeState
    extends ConsumerState<NavigationVoiceBridge> {
  int? _lastAnnouncedIndex;
  bool _announcedStart = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<NavigationRoute?>(activeNavigationRouteProvider,
        (previous, next) {
      if (previous == null && next != null && !_announcedStart) {
        _announcedStart = true;
        _lastAnnouncedIndex = null;
        ref
            .read(voiceSettingsProvider.notifier)
            .speak(VoiceEventType.navigationStarted);
      }
      if (next == null) {
        // Navegación cancelada o terminada -- reseteamos para que la
        // próxima ruta vuelva a anunciar su inicio.
        _announcedStart = false;
        _lastAnnouncedIndex = null;
      }
    });

    ref.listen<int>(nextInstructionIndexProvider, (previous, next) {
      if (next == _lastAnnouncedIndex) return;
      _lastAnnouncedIndex = next;

      final route = ref.read(activeNavigationRouteProvider);
      if (route == null || next >= route.instructions.length) return;

      final instruction = route.instructions[next];
      final voiceEvent = _voiceEventFor(instruction.direction);
      if (voiceEvent != null) {
        ref.read(voiceSettingsProvider.notifier).speak(voiceEvent);
      }
    });

    return widget.child;
  }
}
