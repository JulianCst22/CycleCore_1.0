import 'package:flutter/material.dart';

import 'package:core_ui/core_ui.dart';
import '../domain/recording_snapshot.dart';

/// Qué hacer con una grabación recuperada del diario.
enum RecordingRecoveryChoice {
  /// Seguir grabando en la misma sesión.
  resume,

  /// Terminarla y abrir "Guardar actividad".
  save,

  /// Tirarla (ya confirmado por el usuario).
  discard,
}

/// Pregunta qué hacer con una grabación que no alcanzó a guardarse en el
/// historial porque la app se cerró. No se puede cerrar tocando fuera ni
/// con "atrás": el recorrido no debe perderse por un roce.
///
/// "Descartar" pide una segunda confirmación; si el usuario se arrepiente,
/// vuelve a esta misma pregunta. Devuelve `null` solo si el diálogo se
/// cerró desde afuera.
Future<RecordingRecoveryChoice?> showRecordingRecoveryDialog(
  BuildContext context,
  RecordingSnapshot snapshot,
) async {
  while (true) {
    if (!context.mounted) return null;
    final choice = await showDialog<RecordingRecoveryChoice>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecordingRecoveryDialog(snapshot: snapshot),
    );
    if (choice != RecordingRecoveryChoice.discard) return choice;
    if (!context.mounted) return null;
    if (await _confirmDiscard(context)) return choice;
  }
}

Future<bool> _confirmDiscard(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: CcColors.surfaceHi,
      title: const Text(
        '¿Descartar el recorrido?',
        style: TextStyle(color: CcColors.ink),
      ),
      content: const Text(
        'Se perderá todo lo que grabaste en esta salida. Esta acción no se '
        'puede deshacer.',
        style: TextStyle(color: CcColors.inkDim),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: CcColors.inkDim),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text(
            'Descartar',
            style: TextStyle(color: CcColors.danger),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Tarjeta del diálogo: qué pasó, cuánto se alcanzó a guardar y las
/// opciones. Una sesión que ya estaba terminada (la app se cerró en la
/// pantalla de guardar) no ofrece reanudar.
class RecordingRecoveryDialog extends StatelessWidget {
  final RecordingSnapshot snapshot;

  const RecordingRecoveryDialog({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final finished = snapshot.isFinished;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: CcColors.surfaceHi,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: CcColors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'RECORRIDO SIN GUARDAR',
                    style: CcType.label(color: CcColors.orangeText),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                finished
                    ? 'Tu actividad te está esperando'
                    : 'Tu recorrido sigue aquí',
                style: CcType.displayStyle(size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                finished
                    ? 'La app se cerró antes de guardarla, pero no perdiste '
                          'nada. Solo falta ponerle título.'
                    : 'La app se cerró mientras grababas. Guardamos tu salida '
                          'hasta las ${_clock(snapshot.lastDataAt)}.',
                style: const TextStyle(
                  color: CcColors.inkDim,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              ActivityDividedRow(
                cells: [
                  ActivityStatCell(
                    label: 'Distancia',
                    value: formatDistanceKm(snapshot.distanceMeters),
                    unit: 'km',
                  ),
                  ActivityStatCell(
                    label: 'Tiempo',
                    value: formatDuration(snapshot.movingTime),
                    unit: '',
                  ),
                  ActivityStatCell(
                    label: 'Empezó',
                    value: _clock(snapshot.startedAt),
                    unit: '',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!finished) ...[
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(RecordingRecoveryChoice.resume),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Seguir grabando'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(RecordingRecoveryChoice.save),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Terminar y guardar'),
                ),
              ] else
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(RecordingRecoveryChoice.save),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar actividad'),
                ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(RecordingRecoveryChoice.discard),
                child: const Text(
                  'Descartar',
                  style: TextStyle(color: CcColors.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "07:05" -- hora local en 24 h, sin depender de datos de locale.
  static String _clock(DateTime at) {
    final local = at.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
