import 'package:flutter/material.dart';

import '../../../../core/theme/accent_gradients.dart';

/// Campo de texto compartido entre Login, Register y el asistente de
/// cuenta -- estilo "glass" (fondo translúcido + borde que se ilumina
/// en foco) para que se sienta a la altura del WelcomeScreen, no como
/// un formulario genérico pegado después de una pantalla bonita.
///
/// [suffixText] y [helperText] existen para poder reutilizar este
/// mismo campo en el Paso 2 del asistente (peso, FTP, FC) sin
/// necesitar un widget aparte -- mismo lenguaje visual de principio a
/// fin del alta.
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final String? suffixText;
  final String? helperText;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixText,
    this.helperText,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final _focusNode = FocusNode();
  bool _focused = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: _focused ? 0.10 : 0.06),
        border: Border.all(
          color: _focused
              ? AccentGradients.emberGlow.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.12),
          width: _focused ? 1.4 : 1,
        ),
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText && _obscured,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        cursorColor: AccentGradients.emberGlow,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          suffixText: widget.obscureText ? null : widget.suffixText,
          suffixStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          helperText: widget.helperText,
          helperMaxLines: 2,
          helperStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: _focused
                ? AccentGradients.emberGlow
                : Colors.white.withValues(alpha: 0.55),
          ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withValues(alpha: 0.55),
                    size: 20,
                  ),
                )
              : null,
          filled: false,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(color: Color(0xFFFF8A8A)),
        ),
      ),
    );
  }
}
