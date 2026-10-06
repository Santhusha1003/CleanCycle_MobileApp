import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';

/// Live Weak / Medium / Strong meter under the Create Account password field.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = Validators.strength(password);
    if (strength == PasswordStrength.empty) {
      return const SizedBox.shrink();
    }

    final color = switch (strength) {
      PasswordStrength.weak => AppColors.strengthWeak,
      PasswordStrength.medium => AppColors.strengthMedium,
      PasswordStrength.strong => AppColors.strengthStrong,
      PasswordStrength.empty => AppColors.divider,
    };

    final fill = switch (strength) {
      PasswordStrength.weak => 0.33,
      PasswordStrength.medium => 0.66,
      PasswordStrength.strong => 1.0,
      PasswordStrength.empty => 0.0,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 6,
              color: color,
              backgroundColor: AppColors.divider,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Password strength: ${strength.label}',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
