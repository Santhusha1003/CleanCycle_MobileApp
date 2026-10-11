import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool compact;
  final IconData? icon;
  final bool destructive;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height,
    this.padding,
    this.compact = false,
    this.icon,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.primaryDark;
    final ButtonStyle style = OutlinedButton.styleFrom(
      foregroundColor: color,
      // Tint compact icon actions; plain controls keep their existing styling.
      backgroundColor: compact && icon != null
          ? (destructive ? const Color(0xFFFFF4F4) : AppColors.greenSurface)
          : null,
      side: BorderSide(
        color: destructive ? AppColors.error : AppColors.primary,
        width: 1.2,
      ),
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

    return OutlinedButton(
      onPressed: (isLoading) ? null : onPressed,
      style: style,
      child: compact
          ? (isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
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
