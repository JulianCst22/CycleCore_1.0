import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/climb_route.dart';
import '../../domain/rank_tier.dart';
import '../xp_debug_provider.dart';

/// Botón + bottom sheet para fijar manualmente un nivel de prueba desde
/// el perfil. Mientras el override esté activo, todo (roadmap, climb
/// screen) muestra ese nivel en vez del real -- pensado solo para que
/// puedas ver cómo se ve cada rango sin tener que jugar cientos de
/// actividades reales.
class XpDebugEntryButton extends ConsumerWidget {
  const XpDebugEntryButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(xpDebugOverrideProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: (override != null ? AppColors.primary : Colors.white)
              .withValues(alpha: override != null ? 0.15 : 0.05),
          border: Border.all(
            color: (override != null ? AppColors.primary : Colors.white)
                .withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.science_outlined,
              size: 14,
              color: override != null
                  ? AppColors.primary
                  : AppColors.textSecondaryOnPanel,
            ),
            const SizedBox(width: 5),
            Text(
              override != null ? 'Modo prueba activo' : 'Probar nivel',
              style: TextStyle(
                fontSize: 11,
                color: override != null
                    ? AppColors.primary
                    : AppColors.textSecondaryOnPanel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _XpDebugSheet(),
    );
  }
}

class _XpDebugSheet extends ConsumerStatefulWidget {
  const _XpDebugSheet();

  @override
  ConsumerState<_XpDebugSheet> createState() => _XpDebugSheetState();
}

class _XpDebugSheetState extends ConsumerState<_XpDebugSheet> {
  late double _sliderLevel;

  @override
  void initState() {
    super.initState();
    final currentOverride = ref.read(xpDebugOverrideProvider);
    _sliderLevel = currentOverride != null
        ? _levelForOverrideXp(currentOverride).toDouble()
        : 1;
  }

  int _levelForOverrideXp(int xp) {
    for (var level = ClimbRoute.maxLevel; level >= 1; level--) {
      if (xp >= _xpForLevel(level)) return level;
    }
    return 1;
  }

  int _xpForLevel(int level) {
    // Mismo cálculo que LevelCalculator.cumulativeXpToReach, evitado
    // aquí para no crear un import circular con el notifier -- el
    // notifier expone `setLevel` que hace este cálculo real.
    if (level <= 1) return 0;
    return 150 * (level - 1) * (level - 1);
  }

  @override
  Widget build(BuildContext context) {
    final tier = RankTier.forLevel(_sliderLevel.round());
    final notifier = ref.read(xpDebugOverrideProvider.notifier);
    final isActive = ref.watch(xpDebugOverrideProvider) != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modo prueba: fijar nivel',
            style: TextStyle(
              color: AppColors.textPrimaryOnPanel,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Solo afecta lo que ves en pantalla. No toca tus '
            'actividades ni tu XP real.',
            style: TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(tier.icon, color: tier.color),
              const SizedBox(width: 8),
              Text(
                'Nivel ${_sliderLevel.round()} · ${tier.label}',
                style: TextStyle(
                  color: tier.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Slider(
            value: _sliderLevel,
            min: 1,
            max: ClimbRoute.maxLevel.toDouble(),
            divisions: ClimbRoute.maxLevel - 1,
            activeColor: tier.color,
            label: '${_sliderLevel.round()}',
            onChanged: (value) => setState(() => _sliderLevel = value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isActive
                      ? () {
                          notifier.clear();
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Quitar override'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tier.color,
                  ),
                  onPressed: () {
                    notifier.setLevel(_sliderLevel.round());
                    Navigator.of(context).pop();
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
