import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppStatusCard extends StatelessWidget {
  final String statusText;
  final Color? color;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const AppStatusCard({
    super.key,
    required this.statusText,
    this.color,
    this.textColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bg = (color ?? AppColors.greenSurface);
    final foreground = textColor ?? AppColors.textPrimary;

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
