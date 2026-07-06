import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/training_zones.dart';

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
  late List<_ZoneRowControllers> _powerRows;
  late List<_ZoneRowControllers> _hrRows;

  @override
  void initState() {
    super.initState();
    _powerRows = widget.initialZones.powerZones
        .map((z) => _ZoneRowControllers.fromZone(z))
        .toList();
    _hrRows = widget.initialZones.heartRateZones
        .map((z) => _ZoneRowControllers.fromZone(z))
        .toList();
  }

  @override
  void dispose() {
    for (final r in [..._powerRows, ..._hrRows]) {
      r.dispose();
    }
    super.dispose();
  }

  void _resetToComputed() {
    setState(() {
      for (final r in [..._powerRows, ..._hrRows]) {
        r.dispose();
      }
      _powerRows = widget.computedZones.powerZones
          .map((z) => _ZoneRowControllers.fromZone(z))
          .toList();
      _hrRows = widget.computedZones.heartRateZones
          .map((z) => _ZoneRowControllers.fromZone(z))
          .toList();
    });
  }

  void _confirm() {
    final result = TrainingZones(
      powerZones: _powerRows.map((r) => r.toZone()).toList(),
      heartRateZones: _hrRows.map((r) => r.toZone()).toList(),
    );
    Navigator.of(context).pop(result);
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ZoneTable(
                        title: 'POTENCIA (watts)',
                        accentColor: AppColors.accentSlope,
                        rows: _powerRows,
                      ),
                      const SizedBox(height: 20),
                      _ZoneTable(
                        title: 'FRECUENCIA CARDÍACA (lpm)',
                        accentColor: AppColors.accentHeartRate,
                        rows: _hrRows,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: _resetToComputed,
                    child: const Text(
                      'Restablecer calculadas',
                      style: TextStyle(color: AppColors.textSecondaryOnPanel),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.textSecondaryOnPanel),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Controllers de texto para una fila editable de zona (min / max).
class _ZoneRowControllers {
  final String name;
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl; // vacío = sin límite superior

  _ZoneRowControllers({
    required this.name,
    required this.minCtrl,
    required this.maxCtrl,
  });

  factory _ZoneRowControllers.fromZone(TrainingZone z) {
    return _ZoneRowControllers(
      name: z.name,
      minCtrl: TextEditingController(text: z.min.toString()),
      maxCtrl: TextEditingController(text: z.max?.toString() ?? ''),
    );
  }

  TrainingZone toZone() {
    return TrainingZone(
      name: name,
      min: int.tryParse(minCtrl.text) ?? 0,
      max: maxCtrl.text.trim().isEmpty ? null : int.tryParse(maxCtrl.text),
    );
  }

  void dispose() {
    minCtrl.dispose();
    maxCtrl.dispose();
  }
}

/// Tabla editable de zonas: nombre + campos de min/max.
class _ZoneTable extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<_ZoneRowControllers> rows;

  const _ZoneTable({
    required this.title,
    required this.accentColor,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: accentColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        // Encabezado de columnas.
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'ZONA',
                  style: TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'MÍN',
                  style: TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'MÁX',
                  style: TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...rows.map((r) => _ZoneRow(row: r, accentColor: accentColor)),
      ],
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final _ZoneRowControllers row;
  final Color accentColor;

  const _ZoneRow({required this.row, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.name,
              style: const TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(flex: 2, child: _ZoneNumberField(controller: row.minCtrl)),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: _ZoneNumberField(
              controller: row.maxCtrl,
              placeholder: '∞',
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String? placeholder;

  const _ZoneNumberField({required this.controller, this.placeholder});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textPrimaryOnPanel,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: placeholder,
        hintStyle: const TextStyle(color: AppColors.textSecondaryOnPanel),
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
