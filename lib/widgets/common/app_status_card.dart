import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppStatusCard extends StatelessWidget {
  final String statusText;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const AppStatusCard({
    Key? key,
    required this.statusText,
    this.color,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = (color ?? AppColors.greenSurface);
    final textColor = AppColors.textPrimary;

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
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
