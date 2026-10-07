import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ui.dart';
import '../application/cadence_providers.dart';
import '../application/sensors_providers.dart';
import '../domain/sensor_kind.dart';

/// Las fuentes de cadencia que hay conectadas ahora mismo, con el nombre
/// del aparato para que el ciclista sepa cuál es cuál.
List<({CadenceSource source, String device})> connectedCadenceSources(
  SensorsHubSnapshot hub,
) {
  final power = hub.of(SensorKind.power);
  final cadence = hub.of(SensorKind.cadence);
  final speed = hub.of(SensorKind.speed);
  return [
    if (power.isConnected || power.isReconnecting)
      (
        source: CadenceSource.power,
        device: power.connectedDeviceName ?? 'Medidor de potencia',
      ),
    if (cadence.isConnected || cadence.isReconnecting)
      (
        source: CadenceSource.dedicated,
        device: cadence.connectedDeviceName ?? 'Sensor de cadencia',
      ),
    if ((speed.isConnected || speed.isReconnecting) &&
        speed.alsoProvidesCadence)
      (
        source: CadenceSource.speedCombo,
        device: speed.connectedDeviceName ?? 'Sensor de velocidad',
      ),
  ];
}

/// Pregunta de qué sensor sacar la cadencia cuando hay más de uno que la
/// mide (p. ej. ya tenías el de cadencia y conectas el potenciómetro).
/// No hace nada si hay uno solo.
Future<void> askCadenceSource(BuildContext context, WidgetRef ref) async {
  final options = connectedCadenceSources(ref.read(sensorsHubProvider));
  if (options.length < 2) return;
  final current =
      ref.read(cadenceSourcePreferenceProvider) ??
      ref.read(activeCadenceSourceProvider) ??
      options.first.source;

  final chosen = await showDialog<CadenceSource>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: CcColors.surfaceHi,
      title: Text(
        '¿De dónde tomamos la cadencia?',
        style: CcType.displayStyle(size: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tienes más de un sensor que mide la cadencia. Elige uno; si '
            'deja de mandar datos usamos el otro sin que tengas que hacer '
            'nada.',
            style: TextStyle(
              color: CcColors.inkDim,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          for (final option in options)
            _SourceOption(
              label: option.source.label,
              device: option.device,
              selected: option.source == current,
              onTap: () => Navigator.of(context).pop(option.source),
            ),
        ],
      ),
    ),
  );
  if (chosen != null) {
    await ref.read(cadenceSourcePreferenceProvider.notifier).choose(chosen);
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.label,
    required this.device,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String device;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: selected
            ? CcColors.mCadence.withValues(alpha: 0.14)
            : CcColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? CcColors.mCadence : CcColors.line,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: selected ? CcColors.mCadence : CcColors.inkFaint,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: CcType.label(size: 13.5, color: CcColors.ink),
                      ),
                      Text(
                        device,
                        style: CcType.label(size: 11, color: CcColors.inkDim),
                      ),
                    ],
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

/// Fila de la pantalla de sensores que dice de dónde sale la cadencia y
/// deja cambiarlo. Solo aparece con dos o más fuentes conectadas.
class CadenceSourceRow extends ConsumerWidget {
  const CadenceSourceRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = connectedCadenceSources(ref.watch(sensorsHubProvider));
    if (options.length < 2) return const SizedBox.shrink();
    final active = ref.watch(activeCadenceSourceProvider);
    final preferred = ref.watch(cadenceSourcePreferenceProvider);
    final fellBack = preferred != null && active != null && active != preferred;

    return Material(
      color: CcColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => askCadenceSource(context, ref),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CcColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.autorenew, color: CcColors.mCadence, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cadencia desde',
                      style: CcType.label(size: 11, color: CcColors.inkDim),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      active?.label ?? 'Esperando datos…',
                      style: CcType.label(size: 14, color: CcColors.ink),
                    ),
                    if (fellBack)
                      Text(
                        '${preferred.label} sin datos: usando el otro',
                        style: CcType.label(size: 10.5, color: CcColors.warn),
                      ),
                  ],
                ),
              ),
              Text(
                'Cambiar',
                style: CcType.label(size: 12.5, color: CcColors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
