import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/cyclist_profile.dart';
import '../domain/training_zones.dart';
import 'profile_form_widgets.dart';
import 'profile_providers.dart';
import 'zones_dialog.dart';
import 'zones_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  /// true cuando se abre desde el botón de perfil para editar datos ya
  /// existentes; false en el primer arranque de la app (sin perfil aún).
  final bool isEditing;

  const OnboardingScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ftpCtrl = TextEditingController();
  final _maxHrCtrl = TextEditingController();
  final _restingHrCtrl = TextEditingController();

  bool _saving = false;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    // Si estamos editando, esperamos a que el provider TERMINE de cargar
    // desde SharedPreferences antes de llenar los campos. Leerlo de forma
    // síncrona aquí (ref.read(...).valueOrNull) puede pillar el provider
    // todavía en estado "loading" justo después de un arranque en frío,
    // devolviendo null aunque los datos sí existan en disco.
    if (widget.isEditing) {
      _loadingProfile = true;
      _loadExistingProfile();
    }
  }

  Future<void> _loadExistingProfile() async {
    final existing = await ref.read(profileProvider.future);
    if (!mounted) return;

    if (existing != null) {
      _nameCtrl.text = existing.name;
      _weightCtrl.text = existing.weightKg.toString();
      _ftpCtrl.text = existing.ftpWatts.toString();
      _maxHrCtrl.text = existing.maxHr.toString();
      _restingHrCtrl.text = existing.restingHr?.toString() ?? '';
    }

    setState(() => _loadingProfile = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _ftpCtrl.dispose();
    _maxHrCtrl.dispose();
    _restingHrCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final profile = CyclistProfile(
      name: _nameCtrl.text.trim(),
      weightKg: double.parse(_weightCtrl.text),
      ftpWatts: int.parse(_ftpCtrl.text),
      maxHr: int.parse(_maxHrCtrl.text),
      restingHr: _restingHrCtrl.text.trim().isEmpty
          ? null
          : int.parse(_restingHrCtrl.text),
    );

    await ref.read(profileProvider.notifier).saveProfile(profile);

    // Calculamos las zonas por defecto con los datos que se acaban de
    // guardar, pero si el usuario ya había personalizado sus zonas antes,
    // le mostramos esas en vez de pisarlas silenciosamente.
    final computedZones = TrainingZones.computeDefaults(profile);
    final existingZones = await ref.read(zonesProvider.future);

    if (!mounted) return;

    final confirmedZones = await showZonesDialog(
      context,
      initialZones: existingZones ?? computedZones,
      computedZones: computedZones,
    );

    if (confirmedZones != null) {
      await ref.read(zonesProvider.notifier).saveZones(confirmedZones);
    }

    if (!mounted) return;

    setState(() => _saving = false);

    if (widget.isEditing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Scaffold(
        backgroundColor: AppColors.panelBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              // --- Encabezado ---
              const Icon(
                Icons.directions_bike,
                color: AppColors.primary,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Arma tu perfil',
                style: TextStyle(
                  color: AppColors.textPrimaryOnPanel,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Con esto calibramos tus zonas de esfuerzo y las '
                'recomendaciones en vivo.',
                style: TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),

              const SectionLabel('DATOS BÁSICOS'),
              const SizedBox(height: 10),
              ProfileField(
                controller: _nameCtrl,
                label: 'Nombre',
                icon: Icons.person_outline,
                accentColor: AppColors.accentTime,
                keyboardType: TextInputType.name,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              ProfileField(
                controller: _weightCtrl,
                label: 'Peso',
                suffix: 'kg',
                icon: Icons.monitor_weight_outlined,
                accentColor: AppColors.accentDistance,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0 || n > 250) return 'Peso inválido';
                  return null;
                },
              ),

              const SizedBox(height: 24),
              const SectionLabel('ZONAS DE ESFUERZO'),
              const SizedBox(height: 10),
              ProfileField(
                controller: _ftpCtrl,
                label: 'FTP',
                suffix: 'watts',
                icon: Icons.bolt_outlined,
                accentColor: AppColors.accentSlope,
                helperText: 'Si no lo sabes con exactitud, deja un estimado '
                    '(ej. 150 para un ciclista recreativo).',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0 || n > 600) return 'FTP inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ProfileField(
                controller: _maxHrCtrl,
                label: 'FC máxima',
                suffix: 'lpm',
                icon: Icons.favorite_border,
                accentColor: AppColors.accentHeartRate,
                helperText:
                    'Si no la conoces, una estimación es 208 − (0.7 × edad).',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 100 || n > 230) return 'FC inválida';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ProfileField(
                controller: _restingHrCtrl,
                label: 'FC en reposo',
                suffix: 'lpm',
                icon: Icons.bedtime_outlined,
                accentColor: AppColors.accentElevation,
                helperText: 'Opcional, pero mejora la precisión del '
                    'cálculo de esfuerzo en vivo.',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n < 30 || n > 120) return 'FC inválida';
                  return null;
                },
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
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
                          'Guardar y continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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