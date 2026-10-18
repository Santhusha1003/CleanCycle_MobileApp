import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  const AppPasswordField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.focusNode,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  void _toggle() {
    setState(() => _obscure = !_obscure);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      obscureText: _obscure,
      onChanged: widget.onChanged,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
          ),
          onPressed: _toggle,
        ),
      ),
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }
}
