import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/training_zones.dart';
import 'widgets/zones_editor.dart';

/// Popup que muestra las zonas de potencia y FC recién calculadas a partir
/// del perfil, permitiendo al usuario editarlas antes de guardarlas.
///
/// Devuelve el [TrainingZones] final (editado o tal cual) si el usuario
/// confirma, o null si cancela.
Future<TrainingZones?> showZonesDialog(
  BuildContext context, {
  required TrainingZones initialZones,
  required TrainingZones computedZones,
}) {
  return showDialog<TrainingZones>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => ZonesDialog(
      initialZones: initialZones,
      computedZones: computedZones,
    ),
  );
}

class ZonesDialog extends StatefulWidget {
  final TrainingZones initialZones;
  final TrainingZones computedZones;

  const ZonesDialog({
    super.key,
    required this.initialZones,
    required this.computedZones,
  });

  @override
  State<ZonesDialog> createState() => _ZonesDialogState();
}

class _ZonesDialogState extends State<ZonesDialog> {
  final _editorKey = GlobalKey<ZonesEditorFormState>();

  void _confirm() {
    Navigator.of(context).pop(_editorKey.currentState!.currentZones());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panelBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tus zonas de entrenamiento',
                style: TextStyle(
                  color: AppColors.textPrimaryOnPanel,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Calculadas a partir de tu FTP y FC máxima. Puedes '
                'ajustarlas si conoces las tuyas con más precisión.',
                style: TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: ZonesEditorForm(
                    key: _editorKey,
                    initialZones: widget.initialZones,
                    computedZones: widget.computedZones,
                    palette: ZonesEditorPalette.dark,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Fila de acciones secundarias arriba (con Flexible +
              // ellipsis, nunca se desbordan aunque el texto sea
              // largo o la pantalla angosta) y el botón principal a
              // todo el ancho debajo -- esto es lo que elimina el
              // overflow de píxeles que ocurría cuando las 3 acciones
              // competían por espacio en una sola fila.
              Row(
                children: [
                  Flexible(
                    child: TextButton(
                      onPressed: () =>
                          _editorKey.currentState?.resetToComputed(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Restablecer calculadas',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textSecondaryOnPanel),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.textSecondaryOnPanel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
