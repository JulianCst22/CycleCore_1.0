import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/wheel_size.dart';
import 'cadence_speed_providers.dart';

/// Popup que se muestra cuando el sensor de velocidad ya está conectado
/// y reportando datos de rueda, pero todavía no hay una circunferencia
/// configurada -- sin esto no hay forma de calcular km/h (el protocolo
/// BLE nunca manda velocidad ya calculada, solo revoluciones).
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
        .read(cadenceSpeedSensorControllerProvider.notifier)
        .setWheelCircumferenceMm(mm);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.panelBackground,
      title: const Text(
        'Talla de tu llanta',
        style: TextStyle(color: AppColors.textPrimaryOnPanel),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Necesitamos esto para calcular tu velocidad a partir de '
              'las revoluciones que reporta el sensor.',
              style: TextStyle(
                color: AppColors.textSecondaryOnPanel,
                fontSize: 12.5,
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
                    title: Text(
                      size.label,
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnPanel,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Text(
                      '${size.circumferenceMm.toStringAsFixed(0)} mm',
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => _confirm(size.circumferenceMm),
                  );
                },
              ),
            ),
            const Divider(color: AppColors.textSecondaryOnPanel),
            CheckboxListTile(
              dense: true,
              value: _useCustom,
              onChanged: (v) => setState(() => _useCustom = v ?? false),
              title: const Text(
                'Ingresar circunferencia manual (mm)',
                style: TextStyle(
                  color: AppColors.textPrimaryOnPanel,
                  fontSize: 13,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
            ),
            if (_useCustom)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
                child: TextField(
                  controller: _customMmCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimaryOnPanel),
                  decoration: const InputDecoration(
                    hintText: 'Ej. 2105',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondaryOnPanel,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (_useCustom)
          ElevatedButton(
            onPressed: () {
              final mm = double.tryParse(_customMmCtrl.text);
              if (mm != null && mm > 0) _confirm(mm);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
      ],
    );
  }
}
