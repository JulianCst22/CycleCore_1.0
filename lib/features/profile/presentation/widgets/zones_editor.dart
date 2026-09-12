import 'package:flutter/material.dart';

import 'package:cyclecore_core/theme/app_colors.dart';
import '../../domain/training_zones.dart';

/// Paleta visual del [ZonesEditorForm]. `dark` es el estilo "cockpit"
/// que ya usa el popup de zonas del invitado; `glass` es el estilo
/// índigo/translúcido del asistente de creación de cuenta. Ambos
/// comparten exactamente la misma lógica de edición -- solo cambian
/// los colores.
enum ZonesEditorPalette { dark, glass }

/// Formulario editable de zonas de potencia y frecuencia cardíaca.
///
/// No se guarda solo -- expone [ZonesEditorFormState.currentZones] y
/// [ZonesEditorFormState.resetToComputed] para que quien lo contenga
/// (un diálogo, un paso de wizard) decida cuándo leer el resultado.
/// Esto es a propósito: mismo patrón que ya tenía el `ZonesDialog`
/// original, solo que ahora vive en un widget aparte para no
/// duplicar esta lógica en dos lugares distintos.
class ZonesEditorForm extends StatefulWidget {
  final TrainingZones initialZones;
  final TrainingZones computedZones;
  final ZonesEditorPalette palette;

  const ZonesEditorForm({
    super.key,
    required this.initialZones,
    required this.computedZones,
    this.palette = ZonesEditorPalette.dark,
  });

  @override
  State<ZonesEditorForm> createState() => ZonesEditorFormState();
}

class ZonesEditorFormState extends State<ZonesEditorForm> {
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

  /// Restablece los campos a las zonas calculadas automáticamente a
  /// partir del perfil (FTP / FC máxima).
  void resetToComputed() {
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

  /// Lee el estado actual de los campos y arma el [TrainingZones]
  /// final. Quien contiene este widget lo llama cuando el usuario
  /// confirma (botón "Guardar" / "Finalizar").
  TrainingZones currentZones() {
    return TrainingZones(
      powerZones: _powerRows.map((r) => r.toZone()).toList(),
      heartRateZones: _hrRows.map((r) => r.toZone()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _EditorColors.forPalette(widget.palette);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ZoneTable(
          title: 'POTENCIA (watts)',
          accentColor: AppColors.accentSlope,
          rows: _powerRows,
          colors: palette,
          emptyHint: 'Añade tu FTP en Editar perfil para calcular estas zonas.',
        ),
        const SizedBox(height: 20),
        _ZoneTable(
          title: 'FRECUENCIA CARDÍACA (lpm)',
          accentColor: AppColors.accentHeartRate,
          rows: _hrRows,
          colors: palette,
          emptyHint:
              'Añade tu FC máxima en Editar perfil para calcular estas zonas.',
        ),
      ],
    );
  }
}

/// Colores resueltos según la paleta pedida -- mantiene el resto del
/// widget agnóstico de si está en modo "cockpit" o "glass".
class _EditorColors {
  final Color primaryText;
  final Color secondaryText;
  final Color fieldFill;
  final Color fieldFillFocused;

  const _EditorColors({
    required this.primaryText,
    required this.secondaryText,
    required this.fieldFill,
    required this.fieldFillFocused,
  });

  factory _EditorColors.forPalette(ZonesEditorPalette palette) {
    switch (palette) {
      case ZonesEditorPalette.dark:
        return _EditorColors(
          primaryText: AppColors.textPrimaryOnPanel,
          secondaryText: AppColors.textSecondaryOnPanel,
          fieldFill: Colors.black.withValues(alpha: 0.25),
          fieldFillFocused: Colors.black.withValues(alpha: 0.35),
        );
      case ZonesEditorPalette.glass:
        return _EditorColors(
          primaryText: Colors.white,
          secondaryText: Colors.white.withValues(alpha: 0.6),
          fieldFill: Colors.white.withValues(alpha: 0.08),
          fieldFillFocused: Colors.white.withValues(alpha: 0.14),
        );
    }
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
  final _EditorColors colors;
  final String emptyHint;

  const _ZoneTable({
    required this.title,
    required this.accentColor,
    required this.rows,
    required this.colors,
    required this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    final header = Text(
      title,
      style: TextStyle(
        color: accentColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
      ),
    );

    if (rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 6),
          Text(
            emptyHint,
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'ZONA',
                  style: TextStyle(
                    color: colors.secondaryText,
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
                    color: colors.secondaryText,
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
                    color: colors.secondaryText,
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
        ...rows.map(
          (r) => _ZoneRow(row: r, accentColor: accentColor, colors: colors),
        ),
      ],
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final _ZoneRowControllers row;
  final Color accentColor;
  final _EditorColors colors;

  const _ZoneRow({
    required this.row,
    required this.accentColor,
    required this.colors,
  });

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
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _ZoneNumberField(controller: row.minCtrl, colors: colors),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: _ZoneNumberField(
              controller: row.maxCtrl,
              colors: colors,
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
  final _EditorColors colors;
  final String? placeholder;

  const _ZoneNumberField({
    required this.controller,
    required this.colors,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: colors.primaryText,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: placeholder,
        hintStyle: TextStyle(color: colors.secondaryText),
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        filled: true,
        fillColor: colors.fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
