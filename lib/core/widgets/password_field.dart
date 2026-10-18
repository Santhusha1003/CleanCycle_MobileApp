import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_text_field.dart';

/// Password field with a show/hide toggle (HCI: user control and freedom).
///
/// Touch target of the eye icon is at least 48px via [IconButton].
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
    this.autofillHints = const [AutofillHints.password],
    this.onFieldSubmitted,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hintText: widget.hintText,
      controller: widget.controller,
      focusNode: widget.focusNode,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      textInputAction: widget.textInputAction,
      keyboardType: TextInputType.visiblePassword,
      obscureText: _obscured,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      suffix: IconButton(
        tooltip: _obscured ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscured = !_obscured),
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
