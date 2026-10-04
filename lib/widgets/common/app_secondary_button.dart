import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const AppSecondaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      side: const BorderSide(color: AppColors.primary, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      minimumSize: Size.fromHeight(height ?? 48),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );

    return OutlinedButton(
      onPressed: (isLoading) ? null : onPressed,
      style: style,
      child: SizedBox(
        height: height ?? 48,
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(color: AppColors.primaryDark),
                ),
        ),
      ),
    );
  }
}
