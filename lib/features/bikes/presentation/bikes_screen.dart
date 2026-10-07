import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ui.dart';
import '../application/bikes_providers.dart';
import '../domain/bike.dart';
import 'bike_edit_screen.dart';

/// Las bicicletas del ciclista: cuál usa por defecto y cuánto lleva
/// rodado con cada una.
class BikesScreen extends ConsumerWidget {
  const BikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikes = ref.watch(bikesProvider);
    final usage = ref.watch(bikeUsageProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('Mis bicicletas')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CcColors.orange,
        onPressed: () => _open(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: SafeArea(
        child: bikes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('No se pudieron cargar: $e')),
          data: (list) => list.isEmpty
              ? const _Empty()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _BikeCard(
                    bike: list[i],
                    usage: usage[list[i].id] ?? emptyBikeUsage,
                    onTap: () => _open(context, list[i]),
                    onUse: list[i].isDefault
                        ? null
                        : () => ref
                              .read(bikesRepositoryProvider)
                              .makeDefault(list[i].id),
                  ),
                ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Bike? bike) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => BikeEditScreen(bike: bike)));
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.pedal_bike_outlined,
            size: 48,
            color: CcColors.inkFaint,
          ),
          const SizedBox(height: 16),
          Text(
            'Todavía no has registrado ninguna bicicleta.',
            textAlign: TextAlign.center,
            style: CcType.displayStyle(size: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Su peso y su tipo le sirven al coach para calcular tus vatios '
            'cuando no hay potenciómetro.',
            textAlign: TextAlign.center,
            style: CcType.label(size: 12, color: CcColors.inkDim),
          ),
        ],
      ),
    ),
  );
}

class _BikeCard extends StatelessWidget {
  final Bike bike;
  final BikeUsage usage;
  final VoidCallback onTap;
  final VoidCallback? onUse;

  const _BikeCard({
    required this.bike,
    required this.usage,
    required this.onTap,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final accent = bike.color == null ? CcColors.blue : Color(bike.color!);
    return Material(
      color: CcColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: bike.isDefault ? CcColors.orange : CcColors.line,
              width: bike.isDefault ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Photo(path: bike.photoPath, accent: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bike.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CcType.displayStyle(size: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            bike.brand,
                            bike.kind.label,
                            '${bike.effectiveWeightKg.toStringAsFixed(1)} kg'
                                '${bike.weightKg == null ? ' aprox.' : ''}',
                          ].whereType<String>().join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CcType.label(size: 11.5),
                        ),
                      ],
                    ),
                  ),
                  if (bike.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: CcColors.orange.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'En uso',
                        style: CcType.label(
                          size: 10.5,
                          color: CcColors.orangeText,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Total(
                    label: 'Kilómetros',
                    value: (usage.distanceMeters / 1000).toStringAsFixed(
                      usage.distanceMeters >= 100000 ? 0 : 1,
                    ),
                  ),
                  _Total(
                    label: 'Horas',
                    value: (usage.time.inMinutes / 60).toStringAsFixed(
                      usage.time.inHours >= 100 ? 0 : 1,
                    ),
                  ),
                  _Total(
                    label: 'Desnivel',
                    value: '${usage.elevationGainMeters.round()} m',
                  ),
                  _Total(label: 'Salidas', value: '${usage.activities}'),
                ],
              ),
              if (onUse != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onUse,
                    style: TextButton.styleFrom(
                      foregroundColor: CcColors.blue,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Usar esta'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final String? path;
  final Color accent;

  const _Photo({required this.path, required this.accent});

  @override
  Widget build(BuildContext context) {
    final file = path == null ? null : File(path!);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        image: file != null && file.existsSync()
            ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
            : null,
      ),
      child: file != null && file.existsSync()
          ? null
          : Icon(Icons.pedal_bike, color: accent, size: 26),
    );
  }
}

class _Total extends StatelessWidget {
  final String label;
  final String value;

  const _Total({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CcType.displayStyle(size: 15, weight: FontWeight.w800),
        ),
        Text(label, style: CcType.label(size: 9.5)),
      ],
    ),
  );
}
