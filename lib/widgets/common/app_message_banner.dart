import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Message type for inline message banners.
enum MessageType { success, error, warning, info }

/// A reusable inline message/banner widget.
///
/// Displays feedback messages with soft background colors and appropriate icons.
/// Supports dismissible banners with optional action buttons.
class AppMessageBanner extends StatefulWidget {
  /// The message text to display.
  final String message;

  /// The type of message (success, error, warning, info).
  final MessageType type;

  /// Optional icon to display. If null, a default icon for the message type is used.
  final IconData? icon;

  /// Optional action button configuration.
  final ({String label, VoidCallback onPressed})? action;

  /// Whether the banner can be dismissed.
  final bool dismissible;

  /// Optional callback when the banner is dismissed.
  final VoidCallback? onDismissed;

  /// Optional padding for the banner content.
  final EdgeInsetsGeometry? padding;

  /// Optional margin around the banner.
  final EdgeInsetsGeometry? margin;

  const AppMessageBanner({
    super.key,
    required this.message,
    required this.type,
    this.icon,
    this.action,
    this.dismissible = false,
    this.onDismissed,
    this.padding,
    this.margin,
  });

  @override
  State<AppMessageBanner> createState() => _AppMessageBannerState();
}

class _AppMessageBannerState extends State<AppMessageBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final colors = _getColorsForType(widget.type);
    final icon = widget.icon ?? _getIconForType(widget.type);

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Padding(
        padding:
            widget.padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: colors.icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.message,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.action != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: widget.action!.onPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.icon,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        widget.action!.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.dismissible) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isDismissed = true;
                  });
                  widget.onDismissed?.call();
                },
                icon: Icon(Icons.close, color: colors.icon, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.error:
        return Icons.error;
      case MessageType.warning:
        return Icons.warning;
      case MessageType.info:
        return Icons.info;
    }
  }

  ({Color background, Color border, Color icon, Color text}) _getColorsForType(
    MessageType type,
  ) {
    switch (type) {
      case MessageType.success:
        return (
          background: AppColors.success.withValues(alpha: 0.08),
          border: AppColors.success.withValues(alpha: 0.2),
          icon: AppColors.success,
          text: AppColors.success.withValues(red: 0.2, green: 0.55, blue: 0.35),
        );
      case MessageType.error:
        return (
          background: AppColors.error.withValues(alpha: 0.08),
          border: AppColors.error.withValues(alpha: 0.2),
          icon: AppColors.error,
          text: AppColors.error.withValues(red: 0.8, green: 0.3, blue: 0.3),
        );
      case MessageType.warning:
        return (
          background: AppColors.warning.withValues(alpha: 0.08),
          border: AppColors.warning.withValues(alpha: 0.2),
          icon: AppColors.warning,
          text: AppColors.warning.withValues(red: 0.9, green: 0.65, blue: 0.14),
        );
      case MessageType.info:
        return (
          background: AppColors.info.withValues(alpha: 0.08),
          border: AppColors.info.withValues(alpha: 0.2),
          icon: AppColors.info,
          text: AppColors.info.withValues(red: 0.23, green: 0.48, blue: 0.84),
        );
    }
  }
}
