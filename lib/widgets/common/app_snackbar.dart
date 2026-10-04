import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Feedback type for SnackBar messages.
enum SnackBarType { success, error, warning, info }

/// Helper class to display styled SnackBars with consistent CleanCycle design.
///
/// Supports success, error, warning, and info message types.
/// Provides static methods to show snackbars with appropriate colors and icons.
class AppSnackBar {
  AppSnackBar._();

  /// Show a success SnackBar.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message,
      SnackBarType.success,
      duration: duration,
      action: action,
    );
  }

  /// Show an error SnackBar.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message,
      SnackBarType.error,
      duration: duration,
      action: action,
    );
  }

  /// Show a warning SnackBar.
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message,
      SnackBarType.warning,
      duration: duration,
      action: action,
    );
  }

  /// Show an info SnackBar.
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message,
      SnackBarType.info,
      duration: duration,
      action: action,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    SnackBarType type, {
    required Duration duration,
    SnackBarAction? action,
  }) {
    final colors = _getColorsForType(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIconForType(type), color: colors.text, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colors.background,
        elevation: 0,
        duration: duration,
        action: action,
        showCloseIcon: true,
        closeIconColor: colors.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static IconData _getIconForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle;
      case SnackBarType.error:
        return Icons.error;
      case SnackBarType.warning:
        return Icons.warning;
      case SnackBarType.info:
        return Icons.info;
    }
  }

  static ({Color background, Color text}) _getColorsForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return (
          background: AppColors.success.withValues(alpha: 0.15),
          text: AppColors.success,
        );
      case SnackBarType.error:
        return (
          background: AppColors.error.withValues(alpha: 0.15),
          text: AppColors.error,
        );
      case SnackBarType.warning:
        return (
          background: AppColors.warning.withValues(alpha: 0.15),
          text: AppColors.warning,
        );
      case SnackBarType.info:
        return (
          background: AppColors.info.withValues(alpha: 0.15),
          text: AppColors.info,
        );
    }
  }
}
