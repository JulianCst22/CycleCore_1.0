import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/ui/ui.dart';
import '../domain/navigation_route.dart';
import 'end_navigation_confirm.dart';
import '../application/navigation_providers.dart';

/// Banner que va arriba del mapa mientras hay una navegación activa:
/// ícono de giro + texto + distancia restante hasta ese punto, medida
/// POR LA RUTA (no en línea recta). Mientras el ciclista se salió y la
/// ruta se recalcula, lo dice; si no se pudo recalcular, dice por qué.
///
/// Ya no avanza las instrucciones: eso lo hace
/// `navigationProgressProvider`, que sigue corriendo aunque este banner
/// esté oculto (p. ej. dentro de un segmento).
class TurnInstructionBanner extends ConsumerWidget {
  const TurnInstructionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(activeNavigationRouteProvider);
    if (route == null) return const SizedBox.shrink();

    final progress = ref.watch(navigationProgressProvider);
    final reroute = ref.watch(rerouteStateProvider);
    final positionAsync = ref.watch(liveNavigationPositionProvider);
    final instructionIndex = ref.watch(nextInstructionIndexProvider);

    if (instructionIndex >= route.instructions.length) {
      return const SizedBox.shrink();
    }
    final instruction = route.instructions[instructionIndex];

    if (reroute.busy) {
      return const _StatusBanner(
        icon: null,
        text: 'Recalculando la ruta…',
        detail: 'Tomaste otro camino',
      );
    }
    if (reroute.problem != null && progress.offRoute) {
      return _StatusBanner(
        icon: Icons.wrong_location_outlined,
        text: 'Fuera de la ruta',
        detail: reroute.problem!,
        warn: true,
      );
    }

    // Por la ruta cuando ya se va sobre ella; antes (todavía llegando
    // al primer punto) en línea recta.
    final position = positionAsync.valueOrNull;
    final distance =
        progress.metersTo(instruction) ??
        (position == null
            ? null
            : Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                instruction.lat,
                instruction.lng,
              ));

    return _BannerContent(instruction: instruction, distanceMeters: distance);
  }
}

/// Banner de estado (recalculando / fuera de la ruta), con el mismo
/// formato que el de la instrucción.
class _StatusBanner extends ConsumerWidget {
  final IconData? icon;
  final String text;
  final String detail;
  final bool warn;

  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.detail,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = warn ? CcColors.warn : CcColors.ink;
    return Material(
      color: CcColors.glassDeep,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: icon == null
                  ? const Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: CcColors.route,
                      ),
                    )
                  : Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    detail,
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
      color: CcColors.glassDeep,
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
                    // Mientras falta camino, "Llegaste" sonaba a que ya.
                    instruction.direction == TurnDirection.arrive
                        ? 'Llegas a tu destino'
                        : instruction.text,
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
