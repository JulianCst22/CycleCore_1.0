import 'package:flutter/material.dart';

import '../theme/cc_colors.dart';
import '../theme/cc_type.dart';

/// Campo de texto compartido entre Login, Registro y el asistente de
/// cuenta.
///
/// Rediseño: se abandona el estilo "glass" (fondo translúcido + borde
/// que se ilumina en foco) por uno alineado al resto de la app --
/// etiqueta en versalitas arriba, caja sobre [CcColors.surfaceInset]
/// con borde de 1,5px que pasa a azul al enfocar. La transición del
/// borde se mantiene animada (180 ms).
///
/// - [hint]: texto de ejemplo dentro del campo ("Ej. 72", "tu@correo.com").
/// - [suffixText]: unidad a la derecha ("kg", "watts", "lpm").
/// - [helperText]: guía debajo del campo.
/// - [onChanged]: para medidores en vivo (p. ej. fuerza de contraseña).
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final String? hint;
  final String? suffixText;
  final String? helperText;
  final ValueChanged<String>? onChanged;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.hint,
    this.suffixText,
    this.helperText,
    this.onChanged,
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
    final accent = _focused ? CcColors.blue : CcColors.inkFaint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            widget.label.toUpperCase(),
            style: CcType.label(size: 10, color: CcColors.inkFaint),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: _focused ? const Color(0xFF131B23) : CcColors.surfaceInset,
            border: Border.all(
              color: _focused ? CcColors.blue : CcColors.line,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(widget.icon, size: 18, color: accent),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText && _obscured,
                  keyboardType: widget.keyboardType,
                  validator: widget.validator,
                  onChanged: widget.onChanged,
                  style: const TextStyle(color: CcColors.ink, fontSize: 15),
                  cursorColor: CcColors.blue,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      color: CcColors.inkFaint,
                      fontSize: 15,
                    ),
                    suffixText: widget.obscureText ? null : widget.suffixText,
                    suffixStyle: const TextStyle(
                      color: CcColors.inkDim,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    errorStyle: const TextStyle(
                      color: Color(0xFFF5A6A4),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (widget.obscureText)
                IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: CcColors.inkFaint,
                    size: 20,
                  ),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
        if (widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 6),
            child: Text(
              widget.helperText!,
              style: const TextStyle(
                color: CcColors.inkFaint,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
      ],
    );
  }
}
