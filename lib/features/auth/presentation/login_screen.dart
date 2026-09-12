import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import '../domain/auth_exceptions.dart';
import 'account_success_screen.dart';
import 'auth_providers.dart';
import 'account_setup_wizard.dart';
import 'widgets/auth_error_banner.dart';
import '../../../shared_widgets/auth_text_field.dart';
import 'widgets/dawn_hero.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    await ref
        .read(authProvider.notifier)
        .login(email: _emailCtrl.text, password: _passwordCtrl.text);

    if (!mounted) return;

    ref
        .read(authProvider)
        .when(
          data: (session) {
            if (session != null) {
              final name = (session.displayName?.trim().isNotEmpty ?? false)
                  ? session.displayName!.trim()
                  : session.email.split('@').first;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      AccountSuccessScreen(name: name, isReturning: true),
                ),
              );
            }
          },
          loading: () {},
          error: (error, _) {
            setState(() {
              _errorText = error is AuthException
                  ? error.message
                  : 'No se pudo iniciar sesión. Intenta de nuevo.';
            });
          },
        );

    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CcColors.bg,
      body: Stack(
        children: [
          const SizedBox(
            height: 208,
            width: double.infinity,
            child: DawnHero(),
          ),
          const SizedBox(
            height: 208,
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
                  stops: [0.0, 0.44, 0.74, 0.92, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 0, 0),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: CcColors.ink),
                    ),
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(26, 92, 26, 28),
                      children: [
                        Text(
                          'Hola de nuevo',
                          style:
                              CcType.displayStyle(
                                size: 28,
                                weight: FontWeight.w700,
                                height: 1.1,
                              ).copyWith(
                                shadows: const [
                                  Shadow(
                                    color: Color(0x99000000),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Recuerda tus credenciales y sigamos pedaleando.',
                          style:
                              const TextStyle(
                                color: CcColors.inkDim,
                                fontSize: 14,
                                height: 1.5,
                              ).copyWith(
                                shadows: const [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 26),
                        AuthTextField(
                          controller: _emailCtrl,
                          label: 'Correo',
                          icon: Icons.mail_outline,
                          hint: 'tu@correo.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Correo inválido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _passwordCtrl,
                          label: 'Contraseña',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          helperText:
                              'Tu cuenta vive solo en este teléfono: '
                              'si olvidas la contraseña tendrás que crear otra.',
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Mínimo 6 caracteres'
                              : null,
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 16),
                          AuthErrorBanner(text: _errorText!),
                        ],
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Iniciar sesión'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const AccountSetupWizard(),
                                  ),
                                ),
                            child: const Text.rich(
                              TextSpan(
                                text: '¿No tienes cuenta? ',
                                style: TextStyle(color: CcColors.inkDim),
                                children: [
                                  TextSpan(
                                    text: 'Regístrate',
                                    style: TextStyle(
                                      color: CcColors.blue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
