import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool compact;
  final bool destructive;
  final IconData? icon;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.compact = false,
    this.destructive = false,
    this.icon,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = (destructive ? AppColors.error : AppColors.primaryDark);
    final style = OutlinedButton.styleFrom(
      side: BorderSide(
        color: destructive ? AppColors.error : AppColors.primary,
        width: 1.2,
      ),
      foregroundColor: foreground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: compact ? 12 : 20,
            vertical: compact ? 8 : 14,
          ),
      minimumSize: compact
          ? Size(0, height ?? 36)
          : Size.fromHeight(height ?? 48),
      textStyle: TextStyle(
        fontSize: compact ? 14 : 16,
        fontWeight: FontWeight.w600,
      ),
    );

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: SizedBox(
        height: height ?? (compact ? 36 : 48),
        child: Align(
          widthFactor: compact ? 1 : null,
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: compact ? 18 : 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(child: Text(label)),
                  ],
                ),
        ),
      ),
    );
  }
}
