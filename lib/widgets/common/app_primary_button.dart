import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool compact;
  final IconData? icon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height,
    this.padding,
    this.compact = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding:
          padding ??
          (compact
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
              : const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      // Compact actions retain a 48 logical-pixel touch target without the
      // full-width minimum or a second layer of vertical padding.
      minimumSize: compact ? const Size(48, 48) : Size.fromHeight(height ?? 48),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );

    return ElevatedButton(
      onPressed: (isLoading) ? null : onPressed,
      style: style,
      child: compact
          ? (isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Flexible(child: Text(label)),
                    ],
                  ))
          : SizedBox(
              height: height ?? 48,
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      )
                    : Text(label),
              ),
            ),
    );
  }
}
