import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

/// Google + Apple buttons from the Login high-fidelity screen.
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({
    super.key,
    required this.onGoogle,
    required this.onApple,
  });

  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialButton(
          label: AppStrings.continueWithGoogle,
          icon: Icons.g_mobiledata,
          iconColor: AppColors.googleRed,
          onPressed: onGoogle,
        ),
        const SizedBox(height: 12),
        SocialButton(
          label: AppStrings.continueWithApple,
          icon: Icons.apple,
          iconColor: AppColors.appleBlack,
          onPressed: onApple,
        ),
      ],
    );
  }
}
