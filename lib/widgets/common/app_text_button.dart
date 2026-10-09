import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppTextButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: (isLoading) ? null : onPressed,
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : Text(label, style: const TextStyle(color: AppColors.primaryDark)),
    );
  }
}
