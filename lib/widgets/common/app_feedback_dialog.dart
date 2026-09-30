import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Feedback type for dialog messages.
enum FeedbackType { success, error, warning, info }

/// A reusable feedback dialog widget using Material AlertDialog.
///
/// Displays feedback messages in a modal dialog with appropriate styling.
/// Supports action and cancel buttons.
class AppFeedbackDialog extends StatelessWidget {
  /// The title of the dialog.
  final String title;

  /// The message text to display.
  final String message;

  /// The type of feedback (success, error, warning, info).
  final FeedbackType type;

  /// Optional label for the action button. If null, no action button is shown.
  final String? actionLabel;

  /// Optional callback when the action button is pressed.
  final VoidCallback? onAction;

  /// Optional label for the cancel button. If null, no cancel button is shown.
  final String? cancelLabel;

  /// Optional callback when the cancel button is pressed.
  final VoidCallback? onCancel;

  const AppFeedbackDialog({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    this.cancelLabel,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForType(type);

    return AlertDialog(
      icon: Icon(_getIconForType(type), color: colors.icon, size: 32),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.white,
      elevation: 4,
      actions: [
        if (cancelLabel != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
            child: Text(
              cancelLabel!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (actionLabel != null)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.icon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onAction?.call();
            },
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getIconForType(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Icons.check_circle;
      case FeedbackType.error:
        return Icons.error;
      case FeedbackType.warning:
        return Icons.warning;
      case FeedbackType.info:
        return Icons.info;
    }
  }

  ({Color icon}) _getColorsForType(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return (icon: AppColors.success);
      case FeedbackType.error:
        return (icon: AppColors.error);
      case FeedbackType.warning:
        return (icon: AppColors.warning);
      case FeedbackType.info:
        return (icon: AppColors.info);
    }
  }
}

/// Show a feedback dialog.
///
/// This is a convenience function to show a feedback dialog using showDialog.
Future<void> showFeedbackDialog(
  BuildContext context, {
  required String title,
  required String message,
  required FeedbackType type,
  String? actionLabel,
  VoidCallback? onAction,
  String? cancelLabel,
  VoidCallback? onCancel,
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => AppFeedbackDialog(
      title: title,
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
      cancelLabel: cancelLabel,
      onCancel: onCancel,
    ),
  );
}
