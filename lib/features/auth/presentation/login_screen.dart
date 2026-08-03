import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_exceptions.dart';
import 'account_success_screen.dart';
import 'auth_providers.dart';
import 'account_setup_wizard.dart';
import '../../../core/theme/accent_gradients.dart';
import 'widgets/auth_text_field.dart';

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

    await ref.read(authProvider.notifier).login(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );

    if (!mounted) return;

    ref.read(authProvider).when(
      data: (session) {
        if (session != null) {
          final name = (session.displayName?.trim().isNotEmpty ?? false)
              ? session.displayName!.trim()
              : session.email.split('@').first;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AccountSuccessScreen(
                name: name,
                isReturning: true,
              ),
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
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: AccentGradients.glow(AccentGradients.violetGlow),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: AccentGradients.glow(AccentGradients.emberGlow,
                  opacity: 0.22),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Antes: el IconButton solo, como hijo directo
                    // del ListView, recibía el ancho completo de la
                    // pantalla y se centraba dentro de esa caja (su
                    // alignment por defecto es center) -- por eso se
                    // veía "centrado arriba" aunque no había ningún
                    // Center explícito en el código. Con Align +
                    // centerLeft queda pegado a la izquierda como se
                    // espera de un botón de volver.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: AccentGradients.ctaGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AccentGradients.emberGlow
                                  .withValues(alpha: 0.45),
                              blurRadius: 26,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.directions_bike_rounded,
                            color: Colors.white, size: 34),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Qué bueno verte de nuevo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tu cuenta se guarda solo en este dispositivo por '
                      'ahora. La nube llega pronto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AuthTextField(
                      controller: _emailCtrl,
                      label: 'Correo',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Correo inválido'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _passwordCtrl,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 14),
                      _ErrorBanner(text: _errorText!),
                    ],
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AccentGradients.ctaGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AccentGradients.emberGlow
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _submitting ? null : _submit,
                            child: Center(
                              child: _submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const AccountSetupWizard()),
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: '¿No tienes cuenta? ',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65)),
                            children: const [
                              TextSpan(
                                text: 'Regístrate',
                                style: TextStyle(
                                  color: AccentGradients.emberGlow,
                                  fontWeight: FontWeight.bold,
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
          ),
        ],
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
        color: const Color(0xFFFF5A5A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF5A5A).withValues(alpha: 0.4),
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