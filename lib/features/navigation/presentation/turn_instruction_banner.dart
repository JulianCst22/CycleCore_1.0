import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/cc_colors.dart';
import '../domain/navigation_route.dart';
import 'end_navigation_confirm.dart';
import 'navigation_providers.dart';

/// Distancia (metros) por debajo de la cual se considera que ya
/// "llegaste" al punto de una instrucción y se avanza a la siguiente.
const double _kInstructionArrivalThresholdMeters = 25;

/// Banner que va arriba del mapa mientras hay una navegación activa:
/// ícono de giro + texto + distancia restante hasta ese punto. También
/// es responsable de avanzar `nextInstructionIndexProvider` a medida
/// que te acercás a cada instrucción -- así que conviene tenerlo
/// siempre montado mientras `activeNavigationRouteProvider` no sea
/// null, aunque el usuario no lo esté mirando.
class TurnInstructionBanner extends ConsumerWidget {
  const TurnInstructionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(activeNavigationRouteProvider);
    if (route == null) return const SizedBox.shrink();

    final positionAsync = ref.watch(liveNavigationPositionProvider);
    final instructionIndex = ref.watch(nextInstructionIndexProvider);

    if (instructionIndex >= route.instructions.length) {
      return const SizedBox.shrink();
    }

    final instruction = route.instructions[instructionIndex];

    return positionAsync.when(
      loading: () =>
          _BannerContent(instruction: instruction, distanceMeters: null),
      error: (_, _) =>
          _BannerContent(instruction: instruction, distanceMeters: null),
      data: (position) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          instruction.lat,
          instruction.lng,
        );

        // Avanza sola a la próxima instrucción cuando ya estás cerca
        // del punto de giro -- se hace en un post-frame callback para
        // no modificar el provider en medio del build.
        if (distance < _kInstructionArrivalThresholdMeters) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final current = ref.read(nextInstructionIndexProvider);
            if (current == instructionIndex &&
                instructionIndex < route.instructions.length - 1) {
              ref.read(nextInstructionIndexProvider.notifier).state =
                  instructionIndex + 1;
            } else if (instruction.direction == TurnDirection.arrive) {
              // Llegaste al destino final -- cerramos la navegación.
              ref.read(navigationControllerProvider).cancelNavigation();
            }
          });
        }

        return _BannerContent(
          instruction: instruction,
          distanceMeters: distance,
        );
      },
    );
  }
}

class _BannerContent extends ConsumerWidget {
  final RouteInstruction instruction;
  final double? distanceMeters;

  const _BannerContent({
    required this.instruction,
    required this.distanceMeters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: CcColors.glass,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              _iconFor(instruction.direction),
              color: CcColors.ink,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instruction.text,
                    style: const TextStyle(
                      color: CcColors.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (distanceMeters != null)
                    Text(
                      distanceMeters! >= 1000
                          ? 'en ${(distanceMeters! / 1000).toStringAsFixed(1)} km'
                          : 'en ${distanceMeters!.round()} m',
                      style: const TextStyle(
                        color: CcColors.inkDim,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: CcColors.inkDim, size: 20),
              onPressed: () => confirmEndNavigation(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(TurnDirection direction) {
  switch (direction) {
    case TurnDirection.left:
    case TurnDirection.sharpLeft:
    case TurnDirection.slightLeft:
      return Icons.turn_left;
    case TurnDirection.right:
    case TurnDirection.sharpRight:
    case TurnDirection.slightRight:
      return Icons.turn_right;
    case TurnDirection.uTurn:
      return Icons.u_turn_left;
    case TurnDirection.arrive:
      return Icons.flag;
    case TurnDirection.straight:
      return Icons.straight;
  }
}
