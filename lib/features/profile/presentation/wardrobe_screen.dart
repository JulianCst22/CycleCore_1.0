import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import '../domain/cyclist_kit.dart';
import '../domain/kit_catalog.dart';
import '../domain/kit_unlocks.dart';
import 'package:cyclecore_core/gamification/rank_tier.dart';
import 'cyclist_kit_providers.dart';
import 'extension_points.dart';
import 'widgets/kit_unlock_overlay.dart';
import 'widgets/pedaling_cyclist.dart';

/// El Vestidor: preview del ciclista de perfil (como un maniquí) + qué
/// tiene equipado, y las pestañas Maillot / Bici / Gestos / Voz / Sets
/// para cambiarlo. Cada pieza puede estar equipada, desbloqueada (se
/// puede equipar) o bloqueada (con la condición para conseguirla).
class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  @override
  void initState() {
    super.initState();
    // Al abrir el Vestidor, damos por "vistos" los desbloqueos actuales
    // -- el festejo grande ya lo dispara la subida al terminar la
    // actividad; aquí sólo se limpia el puntito de aviso.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(kitUnlocksSeenProvider.notifier)
          .reconcile(ref.read(unlockedKitIdsProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final kit =
        ref.watch(cyclistKitProvider).valueOrNull ?? KitCatalog.defaultKit;
    final tier = ref.watch(equippedMaillotTierProvider).clamp(0, 5);
    final visual = ref.watch(cyclistKitVisualProvider);
    final debugAll = ref.watch(kitDebugUnlockAllProvider);
    final maillot = KitCatalog.byId[kit.maillotId];
    final bici = KitCatalog.byId[kit.biciId];
    // Pestañas de otras features (hoy, "Voz" -- ver extension_points.dart)
    // que se agregan antes de "Sets", igual que siempre estuvo Voz.
    final extraTabs = ref.watch(wardrobeExtraTabsProvider);

    return DefaultTabController(
      length: 4 + extraTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vestidor'),
          actions: [
            IconButton(
              tooltip: 'Desbloquear todo (test)',
              icon: Icon(
                debugAll ? Icons.lock_open : Icons.lock_outline,
                color: debugAll ? CcColors.gold : null,
              ),
              onPressed: () =>
                  ref.read(kitDebugUnlockAllProvider.notifier).state =
                      !debugAll,
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              color: CcColors.surface,
              child: Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: Center(
                      child: PedalingCyclist(
                        color: RankTier.all[tier].color,
                        size: 130,
                        kit: visual,
                        demoGestures: true,
                      ),
                    ),
                  ),
                  Text(
                    '${maillot?.name ?? '—'}  ·  ${bici?.name ?? '—'}',
                    style: CcType.label(size: 11, color: CcColors.inkDim),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: [
                const Tab(text: 'Maillot'),
                const Tab(text: 'Bici'),
                const Tab(text: 'Gestos'),
                for (final tab in extraTabs) Tab(text: tab.label),
                const Tab(text: 'Sets'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const _SlotGrid(KitSlot.maillot),
                  const _SlotGrid(KitSlot.bici),
                  const _SlotGrid(KitSlot.gesto),
                  for (final tab in extraTabs) Builder(builder: tab.builder),
                  const _SetsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotGrid extends ConsumerWidget {
  final KitSlot slot;

  const _SlotGrid(this.slot);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = KitCatalog.forSlot(slot);
    final kit =
        ref.watch(cyclistKitProvider).valueOrNull ?? KitCatalog.defaultKit;
    final unlocked = ref.watch(unlockedKitIdsProvider);
    final unseen = ref.watch(unseenKitUnlocksProvider);

    return GridView.count(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      crossAxisCount: 2,
      childAspectRatio: 1.55,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        for (final item in items)
          _ItemCard(
            item: item,
            equipped: kit.isEquipped(item),
            unlocked: unlocked.contains(item.id),
            isNew: unseen.contains(item.id),
            onEquip: () => ref.read(cyclistKitProvider.notifier).equip(item),
          ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final KitItem item;
  final bool equipped;
  final bool unlocked;
  final bool isNew;
  final VoidCallback onEquip;

  const _ItemCard({
    required this.item,
    required this.equipped,
    required this.unlocked,
    required this.isNew,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    // Los gestos son un interruptor: se pueden activar Y desactivar
    // tocándolos. El maillot/bici/voz siempre tienen uno puesto.
    final isToggle = item.slot == KitSlot.gesto;
    final swatch = item.rankTierIndex != null
        ? RankTier.all[item.rankTierIndex!.clamp(0, 5)].color
        : CcColors.gold;
    final borderColor = equipped
        ? CcColors.gold
        : (unlocked ? CcColors.line : CcColors.lineSoft);

    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: Material(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: unlocked && (isToggle || !equipped) ? onEquip : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: equipped ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: swatch.withValues(alpha: unlocked ? 0.9 : 0.3),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        unlocked ? kitSlotIcon(item.slot) : Icons.lock_outline,
                        size: 15,
                        color: unlocked ? Colors.black : CcColors.inkDim,
                      ),
                    ),
                    const Spacer(),
                    if (isNew && unlocked)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: CcColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (equipped)
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: CcColors.gold,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CcType.displayStyle(size: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  equipped
                      ? (isToggle ? 'Activo · tocar para quitar' : 'Equipado')
                      : (unlocked
                            ? (isToggle
                                  ? 'Tocar para activar'
                                  : 'Tocar para equipar')
                            : item.unlock.label),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CcType.label(
                    size: 10,
                    color: equipped
                        ? CcColors.gold
                        : (unlocked ? CcColors.inkDim : CcColors.inkFaint),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetsList extends ConsumerWidget {
  const _SetsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedKitIdsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        for (final set in KitCatalog.sets)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SetCard(
              set: set,
              progress: kitSetProgress(set, unlocked),
              unlocked: unlocked,
            ),
          ),
      ],
    );
  }
}

class _SetCard extends StatelessWidget {
  final KitSet set;
  final ({int have, int total}) progress;
  final Set<String> unlocked;

  const _SetCard({
    required this.set,
    required this.progress,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final complete = progress.have == progress.total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: complete ? CcColors.gold : CcColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SET ${set.name.toUpperCase()}',
                style: CcType.label(
                  size: 12,
                  color: complete ? CcColors.gold : CcColors.blue,
                ).copyWith(letterSpacing: 1.2),
              ),
              const Spacer(),
              Text(
                '${progress.have}/${progress.total}',
                style: CcType.displayStyle(size: 15),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            set.description,
            style: const TextStyle(color: CcColors.inkDim, fontSize: 12),
          ),
          const SizedBox(height: 12),
          for (final id in set.itemIds)
            Builder(
              builder: (context) {
                final item = KitCatalog.byId[id];
                if (item == null) return const SizedBox.shrink();
                final has = unlocked.contains(id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        has ? Icons.check_circle : Icons.lock_outline,
                        size: 15,
                        color: has ? CcColors.gold : CcColors.inkFaint,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            color: has ? CcColors.ink : CcColors.inkDim,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        kitSlotLabel(item.slot),
                        style: CcType.label(size: 10, color: CcColors.inkFaint),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
