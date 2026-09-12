import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import '../../profile/domain/cyclist_profile.dart';
import '../../profile/domain/training_zones.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../profile/presentation/widgets/birth_date_field.dart';
import '../../profile/presentation/widgets/zones_editor.dart';
import '../../profile/presentation/zones_providers.dart';
import '../domain/auth_exceptions.dart';
import 'account_success_screen.dart';
import 'auth_providers.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/dawn_hero.dart';
import 'widgets/password_strength_bar.dart';

/// Asistente único que reemplaza al viejo `RegisterScreen` +
/// `OnboardingScreen` encadenados: un solo flujo, un solo lenguaje
/// visual, un solo lugar donde se pide cada dato.
///
/// 3 pasos para quien se registra desde cero:
///   1. Cuenta (nombre, correo, contraseña, foto) -- obligatorio
///   2. Perfil deportivo (peso, FTP, FC máx, FC reposo) -- "configurar luego"
///   3. Zonas de entrenamiento -- "configurar luego"
///
/// [linkOnly] se usa cuando alguien YA tiene perfil local (entró como
/// invitado) y solo quiere vincular una cuenta -- se muestra solo el
/// Paso 1.
///
/// Rediseño: mismo flujo y mismas animaciones (transición de página de
/// 320 ms, puntos de paso animados), traído al sistema navy + azul +
/// naranja. Se añade "Configurar luego" en los pasos 2 y 3.
class AccountSetupWizard extends ConsumerStatefulWidget {
  final bool linkOnly;

  const AccountSetupWizard({super.key, this.linkOnly = false});

  @override
  ConsumerState<AccountSetupWizard> createState() => _AccountSetupWizardState();
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
  DateTime? _birthDate;
  bool _submitting = false;
  bool _checkingEmail = false;
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
    int? parseInt(String s) => int.tryParse(s.trim());
    return CyclistProfile(
      name: _nameCtrl.text.trim().isEmpty ? 'Ciclista' : _nameCtrl.text.trim(),
      weightKg: double.tryParse(_weightCtrl.text.trim()),
      ftpWatts: parseInt(_ftpCtrl.text),
      maxHr: parseInt(_maxHrCtrl.text),
      restingHr: parseInt(_restingHrCtrl.text),
      birthDate: _birthDate,
      avatarPath: _avatarPath,
    );
  }

  int? get _estimatedMaxHr => _birthDate == null
      ? null
      : CyclistProfile(name: '', birthDate: _birthDate).estimatedMaxHrFromAge;

  void _useEstimatedMaxHr() {
    final estimate = _estimatedMaxHr;
    if (estimate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pon tu fecha de nacimiento para calcular el estimado.',
          ),
        ),
      );
      return;
    }
    setState(() => _maxHrCtrl.text = estimate.toString());
  }

  Future<void> _goNext() async {
    if (_currentPage == 0) {
      if (!_accountFormKey.currentState!.validate()) return;
      if (widget.linkOnly) {
        await _submitLinkAccount();
        return;
      }
      // El correo duplicado se avisa AQUÍ, no al final del flujo -- así
      // el usuario no llena todo el perfil para que lo rebote el registro.
      setState(() {
        _errorText = null;
        _checkingEmail = true;
      });
      final taken = await ref
          .read(authProvider.notifier)
          .emailTaken(_emailCtrl.text);
      if (!mounted) return;
      setState(() => _checkingEmail = false);
      if (taken) {
        setState(
          () => _errorText =
              'Ya existe una cuenta con este correo en este dispositivo.',
        );
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

  /// "Configurar luego" (pasos 2 y 3): registra la cuenta con perfil
  /// deportivo por defecto; el usuario lo completa después desde Ajustes.
  Future<void> _skipRemaining() async {
    setState(() => _provisionalProfile = _buildProvisionalProfile());
    await _submitFullFlow();
  }

  Future<void> _registerAccount() async {
    await ref
        .read(authProvider.notifier)
        .register(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text.trim().isEmpty
              ? null
              : _nameCtrl.text.trim(),
        );
  }

  bool _handleAuthResultAndSetError() {
    var succeeded = false;
    ref
        .read(authProvider)
        .when(
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
      // linkOnly sólo actualiza nombre/foto -- el resto del perfil
      // (datos deportivos, fecha de nacimiento) se conserva tal cual.
      final updated = current.copyWith(
        name: _nameCtrl.text.trim().isEmpty
            ? current.name
            : _nameCtrl.text.trim(),
        avatarPath: _avatarPath ?? current.avatarPath,
      );
      await ref.read(profileProvider.notifier).saveProfile(updated);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CcColors.bg,
      body: Stack(
        children: [
          // Misma idea que el Login: una banda de la ilustración de
          // amanecer arriba, que se funde con el fondo. El contenido de
          // cada paso pasa por delante al hacer scroll.
          const SizedBox(
            height: 168,
            width: double.infinity,
            child: DawnHero(),
          ),
          const SizedBox(
            height: 168,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x1A0E1116),
                    Color(0x000E1116),
                    Color(0x990E1116),
                    Color(0xF20E1116),
                    CcColors.bg,
                  ],
                  stops: [0.0, 0.4, 0.72, 0.92, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 22, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _goBack,
                        icon: const Icon(Icons.arrow_back, color: CcColors.ink),
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

  Widget _stepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? leading,
  }) {
    return Column(
      children: [
        leading ??
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: CcColors.surfaceHi,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: CcColors.line),
              ),
              child: Icon(icon, color: CcColors.orange, size: 28),
            ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: CcType.displayStyle(size: 23, weight: FontWeight.w700)
              .copyWith(
                shadows: const [
                  Shadow(color: Color(0x99000000), blurRadius: 14),
                ],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: CcColors.inkDim,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      child: Form(
        key: _accountFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _stepHeader(
              icon: Icons.person_outline,
              title: widget.linkOnly
                  ? 'Lleva tu perfil contigo'
                  : 'No pierdas ni una salida',
              subtitle: widget.linkOnly
                  ? 'Vincula una cuenta y tu perfil, tus récords y tu progreso '
                        'te siguen a cualquier dispositivo. No se pierde nada de '
                        'lo que ya tienes.'
                  : 'Crea tu cuenta y tus recorridos, tus récords y tus subidas '
                        'quedan guardados para siempre. Se queda en este teléfono '
                        'y jamás es obligatoria.',
              leading: Center(
                child: _AvatarPicker(
                  avatarPath: _avatarPath,
                  onTap: _pickAvatar,
                ),
              ),
            ),
            const SizedBox(height: 28),
            AuthTextField(
              controller: _nameCtrl,
              label: 'Nombre',
              icon: Icons.person_outline,
              hint: '¿Cómo te decimos?',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _emailCtrl,
              label: 'Correo',
              icon: Icons.mail_outline,
              hint: 'tu@correo.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Correo inválido' : null,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _passwordCtrl,
              label: 'Contraseña',
              icon: Icons.lock_outline,
              hint: 'Algo que solo tú sepas',
              obscureText: true,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            PasswordStrengthBar(password: _passwordCtrl.text),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _confirmCtrl,
              label: 'Confirmar contraseña',
              icon: Icons.lock_outline,
              hint: 'Escríbela otra vez',
              obscureText: true,
              validator: (v) => (v != _passwordCtrl.text)
                  ? 'Las contraseñas no coinciden'
                  : null,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 14),
              AuthErrorBanner(text: _errorText!),
            ],
            const SizedBox(height: 26),
            _PrimaryButton(
              label: widget.linkOnly ? 'Vincular cuenta' : 'Continuar',
              loading: _submitting || _checkingEmail,
              onTap: (_submitting || _checkingEmail) ? null : _goNext,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      child: Form(
        key: _sportFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _stepHeader(
              icon: Icons.monitor_heart_outlined,
              title: 'Ajustemos a tu medida',
              subtitle:
                  'Con esto, cada zona de esfuerzo y cada consejo por voz será '
                  'para ti. Todo es opcional -- lo que no pongas ahora lo '
                  'completas luego en Editar perfil.',
            ),
            const SizedBox(height: 28),
            BirthDateField(
              value: _birthDate,
              onChanged: (d) => setState(() => _birthDate = d),
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _weightCtrl,
              label: 'Peso (opcional)',
              icon: Icons.monitor_weight_outlined,
              hint: 'Ej. 72',
              suffixText: 'kg',
              helperText: 'Tu peso en kilos. Se usa para las calorías.',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v);
                if (n == null || n <= 0 || n > 250) return 'Peso inválido';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _ftpCtrl,
              label: 'FTP (opcional)',
              icon: Icons.bolt_outlined,
              hint: 'Ej. 180',
              suffixText: 'W',
              helperText:
                  'Tu potencia sostenible una hora, en vatios. Sin FTP no se '
                  'calculan zonas de potencia, nada más.',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v);
                if (n == null || n <= 0 || n > 600) return 'FTP inválido';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _maxHrCtrl,
              label: 'FC máxima (opcional)',
              icon: Icons.favorite_border,
              hint: 'Ej. 190',
              suffixText: 'lpm',
              helperText: 'Tu pulso más alto, en latidos por minuto.',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v);
                if (n == null || n < 100 || n > 230) return 'FC inválida';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _useEstimatedMaxHr,
                style: TextButton.styleFrom(foregroundColor: CcColors.blue),
                icon: const Icon(Icons.calculate_outlined, size: 16),
                label: Text(
                  _estimatedMaxHr == null
                      ? 'No la sé — calcular con mi edad'
                      : 'No la sé — usar estimado ($_estimatedMaxHr lpm)',
                ),
              ),
            ),
            const SizedBox(height: 6),
            AuthTextField(
              controller: _restingHrCtrl,
              label: 'FC en reposo (opcional)',
              icon: Icons.bedtime_outlined,
              hint: 'Ej. 55',
              suffixText: 'lpm',
              helperText:
                  'Tu pulso al despertar, quieto en la cama. Afina el cálculo '
                  'del esfuerzo en vivo.',
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
            const SizedBox(height: 6),
            _SkipButton(
              onTap: _submitting ? null : _skipRemaining,
              label: 'Ahora no, lo hago luego',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZonesStep() {
    final profile = _provisionalProfile ?? _buildProvisionalProfile();
    final computed = TrainingZones.computeDefaults(profile);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _stepHeader(
            icon: Icons.donut_large_outlined,
            title: computed.hasAny
                ? 'Tus zonas ya están listas'
                : 'Sin zonas por ahora',
            subtitle: computed.hasAny
                ? 'Las calculamos con tus datos. Ajústalas si conoces las tuyas '
                      'al detalle, o déjalas así y a rodar.'
                : 'No pusiste FTP ni FC máxima, así que todavía no hay zonas '
                      'que calcular. Cuando quieras, las configuras desde '
                      'Ajustes → Zonas de entrenamiento.',
          ),
          const SizedBox(height: 24),
          if (computed.hasAny) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CcColors.surfaceHi,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: CcColors.line),
              ),
              child: ZonesEditorForm(
                key: _zonesKey,
                initialZones: computed,
                computedZones: computed,
                palette: ZonesEditorPalette.glass,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => _zonesKey.currentState?.resetToComputed(),
                child: const Text('Restablecer calculadas'),
              ),
            ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: 10),
            AuthErrorBanner(text: _errorText!),
          ],
          const SizedBox(height: 14),
          _PrimaryButton(
            label: '¡Listo, a rodar!',
            loading: _submitting,
            onTap: _submitting ? null : _goNext,
          ),
          const SizedBox(height: 6),
          _SkipButton(
            onTap: _submitting ? null : _skipRemaining,
            label: computed.hasAny ? 'Dejarlas así' : 'Continuar',
          ),
        ],
      ),
    );
  }
}

/// Puntos de progreso del asistente -- el activo se estira y toma el
/// naranja de marca. La animación se conserva.
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
            color: active ? CcColors.orange : CcColors.surfaceHi,
          ),
        );
      }),
    );
  }
}

/// Selector de avatar circular -- superficie navy plana (sin degradado
/// ni glow). Si no hay foto, un ícono de bici tenue.
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
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CcColors.surfaceHi,
              border: Border.all(color: CcColors.line),
              image: avatarPath != null
                  ? DecorationImage(
                      image: FileImage(File(avatarPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarPath == null
                ? const Icon(
                    Icons.directions_bike_rounded,
                    color: CcColors.inkFaint,
                    size: 36,
                  )
                : null,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CcColors.orange,
                border: Border.all(color: CcColors.bg, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 14,
              ),
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
    return FilledButton(
      onPressed: onTap,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  const _SkipButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: CcColors.inkDim),
        child: Text(label),
      ),
    );
  }
}
