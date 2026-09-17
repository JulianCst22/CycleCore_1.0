import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_ui/core_ui.dart';
import '../domain/climb_route.dart';
import '../domain/rank_tier.dart';
import '../application/climb_collectibles_provider.dart';
import 'rank_tier_style.dart';

/// Repaso de todo lo que ya se descubrió en la subida: los puntos de
/// interés reales del Alto de Patios que ya se tocaron al menos una
/// vez, agrupados por rango. Se llega aquí desde el ícono 🔖 en la
/// barra superior de [ClimbScreen].
class ClimbCollectionScreen extends ConsumerWidget {
  const ClimbCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectedAsync = ref.watch(climbCollectiblesProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Tu colección de Patios',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
      ),
      body: collectedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se pudo cargar tu colección.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
        ),
        data: (collected) {
          if (collected.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Todavía no has descubierto ningún punto de la '
                  'subida. Tócalos en tu subida a medida que los '
                  'vayas alcanzando.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondaryOnPanel),
                ),
              ),
            );
          }

          final tiersWithContent = RankTier.all
              .where((tier) => ClimbRoute.forTier(tier)
                  .any((poi) => collected.contains(poi.level)))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              for (final tier in tiersWithContent) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
                  child: Row(
                    children: [
                      Icon(tier.icon, color: tier.color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        tier.label,
                        style: TextStyle(
                          color: tier.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final poi in ClimbRoute.forTier(tier))
                  if (collected.contains(poi.level))
                    _CollectibleCard(poi: poi),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CollectibleCard extends StatelessWidget {
  final ClimbPointOfInterest poi;
  const _CollectibleCard({required this.poi});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: poi.tier.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: poi.tier.color.withValues(alpha: 0.16),
            ),
            child: Icon(poi.tier.icon, color: poi.tier.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  poi.name,
                  style: const TextStyle(
                    color: AppColors.textPrimaryOnPanel,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'km ${poi.distanceKm.toStringAsFixed(1)} · '
                  '${poi.altitudeM.round()} msnm · '
                  '${poi.gradePercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  poi.discoveryText,
                  style: const TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
