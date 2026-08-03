import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/training_zones.dart';
import 'profile_providers.dart';
import 'widgets/zones_editor.dart';
import 'zones_providers.dart';

/// Pantalla propia para revisar/ajustar las zonas de entrenamiento
/// después del alta -- antes solo se podían tocar una vez, durante el
/// Paso 3 del `AccountSetupWizard`, y no había forma de volver a
/// verlas ni ajustarlas después. Reutiliza el mismo `ZonesEditorForm`
/// (paleta `dark`, la del resto de la app -- no la `glass` del
/// wizard, porque esta pantalla vive en el "cockpit", no en el alta).
class TrainingZonesScreen extends ConsumerStatefulWidget {
  const TrainingZonesScreen({super.key});

  @override
  ConsumerState<TrainingZonesScreen> createState() =>
      _TrainingZonesScreenState();
}

class _TrainingZonesScreenState extends ConsumerState<TrainingZonesScreen> {
  final _zonesKey = GlobalKey<ZonesEditorFormState>();
  bool _saving = false;

  Future<void> _save() async {
    final zones = _zonesKey.currentState?.currentZones();
    if (zones == null) return;

    setState(() => _saving = true);
    await ref.read(zonesProvider.notifier).saveZones(zones);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final zonesAsync = ref.watch(zonesProvider);

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        elevation: 0,
        title: const Text(
          'Zonas de entrenamiento',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text(
            'No se pudo cargar tu perfil:\n$error',
            style: const TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Completa primero tu perfil para calcular tus zonas.',
                  style: TextStyle(color: AppColors.textSecondaryOnPanel),
                ),
              ),
            );
          }

          // Zonas calculadas a partir del perfil actual (referencia
          // para el botón "Restablecer") -- las guardadas (si
          // existen) son el punto de partida real del formulario, así
          // no se pierden ajustes manuales previos al reabrir esta
          // pantalla.
          final computed = TrainingZones.computeDefaults(profile);
          final saved = zonesAsync.valueOrNull;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                const Text(
                  'Calculadas a partir de tu FTP y FC máxima. Puedes '
                  'ajustarlas si conoces las tuyas con más precisión.',
                  style: TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: ZonesEditorForm(
                    key: _zonesKey,
                    initialZones: saved ?? computed,
                    computedZones: computed,
                    palette: ZonesEditorPalette.dark,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => _zonesKey.currentState?.resetToComputed(),
                    child: const Text(
                      'Restablecer calculadas',
                      style: TextStyle(color: AppColors.textSecondaryOnPanel),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Guardar cambios',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
