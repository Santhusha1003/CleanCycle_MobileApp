import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen scrim + spinner for long-running Firebase calls.
///
/// HCI: visibility of system status — the user always knows the app is busy.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: AppColors.overlayScrim,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Brand lockup used at the top of Login and related screens.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : 64.0;
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.eco_rounded,
            color: AppColors.primary,
            size: compact ? 28 : 36,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          'CleanCycle',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: compact ? 22 : 28,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Clean Today, Greener Tomorrow',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
