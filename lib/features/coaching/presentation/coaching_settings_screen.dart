import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ui.dart';
import '../application/coaching_providers.dart';
import '../application/coaching_settings_providers.dart';
import '../domain/calibration/athlete_calibration.dart';
import '../domain/coaching_preferences.dart';
import '../domain/variables/labels.dart';
import 'coaching_debug_screen.dart';

/// Ajustes del coach: si habla, cuánto, y con qué números está
/// trabajando (la calibración que sale de tus salidas).
class CoachingSettingsScreen extends ConsumerWidget {
  const CoachingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(coachingPreferencesProvider);
    final notifier = ref.read(coachingPreferencesProvider.notifier);
    final calibration = ref.watch(athleteCalibrationProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Coach en subidas')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: [
            _Card(
              child: SwitchListTile(
                value: preferences.enabled,
                onChanged: notifier.setEnabled,
                activeThumbColor: CcColors.orange,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Consejos por voz',
                  style: CcType.displayStyle(size: 14.5),
                ),
                subtitle: Text(
                  preferences.enabled
                      ? 'Te habla dentro de los segmentos que vigilas'
                      : 'Calla, pero el banner sigue mostrando el objetivo',
                  style: CcType.label(size: 11, color: CcColors.inkDim),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const ActivitySectionLabel('Cuánto habla'),
            const SizedBox(height: 10),
            _Card(
              child: RadioGroup<CoachingDetail>(
                groupValue: preferences.detail,
                onChanged: (value) {
                  if (value != null) notifier.setDetail(value);
                },
                child: Column(
                  children: [
                    for (final detail in CoachingDetail.values)
                      RadioListTile<CoachingDetail>(
                        value: detail,
                        activeColor: CcColors.orange,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          detail.label,
                          style: CcType.displayStyle(size: 14),
                        ),
                        subtitle: Text(
                          detail.description,
                          style: CcType.label(size: 11, color: CcColors.inkDim),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const ActivitySectionLabel('Cómo quieres subir'),
            const SizedBox(height: 10),
            _Card(
              child: RadioGroup<Goal>(
                groupValue: preferences.goal,
                onChanged: (value) {
                  if (value != null) notifier.setGoal(value);
                },
                child: Column(
                  children: [
                    for (final goal in Goal.values)
                      RadioListTile<Goal>(
                        value: goal,
                        activeColor: CcColors.orange,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          goal.label,
                          style: CcType.displayStyle(size: 14),
                        ),
                        subtitle: Text(
                          goal.description,
                          style: CcType.label(size: 11, color: CcColors.inkDim),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const ActivitySectionLabel('Cada cuánto habla'),
            const SizedBox(height: 10),
            _Card(
              child: RadioGroup<CoachingPace>(
                groupValue: preferences.pace,
                onChanged: (value) {
                  if (value != null) notifier.setPace(value);
                },
                child: Column(
                  children: [
                    for (final pace in CoachingPace.values)
                      RadioListTile<CoachingPace>(
                        value: pace,
                        activeColor: CcColors.orange,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          pace.label,
                          style: CcType.displayStyle(size: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Si aparece algo urgente —una rampa, el pulso en el tope— te '
              'avisa igual, sin esperar el turno.',
              style: CcType.label(size: 11, color: CcColors.inkDim),
            ),
            const SizedBox(height: 14),
            _Card(
              child: SwitchListTile(
                value: preferences.askBeforeRide,
                onChanged: notifier.setAskBeforeRide,
                activeThumbColor: CcColors.orange,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Recomendación antes de grabar',
                  style: CcType.displayStyle(size: 14.5),
                ),
                subtitle: Text(
                  'Al tocar «Grabar» te muestra tus sensores y lo que el '
                  'coach recomienda, para ajustarlo',
                  style: CcType.label(size: 11, color: CcColors.inkDim),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const ActivitySectionLabel('Con qué números trabaja'),
            const SizedBox(height: 10),
            _Card(child: _Calibration(calibration: calibration)),
            const SizedBox(height: 14),
            _Card(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CoachingDebugScreen(),
                  ),
                ),
                title: Text(
                  'Ver la huella del motor',
                  style: CcType.displayStyle(size: 14),
                ),
                subtitle: Text(
                  'Las figuras difusas, las reglas que dispararon y lo que '
                  'tarda en pensar',
                  style: CcType.label(size: 11, color: CcColors.inkDim),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: CcColors.inkDim,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'El coach solo habla dentro de un segmento vigilado, y solo '
              'cuando tiene algo que aportar.',
              style: TextStyle(
                color: CcColors.inkFaint,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Calibration extends StatelessWidget {
  final AthleteCalibration? calibration;

  const _Calibration({required this.calibration});

  @override
  Widget build(BuildContext context) {
    final model = calibration?.model;
    if (calibration == null || model == null) {
      return Text(
        'Todavía no hay con qué calibrar: sube tu FTP en el perfil o sal '
        'con potenciómetro.',
        style: CcType.label(size: 12, color: CcColors.inkDim),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Value(label: 'CP', value: '${model.cp.round()}', unit: 'W'),
            const SizedBox(width: 12),
            _Value(
              label: "W'",
              value: (model.wPrime / 1000).toStringAsFixed(1),
              unit: 'kJ',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          calibration!.explanation,
          style: CcType.label(size: 11, color: CcColors.inkFaint),
        ),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _Value({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('$label ', style: CcType.label(size: 11, color: CcColors.inkDim)),
        Text(
          value,
          style: CcType.displayStyle(size: 18, weight: FontWeight.w800),
        ),
        const SizedBox(width: 3),
        Text(
          unit,
          style: const TextStyle(color: CcColors.inkDim, fontSize: 10),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CcColors.line),
      ),
      child: child,
    );
  }
}
