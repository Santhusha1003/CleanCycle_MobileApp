import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Full-width green CTA used on Login, Register, Verify and Reset.
///
/// HCI: visible system status — when [isLoading] is true the button shows a
/// spinner and ignores taps so the user cannot double-submit.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Error prevention: screens pass `false` until the form is valid.
  final bool enabled;

  bool get _canTap => enabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.minTouchTarget,
      child: ElevatedButton(
        onPressed: _canTap ? onPressed : null,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Outlined social / secondary action button (Google, Apple).
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.minTouchTarget,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.textPrimary),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}
