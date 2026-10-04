import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A full-screen loading indicator widget.
///
/// Used as a standalone screen or page when content is loading.
/// Displays a centered loading indicator with optional title and message.
class AppLoadingScreen extends StatelessWidget {
  /// Optional title text displayed above the loading indicator.
  final String? title;

  /// Optional message text displayed below the loading indicator.
  final String? message;

  /// The color of the loading indicator.
  /// Defaults to [AppColors.primary].
  final Color indicatorColor;

  /// The background color of the screen.
  /// Defaults to [AppColors.background].
  final Color backgroundColor;

  const AppLoadingScreen({
    super.key,
    this.title,
    this.message,
    this.indicatorColor = AppColors.primary,
    this.backgroundColor = AppColors.background,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
