import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/database.dart' show Activity;
import '../../../core/fuzzy_type2/fuzzy_type2.dart' hide Interval;
import '../../../core/fuzzy_type2/fuzzy_type2.dart' as fuzzy show Interval;
import '../../../core/physiology/physiology.dart';
import '../../../core/ui/ui.dart';
import '../application/coaching_controller.dart';
import '../application/coaching_providers.dart';
import '../data/ride_export_repository.dart';
import '../domain/advice/governor.dart';
import '../domain/advice/targets.dart';
import '../domain/coaching_parameters.dart';
import '../domain/coaching_session.dart';
import '../domain/extraction/ride_features.dart';
import 'widgets/fou_painter.dart';

/// Lo que el motor está pensando, dibujado: la huella de cada salida con
/// su centroide de intervalo, las reglas que dispararon, el veredicto del
/// gobernador y lo que tarda una inferencia.
///
/// No es parte del camino normal: se entra desde los ajustes del coach y
/// sirve para depurar en la calle y para sustentar.
class CoachingDebugScreen extends ConsumerWidget {
  const CoachingDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coachingControllerProvider);
    final advice = state.advice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Huella del motor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exportar una salida',
            onPressed: () => _exportRide(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: advice == null
            ? _Empty(blocked: state.blocked)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                children: [
                  _Timings(state: state, advice: advice),
                  const SizedBox(height: 12),
                  _Physics(state: state, advice: advice),
                  const SizedBox(height: 16),
                  const ActivitySectionLabel('Salidas'),
                  const SizedBox(height: 10),
                  _Output(
                    title: 'Estado · motor A',
                    output: advice.decision.effort,
                    accent: CcColors.blue,
                  ),
                  _Output(
                    title: 'Demanda · motor B',
                    output: advice.decision.demand,
                    accent: CcColors.mSlope,
                  ),
                  _Output(
                    title: 'Ajuste · motor C',
                    output: advice.decision.adjustment,
                    accent: CcColors.orange,
                    unit: '%',
                    target: advice.power,
                  ),
                  _Output(
                    title: 'Cadencia · motor C',
                    output: advice.decision.cadence,
                    accent: CcColors.mCadence,
                    unit: 'rpm',
                  ),
                  _Output(
                    title: 'Urgencia · motor C',
                    output: advice.decision.urgency,
                    accent: CcColors.warn,
                  ),
                  const SizedBox(height: 6),
                  const ActivitySectionLabel('Por qué'),
                  const SizedBox(height: 10),
                  _Verdict(advice: advice, state: state),
                  const SizedBox(height: 16),
                  const ActivitySectionLabel('Reglas disparadas'),
                  const SizedBox(height: 10),
                  _Rules(advice: advice),
                  const SizedBox(height: 16),
                  const ActivitySectionLabel('Entradas'),
                  const SizedBox(height: 10),
                  _Inputs(features: advice.features),
                ],
              ),
      ),
    );
  }
}

/// Saca una salida en el formato que reproduce el motor, para pasarla al
/// computador y sacar su tabla de avisos con
/// `dart run tool/thesis.dart --grabacion <archivo>`.
///
/// Se elige de la lista de salidas recientes, con o sin potenciómetro:
/// así se exportan las dos subidas de una misma mañana, aunque se haga
/// al final del día.
Future<void> _exportRide(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) =>
      messenger.showSnackBar(SnackBar(content: Text(text)));

  final athlete = ref.read(coachAthleteProvider);
  if (athlete == null) {
    say(
      'Todavía no hay calibración: completa tu peso y tu FTP en el perfil '
      'para poder reproducir una salida.',
    );
    return;
  }
  final repository = ref.read(rideExportRepositoryProvider);
  final rides = await repository.recentRides();
  if (rides.isEmpty) {
    say('Todavía no hay salidas guardadas.');
    return;
  }
  if (!context.mounted) return;
  final ride = await showModalBottomSheet<Activity>(
    context: context,
    backgroundColor: CcColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _RidePicker(rides: rides),
  );
  if (ride == null) return;
  try {
    final json = await repository.exportJson(ride.id, athlete: athlete);
    if (json == null) {
      say('Esa salida no tiene puntos suficientes para reproducirla.');
      return;
    }
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/${RideExportRepository.fileNameOf(ride)}',
    );
    await file.writeAsString(json);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'CycleCore · ${ride.title}');
  } on Object catch (error) {
    say('No se pudo exportar: $error');
  }
}

/// Las salidas recientes para elegir cuál exportar.
class _RidePicker extends StatelessWidget {
  final List<Activity> rides;

  const _RidePicker({required this.rides});

  static String _clock(DateTime at) {
    final local = at.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Text(
                'Exportar una salida',
                style: CcType.displayStyle(size: 19),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Para reproducirla en el computador con las herramientas '
                'de la tesis.',
                style: CcType.label(size: 12, color: CcColors.inkDim),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final ride in rides)
                    ListTile(
                      onTap: () => Navigator.of(context).pop(ride),
                      title: Text(
                        ride.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CcColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${formatShortDate(ride.startedAt)} · '
                        '${_clock(ride.startedAt)} · '
                        '${formatDistanceKm(ride.distanceMeters)} km · '
                        '${ride.avgPower != null ? 'con potenciómetro' : 'sin potenciómetro'}',
                        style: CcType.label(size: 12, color: CcColors.inkDim),
                      ),
                      trailing: const Icon(
                        Icons.ios_share,
                        size: 20,
                        color: CcColors.blue,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String? blocked;

  const _Empty({required this.blocked});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(
        blocked ??
            'El motor solo corre dentro de un segmento vigilado. Entra a uno '
                'y acá se dibuja lo que está pensando.',
        textAlign: TextAlign.center,
        style: CcType.label(size: 12.5, color: CcColors.inkDim),
      ),
    ),
  );
}

/// Cuánto tarda pensar: el criterio de la fase es p95 por debajo de 5 ms.
class _Timings extends StatelessWidget {
  final CoachingLiveState state;
  final Advice advice;

  const _Timings({required this.state, required this.advice});

  @override
  Widget build(BuildContext context) {
    final micros = [...state.inferenceMicros]..sort();
    final p50 = micros.isEmpty ? null : micros[(micros.length - 1) ~/ 2];
    final p95 = state.inferenceP95Micros;
    String ms(int? value) =>
        value == null ? '--' : (value / 1000).toStringAsFixed(2);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: 'Segundo', value: '${advice.second}'),
              _Chip(
                label: 'Modo',
                value: advice.decision.mode == InferenceMode.type2
                    ? 'tipo-2'
                    : 'tipo-1',
              ),
              _Chip(label: 'Mediana', value: '${ms(p50)} ms'),
              _Chip(
                label: 'p95',
                value: '${ms(p95)} ms',
                accent: p95 != null && p95 < 5000 ? CcColors.ok : CcColors.warn,
              ),
              _Chip(label: 'Muestras', value: '${micros.length}'),
              _Chip(
                label: 'Potencia',
                value: advice.features.powerIsEstimated ? 'estimada' : 'medida',
                accent: advice.features.powerIsEstimated
                    ? CcColors.warn
                    : CcColors.ok,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Una salida con su huella dibujada y sus números.
/// Verificación física independiente (F12): lo que pidieron las reglas
/// contra lo que dice la ecuación de la reserva.
///
/// No corrige nada —para eso está el techo sostenible del objetivo—;
/// sirve para saber si la base de reglas se está yendo de la física, que
/// es lo que hay que revisar cuando se separan.
class _Physics extends StatelessWidget {
  final CoachingLiveState state;
  final Advice advice;

  const _Physics({required this.state, required this.advice});

  @override
  Widget build(BuildContext context) {
    final check = advice.physics;
    final review = state.physics;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reglas contra física', style: CcType.displayStyle(size: 13.5)),
          const SizedBox(height: 4),
          Text(
            check == null
                ? 'Sin potencia sostenible todavía: no hay con qué '
                      'contrastar.'
                : 'Las reglas piden ${check.advised.round()} vatios; la '
                      'reserva da para ${check.sustainable.round()}.',
            style: CcType.label(size: 11, color: CcColors.inkDim),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (check != null)
                _Chip(
                  label: 'Diferencia',
                  value:
                      '${check.differencePercent >= 0 ? '+' : ''}'
                      '${check.differencePercent.toStringAsFixed(1)} %',
                  accent: check.needsReview ? CcColors.warn : CcColors.ok,
                ),
              _Chip(label: 'Contrastes', value: '${review.evaluations}'),
              _Chip(
                label: 'Fuera de rango',
                value: '${review.flagged}',
                accent: review.flagged == 0 ? CcColors.ok : CcColors.warn,
              ),
              _Chip(
                label: 'Peor',
                value:
                    '${review.worst >= 0 ? '+' : ''}'
                    '${(review.worst * 100).toStringAsFixed(1)} %',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Output extends StatelessWidget {
  final String title;
  final OutputInference output;
  final Color accent;
  final String unit;
  final Target? target;

  const _Output({
    required this.title,
    required this.output,
    required this.accent,
    this.unit = '',
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    final centroid = output.centroid;
    final width = output.relativeUncertainty;
    final active =
        output.activations.entries.where((e) => e.value.hi > 0).toList()
          ..sort((a, b) => b.value.mid.compareTo(a.value.mid));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: CcType.displayStyle(size: 13.5)),
                ),
                Text(
                  centroid == null
                      ? 'sin evidencia'
                      : '${_n(centroid.mid)}$unit',
                  style: CcType.displayStyle(
                    size: 16,
                    weight: FontWeight.w800,
                  ).copyWith(color: accent),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              centroid == null
                  ? 'ninguna regla aportó evidencia'
                  : 'y ∈ [${_n(centroid.lo)} · ${_n(centroid.hi)}]'
                        '${width == null ? '' : '    Û ${(width * 100).toStringAsFixed(1)} %'}'
                        '    h ${output.upperShape.height.toStringAsFixed(2)}',
              style: CcType.label(size: 10.5, color: CcColors.inkDim),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              width: double.infinity,
              child: CustomPaint(
                painter: FootprintPainter(output: output, accent: accent),
              ),
            ),
            if (active.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in active.take(3))
                    _Chip(label: e.key.name, value: _interval(e.value)),
                ],
              ),
            ],
            if (target != null) ...[
              const SizedBox(height: 8),
              Text(
                'Objetivo ${target!.spoken.round()} W · banda '
                '${target!.band.lo.round()}–${target!.band.hi.round()} W'
                '${target!.limitedBySustainable ? ' · limitado por lo sostenible' : ''}',
                style: CcType.label(size: 10.5, color: CcColors.orangeText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _n(double x) =>
      x.abs() >= 100 ? x.toStringAsFixed(0) : x.toStringAsFixed(1);
}

String _interval(fuzzy.Interval x) => x.isPoint
    ? x.lo.toStringAsFixed(2)
    : '${x.lo.toStringAsFixed(2)}–${x.hi.toStringAsFixed(2)}';

/// El veredicto del gobernador, el motivo del consejo y la frase.
class _Verdict extends StatelessWidget {
  final Advice advice;
  final CoachingLiveState state;

  const _Verdict({required this.advice, required this.state});

  @override
  Widget build(BuildContext context) {
    final situation = advice.situation;
    final diagnosis = advice.diagnosis;
    final spoken = state.spoken;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Chip(
                label: 'Gobernador',
                value: _reason(advice.verdict.reason),
                accent: advice.speak ? CcColors.ok : CcColors.inkDim,
              ),
              _Chip(label: 'Tono', value: advice.register.name),
              if (situation != null)
                _Chip(
                  label: 'Situación',
                  value:
                      '${situation.state.name} · ${situation.demand.name} · '
                      '${situation.phase.name}',
                ),
            ],
          ),
          if (diagnosis != null) ...[
            const SizedBox(height: 10),
            Text(
              '${diagnosis.rule.id} · ${diagnosis.rule.then}',
              style: CcType.displayStyle(size: 12.5),
            ),
            const SizedBox(height: 3),
            Text(
              diagnosis.rule.rationale,
              style: CcType.label(size: 11, color: CcColors.inkDim),
            ),
          ],
          if (spoken != null) ...[
            const SizedBox(height: 10),
            Text(
              '«${spoken.text}»',
              style: const TextStyle(
                color: CcColors.ink,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              spoken.pieceIds.join(' + '),
              style: CcType.label(size: 10, color: CcColors.inkFaint),
            ),
          ],
        ],
      ),
    );
  }

  static String _reason(GovernorReason reason) => switch (reason) {
    GovernorReason.speak => 'habla',
    GovernorReason.lowUrgency => 'sin urgencia',
    GovernorReason.noSituation => 'sin situación',
    GovernorReason.tooSoon => 'muy pronto',
    GovernorReason.repeated => 'repetida',
    GovernorReason.hysteresis => 'histéresis',
  };
}

class _Rules extends StatelessWidget {
  final Advice advice;

  const _Rules({required this.advice});

  @override
  Widget build(BuildContext context) {
    final decision = advice.decision;
    final fired = [
      ...decision.effortTrace.take(3),
      ...decision.demandTrace.take(2),
      ...decision.decisionTrace.take(5),
    ].where((f) => f.strength.hi > 0).toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fired.isEmpty)
            Text(
              'Ninguna regla disparó todavía.',
              style: CcType.label(size: 11, color: CcColors.inkDim),
            ),
          for (final f in fired)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      f.rule.id,
                      style: CcType.displayStyle(size: 11.5),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f.rule.then.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcType.label(size: 10.5, color: CcColors.inkDim),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _interval(f.strength),
                    style: CcType.label(size: 10.5, color: CcColors.ink),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Inputs extends StatelessWidget {
  final RideFeatures features;

  const _Inputs({required this.features});

  @override
  Widget build(BuildContext context) {
    final rows = <({String name, UncertainValue? value})>[
      (name: 'intensidad', value: features.intensity),
      (name: 'reserva cardíaca', value: features.heartRateReserve),
      (name: 'torque relativo', value: features.torque),
      (name: 'reserva de W′ (%)', value: features.reserve),
      (name: 'suficiencia', value: features.sufficiency),
      (name: 'deriva (%)', value: features.decoupling),
      (name: 'variabilidad', value: features.variability),
      (name: 'pendiente (%)', value: features.gradientAhead),
      (name: 'rampa máxima (%)', value: features.maxRamp),
      (name: 'aspereza', value: features.roughness),
      (name: 'desnivel restante (m)', value: features.climbLeft),
      (name: 'avance (%)', value: features.progress),
      (name: 'ventaja al récord (s)', value: features.recordPace),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.name,
                      style: CcType.label(size: 10.5, color: CcColors.inkDim),
                    ),
                  ),
                  Text(
                    row.value == null
                        ? 'sin dato'
                        : '${_n(row.value!.value)}  '
                              '[${_n(row.value!.lo)} · ${_n(row.value!.hi)}]',
                    style: CcType.label(size: 10.5, color: CcColors.ink),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _n(double x) =>
      x.abs() >= 100 ? x.toStringAsFixed(0) : x.toStringAsFixed(2);
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;

  const _Chip({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    final color = accent ?? CcColors.inkDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: CcType.label(
              size: 8.5,
              color: CcColors.inkFaint,
            ).copyWith(letterSpacing: 0.4),
          ),
          const SizedBox(width: 5),
          // Un valor largo (la situación, por ejemplo) encoge en vez de
          // desbordar la tarjeta.
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcType.label(size: 11, color: CcColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: CcColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CcColors.line),
    ),
    child: child,
  );
}
