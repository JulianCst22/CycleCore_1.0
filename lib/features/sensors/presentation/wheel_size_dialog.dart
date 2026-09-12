import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import '../domain/wheel_size.dart';
import 'speed_providers.dart';

/// Popup para configurar la circunferencia de rueda. Aparece solo cuando
/// el sensor de velocidad ya está conectado y reporta datos de rueda
/// pero no hay circunferencia guardada -- sin esto no hay forma de
/// calcular km/h (el protocolo BLE nunca manda velocidad ya calculada,
/// solo revoluciones). También se abre a mano desde la tarjeta del
/// sensor de velocidad conectado.
Future<void> showWheelSizeDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _WheelSizeDialogContent(),
  );
}

class _WheelSizeDialogContent extends ConsumerStatefulWidget {
  const _WheelSizeDialogContent();

  @override
  ConsumerState<_WheelSizeDialogContent> createState() =>
      _WheelSizeDialogContentState();
}

class _WheelSizeDialogContentState
    extends ConsumerState<_WheelSizeDialogContent> {
  final TextEditingController _customMmCtrl = TextEditingController();
  bool _useCustom = false;

  @override
  void dispose() {
    _customMmCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm(double mm) async {
    await ref
        .read(speedSensorControllerProvider.notifier)
        .setWheelCircumferenceMm(mm);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CcColors.surfaceHi,
      title: Text('Talla de tu llanta', style: CcType.displayStyle(size: 18)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La necesitamos para calcular la velocidad a partir de las '
              'revoluciones que reporta el sensor.',
              style: TextStyle(
                color: CcColors.inkDim,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: WheelSize.commonSizes.length,
                itemBuilder: (context, index) {
                  final size = WheelSize.commonSizes[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      size.label,
                      style: CcType.label(size: 13, color: CcColors.ink),
                    ),
                    trailing: Text(
                      '${size.circumferenceMm.toStringAsFixed(0)} mm',
                      style: CcType.label(size: 12, color: CcColors.inkDim),
                    ),
                    onTap: () => _confirm(size.circumferenceMm),
                  );
                },
              ),
            ),
            const Divider(color: CcColors.lineSoft),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _useCustom,
              onChanged: (v) => setState(() => _useCustom = v ?? false),
              title: Text(
                'Ingresar circunferencia manual (mm)',
                style: CcType.label(size: 13, color: CcColors.ink),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: CcColors.orange,
            ),
            if (_useCustom)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextField(
                  controller: _customMmCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: CcColors.ink),
                  decoration: const InputDecoration(
                    hintText: 'Ej. 2105',
                    hintStyle: TextStyle(color: CcColors.inkFaint),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (_useCustom)
          FilledButton(
            onPressed: () {
              final mm = double.tryParse(_customMmCtrl.text);
              if (mm != null && mm > 0) _confirm(mm);
            },
            child: const Text('Guardar'),
          ),
      ],
    );
  }
}
