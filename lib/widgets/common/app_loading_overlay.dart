import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// An overlay widget that displays a loading indicator with a semi-transparent background.
///
/// Used to block user interaction while an async operation is in progress.
/// Covers the entire screen or parent container with a dark overlay and centered loading indicator.
class AppLoadingOverlay extends StatelessWidget {
  /// Whether to display the loading overlay.
  /// Defaults to false.
  final bool isVisible;

  /// Optional message to display below the loading indicator.
  final String? message;

  /// The color of the overlay background.
  /// Defaults to semi-transparent black.
  final Color overlayColor;

  /// The opacity of the overlay background.
  /// Defaults to 0.5.
  final double opacity;

  /// The color of the loading indicator.
  /// Defaults to [AppColors.primary].
  final Color indicatorColor;

  const AppLoadingOverlay({
    super.key,
    this.isVisible = false,
    this.message,
    this.overlayColor = Colors.black,
    this.opacity = 0.5,
    this.indicatorColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: overlayColor.withValues(alpha: opacity),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
