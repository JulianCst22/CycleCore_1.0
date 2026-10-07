import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ui.dart';
import '../../sensors/sensors.dart';
import '../application/coaching_settings_providers.dart';
import '../domain/coaching_preferences.dart';
import '../domain/variables/labels.dart';

/// Antes de grabar: lo que el coach recomienda para la salida, listo
/// para ajustar. Se muestra al tocar «Grabar», que es cuando el ciclista
/// todavía está quieto; dentro del segmento ya no se toca nada.
///
/// Devuelve `true` si hay que empezar a grabar. Si el ciclista pidió no
/// volver a verla, ni se abre.
Future<bool> confirmCoachSetup(BuildContext context, WidgetRef ref) async {
  final preferences = ref.read(coachingPreferencesProvider);
  if (!preferences.askBeforeRide) return true;
  final start = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CcColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _CoachSetupSheet(),
  );
  return start ?? false;
}

class _CoachSetupSheet extends ConsumerStatefulWidget {
  const _CoachSetupSheet();

  @override
  ConsumerState<_CoachSetupSheet> createState() => _CoachSetupSheetState();
}

class _CoachSetupSheetState extends ConsumerState<_CoachSetupSheet> {
  bool _dontAskAgain = false;

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(coachingPreferencesProvider);
    final notifier = ref.read(coachingPreferencesProvider.notifier);
    const recommended = CoachingPreferences.recommended;
    final hub = ref.watch(sensorsHubProvider);
    bool on(SensorKind kind) => hub.of(kind).isConnected;
    final cadenceSource = ref.watch(activeCadenceSourceProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: CcColors.inkFaint,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Antes de subir',
                      style: CcType.displayStyle(size: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Te recomendamos esto para hoy. Ajústalo a tu gusto.',
                      style: CcType.label(size: 13, color: CcColors.inkDim),
                    ),
                    const SizedBox(height: 18),
                    const _Label('Tus sensores'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SensorChip(
                          icon: Icons.favorite,
                          label: 'Pulso',
                          connected: on(SensorKind.heartRate),
                          color: CcColors.mHeartRate,
                        ),
                        _SensorChip(
                          icon: Icons.bolt,
                          label: 'Potencia',
                          connected: on(SensorKind.power),
                          color: CcColors.mPower,
                        ),
                        _SensorChip(
                          icon: Icons.autorenew,
                          label: cadenceSource == null
                              ? 'Cadencia'
                              : 'Cadencia · ${_shortSource(cadenceSource)}',
                          connected:
                              on(SensorKind.cadence) || cadenceSource != null,
                          color: CcColors.mCadence,
                        ),
                        _SensorChip(
                          icon: Icons.speed,
                          label: 'Velocidad',
                          connected: on(SensorKind.speed),
                          color: CcColors.mSpeed,
                          offLabel: 'GPS',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _Note(text: _sensorAdvice(hub)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SensorsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.bluetooth, size: 16),
                        label: const Text('Conectar sensores'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const _Label('Cómo quieres subir'),
                    const SizedBox(height: 8),
                    _Choices<Goal>(
                      values: Goal.values,
                      selected: preferences.goal,
                      recommended: recommended.goal,
                      labelOf: (g) => g.label,
                      onSelected: notifier.setGoal,
                    ),
                    const SizedBox(height: 6),
                    _Note(text: preferences.goal.description),
                    const SizedBox(height: 16),
                    const _Label('Cada cuánto te habla'),
                    const SizedBox(height: 8),
                    _Choices<CoachingPace>(
                      values: CoachingPace.values,
                      selected: preferences.pace,
                      recommended: recommended.pace,
                      labelOf: _paceLabel,
                      onSelected: notifier.setPace,
                    ),
                    const SizedBox(height: 6),
                    const _Note(
                      text:
                          'Lo urgente —una rampa que viene, el pulso muy alto— te '
                          'lo dice igual, sin esperar el turno.',
                    ),
                    const SizedBox(height: 16),
                    const _Label('Cuánto habla'),
                    const SizedBox(height: 8),
                    _Choices<CoachingDetail>(
                      values: CoachingDetail.values,
                      selected: preferences.detail,
                      recommended: recommended.detail,
                      labelOf: (d) => d.label,
                      onSelected: notifier.setDetail,
                    ),
                    const SizedBox(height: 6),
                    _Note(text: preferences.detail.description),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: preferences.enabled,
                      onChanged: notifier.setEnabled,
                      activeThumbColor: CcColors.orange,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Consejos por voz',
                        style: CcType.label(size: 14, color: CcColors.ink),
                      ),
                      subtitle: Text(
                        preferences.enabled
                            ? 'Te habla dentro de los segmentos que vigilas'
                            : 'Callado: solo verás el objetivo en pantalla',
                        style: CcType.label(size: 11, color: CcColors.inkDim),
                      ),
                    ),
                    CheckboxListTile(
                      value: _dontAskAgain,
                      onChanged: (v) =>
                          setState(() => _dontAskAgain = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      title: Text(
                        'No volver a mostrar (se cambia en Ajustes › Coach)',
                        style: CcType.label(size: 12, color: CcColors.inkDim),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // El botón queda fijo abajo: no hay que bajar hasta el final
            // para arrancar.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: CcColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (_dontAskAgain) await notifier.setAskBeforeRide(false);
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Grabar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _shortSource(CadenceSource source) => switch (source) {
    CadenceSource.power => 'potenciómetro',
    CadenceSource.dedicated => 'sensor',
    CadenceSource.speedCombo => 'combo',
  };

  static String _paceLabel(CoachingPace pace) => switch (pace) {
    CoachingPace.cadaMinuto => '1 min',
    CoachingPace.cadaDosMinutos => '2 min',
    CoachingPace.cadaMedioKilometro => '500 m',
    CoachingPace.cadaKilometro => '1 km',
  };

  /// Qué cambia en el coach según lo que haya conectado.
  static String _sensorAdvice(SensorsHubSnapshot hub) {
    final power = hub.of(SensorKind.power).isConnected;
    final heart = hub.of(SensorKind.heartRate).isConnected;
    final speed = hub.of(SensorKind.speed).isConnected;
    final parts = <String>[
      if (power)
        'Con potenciómetro te habla en vatios.'
      else
        'Sin potenciómetro estima el esfuerzo con velocidad y pendiente, '
            'y no dice vatios.',
      if (!power && !speed) 'Sin sensor de velocidad usa el GPS.',
      if (!heart) 'Sin banda de pulso pierde una señal.',
      'Si un sensor entra o se cae en plena subida, se acomoda solo.',
    ];
    return parts.join(' ');
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: CcType.label(
      size: 10.5,
      color: CcColors.inkFaint,
    ).copyWith(letterSpacing: 1.2),
  );
}

class _Note extends StatelessWidget {
  final String text;
  const _Note({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(color: CcColors.inkDim, fontSize: 12, height: 1.35),
  );
}

class _SensorChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool connected;
  final Color color;
  final String? offLabel;

  const _SensorChip({
    required this.icon,
    required this.label,
    required this.connected,
    required this.color,
    this.offLabel,
  });

  @override
  Widget build(BuildContext context) {
    final text = connected || offLabel == null ? label : '$label · $offLabel';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: connected
            ? color.withValues(alpha: 0.14)
            : CcColors.surfaceInset,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: connected ? color.withValues(alpha: 0.6) : CcColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: connected ? color : CcColors.inkFaint),
          const SizedBox(width: 6),
          Text(
            text,
            style: CcType.label(
              size: 12,
              color: connected ? CcColors.ink : CcColors.inkFaint,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            connected ? Icons.check : Icons.close,
            size: 13,
            color: connected ? CcColors.ok : CcColors.inkFaint,
          ),
        ],
      ),
    );
  }
}

/// Fila de opciones con la recomendada marcada.
class _Choices<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final T recommended;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  const _Choices({
    required this.values,
    required this.selected,
    required this.recommended,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _choice(values[i])),
        ],
      ],
    );
  }

  Widget _choice(T value) {
    final isSelected = value == selected;
    final isRecommended = value == recommended;
    return Material(
      color: isSelected
          ? CcColors.orange.withValues(alpha: 0.16)
          : CcColors.surfaceInset,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? CcColors.orange : CcColors.line,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labelOf(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcType.label(
                  size: 13.5,
                  color: isSelected ? CcColors.ink : CcColors.inkDim,
                ),
              ),
              const SizedBox(height: 2),
              // En los botones angostos (cuatro por fila) la palabra no
              // cabe a este tamaño: se encoge en vez de partirse.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isRecommended ? 'Recomendado' : ' ',
                  maxLines: 1,
                  style: CcType.label(size: 9.5, color: CcColors.orangeText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
