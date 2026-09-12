import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import '../domain/auth_exceptions.dart';
import 'auth_providers.dart';
import 'widgets/auth_error_banner.dart';
import '../../../shared_widgets/auth_text_field.dart';
import 'widgets/password_strength_bar.dart';

/// Cambiar la contraseña de la cuenta vinculada. Pide primero la
/// contraseña ACTUAL como filtro de seguridad -- sin ella no se puede
/// cambiar aunque el teléfono esté desbloqueado.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contraseña actualizada.')));
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = 'No se pudo cambiar la contraseña. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CcColors.bg,
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              Text(
                'Escribe tu contraseña actual y luego la nueva.',
                style: CcType.label(size: 12, color: CcColors.inkDim),
              ),
              const SizedBox(height: 20),
              AuthTextField(
                controller: _currentCtrl,
                label: 'Contraseña actual',
                icon: Icons.lock_outline,
                hint: 'La que usas ahora',
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Requerida' : null,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _newCtrl,
                label: 'Nueva contraseña',
                icon: Icons.lock_reset_outlined,
                hint: 'Algo que solo tú sepas',
                obscureText: true,
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Mínimo 6 caracteres'
                    : (v == _currentCtrl.text
                          ? 'Elige una distinta a la actual'
                          : null),
              ),
              PasswordStrengthBar(password: _newCtrl.text),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _confirmCtrl,
                label: 'Confirmar nueva contraseña',
                icon: Icons.lock_outline,
                hint: 'Escríbela otra vez',
                obscureText: true,
                validator: (v) => (v != _newCtrl.text)
                    ? 'Las contraseñas no coinciden'
                    : null,
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                AuthErrorBanner(text: _errorText!),
              ],
              const SizedBox(height: 26),
              FilledButton(
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
                    : const Text('Guardar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
