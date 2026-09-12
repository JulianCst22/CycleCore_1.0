import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/theme/accent_gradients.dart';
import 'package:cyclecore_core/theme/app_colors.dart';
import '../domain/cyclist_profile.dart';
import '../domain/training_zones.dart';
import 'profile_form_widgets.dart';
import 'profile_providers.dart';
import 'zones_dialog.dart';
import 'zones_providers.dart';

/// Recolector de los datos esenciales para las recomendaciones por
/// voz (peso, FTP, FC máx/reposo) cuando NO hace falta pedir cuenta:
/// invitados, o alguien que inició sesión pero todavía no tiene
/// perfil local en este dispositivo. Quien SÍ está creando una cuenta
/// nueva pasa por el asistente de 3 pasos (`AccountSetupWizard`) en
/// vez de esta pantalla -- ahí es donde también se pide foto/nombre,
/// así que aquí no hace falta duplicarlo.
///
/// El único cambio de diseño respecto a la versión anterior es el
/// encabezado: en vez del ícono plano, un badge circular con el
/// mismo gradiente de marca que ya ves en Welcome/Login -- así el
/// invitado también recibe ese toque "premium" aunque no suba foto.
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
      _weightCtrl.text = existing.weightKg?.toString() ?? '';
      _ftpCtrl.text = existing.ftpWatts?.toString() ?? '';
      _maxHrCtrl.text = existing.maxHr?.toString() ?? '';
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

  /// Validador para un campo numérico opcional: vacío es válido; si trae
  /// algo, debe ser un número dentro del rango.
  static String? _optionalRange(String? v, num lo, num hi, String msg) {
    if (v == null || v.trim().isEmpty) return null;
    final n = num.tryParse(v.trim());
    if (n == null || n < lo || n > hi) return msg;
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    // Conservamos foto/ciudad/bio si ya existían (p. ej. quien vino
    // del asistente de cuenta y luego edita solo sus datos deportivos
    // desde aquí) -- este formulario nunca debe vaciar esos campos.
    final existing = ref.read(profileProvider).valueOrNull;

    int? pInt(String s) => int.tryParse(s.trim());
    final profile = CyclistProfile(
      name: _nameCtrl.text.trim(),
      weightKg: double.tryParse(_weightCtrl.text.trim()),
      ftpWatts: pInt(_ftpCtrl.text),
      maxHr: pInt(_maxHrCtrl.text),
      restingHr: pInt(_restingHrCtrl.text),
      birthDate: existing?.birthDate,
      avatarPath: existing?.avatarPath,
      city: existing?.city,
      bio: existing?.bio,
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
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              // --- Encabezado ---
              if (!widget.isEditing) ...[
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AccentGradients.ctaGradient,
                      shape: BoxShape.circle,
                      boxShadow: AccentGradients.ctaGlow(blur: 24),
                    ),
                    child: const Icon(
                      Icons.directions_bike_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const Icon(
                  Icons.directions_bike,
                  color: AppColors.primary,
                  size: 40,
                ),
                const SizedBox(height: 12),
              ],
              Text(
                widget.isEditing
                    ? 'Edita tu perfil deportivo'
                    : 'Arma tu perfil',
                textAlign: widget.isEditing
                    ? TextAlign.start
                    : TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimaryOnPanel,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Con esto calibramos tus zonas de esfuerzo y las '
                'recomendaciones en vivo.',
                textAlign: widget.isEditing
                    ? TextAlign.start
                    : TextAlign.center,
                style: const TextStyle(
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
                label: 'Peso (opcional)',
                suffix: 'kg',
                icon: Icons.monitor_weight_outlined,
                accentColor: AppColors.accentDistance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => _optionalRange(v, 20, 250, 'Peso inválido'),
              ),

              const SizedBox(height: 24),
              const SectionLabel('ZONAS DE ESFUERZO'),
              const SizedBox(height: 4),
              const Text(
                'Todo opcional. Sin FTP no hay zonas de potencia; sin FC máx '
                'no hay zonas de FC. Lo completas cuando quieras.',
                style: TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              ProfileField(
                controller: _ftpCtrl,
                label: 'FTP (opcional)',
                suffix: 'watts',
                icon: Icons.bolt_outlined,
                accentColor: AppColors.accentSlope,
                helperText: 'Tu potencia sostenible una hora, en vatios.',
                keyboardType: TextInputType.number,
                validator: (v) => _optionalRange(v, 1, 600, 'FTP inválido'),
              ),
              const SizedBox(height: 12),
              ProfileField(
                controller: _maxHrCtrl,
                label: 'FC máxima (opcional)',
                suffix: 'lpm',
                icon: Icons.favorite_border,
                accentColor: AppColors.accentHeartRate,
                helperText:
                    'Si no la conoces, una estimación es 208 − (0.7 × edad).',
                keyboardType: TextInputType.number,
                validator: (v) => _optionalRange(v, 100, 230, 'FC inválida'),
              ),
              const SizedBox(height: 12),
              ProfileField(
                controller: _restingHrCtrl,
                label: 'FC en reposo (opcional)',
                suffix: 'lpm',
                icon: Icons.bedtime_outlined,
                accentColor: AppColors.accentElevation,
                helperText:
                    'Mejora la precisión del cálculo de esfuerzo en vivo.',
                keyboardType: TextInputType.number,
                validator: (v) => _optionalRange(v, 30, 120, 'FC inválida'),
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
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.5,
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
