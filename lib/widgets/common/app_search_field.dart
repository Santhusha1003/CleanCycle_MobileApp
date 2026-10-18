import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final FocusNode? focusNode;

  const AppSearchField({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.focusNode,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Search',
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () {
                  widget.controller.clear();
                  widget.onClear?.call();
                },
              )
            : null,
      ),
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }
}
