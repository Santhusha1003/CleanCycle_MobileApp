import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';

/// Live checklist from the Figma "Create a New Password" screen.
class PasswordRulesChecklist extends StatelessWidget {
  const PasswordRulesChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RuleRow(
          label: AppStrings.ruleMinChars,
          met: Validators.hasMinLength(password),
        ),
        _RuleRow(
          label: AppStrings.ruleNumber,
          met: Validators.hasNumber(password),
        ),
        _RuleRow(
          label: AppStrings.ruleSpecial,
          met: Validators.hasSpecial(password),
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 22,
            color: met ? AppColors.strengthStrong : AppColors.textHint,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: met ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: met ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
