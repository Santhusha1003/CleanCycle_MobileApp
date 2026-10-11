import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;
  final bool showBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.elevation = 0,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.white;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: showBorder
          ? const BorderSide(color: AppColors.border)
          : BorderSide.none,
    );

    final card = Material(
      color: bg,
      elevation: elevation ?? 0,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    return Container(margin: margin, child: card);
  }
}
