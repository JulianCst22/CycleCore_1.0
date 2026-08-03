import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/accent_gradients.dart';
import '../../profile/domain/cyclist_profile.dart';
import '../../profile/domain/training_zones.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../profile/presentation/widgets/zones_editor.dart';
import '../../profile/presentation/zones_providers.dart';
import '../domain/auth_exceptions.dart';
import 'account_success_screen.dart';
import 'auth_providers.dart';
import 'widgets/auth_text_field.dart';

/// Asistente único que reemplaza al viejo `RegisterScreen` +
/// `OnboardingScreen` encadenados. Antes, crear una cuenta pedía
/// nombre/correo/contraseña y dos pantallas después volvía a pedir el
/// nombre (y el peso, FTP, etc.) en un formulario con una estética
/// totalmente distinta -- ese salto es justo lo que este widget
/// elimina: un solo flujo, un solo lenguaje visual, un solo lugar
/// donde se pide cada dato.
///
/// 3 pasos quien se registra desde cero:
///   1. Cuenta (nombre, correo, contraseña, foto)
///   2. Perfil deportivo (peso, FTP, FC máx, FC reposo)
///   3. Zonas de entrenamiento (editable inline, no como popup)
///
/// [linkOnly] se usa cuando alguien YA tiene perfil local (entró como
/// invitado) y solo quiere vincular una cuenta desde la pestaña
/// Perfil -- en ese caso se muestra únicamente el Paso 1, y al
/// terminar se actualiza el perfil existente (nombre/foto) sin tocar
/// sus datos deportivos ni sus zonas.
class AccountSetupWizard extends ConsumerStatefulWidget {
  final bool linkOnly;

  const AccountSetupWizard({super.key, this.linkOnly = false});

  @override
  ConsumerState<AccountSetupWizard> createState() =>
      _AccountSetupWizardState();
}

class _AccountSetupWizardState extends ConsumerState<AccountSetupWizard> {
  static const _stepCount = 3;

  final _pageController = PageController();
  final _accountFormKey = GlobalKey<FormState>();
  final _sportFormKey = GlobalKey<FormState>();
  final _zonesKey = GlobalKey<ZonesEditorFormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ftpCtrl = TextEditingController();
  final _maxHrCtrl = TextEditingController();
  final _restingHrCtrl = TextEditingController();

  int _currentPage = 0;
  String? _avatarPath;
  bool _submitting = false;
  String? _errorText;
  CyclistProfile? _provisionalProfile;

  @override
  void initState() {
    super.initState();
    if (widget.linkOnly) {
      final existing = ref.read(profileProvider).valueOrNull;
      if (existing != null) {
        _nameCtrl.text = existing.name;
        _avatarPath = existing.avatarPath;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _weightCtrl.dispose();
    _ftpCtrl.dispose();
    _maxHrCtrl.dispose();
    _restingHrCtrl.dispose();
    super.dispose();
  }

  void _animateTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _goBack() {
    if (_currentPage == 0) {
      Navigator.of(context).pop();
    } else {
      _animateTo(_currentPage - 1);
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory(p.join(docsDir.path, 'profile_avatar'));
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }
    final ext = p.extension(picked.path);
    final newPath = p.join(
      avatarsDir.path,
      'avatar_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(picked.path).copy(newPath);

    if (!mounted) return;
    setState(() => _avatarPath = newPath);
  }

  CyclistProfile _buildProvisionalProfile() {
    return CyclistProfile(
      name: _nameCtrl.text.trim().isEmpty ? 'Ciclista' : _nameCtrl.text.trim(),
      weightKg: double.tryParse(_weightCtrl.text) ?? 70,
      ftpWatts: int.tryParse(_ftpCtrl.text) ?? 150,
      maxHr: int.tryParse(_maxHrCtrl.text) ?? 180,
      restingHr: _restingHrCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_restingHrCtrl.text),
      avatarPath: _avatarPath,
    );
  }

  Future<void> _goNext() async {
    if (_currentPage == 0) {
      if (!_accountFormKey.currentState!.validate()) return;
      if (widget.linkOnly) {
        await _submitLinkAccount();
        return;
      }
      _animateTo(1);
    } else if (_currentPage == 1) {
      if (!_sportFormKey.currentState!.validate()) return;
      setState(() => _provisionalProfile = _buildProvisionalProfile());
      _animateTo(2);
    } else {
      await _submitFullFlow();
    }
  }

  Future<void> _registerAccount() async {
    await ref.read(authProvider.notifier).register(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          displayName:
              _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        );
  }

  bool _handleAuthResultAndSetError() {
    var succeeded = false;
    ref.read(authProvider).when(
      data: (session) => succeeded = session != null,
      loading: () {},
      error: (error, _) {
        _errorText = error is AuthException
            ? error.message
            : 'No se pudo crear la cuenta. Intenta de nuevo.';
      },
    );
    return succeeded;
  }

  Future<void> _submitFullFlow() async {
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    await _registerAccount();
    if (!mounted) return;

    final succeeded = _handleAuthResultAndSetError();
    if (!succeeded) {
      setState(() => _submitting = false);
      _animateTo(0);
      return;
    }

    final profile = _provisionalProfile ?? _buildProvisionalProfile();
    await ref.read(profileProvider.notifier).saveProfile(profile);

    final zones =
        _zonesKey.currentState?.currentZones() ??
            TrainingZones.computeDefaults(profile);
    await ref.read(zonesProvider.notifier).saveZones(zones);

    if (!mounted) return;
    // El momento de bienvenida solo vive aquí -- en el registro
    // completo desde cero. El flujo de invitado y el de vincular
    // cuenta (linkOnly) siguen siendo instantáneos a propósito, para
    // no meterle fricción a quien solo quiere empezar a rodar.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AccountSuccessScreen(name: profile.name),
      ),
    );
  }

  Future<void> _submitLinkAccount() async {
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    await _registerAccount();
    if (!mounted) return;

    final succeeded = _handleAuthResultAndSetError();
    if (!succeeded) {
      setState(() => _submitting = false);
      return;
    }

    final current = ref.read(profileProvider).valueOrNull;
    if (current != null) {
      final updated = CyclistProfile(
        name:
            _nameCtrl.text.trim().isEmpty ? current.name : _nameCtrl.text.trim(),
        weightKg: current.weightKg,
        ftpWatts: current.ftpWatts,
        maxHr: current.maxHr,
        restingHr: current.restingHr,
        avatarPath: _avatarPath ?? current.avatarPath,
        city: current.city,
        bio: current.bio,
      );
      await ref.read(profileProvider.notifier).saveProfile(updated);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AccentGradients.indigoDeep,
      body: Stack(
        children: [
          const DecoratedBox(
            decoration:
                BoxDecoration(gradient: AccentGradients.backgroundGradient),
            child: SizedBox.expand(),
          ),
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: AccentGradients.glow(AccentGradients.emberGlow,
                  opacity: 0.28),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: AccentGradients.glow(AccentGradients.violetGlow),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 20, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _goBack,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                      if (!widget.linkOnly)
                        _StepDots(count: _stepCount, current: _currentPage),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _buildAccountStep(),
                      if (!widget.linkOnly) _buildSportStep(),
                      if (!widget.linkOnly) _buildZonesStep(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Form(
        key: _accountFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: _AvatarPicker(avatarPath: _avatarPath, onTap: _pickAvatar),
            ),
            const SizedBox(height: 24),
            Text(
              widget.linkOnly ? 'Vincula tu cuenta' : 'Crea tu cuenta',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.linkOnly
                  ? 'Vas a poder acceder a tu perfil y tus estadísticas '
                      'desde otro dispositivo. No se pierde nada de lo '
                      'que ya tienes.'
                  : 'Se guarda solo en este dispositivo por ahora. Nunca '
                      'es obligatoria para usar la app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            AuthTextField(
              controller: _nameCtrl,
              label: 'Nombre',
              icon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _emailCtrl,
              label: 'Correo',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Correo inválido' : null,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _passwordCtrl,
              label: 'Contraseña',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _confirmCtrl,
              label: 'Confirmar contraseña',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (v) => (v != _passwordCtrl.text)
                  ? 'Las contraseñas no coinciden'
                  : null,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 14),
              _ErrorBanner(text: _errorText!),
            ],
            const SizedBox(height: 26),
            _PrimaryButton(
              label: widget.linkOnly ? 'Vincular cuenta' : 'Continuar',
              loading: _submitting,
              onTap: _submitting ? null : _goNext,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Form(
        key: _sportFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: AccentGradients.ctaGradient,
                  shape: BoxShape.circle,
                  boxShadow: AccentGradients.ctaGlow(blur: 26),
                ),
                child: const Icon(Icons.monitor_heart_outlined,
                    color: Colors.white, size: 34),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tu perfil deportivo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Con esto calibramos tus zonas de esfuerzo y las '
              'recomendaciones por voz en vivo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            AuthTextField(
              controller: _weightCtrl,
              label: 'Peso',
              suffixText: 'kg',
              icon: Icons.monitor_weight_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0 || n > 250) return 'Peso inválido';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _ftpCtrl,
              label: 'FTP',
              suffixText: 'watts',
              icon: Icons.bolt_outlined,
              helperText: 'Si no lo sabes con exactitud, deja un estimado '
                  '(ej. 150 para un ciclista recreativo).',
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0 || n > 600) return 'FTP inválido';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _maxHrCtrl,
              label: 'FC máxima',
              suffixText: 'lpm',
              icon: Icons.favorite_border,
              helperText:
                  'Si no la conoces, una estimación es 208 − (0.7 × edad).',
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 100 || n > 230) return 'FC inválida';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _restingHrCtrl,
              label: 'FC en reposo',
              suffixText: 'lpm',
              icon: Icons.bedtime_outlined,
              helperText: 'Opcional, pero mejora la precisión del cálculo '
                  'de esfuerzo en vivo.',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v);
                if (n == null || n < 30 || n > 120) return 'FC inválida';
                return null;
              },
            ),
            const SizedBox(height: 26),
            _PrimaryButton(label: 'Continuar', onTap: _goNext),
          ],
        ),
      ),
    );
  }

  Widget _buildZonesStep() {
    final profile = _provisionalProfile ?? _buildProvisionalProfile();
    final computed = TrainingZones.computeDefaults(profile);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Tus zonas de entrenamiento',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculadas a partir de tu FTP y FC máxima. Puedes ajustarlas '
            'si conoces las tuyas con más precisión.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ZonesEditorForm(
              key: _zonesKey,
              initialZones: computed,
              computedZones: computed,
              palette: ZonesEditorPalette.glass,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => _zonesKey.currentState?.resetToComputed(),
              child: Text(
                'Restablecer calculadas',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
              ),
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 10),
            _ErrorBanner(text: _errorText!),
          ],
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Finalizar',
            loading: _submitting,
            onTap: _submitting ? null : _goNext,
          ),
        ],
      ),
    );
  }
}

/// Puntos de progreso del asistente -- el activo se estira y toma el
/// gradiente de marca, los demás quedan como puntos translúcidos.
class _StepDots extends StatelessWidget {
  final int count;
  final int current;

  const _StepDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: active ? AccentGradients.ctaGradient : null,
            color: active ? null : Colors.white.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}

/// Selector de avatar circular: si no hay foto, muestra un badge con
/// el gradiente de marca y un ícono de bici -- ese es el "algo
/// premium" para quien no quiere subir foto todavía, en vez de un
/// círculo gris vacío.
class _AvatarPicker extends StatelessWidget {
  final String? avatarPath;
  final VoidCallback onTap;

  const _AvatarPicker({required this.avatarPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  avatarPath == null ? AccentGradients.ctaGradient : null,
              image: avatarPath != null
                  ? DecorationImage(
                      image: FileImage(File(avatarPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
              boxShadow: AccentGradients.ctaGlow(blur: 30),
            ),
            child: avatarPath == null
                ? const Icon(Icons.directions_bike_rounded,
                    color: Colors.white, size: 40)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AccentGradients.indigoDeep,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.camera_alt,
                  color: Colors.white, size: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AccentGradients.ctaGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AccentGradients.ctaGlow(opacity: 0.4, blur: 20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;

  const _ErrorBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AccentGradients.errorRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AccentGradients.errorRed.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF8A8A), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFFF8A8A), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
